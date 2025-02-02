import 'package:flutter/material.dart';

class ShortcutInfo {
  String command;
  String description;

  ShortcutInfo(this.command, this.description);
}

class ShortcutPanel extends StatelessWidget {
  ShortcutPanel({super.key});

  final shortcuts = [
    ShortcutInfo("Command + Enter", "Submit prompt"),
    ShortcutInfo("Command + V", "Paste content"),
    ShortcutInfo("Command + L", "Clear messages"),
    ShortcutInfo("Command + C", "Clear attachments"),
    ShortcutInfo("Command + ;", "Toggle message details"),
    ShortcutInfo("Command + U", "Scroll up"),
    ShortcutInfo("Command + D", "Scroll down"),
    ShortcutInfo("Command + S", "Stop current response"),
    ShortcutInfo("Command + ,", "Open settings"),
    ShortcutInfo("Command + Shift + ,", "Show/Hide window"),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
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
