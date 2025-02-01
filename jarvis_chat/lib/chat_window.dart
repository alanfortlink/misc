import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlighting/themes/github-dark.dart';
import 'package:flutter_markdown/flutter_markdown.dart' as md;
import 'package:jarvis_chat/ollama/ollama_client.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:window_manager/window_manager.dart';

class PasteContentIntent extends Intent {
  const PasteContentIntent();
}

class PasteIntent extends Intent {
  const PasteIntent();
}

class ScrollUpIntent extends Intent {
  const ScrollUpIntent();
}

class ScrollDownIntent extends Intent {
  const ScrollDownIntent();
}

class StopIntent extends Intent {
  const StopIntent();
}

class SubmitIntent extends Intent {
  const SubmitIntent();
}

class ClearIntent extends Intent {
  final bool text;
  final bool images;
  const ClearIntent({required this.text, required this.images});
}

class ChatImage extends StatelessWidget {
  final Uint8List bytes;

  const ChatImage(this.bytes, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100.0,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          padding: const EdgeInsets.all(4.0),
          margin: const EdgeInsets.only(right: 8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
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
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  String message;
  bool isUser;
  List<Uint8List> images;

  ChatMessage(this.message, this.isUser, this.images);
}

// dark, almost black background color
const Color backgroundColor = Color(0xFF202020);

const Color ollamaMessageColor = Colors.transparent;

// dark, but can be a little grey
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

  void _scroll() {
    Future.delayed(const Duration(milliseconds: 100), () {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 10),
        curve: Curves.easeOut,
      );
    });
  }

  void _scrollUp() {
    scrollController.animateTo(
      scrollController.offset - 200,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
  }

  void _scrollDown() {
    scrollController.animateTo(
      scrollController.offset + 200,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    super.initState();

    ollamaClient = OllamaClient(onData: (data, done) {
      if (data == null) {
        return;
      }
      setState(() {
        if (currentMessage == null) {
          currentMessage = ChatMessage(data, false, []);
        } else {
          currentMessage!.message = "${currentMessage!.message}$data";
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
    setState(() {});
  }

  @override
  void dispose() {
    promptFocusNode.dispose();
    promptController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _onPromptSubmitted() {
    if (promptController.text.isEmpty) {
      return;
    }

    ollamaClient.send(promptController.text, images, pastMessages);
    pastMessages.add(ChatMessage(promptController.text, true, images));
    images = [];
    promptController.clear();
    currentMessage = ChatMessage("", false, []);
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

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        SingleActivator(
          LogicalKeyboardKey.keyS,
          meta: true,
          includeRepeats: true,
        ): StopIntent(),
        SingleActivator(
          LogicalKeyboardKey.keyV,
          meta: true,
          includeRepeats: true,
        ): PasteIntent(),
        SingleActivator(
          LogicalKeyboardKey.keyU,
          meta: true,
          includeRepeats: true,
        ): ScrollUpIntent(),
        SingleActivator(
          LogicalKeyboardKey.keyD,
          meta: true,
          includeRepeats: true,
        ): ScrollDownIntent(),
        SingleActivator(
          LogicalKeyboardKey.enter,
          meta: true,
          includeRepeats: true,
        ): SubmitIntent(),
        SingleActivator(
          LogicalKeyboardKey.keyL,
          meta: true,
          includeRepeats: true,
        ): ClearIntent(text: true, images: true),
        SingleActivator(
          LogicalKeyboardKey.keyC,
          meta: true,
          includeRepeats: true,
        ): ClearIntent(text: false, images: true),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          StopIntent: CallbackAction<StopIntent>(
            onInvoke: (StopIntent intent) async {
              _stop();
              return null;
            },
          ),
          PasteIntent: CallbackAction<PasteIntent>(
            onInvoke: (PasteIntent intent) async {
              _handlePaste();
              return null;
            },
          ),
          SubmitIntent: CallbackAction<SubmitIntent>(
            onInvoke: (SubmitIntent intent) async {
              _onPromptSubmitted();
              return null;
            },
          ),
          ScrollUpIntent: CallbackAction<ScrollUpIntent>(
            onInvoke: (ScrollUpIntent intent) async {
              _scrollUp();
              return null;
            },
          ),
          ScrollDownIntent: CallbackAction<ScrollDownIntent>(
            onInvoke: (ScrollDownIntent intent) async {
              _scrollDown();
              return null;
            },
          ),
          ClearIntent: CallbackAction<ClearIntent>(
            onInvoke: (ClearIntent intent) async {
              if (intent.text) {
                pastMessages.clear();
              }

              if (intent.images) {
                images.clear();
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
                child: ListView.builder(
                  controller: scrollController,
                  itemCount:
                      pastMessages.length + (currentMessage == null ? 0 : 1),
                  itemBuilder: (context, index) {
                    final message = index < pastMessages.length
                        ? pastMessages[index]
                        : ChatMessage(
                            (currentMessage!.message.trim().isEmpty)
                                ? "..."
                                : currentMessage!.message,
                            false,
                            [],
                          );
                    return Container(
                      padding: const EdgeInsets.all(4.0),
                      margin: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: message.isUser
                              ? BorderSide.none
                              : BorderSide(
                                  color: Colors.white.withValues(alpha: 0.1),
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
                            margin:
                                const EdgeInsets.only(top: 8.0, bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: message.isUser
                                        ? userMessageColor
                                        : ollamaMessageColor,
                                    borderRadius: BorderRadius.circular(8.0),
                                    boxShadow: [],
                                  ),
                                  child: md.MarkdownBody(
                                    builders: {
                                      "pre": MarkdownCodeBlockBuilder(),
                                    },
                                    fitContent: message.isUser,
                                    selectable: true,
                                    data: message.message,
                                    styleSheet: md.MarkdownStyleSheet(
                                      codeblockPadding:
                                          const EdgeInsets.all(12.0),
                                      blockquoteDecoration: BoxDecoration(
                                        color: backgroundColor.darken(0.5),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
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
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 16.0),
                child: Row(
                  children: images.map((bytes) => ChatImage(bytes)).toList(),
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
                        onSubmitted: (_) => _onPromptSubmitted(),
                        controller: promptController,
                        onChanged: (value) {
                          if (value.length > oldText.length + 1) {
                            // _handlePaste();
                          } else {
                            oldText = value;
                          }
                          setState(() {});
                        },
                        decoration: const InputDecoration(
                          hintText: "Prompt...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    currentMessage == null
                        ? IconButton(
                            disabledColor: Colors.grey,
                            onPressed: promptController.text.isEmpty
                                ? null
                                : _onPromptSubmitted,
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
  @override
  Widget? visitText(text, TextStyle? preferredStyle) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.only(top: 8.0),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: HighlightView(
              text.text,
              language: "dart",
              theme: githubDarkTheme.map((key, value) {
                return MapEntry(
                  key,
                  key == "root"
                      ? value.copyWith(
                          backgroundColor: Colors.transparent,
                        )
                      : value,
                );
              }),
              padding: EdgeInsets.all(12),
            ),
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
