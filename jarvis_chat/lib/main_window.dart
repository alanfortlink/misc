import 'dart:io';

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
  final LocalStore store;

  const MainWindow({super.key, required this.store});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow>
    with TrayListener, WindowListener {
  void _showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  void _hideWindow() async {
    await windowManager.hide();
  }

  void _toggle() async {
    if (await windowManager.isVisible()) {
      _hideWindow();
    } else {
      _showWindow();
    }
  }

  Future<void> _init() async {
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

  Future<void> saveWindowState() async {
    final position = await windowManager.getPosition();
    widget.store.lastX = position.dx.toInt();
    widget.store.lastY = position.dy.toInt();

    final size = await windowManager.getSize();
    widget.store.lastWidth = size.width.toInt();
    widget.store.lastHeight = size.height.toInt();
  }

  @override
  void onWindowResized() {
    saveWindowState();
    super.onWindowResized();
  }

  @override
  void onWindowMoved() {
    saveWindowState();
    super.onWindowMoved();
  }

  @override
  void onTrayIconMouseDown() async {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == "open_chat") {
      _showWindow();
    } else if (menuItem.key == "quit") {
      await windowManager.close();
      exit(0);
    } else if (menuItem.key == "hide_chat") {
      _hideWindow();
    }

    super.onTrayMenuItemClick(menuItem);
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
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
      home: SelectionArea(
        child: CommandWCloser(
          child: Scaffold(
            body: ChangeNotifierProvider<LocalStore>.value(
              value: widget.store,
              child: ChatWindow(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    trayManager.addListener(this);
    windowManager.addListener(this);
    super.initState();
    _init();
  }
}
