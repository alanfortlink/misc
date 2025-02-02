import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlighting/themes/github-dark.dart';
import 'package:flutter_markdown/flutter_markdown.dart' as md;
import 'package:jarvis_chat/local_store.dart';
import 'package:jarvis_chat/ollama/ollama_client.dart';
import 'package:jarvis_chat/settings_window.dart';
import 'package:jarvis_chat/shortcut_panel.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:provider/provider.dart';
import 'package:syntax_highlight/syntax_highlight.dart';
import 'package:window_manager/window_manager.dart';

class ShortcutIntent extends Intent {
  final String id;
  const ShortcutIntent(this.id);
}

class ChatImage extends StatelessWidget {
  final Uint8List bytes;
  final VoidCallback? onRemove;

  const ChatImage(this.bytes, {super.key, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) {
                return Dialog(
                  child: Image.memory(bytes),
                );
              },
            );
          },
          child: SizedBox(
            height: 80.0,
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                margin: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: Colors.grey[700]!.withValues(alpha: 0.5),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8.0),
                ),
              ),
              child: InkWell(
                onTap: onRemove,
                child: Icon(
                  Icons.close,
                  size: 16.0,
                ),
              ),
            ),
          ),
      ],
    ).animate().scale(
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
        );
  }
}

class ChatMessage {
  String message;
  bool isUser;
  List<Uint8List> images;
  String model;

  ChatMessage(this.message, this.isUser, this.images, this.model);
}

const Color backgroundColor = Color(0xFF202020);
const Color ollamaMessageColor = Colors.transparent;
const Color userMessageColor = Color(0xFF333333);

class ChatWindow extends StatefulWidget {
  const ChatWindow({super.key});

  @override
  State<ChatWindow> createState() => _ChatWindowState();
}

class _ChatWindowState extends State<ChatWindow> with WindowListener {
  late OllamaClient ollamaClient;

  final List<ChatMessage> pastMessages = [];

  final TextEditingController promptController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode promptFocusNode = FocusNode();

  ChatMessage? currentMessage;
  List<Uint8List> images = [];
  String oldText = "";
  final MarkdownCodeBlockBuilder _markdownCodeBlockBuilder =
      MarkdownCodeBlockBuilder();
  late final Highlighter highlighter;

  void _scroll() {
    Future.delayed(const Duration(milliseconds: 100), () {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 10),
        curve: Curves.easeOut,
      );
    });
  }

  void _scrollOffset(offset) {
    scrollController.animateTo(
      scrollController.offset + offset,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    super.initState();

    ollamaClient = OllamaClient(onData: (data, done, images, model) {
      if (data == null) {
        return;
      }
      setState(() {
        if (currentMessage == null) {
          currentMessage = ChatMessage(data, false, images, model);
        } else {
          currentMessage!.message = "${currentMessage!.message}$data";
          currentMessage!.images.addAll(images);
          currentMessage!.model = model;
        }

        if (done) {
          pastMessages.add(currentMessage!);
          currentMessage = null;
          FocusScope.of(context).requestFocus(promptFocusNode);
        }

        _scroll();
      });
    });
    _init();
  }

  void _init() async {
    final theme = await HighlighterTheme.loadDarkTheme();
    highlighter = Highlighter(language: 'dart', theme: theme);
    await _markdownCodeBlockBuilder.init(highlighter);
    setState(() {});
  }

  @override
  void dispose() {
    promptFocusNode.dispose();
    promptController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _onPromptSubmitted(LocalStore store) {
    if (promptController.text.isEmpty) {
      return;
    }

    if (!store.isServerUp) {
      return;
    }

    final prompt = ChatMessage(promptController.text, true, images, "user");
    ollamaClient.send(prompt, pastMessages, store);
    pastMessages.add(prompt);

    images = [];
    promptController.clear();
    currentMessage = ChatMessage("", false, [], "");
    _scroll();
    setState(() {});
  }

  void _handlePaste() async {
    final files = await Pasteboard.files();
    final image = await Pasteboard.image;

    if (files.isEmpty && image == null) {
      final text = await Pasteboard.text;

      if (text != null) {
        if (promptController.text.isNotEmpty) {
          if (promptController.selection.baseOffset ==
              promptController.selection.extentOffset) {
            promptController.text = promptController.text.substring(
                  0,
                  promptController.selection.baseOffset,
                ) +
                text +
                promptController.text.substring(
                  promptController.selection.baseOffset,
                );
          } else {
            promptController.text = promptController.text.replaceRange(
              promptController.selection.baseOffset,
              promptController.selection.extentOffset,
              text,
            );
          }
        } else {
          promptController.text = text;
        }

        promptController.selection = TextSelection.collapsed(
          offset: promptController.text.length,
        );
      }
      setState(() {});
      return;
    }

    if (files.isNotEmpty) {
      for (final file in files) {
        final bytes = await File(file).readAsBytes();
        images.add(bytes);
      }
      setState(() {});
      return;
    }

    if (image != null) {
      images.add(image);
      setState(() {});
      return;
    }

    promptController.text = oldText;
    setState(() {});
  }

  void _stop() {
    if (currentMessage == null) {
      return;
    }

    ollamaClient.stop();
    pastMessages.add(currentMessage!);
    currentMessage = null;
    setState(() {});
  }

  bool isCheckingConnection = false;

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<LocalStore>(context);

    final shortcuts = {
      LogicalKeyboardKey.keyS: "stop",
      LogicalKeyboardKey.keyV: "paste",
      LogicalKeyboardKey.keyU: "scrollUp",
      LogicalKeyboardKey.keyD: "scrollDown",
      LogicalKeyboardKey.keyL: "clearAll",
      LogicalKeyboardKey.keyC: "clearImages",
      LogicalKeyboardKey.enter: "submit",
      LogicalKeyboardKey.comma: "settings",
      LogicalKeyboardKey.semicolon: "toggleDetails",
    };

    return Shortcuts(
      shortcuts: shortcuts.map(
        (key, value) => MapEntry(
          SingleActivator(key, meta: true, includeRepeats: true),
          ShortcutIntent(value),
        ),
      ),
      child: Actions(
        actions: <Type, Action<Intent>>{
          ShortcutIntent: CallbackAction<ShortcutIntent>(
            onInvoke: (ShortcutIntent intent) async {
              if (intent.id == "stop") {
                _stop();
              } else if (intent.id == "paste") {
                _handlePaste();
              } else if (intent.id == "scrollUp") {
                _scrollOffset(-200);
              } else if (intent.id == "scrollDown") {
                _scrollOffset(200);
              } else if (intent.id == "submit") {
                _onPromptSubmitted(store);
              } else if (intent.id == "clearAll") {
                pastMessages.clear();
                images.clear();
              } else if (intent.id == "clearImages") {
                images.clear();
              } else if (intent.id == "toggleDetails") {
                store.detailsEnabled = !store.detailsEnabled;
                if (store.detailsEnabled) {
                  _scroll();
                }
                images.clear();
              } else if (intent.id == "settings") {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ChangeNotifierProvider<LocalStore>.value(
                      value: store,
                      child: const SettingsWindow(),
                    ),
                  ),
                );
              }

              setState(() {});
              return null;
            },
          ),
        },
        child: Container(
          color: backgroundColor,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ListView.builder(
                      controller: scrollController,
                      itemCount: pastMessages.length +
                          (currentMessage == null ? 0 : 1),
                      itemBuilder: (context, index) {
                        final message = index < pastMessages.length
                            ? pastMessages[index]
                            : ChatMessage(
                                (currentMessage!.message.trim().isEmpty)
                                    ? ""
                                    : currentMessage!.message,
                                false,
                                [],
                                "",
                              );
                        return Container(
                          padding: const EdgeInsets.all(4.0),
                          margin: const EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: message.isUser
                                  ? BorderSide.none
                                  : BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.1),
                                      width: 1.0,
                                    ),
                            ),
                          ),
                          child: ListTile(
                            title: Align(
                              alignment: message.isUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(
                                    top: 8.0, bottom: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        color: message.isUser
                                            ? userMessageColor
                                            : ollamaMessageColor,
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        boxShadow: [],
                                      ),
                                      child: (message.message.trim().isEmpty)
                                          ? Align(
                                              alignment: Alignment.centerLeft,
                                              child: Container(
                                                width: 24.0,
                                                height: 24.0,
                                                child:
                                                    CircularProgressIndicator(
                                                  color:
                                                      Colors.white.withValues(
                                                    alpha: 0.5,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : md.MarkdownBody(
                                              softLineBreak: true,
                                              builders: {
                                                "pre":
                                                    _markdownCodeBlockBuilder,
                                              },
                                              fitContent: message.isUser,
                                              selectable: true,
                                              data: message.message,
                                              styleSheet: md.MarkdownStyleSheet(
                                                codeblockPadding:
                                                    const EdgeInsets.all(12.0),
                                                blockquoteDecoration:
                                                    BoxDecoration(
                                                  color: backgroundColor
                                                      .darken(0.5),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.1),
                                                    width: 1.0,
                                                  ),
                                                ),
                                                p: TextStyle(
                                                  color: message.isUser
                                                      ? Colors.white
                                                      : Colors.white,
                                                ),
                                              ),
                                            ),
                                    ),
                                    Container(
                                      child: Row(
                                        mainAxisAlignment: message.isUser
                                            ? MainAxisAlignment.end
                                            : MainAxisAlignment.start,
                                        children: message.images
                                            .map((bytes) => ChatImage(bytes))
                                            .toList(),
                                      ),
                                    ),
                                    if (!message.isUser && store.detailsEnabled)
                                      Align(
                                        alignment: Alignment.bottomLeft,
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                            left: 8.0,
                                          ),
                                          child: Text(
                                            message.model,
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.4,
                                              ),
                                              fontWeight: FontWeight.normal,
                                              fontSize: 8.0,
                                            ),
                                          ),
                                        ).animate().scale(
                                              duration: const Duration(
                                                  milliseconds: 100),
                                              curve: Curves.easeOut,
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (pastMessages.isEmpty)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "No Messages Yet",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 14.0,
                              ),
                            ),
                            const SizedBox(height: 32.0),
                            ShortcutPanel(),
                          ],
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 16,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: images
                              .map(
                                (bytes) => Container(
                                  color: Colors.transparent,
                                  margin: const EdgeInsets.all(4.0),
                                  child: Center(
                                    child: ChatImage(
                                      bytes,
                                      onRemove: () {
                                        images.remove(bytes);
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: backgroundColor.darken(0.7),
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: backgroundColor.withValues(alpha: 0.8),
                      blurRadius: 4.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TextField(
                        maxLines: null,
                        focusNode: promptFocusNode,
                        onSubmitted: (_) => _onPromptSubmitted(store),
                        controller: promptController,
                        onChanged: (value) {
                          if (value.length > oldText.length + 1) {
                            // _handlePaste();
                          } else {
                            oldText = value;
                          }
                          setState(() {});
                        },
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        decoration: const InputDecoration(
                          hintText: "Prompt...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    !store.isServerUp
                        ? IconButton(
                            onPressed: () async {
                              isCheckingConnection = true;
                              setState(() {});
                              await store.checkConnection();
                              isCheckingConnection = false;
                              setState(() {});
                            },
                            icon: Tooltip(
                              message: "ollama server offline",
                              child: Icon(
                                Icons.cloud_off,
                              ),
                            ),
                          )
                        : currentMessage == null
                            ? IconButton(
                                disabledColor: Colors.grey,
                                onPressed: promptController.text.isEmpty
                                    ? null
                                    : () => _onPromptSubmitted(store),
                                icon: const Icon(Icons.send),
                              )
                            : IconButton(
                                onPressed: () {
                                  _stop();
                                },
                                icon: const Icon(Icons.stop),
                              ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on Color {
  darken(double d) {
    return Color.from(
      alpha: a * d,
      red: r * d,
      green: g * d,
      blue: b * d,
    );
  }
}

class MarkdownCodeBlockBuilder extends md.MarkdownElementBuilder {
  late Highlighter highlighter;

  Future<void> init(Highlighter highlighter) async {
    this.highlighter = highlighter;
  }

  @override
  Widget? visitText(text, TextStyle? preferredStyle) {
    final highlightedCode = highlighter.highlight(text.text);

    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.only(top: 8.0),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text.rich(
              highlightedCode,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.0,
                fontFamily: "monospace",
              ),
            ),
            // HighlightView(
            //   text.text,
            //   language: "dart",
            //   theme: githubDarkTheme.map((key, value) {
            //     return MapEntry(
            //       key,
            //       key == "root"
            //           ? value.copyWith(
            //               backgroundColor: Colors.transparent,
            //             )
            //           : value,
            //     );
            //   }),
            //   padding: EdgeInsets.all(12),
            // ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: text.text));
              },
              icon: Icon(
                Icons.copy,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
