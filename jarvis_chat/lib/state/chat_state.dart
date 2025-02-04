import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:jarvis_chat/llm/llm_client_base.dart';
import 'package:jarvis_chat/llm/ollama_client.dart';
import 'package:jarvis_chat/state/app_state.dart';

class ChatState extends ChangeNotifier {
  final List<ChatMessage> messages = [];
  ChatMessage? incoming;
  List<Uint8List> attachments = [];

  late final LLMClientBase _client;

  Future<void> init(AppState appState) async {
    _client =
        OllamaClient(appState: appState, onData: _onData, onError: _onError);
  }

  Future<void> _onData(ChatMessageChunk chunk) async {
    incoming ??= ChatMessage(
      content: "",
      images: [],
      isUser: false,
      model: chunk.model,
    );

    incoming!.content += chunk.content;
    incoming!.images.addAll(chunk.images);
    incoming!.model = chunk.model;

    if (chunk.done) {
      messages.add(incoming!);
      incoming = null;
    }

    notifyListeners();
  }

  Future<void> send(String content) async {
    final message = ChatMessage(
      content: content,
      images: attachments.toList(),
      isUser: true,
      model: "user",
    );

    incoming ??= ChatMessage(
      content: "",
      images: [],
      isUser: false,
      model: "",
    );

    messages.add(message);
    attachments.clear();
    _client.sendMessage(message, messages);
    notifyListeners();
  }

  void addAttachment(Uint8List attachment) {
    attachments.add(attachment);
    notifyListeners();
  }

  void clearAttachments() {
    attachments.clear();
    notifyListeners();
  }

  Future<void> _onError(Object error) async {
    if (incoming != null) {
      messages.add(incoming!);
      incoming = null;
    }
    notifyListeners();
  }

  Future<bool> checkConnection(AppState store) async {
    return await _client.checkConnetion(store);
  }

  Future<void> stop() async {
    await _client.stopListening();
    if (incoming != null) {
      messages.add(incoming!);
      incoming = null;
    }
    notifyListeners();
  }
}
