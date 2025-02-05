import 'dart:io';

import 'package:flutter/material.dart';

class ShortcutInfo {
  String command;
  String description;

  ShortcutInfo(this.command, this.description);
}

class ShortcutPanel extends StatelessWidget {
  ShortcutPanel({super.key});

  final keyboardKey = Platform.isMacOS ? "⌘" : "Ctrl";

  @override
  Widget build(BuildContext context) {
    final shortcuts = [
      ShortcutInfo("$keyboardKey + ⏎", "Submit Prompt"),
      ShortcutInfo("$keyboardKey + V", "Paste Content"),
      ShortcutInfo("$keyboardKey + L", "Clear Messages"),
      ShortcutInfo("$keyboardKey + C", "Clear Attachments"),
      ShortcutInfo("$keyboardKey + ;", "Toggle Details"),
      ShortcutInfo("$keyboardKey + U", "Scroll ⬆︎"),
      ShortcutInfo("$keyboardKey + D", "Scroll ⬇︎"),
      ShortcutInfo("$keyboardKey + S", "Stop Response"),
      ShortcutInfo("$keyboardKey + ,", "Open Settings"),
      ShortcutInfo("$keyboardKey + /", "Switch between ollama / openai"),
      ShortcutInfo("$keyboardKey + ⇧ + ,", "Show/Hide window"),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final value in shortcut.command.split(" "))
                          Container(
                            constraints: BoxConstraints(
                              minWidth: 32,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Text(
                              value,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize:
                                    (value == "+" || value == "or") ? 14 : 16,
                                fontWeight: (value == "+" || value == "or")
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                Icon(
                  size: 14,
                  Icons.arrow_forward,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      shortcut.description,
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: 0.4,
                        ),
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
              margin: const EdgeInsets.symmetric(horizontal: 100),
              height: 1,
              width: double.infinity,
              color: Colors.white.withValues(alpha: 0.1),
            ),
        ],
      ],
    );
  }
}
