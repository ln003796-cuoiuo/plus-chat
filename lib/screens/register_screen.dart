// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'register_verification_screen.dart'; // Используем обновлённый экран

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;

  // --- ВСПОМОГАТЕЛЬНЫЙ МЕТОД ДЛЯ СОЗДАНИЯ SnackBar ---
  SnackBar _buildErrorSnackBar(String message) {
    return SnackBar(
      content: Text(message),
      // backgroundColor больше не используется напрямую
    );
  }
  // --- /ВСПОМОГАТЕЛЬНЫЙ МЕТОД ---

  Future<void> _registerStep1() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildErrorSnackBar('Заполните все поля'),
        );
      }
      return;
    }

    if (password != confirmPassword) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildErrorSnackBar('Пароли не совпадают'),
        );
      }
      return;
    }

    setState(() => _loading = true);
    try {
      // Шаг 1: Отправить email
      final response = await ApiService.registerStep1(email);

      if (response['success'] == true) {
        // Перейти к верификации кода
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegisterVerificationScreen(email), // Передаём email как позиционный аргумент
          ),
        );
      } else {
        if (mounted) {
          // --- ИСПРАВЛЕНО: SnackBar ---
          ScaffoldMessenger.of(context).showSnackBar(
            _buildErrorSnackBar(response['error'] ?? 'Ошибка при регистрации'),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // --- ИСПРАВЛЕНО: SnackBar ---
        ScaffoldMessenger.of(context).showSnackBar(
          _buildErrorSnackBar('Ошибка сети: $e'),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Пароль',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Подтвердите пароль',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _registerStep1,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Зарегистрироваться'),
            ),
          ],
        ),
      ),
    );
  }
}