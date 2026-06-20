import 'package:flutter/material.dart';

class WebViewScreen extends StatelessWidget {
  final String title;
  final String content;

  const WebViewScreen({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Text(
          content,
          style: const TextStyle(fontSize: 15, height: 1.6),
        ),
      ),
    );
  }
}