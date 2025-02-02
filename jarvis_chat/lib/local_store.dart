import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class LocalStore extends ChangeNotifier {
  late final SharedPreferences _prefs;

  @override
  void notifyListeners({bool triggerCheck = true}) {
    if (triggerCheck) {
      checkConnection();
    }
    super.notifyListeners();
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    final defaultOptions = {
      "address": "127.0.0.1",
      "port": "11434",
      "textModel": "codellama:latest",
      "imageModel": "llava:7b",
    };

    for (final entry in defaultOptions.entries) {
      if (!_prefs.containsKey(entry.key)) {
        _prefs.setString(entry.key, entry.value);
      }
    }

    checkConnection();
  }

  int get lastX => _prefs.getInt("lastX") ?? 0;
  int get lastY => _prefs.getInt("lastY") ?? 0;

  set lastX(int value) {
    _prefs.setInt("lastX", value);
  }

  set lastY(int value) {
    _prefs.setInt("lastY", value);
  }

  String get address => _prefs.getString("address")!;
  String get port => _prefs.getString("port")!;
  String get textModel => _prefs.getString("textModel")!;
  String get imageModel => _prefs.getString("imageModel")!;

  bool _isServerUp = false;
  Future<bool> checkConnection() async {
    _isServerUp = false;
    try {
      final response = await http.Client().get(
        Uri.parse("http://$address:$port"),
      );
      _isServerUp = response.body.toLowerCase().contains("ollama");
    } catch (e) {
      _isServerUp = false;
    }

    notifyListeners(triggerCheck: false);
    return _isServerUp;
  }

  bool get isServerUp => _isServerUp;

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

    notifyListeners(triggerCheck: false);
  }
}
