import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:jarvis_chat/llm/llm_client_base.dart';
import 'package:jarvis_chat/state/app_state.dart';

class OpenAIClient extends LLMClientBase {
  final OnDataCallback onData;
  final OnErrorCallback onError;
  final AppState appState;

  OpenAIClient({
    required this.appState,
    required this.onData,
    required this.onError,
  });

  String getModel(ChatMessage message, AppState appState) {
    return appState.openaiModel;
  }

  Map<String, Object?> parseMessage(ChatMessage? message) {
    if (message == null) {
      return {
        "role": "system",
        "content": """You are an assistant for a good software engineer. 
Prefer to use simple and short answers. 
Do not explain too much, unless it is explicitly requested.
""",
      };
    }

    return {
      "role": message.isUser ? "user" : "assistant",
      "content": [
        {
          "type": "text",
          "text": message.content,
        },
        for (final image in message.images)
          {
            "type": "image_url",
            "image_url": {
              "url": "data:image/jpeg;base64,${base64Encode(image)}",
            },
          },
      ],
      // TODO: Images to openai
      // "images": message.images.map((e) => base64Encode(e)).toList(),
    };
  }

  Uri getOpenAIChatUri() {
    return Uri.parse("${appState.openaiURL}/v1/chat/completions");
  }

  @override
  Future<void> handleChunk(String chunk) async {
    try {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (chunk.trim().isEmpty) {
        return;
      }

      final line =
          chunk.startsWith('data: ') ? chunk.replaceFirst('data: ', '') : chunk;

      if (line.trim() == '[DONE]') {
        final chatMessageChunk = ChatMessageChunk(
          content: "",
          images: [],
          done: true,
          model: "",
        );
        onData(chatMessageChunk, appState);
        return;
      }

      final Map<String, dynamic> jsonData = jsonDecode(line);

      final model = jsonData["model"] ?? "unknown-model";
      final choices = jsonData["choices"] as List<dynamic>?;

      if (choices == null || choices.isEmpty) {
        final chatMessageChunk = ChatMessageChunk(
          content: "",
          images: [],
          done: true,
          model: model,
        );
        onData(chatMessageChunk, appState);
        return;
      }

      final choice = choices.first;
      final delta = choice["delta"] as Map<String, dynamic>? ?? {};
      final finishReason = choice["finish_reason"];

      final partialContent = delta["content"] as String? ?? "";

      // Indicate "done" if finish_reason is set; otherwise keep streaming.
      final isDone = finishReason != null && finishReason.isNotEmpty;

      final chatMessageChunk = ChatMessageChunk(
        content: partialContent,
        images: [], // Not used in standard ChatCompletion
        done: isDone,
        model: model,
      );

      onData(chatMessageChunk, appState);
    } catch (e) {
      appState.addErrorMessage("OpenAI error: $chunk $e");
      onError(e);
    }
  }

  @override
  void handleDone() {}

  @override
  void handleError(Object error) {
    appState.addErrorMessage("OpenAI error: $error");
    onError(error);
  }

  @override
  void sendMessage(ChatMessage message, List<ChatMessage> history) {
    // Prepare the OpenAI request body
    final body = {
      "model": getModel(message, appState),
      "messages": [if (appState.useSystemCommand) null, ...history, message]
          .map(parseMessage)
          .toList(),
      "temperature": 1,
      "stream": true,
    };

    final llmRequest = LLMRequest(
      uri: getOpenAIChatUri(),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${appState.apiKey}', // or whichever token
      },
      body: jsonEncode(body),
    );

    sendRequest(llmRequest);
  }

  @override
  Future<bool> checkConnetion(AppState appState) async {
    try {
      final response = await http
          .post(
            getOpenAIChatUri(),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${appState.apiKey}',
            },
            body: jsonEncode({
              "model": appState.openaiModel,
              "messages": [
                {"role": "user", "content": "ping"}
              ],
              "stream": false,
              "temperature": 1,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return true;
      }

      appState.addErrorMessage(
        "OpenAI connection error: ${response.statusCode} ${response.body}",
      );
      return false;
    } catch (e) {
      appState.addErrorMessage(
        "OpenAI connection error: ${e.toString()}",
      );
      return false;
    }
  }
}
