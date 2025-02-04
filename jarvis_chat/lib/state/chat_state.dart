import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:jarvis_chat/llm/llm_client_base.dart';
import 'package:jarvis_chat/llm/ollama_client.dart' as ollama;
import 'package:jarvis_chat/llm/openai_client.dart' as openai;
import 'package:jarvis_chat/state/app_state.dart';

class ChatState extends ChangeNotifier {
  final List<ChatMessage> messages = [];
  ChatMessage? incoming;
  List<Uint8List> attachments = [];
  List<OnDataCallback> onDataCallbacks = [];
  List<OnErrorCallback> onErrorCallbaks = [];

  late final ollama.OllamaClient _ollamaClient;
  late final openai.OpenAIClient _openaiClient;

  Future<void> init(AppState appState) async {
    // _client =
    //     OllamaClient(appState: appState, onData: _onData, onError: _onError);
    _ollamaClient = ollama.OllamaClient(
        appState: appState, onData: _onData, onError: _onError);
    _openaiClient = openai.OpenAIClient(
        appState: appState, onData: _onData, onError: _onError);
  }

  void addOnDataCallback(OnDataCallback callback) {
    onDataCallbacks.add(callback);
  }

  void removeOnDataCallback(OnDataCallback callback) {
    onDataCallbacks.remove(callback);
  }

  void addOnErrorCallback(OnErrorCallback callback) {
    onErrorCallbaks.add(callback);
  }

  void removeOnErrorCallback(OnErrorCallback callback) {
    onErrorCallbaks.remove(callback);
  }

  Future<void> _onData(ChatMessageChunk chunk, AppState appState) async {
    if (incoming == null && chunk.done) {
      return;
    }

    incoming ??= ChatMessage(
      content: "",
      images: [],
      isUser: false,
      model: chunk.model,
    );

    incoming!.content += chunk.content;
    incoming!.images.addAll(chunk.images);

    if (chunk.model.isNotEmpty) {
      incoming!.model = chunk.model;
    }

    if (chunk.done) {
      messages.add(incoming!);
      incoming = null;
    }

    for (final callback in onDataCallbacks) {
      callback(chunk, appState);
    }

    notifyListeners();
  }

  Future<void> send(String content, AppState appState) async {
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

    if (appState.useOpenAI) {
      _openaiClient.sendMessage(message, messages);
    } else {
      _ollamaClient.sendMessage(message, messages);
    }
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
      if (incoming!.content.trim().isNotEmpty) {
        messages.add(incoming!);
      } else {
        messages.add(ChatMessage(
          content: "An error occurred",
          images: [],
          isUser: false,
          model: "",
        ));
      }
      incoming = null;
    }

    for (final callback in onErrorCallbaks) {
      callback(error);
    }

    notifyListeners();
  }

  Future<bool> checkConnection(AppState appState) async {
    final client = appState.useOpenAI ? _openaiClient : _ollamaClient;
    return await client.checkConnetion(appState);
  }

  Future<void> stop(AppState appState) async {
    final client = appState.useOpenAI ? _openaiClient : _ollamaClient;
    await client.stopListening();
    if (incoming != null) {
      messages.add(incoming!);
      incoming = null;
    }
    notifyListeners();
  }
}
