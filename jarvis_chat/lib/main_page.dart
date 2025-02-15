import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jarvis_chat/image_panel.dart';
import 'package:jarvis_chat/jarvis_theme.dart';
import 'package:jarvis_chat/message_panel.dart';
import 'package:jarvis_chat/prompt_panel.dart';
import 'package:jarvis_chat/shortcut_panel.dart';
import 'package:jarvis_chat/state/chat_state.dart';
import 'package:jarvis_chat/state/app_state.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  final AppState store;
  final ChatState chatState;

  const MainPage({
    super.key,
    required this.store,
    required this.chatState,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    final bgColor =
        Platform.isMacOS ? Colors.transparent : JarvisTheme.backgroundColor;

    return MaterialApp(
      color: bgColor,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
      ),
      home: ChangeNotifierProvider.value(
        value: widget.store,
        child: ChangeNotifierProvider.value(
          value: widget.chatState,
          child: Scaffold(
            backgroundColor: bgColor,
            body: MainPanel(),
          ),
        ),
      ),
    );
  }
}

class MainPanel extends StatefulWidget {
  const MainPanel({super.key});

  @override
  State<MainPanel> createState() => _MainPanelState();
}

class _MainPanelState extends State<MainPanel> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final chatState = Provider.of<ChatState>(context);

    final allMessages = [
      ...chatState.messages,
      if (chatState.incoming != null) chatState.incoming
    ];

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: JarvisTheme.backgroundColor,
        border: Border.all(
          color: JarvisTheme.muchBrighterThanBackground.withValues(
            alpha: 0.5,
          ),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
        // gradient: LinearGradient(
        //   begin: Alignment.topLeft,
        //   end: Alignment.bottomRight,
        //   colors: [
        //     JarvisTheme.backgroundColor,
        //     JarvisTheme.backgroundColor.withValues(
        //       alpha: 0.99,
        //     ),
        //   ],
        // ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                allMessages.isEmpty
                    ? Align(
                        alignment: Alignment.center,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "No messages yet",
                                style: TextStyle(
                                  color: JarvisTheme.textColor,
                                  fontSize: 16.0,
                                ),
                              ),
                              const SizedBox(height: 40),
                              ShortcutPanel(),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: appState.messagesScrollController,
                        itemCount: allMessages.length,
                        itemBuilder: (context, index) {
                          return MessagePanel(
                            message: allMessages[index]!,
                          );
                        },
                        separatorBuilder: (context, index) {
                          return allMessages[index]!.isUser
                              ? Container()
                              : Container(
                                  height: 1,
                                  color: JarvisTheme.muchBrighterThanBackground,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                );
                        },
                      ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: chatState.attachments
                        .map(
                          (attachment) => ImagePanel(
                            attachment,
                            onRemove: () {
                              chatState.attachments.remove(attachment);
                              setState(() {});
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PromptPanel(),
        ],
      ),
    );
  }
}
