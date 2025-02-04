import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:jarvis_chat/state/app_state.dart';

class ChatMessage {
  String content;
  List<Uint8List> images;
  bool isUser;
  String model;

  ChatMessage({
    required this.content,
    required this.images,
    required this.isUser,
    required this.model,
  });
}

class LLMRequest {
  final Uri uri;
  final String body;

  LLMRequest({
    required this.uri,
    required this.body,
  });
}

class ChatMessageChunk {
  final String content;
  final List<Uint8List> images;
  final bool done;
  final String model;

  ChatMessageChunk({
    required this.content,
    required this.images,
    required this.done,
    required this.model,
  });
}

abstract class LLMClientBase {
  StreamSubscription? _stream;

  bool get isListening => _stream != null && !_stream!.isPaused;

  Future<void> sendRequest(LLMRequest llmRequest) async {
    try {
      _stream?.cancel();
      _stream = null;

      final http.Request httpRequest = http.Request("POST", llmRequest.uri)
        ..headers["Content-Type"] = "application/json"
        ..body = llmRequest.body;

      final response = await http.Client().send(httpRequest);

      _stream = response.stream.transform(utf8.decoder).listen(
        (data) async {
          await handleChunk(data);
        },
        onDone: () {
          _stream?.cancel();
          _stream = null;
          handleDone();
        },
        onError: (error) {
          handleError(error);
        },
      );
    } catch (e) {
      handleError(e);
    }
  }

  Future<void> stopListening() async {
    await _stream?.cancel();
    _stream = null;
  }

  void sendMessage(ChatMessage message, List<ChatMessage> history);

  Future<void> handleChunk(String chunk);
  void handleDone();
  void handleError(Object error);

  Future<bool> checkConnetion(AppState appState);
}
