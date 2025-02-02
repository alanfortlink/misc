import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:jarvis_chat/chat_window.dart';
import 'package:jarvis_chat/local_store.dart';
import 'package:http/http.dart' as http;

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
  String? content,
  bool done,
  List<Uint8List> images,
  String model,
);

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
    LocalStore store,
  ) async {
    final chatAPI = "${store.address}:${store.port}/api/chat";

    final isImageRequest =
        prompt.images.isNotEmpty || prompt.message.startsWith("/image");

    final isCodeRequest = prompt.message.startsWith("/code");

    final request = http.Request("POST", Uri.parse("http://$chatAPI"))
      ..headers["Content-Type"] = "application/json"
      ..body = jsonEncode(
        {
          "model": (isImageRequest)
              ? store.imageModel
              : isCodeRequest
                  ? store.codeModel
                  : store.textModel,
          "messages": [
            null, // System message
            ...previousMessages,
            ChatMessage(
              prompt.message,
              true,
              prompt.images,
              "user",
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
      final model = json["model"] as String;
      final message = json["message"] as Map<dynamic, dynamic>;
      String content = message["content"] as String;
      final images = (message["images"] ?? [])
          .map((e) => base64Decode(e as String))
          .cast<Uint8List>()
          .toList();

      // if (json["model"].toString().contains("deepseek")) {
      //   final endOfThinkingToken = "</think>";
      //   if (!hasFinishedThinking) {
      //     if (content.contains(endOfThinkingToken)) {
      //       hasFinishedThinking = true;
      //       content = content.split(endOfThinkingToken).last;
      //     } else {
      //       return;
      //     }
      //   }
      // }
      onData(content, json["done"], images, model);
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
