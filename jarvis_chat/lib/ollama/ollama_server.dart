import 'dart:convert';
import 'dart:io';

String get llamaBin {
  if (Platform.isMacOS) {
    return "/opt/homebrew/bin/ollama";
  }

  return "";
}

class OllamaServer {
  static const String address = "127.0.0.1";
  static const String port = "6666";
  static const String host = "$address:$port";

  Process? server;

  Future<void> start() async {
    return;
    server?.kill();
    await startServer();
  }

  Future<void> startServer() async {
    server = await Process.start(
      llamaBin,
      ["serve"],
      environment: {
        "OLLAMA_HOST": host,
      },
    );
    server!.stdout.transform(utf8.decoder).listen((_) {});
    server!.stderr.transform(utf8.decoder).listen((_) {});
  }

  void stop() {
    server?.kill();
  }
}
