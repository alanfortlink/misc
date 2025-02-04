import 'package:flutter/material.dart';
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
    return MaterialApp(
      home: ChangeNotifierProvider.value(
        value: widget.store,
        child: ChangeNotifierProvider.value(
          value: widget.chatState,
          child: Scaffold(
            backgroundColor: JarvisTheme.backgroundColor,
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
      margin: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: allMessages.isEmpty
                ? Align(
                    alignment: Alignment.center,
                    child: ShortcutPanel(),
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
                              color: JarvisTheme.brighterThanBackground,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                            );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          PromptPanel(),
        ],
      ),
    );
  }
}
