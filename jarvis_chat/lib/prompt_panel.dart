import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jarvis_chat/image_panel.dart';
import 'package:jarvis_chat/jarvis_theme.dart';
import 'package:jarvis_chat/settings_page.dart';
import 'package:jarvis_chat/shortcut_intent.dart';
import 'package:jarvis_chat/state/chat_state.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:provider/provider.dart';

import 'state/app_state.dart';

class PromptPanel extends StatefulWidget {
  const PromptPanel({super.key});

  @override
  State<PromptPanel> createState() => _PromptPanelState();
}

class _PromptPanelState extends State<PromptPanel> {
  String oldText = "";
  bool lastServerUp = false;

  DateTime lastCheck = DateTime.now().subtract(const Duration(seconds: 2));

  Future<void> _onPromptChanged(value) async {
    if (value.length <= oldText.length + 1) {
      oldText = value;
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final chatState = Provider.of<ChatState>(context, listen: false);

    appState.serverUp = await chatState.checkConnection(appState);
    setState(() {});

    chatState.addListener(_autoScroll);
  }

  @override
  void dispose() {
    final chatState = Provider.of<ChatState>(context, listen: false);
    chatState.removeListener(_autoScroll);
    super.dispose();
  }

  void _autoScroll() async {
    final appState = Provider.of<AppState>(context, listen: false);

    if (!appState.messagesScrollController.hasClients) {
      return;
    }

    if (appState.messagesScrollController.position.maxScrollExtent ==
        appState.messagesScrollController.offset) {
      return;
    }

    appState.messagesScrollController.animateTo(
      appState.messagesScrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 10),
      curve: Curves.elasticOut,
    );
  }

  void _handlePaste() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final chatState = Provider.of<ChatState>(context, listen: false);

    final files = await Pasteboard.files();
    final image = await Pasteboard.image;

    final promptController = appState.promptTextController;

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
        chatState.addAttachment(bytes);
      }
      setState(() {});
      return;
    }

    if (image != null) {
      chatState.addAttachment(image);
      setState(() {});
      return;
    }

    promptController.text = oldText;
    setState(() {});
  }

  Future<void> _onPromptSubmitted() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final chatState = Provider.of<ChatState>(context, listen: false);

    if (appState.promptTextController.text.isEmpty) {
      return;
    }

    if (!appState.serverUp) {
      return;
    }

    await chatState.send(appState.promptTextController.text);
    appState.promptTextController.clear();

    if (appState.messagesScrollController.hasClients) {
      Future.delayed(
        const Duration(milliseconds: 100),
        () {
          appState.messagesScrollController.animateTo(
            appState.messagesScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 10),
            curve: Curves.elasticOut,
          );
        },
      );
    }
    setState(() {});
  }

  Future<void> _stopPrompt() async {
    final chatState = Provider.of<ChatState>(context, listen: false);
    await chatState.stop();
  }

  void _scrollOffset(offset) {
    final appState = Provider.of<AppState>(context, listen: false);
    if (!appState.messagesScrollController.hasClients) {
      return;
    }
    appState.messagesScrollController.animateTo(
      appState.messagesScrollController.offset + offset,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final chatState = Provider.of<ChatState>(context);

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
                _stopPrompt();
              } else if (intent.id == "paste") {
                _handlePaste();
              } else if (intent.id == "scrollUp") {
                _scrollOffset(-200);
              } else if (intent.id == "scrollDown") {
                _scrollOffset(200);
              } else if (intent.id == "submit") {
                _onPromptSubmitted();
              } else if (intent.id == "clearAll") {
                _stopPrompt();
                chatState.clearAttachments();
                chatState.messages.clear();
              } else if (intent.id == "clearImages") {
                chatState.clearAttachments();
              } else if (intent.id == "toggleDetails") {
                appState.detailsEnabled = !appState.detailsEnabled;
                if (appState.detailsEnabled) {
                  _scrollOffset(30);
                }
                chatState.clearAttachments();
              } else if (intent.id == "settings") {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ChangeNotifierProvider<AppState>.value(
                      value: appState,
                      child: ChangeNotifierProvider<ChatState>.value(
                        value: chatState,
                        child: const SettingsPage(),
                      ),
                    ),
                  ),
                );
              }

              setState(() {});
              return null;
            },
          ),
        },
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: JarvisTheme.darkerThanBackground,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      maxLines: null,
                      controller: appState.promptTextController,
                      focusNode: appState.promptFocusNode,
                      style: TextStyle(
                        color: JarvisTheme.textColor,
                      ),
                      onChanged: _onPromptChanged,
                      decoration: InputDecoration(
                        hintText: "Prompt...",
                        border: InputBorder.none,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  (!appState.serverUp)
                      ? IconButton(
                          icon: Icon(Icons.cloud_off),
                          onPressed: () async {
                            await chatState.checkConnection(appState);
                          },
                        )
                      : chatState.incoming == null
                          ? IconButton(
                              icon: Icon(Icons.send),
                              onPressed: _onPromptSubmitted,
                            )
                          : IconButton(
                              icon: Icon(Icons.stop),
                              onPressed: _stopPrompt,
                            )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
