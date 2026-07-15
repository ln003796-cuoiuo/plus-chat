// lib/screens/auth_wrapper.dart
// Этот файл должен обрабатывать проверку аутентификации и перенаправление
// либо на LoginScreen, либо на HomeScreen (или другой стартовый экран для авторизованных пользователей).

import 'package:flutter/material.dart';
import 'package:plus_chat/services/update_service.dart';
import 'package:plus_chat/models/chat.dart'; // Предполагаем, что нужен для UpdateService
import 'login_screen.dart'; // Импортируем LoginScreen
import 'home_screen.dart'; // Импортируем HomeScreen (или другой стартовый экран для авторизованных)

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Проверяем обновления в фоне
    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    // Проверяем обновления в фоне
    final info = await UpdateService.checkForUpdate();
    if (info != null && info.needsUpdate && mounted) {
      // Используем WidgetsBinding для вызова диалога после постройки виджета
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          UpdateService.showUpdateDialog(context, info);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // AuthWrapper теперь просто проверяет аутентификацию и направляет пользователя
    // к нужному экрану (Login или Home).
    // Проверка безопасности (Root, Integrity) уже выполнена в main().
    return FutureBuilder<bool>(
      future: AuthService.isAuthenticated(), // Предполагаем, что метод существует
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          // Пользователь аутентифицирован, направляем на главный экран
          return const HomeScreen(); // Или любой другой начальный экран после входа
        } else {
          // Пользователь не аутентифицирован, направляем на экран входа
          return const LoginScreen();
        }
      },
    );
  }
}