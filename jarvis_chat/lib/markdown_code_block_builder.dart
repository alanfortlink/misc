import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart' as md;
import 'package:jarvis_chat/jarvis_theme.dart';
import 'package:syntax_highlight/syntax_highlight.dart';

class MarkdownCodeBlockBuilder extends md.MarkdownElementBuilder {
  late Highlighter highlighter;
  bool loaded = false;

  Future<void> init() async {
    final theme = await HighlighterTheme.loadDarkTheme();
    highlighter = Highlighter(language: 'dart', theme: theme);
  }

  @override
  Widget? visitText(text, TextStyle? preferredStyle) {
    final highlightedCode = highlighter.highlight(text.text);

    return SelectionArea(
      child: Container(
        color: JarvisTheme.darkerThanBackground,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.all(8),
                child: Text.rich(
                  highlightedCode,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.0,
                    fontFamily: "monospace",
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: text.text));
                },
                icon: Icon(
                  Icons.copy,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
