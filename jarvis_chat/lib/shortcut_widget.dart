import 'package:flutter/widgets.dart';

class JShotcutWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onInvoke;
  final SingleActivator activator;
  final String id;

  const JShotcutWidget({
    super.key,
    required this.id,
    required this.onInvoke,
    required this.child,
    required this.activator,
  });

  @override
  State<JShotcutWidget> createState() => _ShotcutWidgetState();
}

class _ShotcutWidgetState extends State<JShotcutWidget> {
  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        widget.activator: ShortcutIntent(widget.id),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ShortcutIntent: CallbackAction<ShortcutIntent>(
            onInvoke: (ShortcutIntent intent) async {
              if (intent.id == widget.id) {
                widget.onInvoke();
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

class ShortcutIntent extends Intent {
  final String id;
  const ShortcutIntent(this.id);
}
