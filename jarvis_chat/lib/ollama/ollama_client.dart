import 'dart:async';
import 'dart:convert';
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
You are an assistant for a good software engineer.
You will analyze images and give a short and simple answer.
""";

typedef OnDataCallback = void Function(String? content, bool done);

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
    final request = http.Request("POST", Uri.parse("http://$textAPI"))
      ..headers["Content-Type"] = "application/json"
      ..body = jsonEncode(
        {
          "model": prompt.images.isEmpty ? "llama3.2:latest" : "llava:7b",
          "messages": [
            null,
            ...previousMessages,
            ChatMessage(prompt.message, true, prompt.images,),
          ]
              .map((e) => {
                    'role': e == null
                        ? 'system'
                        : e.isUser
                            ? 'user'
                            : 'assistant',
                    'content': e == null ? textSystem : e.message,
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
      onData(content, json["done"]);
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
