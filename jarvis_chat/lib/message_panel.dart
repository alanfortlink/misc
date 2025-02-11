import 'package:flutter/material.dart';
import 'package:jarvis_chat/image_panel.dart';
import 'package:jarvis_chat/jarvis_theme.dart';
import 'package:jarvis_chat/llm/llm_client_base.dart';
import 'package:jarvis_chat/markdown_code_block_builder.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'state/app_state.dart';

class MessagePanel extends StatefulWidget {
  final ChatMessage message;

  const MessagePanel({
    super.key,
    required this.message,
  });

  @override
  State<MessagePanel> createState() => _MessagePanelState();
}

class _MessagePanelState extends State<MessagePanel> {
  final _markdownCodeBlockBuilder = MarkdownCodeBlockBuilder();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _markdownCodeBlockBuilder.init();
  }

  void _launch(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    final alignment =
        widget.message.isUser ? Alignment.centerRight : Alignment.centerLeft;

    return ListTile(
      title: Align(
        alignment: alignment,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.message.isUser
                ? JarvisTheme.muchBrighterThanBackground
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              (widget.message.content.trim().isEmpty)
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 24.0,
                        height: 24.0,
                        child: CircularProgressIndicator(
                          color: Colors.white.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    )
                  : md.MarkdownBody(
                      onTapLink: (text, href, title) {
                        if (href != null) {
                          _launch(href);
                        }
                      },
                      softLineBreak: true,
                      builders: {
                        "pre": _markdownCodeBlockBuilder,
                      },
                      fitContent: widget.message.isUser,
                      selectable: true,
                      data: widget.message.content,
                      styleSheet: md.MarkdownStyleSheet(
                        codeblockPadding: const EdgeInsets.all(12.0),
                        blockquoteDecoration: BoxDecoration(
                          color: JarvisTheme.darkerThanBackground,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1.0,
                          ),
                        ),
                        p: TextStyle(
                          color: widget.message.isUser
                              ? Colors.white
                              : Colors.white,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
      subtitle: Column(
        children: [
          if (appState.detailsEnabled && !widget.message.isUser)
            Align(
              alignment: alignment,
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                child: Text(
                  widget.message.model,
                  style: const TextStyle(
                    color: JarvisTheme.weakerTextColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          if (widget.message.images.isNotEmpty)
            Align(
              alignment: alignment,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: widget.message.images
                      .map(
                        (bytes) => Container(
                          color: Colors.transparent,
                          child: Center(
                            child: ImagePanel(
                              bytes,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            )
        ],
      ),
    );
  }
}
