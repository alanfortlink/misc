import 'dart:io';

import 'package:flutter/material.dart';

class ShortcutInfo {
  String command;
  String description;

  ShortcutInfo(this.command, this.description);
}

class ShortcutPanel extends StatelessWidget {
  ShortcutPanel({super.key});

  final keyboardKey = Platform.isMacOS ? "Command" : "Control";

  @override
  Widget build(BuildContext context) {
    final shortcuts = [
      ShortcutInfo("$keyboardKey + Enter", "Submit prompt"),
      ShortcutInfo("$keyboardKey + V", "Paste content"),
      ShortcutInfo("$keyboardKey + L", "Clear messages"),
      ShortcutInfo("$keyboardKey + C", "Clear attachments"),
      ShortcutInfo("$keyboardKey + ;", "Toggle message details"),
      ShortcutInfo("$keyboardKey + U", "Scroll up"),
      ShortcutInfo("$keyboardKey + D", "Scroll down"),
      ShortcutInfo("$keyboardKey + S", "Stop current response"),
      ShortcutInfo("$keyboardKey + ,", "Open settings"),
      ShortcutInfo("$keyboardKey + /", "Switch between ollama / openai"),
      ShortcutInfo("$keyboardKey + Shift + ,", "Show/Hide window"),
      ShortcutInfo("/code or /image", "Prefix for /code and /image models"),
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var shortcut in shortcuts) ...[
          Container(
            padding: const EdgeInsets.all(4),
            margin: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      shortcut.command,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      shortcut.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (shortcut != shortcuts.last)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 64),
              height: 1,
              width: double.infinity,
              color: Colors.white.withValues(alpha: 0.1),
            ),
        ],
      ],
    );
  }
}
