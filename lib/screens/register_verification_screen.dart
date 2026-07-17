// lib/screens/register_verification_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
// УБРАНО: import 'package:plus_chat/screens/register_setup_screen.dart'; // Предполагаем, что маршрут определён
import 'setup_profile_screen.dart'; // Используем SetupScreen как ввод данных

class RegisterVerificationScreen extends StatefulWidget {
  final String emailOrPhone; // Принимаем emailOrPhone как позиционный аргумент
  final bool isLogin; // Принимаем флаг, что это вход, а не регистрация

  const RegisterVerificationScreen(this.emailOrPhone, {this.isLogin = false, super.key}); // Обновлённый конструктор

  @override
  State<RegisterVerificationScreen> createState() => _RegisterVerificationScreenState();
}

class _RegisterVerificationScreenState extends State<RegisterVerificationScreen> {
  final _codeController = TextEditingController();
  Timer? _resendTimer;
  int _resendCooldown = 60;
  bool _isResendActive = false;
  bool _loading = false;

  // --- ВСПОМОГАТЕЛЬНЫЙ МЕТОД ДЛЯ СОЗДАНИЯ SnackBar ---
  SnackBar _buildErrorSnackBar(String message) {
    return SnackBar(
      content: Text(message),
      // backgroundColor больше не используется напрямую
    );
  }
  // --- /ВСПОМОГАТЕЛЬНЫЙ МЕТОД ---

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _isResendActive = false;
    _resendCooldown = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() {
          _resendCooldown--;
        });
      } else {
        _isResendActive = true;
        timer.cancel();
      }
    });
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildErrorSnackBar('Введите код'),
        );
      }
      return;
    }

    setState(() => _loading = true);
    try {
      // Используем verifyCode из ApiService
      final response = await ApiService.verifyCode(widget.emailOrPhone, code);

      if (response['success'] == true) {
        if (widget.isLogin) {
          // Успешная верификация для входа
          AuthService.saveTokens(response['access_token'], response['refresh_token']);
          // TODO: Перейти на главный экран
          // Navigator.pushReplacementNamed(context, '/home');
          print("Успешный вход по коду");
          // Пример перехода:
          // Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        } else {
          // Успешная верификация для регистрации
          // TODO: Перейти к следующему шагу регистрации (например, SetupProfileScreen)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SetupProfileScreen(), // Или другой экран
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildErrorSnackBar(response['error'] ?? 'Ошибка при верификации'),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildErrorSnackBar('Ошибка сети: $e'),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --- ИСПРАВЛЕНО: resendCode ---
  Future<void> _resendCode() async {
    if (!_isResendActive) return;

    setState(() => _loading = true);
    try {
      // Для входа по коду: повторно отправляем код на тот же emailOrPhone
      // Используем login, предполагая, что сервер отправляет код при входе по emailOrPhone без пароля
      final response = await ApiService.login(widget.emailOrPhone);

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Код отправлен снова')),
          );
        }
        _startResendTimer(); // Перезапускаем таймер
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildErrorSnackBar(response['error'] ?? 'Ошибка при отправке кода'),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildErrorSnackBar('Ошибка сети при отправке кода: $e'),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  // --- /ИСПРАВЛЕНО ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Подтверждение')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Код отправлен на ${widget.emailOrPhone}'),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Код подтверждения',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24),
              maxLength: 6,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _verifyCode,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Подтвердить'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_isResendActive ? 'Готово!' : 'Отправить снова через $_resendCooldown'),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: (_loading || !_isResendActive) ? null : _resendCode,
                  child: const Text('Отправить снова'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}