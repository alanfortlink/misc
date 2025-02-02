import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:jarvis_chat/local_store.dart';
import 'package:jarvis_chat/main_window.dart';
import 'package:syntax_highlight/syntax_highlight.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  late final LocalStore store = LocalStore();
  await store.init();

  await Highlighter.initialize(['dart', 'yaml', 'sql']);

  await windowManager.ensureInitialized();
  WindowOptions windowOptions = WindowOptions(
    size: Size(
      store.lastWidth.toDouble(),
      store.lastHeight.toDouble(),
    ),
    center: false,
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
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

  runApp(MainWindow(store: store));
}
