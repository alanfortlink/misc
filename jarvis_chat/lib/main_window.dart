import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:jarvis_chat/chat_window.dart';
import 'package:jarvis_chat/command_w_closer.dart';
import 'package:jarvis_chat/local_store.dart';
import 'package:provider/provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> with TrayListener {
  late final LocalStore store = LocalStore();

  void _toggle() async {
    if (await windowManager.isVisible()) {
      await windowManager.hide();
    } else {
      await windowManager.show();
      await windowManager.focus();
    }
  }

  Future<void> _init() async {
    await store.init();
    HotKey newChatHotKey = HotKey(
      key: PhysicalKeyboardKey.comma,
      modifiers: [HotKeyModifier.meta, HotKeyModifier.shift],
    );

    await hotKeyManager.register(
      newChatHotKey,
      keyDownHandler: (hotKey) async {
        _toggle();
      },
    );
  }

  @override
  void onTrayIconMouseDown() async {}

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == "show_window") {
    } else if (menuItem.key == "exit_app") {}

    super.onTrayMenuItemClick(menuItem);
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    super.dispose();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jarvis Chat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: CommandWCloser(
        child: Scaffold(
          body: ChangeNotifierProvider<LocalStore>.value(
            value: store,
            child: ChatWindow(),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    trayManager.addListener(this);
    super.initState();
    _init();
  }
}
