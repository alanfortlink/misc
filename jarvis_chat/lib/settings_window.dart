import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jarvis_chat/chat_window.dart';
import 'package:jarvis_chat/local_store.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';

class SettingsWindow extends StatefulWidget {
  const SettingsWindow({super.key});

  @override
  State<SettingsWindow> createState() => _SettingsWindowState();
}

class _SettingsWindowState extends State<SettingsWindow> {
  final TextEditingController _serverAddressController =
      TextEditingController();
  final TextEditingController _serverPortController = TextEditingController();
  final TextEditingController _textModelController = TextEditingController();
  final TextEditingController _imageModelController = TextEditingController();

  late final LocalStore store;

  @override
  void initState() {
    super.initState();
    store = Provider.of<LocalStore>(context, listen: false);
    store.addListener(_update);
    _update();
    _loadModels();
  }

  @override
  void dispose() {
    store.removeListener(_update);
    super.dispose();
  }

  void _loadModels() async {
    await store.loadModels();
  }

  void _update() async {
    _serverAddressController.text = store.address;
    _serverPortController.text = store.port;
    _textModelController.text = store.textModel;
    _imageModelController.text = store.imageModel;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<LocalStore>(context);

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
        child: Scaffold(
          body: Container(
            margin: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        "Settings",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 1,
                  color: Colors.grey,
                ),
                SizedBox(height: 20),
                // back button

                TextField(
                  controller: _serverAddressController,
                  decoration: const InputDecoration(
                    labelText: "Server Address",
                  ),
                  onSubmitted: (value) {
                    store.address = value;
                  },
                ),
                TextField(
                  controller: _serverPortController,
                  decoration: const InputDecoration(
                    labelText: "Server Port",
                  ),
                  onSubmitted: (value) {
                    store.port = value;
                  },
                ),
                TextField(
                  controller: _textModelController,
                  decoration: const InputDecoration(
                    labelText: "Text Model",
                  ),
                  onSubmitted: (value) {
                    store.textModel = value;
                  },
                ),
                TextField(
                  controller: _imageModelController,
                  decoration: const InputDecoration(
                    labelText: "Image Model",
                  ),
                  onSubmitted: (value) {
                    store.imageModel = value;
                  },
                ),
                Text(
                  "Connection Status: ${store.isServerUp ? "Up" : "Down"}",
                ),
                Text("Address: ${store.address}"),
                Text("Port: ${store.port}"),
                Text("Text Model: ${store.textModel}"),
                Text("Image Model: ${store.imageModel}"),
                Divider(height: 5),
                Text("Local Models:"),
                Expanded(
                  child: Container(
                    child: ListView.builder(
                      itemCount: store.models.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(store.models[index]),
                          trailing: Container(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: store.models[index]),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Copied to clipboard"),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(LineIcons.check),
                                  onPressed: () {
                                    store.textModel = store.models[index];
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
    );
  }
}
