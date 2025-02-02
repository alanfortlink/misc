import 'package:flutter/material.dart';

class ConnectionChecker extends StatefulWidget {
  const ConnectionChecker({super.key});

  @override
  State<ConnectionChecker> createState() => _ConnectionCheckerState();
}

class _ConnectionCheckerState extends State<ConnectionChecker> {
  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator();
  }
}
