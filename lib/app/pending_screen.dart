import 'package:flutter/material.dart';

/// Buildable integration slot; the assigned owner supplies the actual screen.
class PendingScreen extends StatelessWidget {
  const PendingScreen({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: const SizedBox.expand(),
  );
}
