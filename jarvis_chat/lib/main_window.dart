import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:jarvis_chat/jarvis_theme.dart';
import 'package:jarvis_chat/main_page.dart';
import 'package:jarvis_chat/state/chat_state.dart';
import 'package:jarvis_chat/state/app_state.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class MainWindow extends StatefulWidget {
  final AppState store;
  final ChatState chatState;

  const MainWindow({
    super.key,
    required this.store,
    required this.chatState,
  });

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow>
    with TrayListener, WindowListener {
  void _showWindow() async {
    await windowManager.show();
    await windowManager.focus();
    widget.store.promptFocusNode.requestFocus();
  }

  void _hideWindow() async {
    await windowManager.hide();
  }

  void _toggle() async {
    if (await windowManager.isFocused()) {
      _hideWindow();
    } else {
      _showWindow();
    }
  }

  Future<void> _init() async {
    HotKey newChatHotKey = HotKey(
      key: PhysicalKeyboardKey.comma,
      modifiers: [
        Platform.isMacOS ? HotKeyModifier.meta : HotKeyModifier.control,
        HotKeyModifier.shift
      ],
    );

    await hotKeyManager.register(
      newChatHotKey,
      keyDownHandler: (hotKey) async {
        _toggle();
      },
    );

    if (Platform.isMacOS) {
      Window.setEffect(
        effect: WindowEffect.aero,
        color: Colors.transparent,
        dark: true,
      );
      Window.overrideMacOSBrightness(
        dark: true,
      );
    }
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
  void onTrayIconRightMouseDown() async {
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
    return MainPage(store: widget.store, chatState: widget.chatState);
  }

  @override
  void initState() {
    trayManager.addListener(this);
    windowManager.addListener(this);
    super.initState();
    _init();
  }
}
