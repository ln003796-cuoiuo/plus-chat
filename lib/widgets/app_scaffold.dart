// lib/widgets/app_scaffold.dart
import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final bool showBackButton; // --- ДОБАВЛЕНО ---
  final List<Widget>? actions;
  final Widget body;
  final PreferredSizeWidget? appBar; // Опционально, если нужно полное управление AppBar

  const AppScaffold({
    Key? key,
    required this.title,
    this.showBackButton = true, // --- ДОБАВЛЕНО: значение по умолчанию ---
    this.actions,
    required this.body,
    this.appBar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar ?? // Если передан кастомный AppBar, используем его
          AppBar(
            title: Text(title),
            automaticallyImplyLeading: showBackButton, // --- ИСПОЛЬЗОВАНО ---
            actions: actions,
          ),
      body: body,
    );
  }
}