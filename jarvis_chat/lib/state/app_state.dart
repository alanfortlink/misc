import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AppState extends ChangeNotifier {
  late final SharedPreferences _prefs;
  final promptTextController = TextEditingController();
  final promptFocusNode = FocusNode();
  final messagesScrollController = ScrollController();

  List<String> errorMessages = [];

  void addErrorMessage(String message) {
    errorMessages.add("${DateTime.now()}: $message");
    notifyListeners();
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    final ollamaDefaultOptions = {
      "address": "127.0.0.1",
      "port": "11434",
      "textModel": "llama3.2:latest",
      "imageModel": "llava:7b",
      "codeModel": "codellama:latest",
      "apikey": "",
      "openaiModel": "gpt-4o",
      "openaiURL": "https://api.openai.com",
    };

    for (final entry in ollamaDefaultOptions.entries) {
      if (!_prefs.containsKey(entry.key)) {
        _prefs.setString(entry.key, entry.value);
      }
    }
  }

  String get openaiURL => _prefs.getString("openaiURL") ?? "";
  set openaiURL(String value) {
    _prefs.setString("openaiURL", value);
    notifyListeners();
  }

  bool get useOpenAI => _prefs.getBool("useOpenAI") ?? false;
  set useOpenAI(bool value) {
    _prefs.setBool("useOpenAI", value);
    notifyListeners();
  }

  String get apiKey => _prefs.getString("apikey") ?? "";
  set apiKey(String value) {
    _prefs.setString("apikey", value);
    notifyListeners();
  }

  String get openaiModel => _prefs.getString("openaiModel") ?? "";
  set openaiModel(String value) {
    _prefs.setString("openaiModel", value);
    notifyListeners();
  }

  int get lastX => _prefs.getInt("lastX") ?? 0;
  int get lastY => _prefs.getInt("lastY") ?? 0;
  int get lastWidth => _prefs.getInt("lastWidth") ?? 800;
  int get lastHeight => _prefs.getInt("lastHeight") ?? 900;

  set lastX(int value) {
    _prefs.setInt("lastX", value);
  }

  set lastY(int value) {
    _prefs.setInt("lastY", value);
  }

  set lastWidth(int value) {
    _prefs.setInt("lastWidth", value);
  }

  set lastHeight(int value) {
    _prefs.setInt("lastHeight", value);
  }

  bool get detailsEnabled => _prefs.getBool("detailsEnabled") ?? false;
  set detailsEnabled(bool value) {
    _prefs.setBool("detailsEnabled", value);
    notifyListeners();
  }

  String get address => _prefs.getString("address")!;
  String get port => _prefs.getString("port")!;
  String get textModel => _prefs.getString("textModel")!;
  String get imageModel => _prefs.getString("imageModel")!;
  String get codeModel => _prefs.getString("codeModel")!;

  bool _serverUp = false;
  bool get serverUp => _serverUp;
  set serverUp(bool value) {
    _serverUp = value;
    notifyListeners();
  }

  set address(String value) {
    _prefs.setString("address", value);
    notifyListeners();
  }

  set port(String value) {
    _prefs.setString("port", value);
    notifyListeners();
  }

  set textModel(String value) {
    _prefs.setString("textModel", value);
    notifyListeners();
  }

  set imageModel(String value) {
    _prefs.setString("imageModel", value);
    notifyListeners();
  }

  set codeModel(String value) {
    _prefs.setString("codeModel", value);
    notifyListeners();
  }

  List<String> _models = [];
  List<String> get models => _models;

  Future<void> loadModels() async {
    _models = [];
    try {
      final response = await http.Client().get(
        Uri.parse("http://$address:$port/api/tags"),
      );
      final json = jsonDecode(response.body);
      for (final model in json["models"]) {
        _models.add(model["name"].toString());
      }
    } catch (e) {
      _models = [];
    }

    notifyListeners();
  }
}
