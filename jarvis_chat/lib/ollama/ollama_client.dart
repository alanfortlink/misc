import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:jarvis_chat/chat_window.dart';
import 'package:jarvis_chat/ollama/ollama_server.dart';
import 'package:http/http.dart' as http;

String get textAPI => "${OllamaServer.host}/api/chat";

String textSystem = """
You are an assistant for a good software engineer. 
Prefer to use simple and short answers.
Do not explain too much, unless it is explicitly requested.
""";

String imageSystem = """
You are an assistant that analyses and generates images.
Your answers should be short and concise.
""";

typedef OnDataCallback = void Function(
    String? content, bool done, List<Uint8List> images);

class OllamaClient {
  final OnDataCallback onData;

  final http.Client client = http.Client();
  final List<int> lastContext = [];

  StreamSubscription? currentResponse;
  bool hasFinishedThinking = false;

  OllamaClient({required this.onData});

  Future<void> send(
    ChatMessage prompt,
    List<ChatMessage> previousMessages,
  ) async {
    final isImageRequest =
        prompt.images.isNotEmpty || prompt.message.startsWith("/img");

    final request = http.Request("POST", Uri.parse("http://$textAPI"))
      ..headers["Content-Type"] = "application/json"
      ..body = jsonEncode(
        {
          "model": (isImageRequest) ? "llava:7b" : "llama3.2:latest",
          "messages": [
            null, // System message
            ...previousMessages,
            ChatMessage(
              prompt.message,
              true,
              prompt.images,
            ),
          ]
              .map((e) => {
                    'role': e == null
                        ? 'system'
                        : e.isUser
                            ? 'user'
                            : 'assistant',
                    'content': e == null
                        ? (isImageRequest ? imageSystem : textSystem)
                        : e.message,
                    'images': e == null
                        ? []
                        : e.images.map((e) => base64Encode(e)).toList(),
                  })
              .toList(),
          "options": {
            "temperature": 0.6,
          },
          "temperature": 0.6,
          "stream": true,
        },
      );

    final response = await client.send(request);

    hasFinishedThinking = false;
    currentResponse = response.stream.transform(utf8.decoder).listen((data) {
      final json = jsonDecode(data) as Map<dynamic, dynamic>;
      final message = json["message"] as Map<dynamic, dynamic>;
      final content = message["content"] as String;
      print(json);
      final images = (message["images"] ?? [])
          .map((e) => base64Decode(e as String))
          .cast<Uint8List>()
          .toList();
      onData(content, json["done"], images);
    });
  }

  Future<void> stop() async {
    if (currentResponse != null) {
      try {
        await currentResponse?.cancel();
      } catch (e) {
        //
      }
    }
  }
}
