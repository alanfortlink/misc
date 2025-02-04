import 'dart:convert';

import 'package:jarvis_chat/llm/llm_client_base.dart';
import 'package:http/http.dart' as http;
import 'package:jarvis_chat/state/app_state.dart';

typedef OnDataCallback = void Function(
  ChatMessageChunk chunk,
);

typedef OnErrorCallback = void Function(
  Object error,
);

class OllamaClient extends LLMClientBase {
  final OnDataCallback onData;
  final OnErrorCallback onError;
  final AppState appState;

  OllamaClient({
    required this.appState,
    required this.onData,
    required this.onError,
  });

  String getModel(ChatMessage message, AppState appState) {
    final isImageRequest =
        message.images.isNotEmpty || message.content.startsWith("/image");

    final isCodeRequest = message.content.startsWith("/code");

    return (isImageRequest)
        ? appState.imageModel
        : isCodeRequest
            ? appState.codeModel
            : appState.textModel;
  }

  Map<String, Object> parseMessage(ChatMessage? message) {
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
      "content": message.content,
      "images": message.images.map((e) => base64Encode(e)).toList(),
    };
  }

  String getBaseUrl(AppState appState) {
    return "http://${appState.address}:${appState.port}";
  }

  Uri getBaseUri(AppState appState) {
    return Uri.parse(getBaseUrl(appState));
  }

  Uri getChatUri(AppState appState) {
    return Uri.parse("${getBaseUrl(appState)}/api/chat");
  }

  @override
  Future<void> handleChunk(String chunk) async {
    final json = jsonDecode(chunk);
    final model = json["model"] as String;
    final message = json["message"] as Map<String, dynamic>;
    final done = json["done"] as bool;
    final content = message["content"] as String;
    // final images = ((message["images"] ?? [])).map((e) => base64Decode(e)).toList();

    final chatMessageChunk = ChatMessageChunk(
      content: content,
      images: [],
      done: done,
      model: model,
    );

    onData(chatMessageChunk);
  }

  @override
  void handleDone() {
    // final chatMessageChunk = ChatMessageChunk(
    //   content: "",
    //   images: [],
    //   done: true,
    //   model: "system",
    // );

    // onData(chatMessageChunk);
  }

  @override
  void handleError(Object error) {
    onError(error);
  }

  @override
  void sendMessage(ChatMessage message, List<ChatMessage> history) {
    final llmRequest = LLMRequest(
      uri: getChatUri(appState),
      body: jsonEncode(
        {
          "model": getModel(message, appState),
          "messages": [null, ...history, message].map(parseMessage).toList(),
          "temperature": 0.6,
          "stream": true,
        },
      ),
    );

    sendRequest(llmRequest);
  }

  @override
  Future<bool> checkConnetion(AppState appState) async {
    print("Checking connection");
    final baseUri = getBaseUri(appState);
    try {
      final response = await http.Client().get(baseUri);
      if (response.body.toLowerCase().contains("ollama")) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
