import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/chats_screen.dart';

void main() {
  runApp(const PlusChatApp());
}

class PlusChatApp extends StatelessWidget {
  const PlusChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Плюс Чат',  // ← ИЗМЕНЕНО
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF075E54),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF075E54),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const AuthGate(),
    );
  }
}

// ... остальной код без изменений ...

// Автоматически показывает нужный экран в зависимости от авторизации
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await AuthService.getToken();
    if (mounted) {
      setState(() {
        _loggedIn = token != null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _loggedIn ? const ChatsScreen() : const LoginScreen();
  }
}