import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jarvis_chat/jarvis_theme.dart';
import 'package:jarvis_chat/shortcut_intent.dart';
import 'package:jarvis_chat/state/app_state.dart';
import 'package:jarvis_chat/state/chat_state.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _serverAddressController =
      TextEditingController();
  final TextEditingController _serverPortController = TextEditingController();
  final TextEditingController _textModelController = TextEditingController();
  final TextEditingController _imageModelController = TextEditingController();
  final TextEditingController _codeModelController = TextEditingController();

  late final AppState appState;

  @override
  void initState() {
    super.initState();
    appState = Provider.of<AppState>(context, listen: false);
    appState.addListener(_update);
    _update();
    _loadModels();
  }

  @override
  void dispose() {
    appState.removeListener(_update);
    super.dispose();
  }

  void _loadModels() async {
    await appState.loadModels();
  }

  void _update() async {
    _serverAddressController.text = appState.address;
    _serverPortController.text = appState.port;
    _textModelController.text = appState.textModel;
    _imageModelController.text = appState.imageModel;
    _codeModelController.text = appState.codeModel;
    setState(() {});
  }

  Future<void> _updateConnectionStatus() async {
    final chatState = Provider.of<ChatState>(context, listen: false);
    appState.serverUp = await chatState.checkConnection(appState);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final chatState = Provider.of<ChatState>(context);

    final shortcuts = {
      LogicalKeyboardKey.keyW: "setting",
      LogicalKeyboardKey.comma: "settings",
    };

    return Shortcuts(
      shortcuts: shortcuts.map(
        (key, value) => MapEntry(
          SingleActivator(key, meta: true, includeRepeats: true),
          ShortcutIntent(value),
        ),
      ),
      child: Actions(
        actions: <Type, Action<Intent>>{
          ShortcutIntent: CallbackAction<ShortcutIntent>(
            onInvoke: (ShortcutIntent intent) async {
              if (intent.id == "settings") {
                Navigator.of(context).pop();
              }
              setState(() {});
              return null;
            },
          ),
        },
        child: SelectionArea(
          child: Scaffold(
            appBar: AppBar(
              foregroundColor: Colors.white,
              backgroundColor: JarvisTheme.backgroundColor,
              title: const Text(
                "Settings",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            body: Container(
              padding: const EdgeInsets.all(16),
              color: JarvisTheme.backgroundColor,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    controller: _serverAddressController,
                    decoration: const InputDecoration(
                      labelText: "Server Address",
                      labelStyle: TextStyle(color: Colors.grey),
                    ),
                    onSubmitted: (value) {
                      appState.address = value;
                      _updateConnectionStatus();
                    },
                  ),
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    controller: _serverPortController,
                    decoration: const InputDecoration(
                      labelText: "Server Port",
                      labelStyle: TextStyle(color: Colors.grey),
                    ),
                    onSubmitted: (value) {
                      appState.port = value;
                      _updateConnectionStatus();
                    },
                  ),
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    controller: _textModelController,
                    decoration: const InputDecoration(
                      labelText: "Text Model",
                      labelStyle: TextStyle(color: Colors.grey),
                    ),
                    onSubmitted: (value) {
                      appState.textModel = value;
                      _updateConnectionStatus();
                    },
                  ),
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    controller: _imageModelController,
                    decoration: const InputDecoration(
                      labelText: "Image Model (/image)",
                      labelStyle: TextStyle(color: Colors.grey),
                    ),
                    onSubmitted: (value) {
                      appState.imageModel = value;
                      _updateConnectionStatus();
                    },
                  ),
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    controller: _codeModelController,
                    decoration: const InputDecoration(
                      labelText: "Code Model (/code)",
                      labelStyle: TextStyle(color: Colors.grey),
                    ),
                    onSubmitted: (value) {
                      appState.codeModel = value;
                      _updateConnectionStatus();
                    },
                  ),
                  Text(
                    "Connection Status: ${appState.serverUp ? "Up" : "Down"}",
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  Text("Address: ${appState.address}",
                      style: const TextStyle(
                        color: Colors.white,
                      )),
                  Text("Port: ${appState.port}",
                      style: const TextStyle(
                        color: Colors.white,
                      )),
                  Text("Text Model: ${appState.textModel}",
                      style: const TextStyle(
                        color: Colors.white,
                      )),
                  Text("Image Model: ${appState.imageModel}",
                      style: const TextStyle(
                        color: Colors.white,
                      )),
                  Text("Code Model: ${appState.codeModel}",
                      style: const TextStyle(
                        color: Colors.white,
                      )),
                  Divider(height: 5),
                  Text("Local Models:",
                      style: const TextStyle(
                        color: Colors.white,
                      )),
                  Expanded(
                    child: Container(
                      child: ListView.builder(
                        itemCount: appState.models.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(appState.models[index],
                                style: const TextStyle(
                                  color: Colors.white,
                                )),
                            trailing: Container(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.copy,
                                        color: Colors.white),
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(
                                            text: appState.models[index]),
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text("Copied to clipboard"),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(LineIcons.check,
                                        color: Colors.white),
                                    onPressed: () {
                                      appState.textModel =
                                          appState.models[index];
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
