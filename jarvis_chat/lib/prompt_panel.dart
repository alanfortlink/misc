import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:jarvis_chat/jarvis_theme.dart';
import 'package:jarvis_chat/settings_page.dart';
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

  DateTime lastCheck = DateTime.now().subtract(const Duration(seconds: 2));
  DateTime lastCommand = DateTime.now().subtract(const Duration(seconds: 2));

  Future<void> _onPromptChanged(value) async {
    if (value.length <= oldText.length + 1) {
      oldText = value;
    }
    setState(() {});
  }

  @override
  void initState() {
    _init();
    super.initState();
  }

  void _init() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final chatState = Provider.of<ChatState>(context, listen: false);

    chatState.addOnDataCallback(_onData);
    chatState.addOnErrorCallback(_onError);

    Future.delayed(
      const Duration(milliseconds: 100),
      () async {
        appState.serverUp = await chatState.checkConnection(appState);
      },
    );

    final shortcuts = {
      LogicalKeyboardKey.keyS: () {
        _stopPrompt();
      },
      LogicalKeyboardKey.keyV: () {
        _handlePaste();
      },
      LogicalKeyboardKey.slash: () {
        appState.useOpenAI = !appState.useOpenAI;
      },
      LogicalKeyboardKey.keyU: () {
        _scrollOffset(-appState.lastHeight);
      },
      LogicalKeyboardKey.keyD: () {
        _scrollOffset(appState.lastHeight);
      },
      LogicalKeyboardKey.keyL: () {
        _stopPrompt();
        chatState.clearAttachments();
        chatState.messages.clear();
      },
      LogicalKeyboardKey.keyC: () {
        chatState.clearAttachments();
      },
      LogicalKeyboardKey.enter: () {
        _onPromptSubmitted();
      },
      LogicalKeyboardKey.comma: () {
        if (DateTime.now().difference(lastCommand).inSeconds < 1) {
          return;
        }

        lastCommand = DateTime.now();

        if (SettingsPage.open) {
          Navigator.of(context).pop();
          SettingsPage.open = false;
          return;
        }

        SettingsPage.open = true;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider<AppState>.value(
              value: appState,
              child: ChangeNotifierProvider<ChatState>.value(
                value: chatState,
                child: const SettingsPage(),
              ),
            ),
          ),
        );
      },
      LogicalKeyboardKey.semicolon: () {
        appState.detailsEnabled = !appState.detailsEnabled;
        if (appState.detailsEnabled) {
          _scrollOffset(30);
        }
        chatState.clearAttachments();
      },
    };

    for (final entry in shortcuts.entries) {
      final key = entry.key;
      final value = entry.value;

      final newHotKey = HotKey(
        key: key,
        modifiers: [HotKeyModifier.meta],
        scope: HotKeyScope.inapp,
      );

      await hotKeyManager.register(
        newHotKey,
        keyDownHandler: (hotKey) async {
          value();
        },
      );
    }
  }

  @override
  void dispose() {
    final chatState = Provider.of<ChatState>(context, listen: false);
    chatState.removeOnDataCallback(_onData);
    chatState.removeOnErrorCallback(_onError);
    super.dispose();
  }

  void _onError(_) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final chatState = Provider.of<ChatState>(context, listen: false);

    if (DateTime.now().difference(lastCheck).inSeconds < 2) {
      return;
    }

    lastCheck = DateTime.now();

    appState.serverUp = await chatState.checkConnection(appState);
    setState(() {});
  }

  void _onData(chunk, __) async {
    final appState = Provider.of<AppState>(context, listen: false);

    if (chunk.done) {
      Future.delayed(
        const Duration(milliseconds: 100),
        () {
          appState.promptFocusNode.requestFocus();
        },
      );
    }

    Future.delayed(
      const Duration(milliseconds: 100),
      () {
        if (!appState.messagesScrollController.hasClients) {
          return;
        }

        if (appState.messagesScrollController.position.maxScrollExtent ==
            appState.messagesScrollController.offset) {
          return;
        }

        appState.messagesScrollController.jumpTo(
          appState.messagesScrollController.position.maxScrollExtent,
        );
      },
    );
  }

  void _handlePaste() async {
    if (SettingsPage.open) {
      return;
    }

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

    await _stopPrompt();

    if (appState.promptTextController.text.isEmpty) {
      return;
    }

    if (!appState.serverUp) {
      appState.serverUp = await chatState.checkConnection(appState);
      if (!appState.serverUp) {
        return;
      }
    }

    await chatState.send(appState.promptTextController.text, appState);
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
    final appState = Provider.of<AppState>(context, listen: false);
    final chatState = Provider.of<ChatState>(context, listen: false);
    await chatState.stop(appState);
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

    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.end,
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
                  minLines: 1,
                  maxLines: 8,
                  controller: appState.promptTextController,
                  focusNode: appState.promptFocusNode,
                  autofocus: true,
                  canRequestFocus: true,
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
                        appState.serverUp =
                            await chatState.checkConnection(appState);
                        setState(() {});
                      },
                    )
                  : chatState.incoming == null
                      ? IconButton(
                          icon: Icon(
                            appState.useOpenAI ? Icons.wifi : Icons.send,
                          ),
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
    );
  }
}
