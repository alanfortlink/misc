import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

class CommandWCloser extends StatefulWidget {
  final Widget child;

  const CommandWCloser({
    super.key,
    required this.child,
  });

  @override
  State<CommandWCloser> createState() => _CommandWCloserState();
}

class _CommandWCloserState extends State<CommandWCloser> {
  @override
  Widget build(BuildContext context) {
    // Create a custom Intent and Action to close the window.
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        // On macOS, Command is meta. So Command+W -> meta + keyW
        SingleActivator(LogicalKeyboardKey.keyW,
            meta: true, includeRepeats: true): const CloseWindowIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          CloseWindowIntent: CallbackAction<CloseWindowIntent>(
            onInvoke: (intent) async {
              if (await windowManager.isVisible()) {
                await windowManager.hide();
              } else {
                await windowManager.show();
                await windowManager.focus();
              }
              return null;
            },
          ),
        },
        child: widget.child,
      ),
    );
  }
}

class CloseWindowIntent extends Intent {
  const CloseWindowIntent();
}
