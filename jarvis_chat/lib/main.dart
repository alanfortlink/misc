import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_acrylic/window.dart';
import 'package:flutter_acrylic/window_effect.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:jarvis_chat/main_window.dart';
import 'package:jarvis_chat/state/chat_state.dart';
import 'package:jarvis_chat/state/app_state.dart';
import 'package:syntax_highlight/syntax_highlight.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  late final AppState store = AppState();
  await store.init();

  late final chatState = ChatState();
  await chatState.init(store);

  await Highlighter.initialize(['dart']);

  await Window.initialize();

  await windowManager.ensureInitialized();
  WindowOptions windowOptions = WindowOptions(
    size: Size(
      store.lastWidth.toDouble(),
      store.lastHeight.toDouble(),
    ),
    center: false,
    backgroundColor: Colors.transparent,
    skipTaskbar: Platform.isMacOS,
    titleBarStyle:
        Platform.isMacOS ? TitleBarStyle.hidden : TitleBarStyle.normal,
    windowButtonVisibility: false,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    windowManager.setPosition(
      Offset(
        store.lastX.toDouble(),
        store.lastY.toDouble(),
      ),
    );
    await windowManager.show();
  });

  await trayManager.setIcon("assets/images/icon.png");

  await trayManager.setContextMenu(Menu(items: [
    MenuItem(
      key: "open_chat",
      toolTip: "Open Chat",
      label: "Open Chat",
    ),
    MenuItem(
      key: "hide_chat",
      toolTip: "Hide Chat",
      label: "Hide Chat",
    ),
    MenuItem(
      key: "quit",
      toolTip: "Quit",
      label: "Quit",
    ),
  ]));

  await hotKeyManager.unregisterAll();

  runApp(MainWindow(store: store, chatState: chatState));
}
