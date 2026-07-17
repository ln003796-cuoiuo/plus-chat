// lib/screens/register_verification_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'setup_profile_screen.dart'; // Импортируем SetupProfileScreen

class RegisterVerificationScreen extends StatefulWidget {
  final String emailOrPhone; // Принимаем emailOrPhone как именованный аргумент
  final String type; // 'login' или 'register', как именованный аргумент

  const RegisterVerificationScreen({
    super.key,
    required this.emailOrPhone, // Именованный аргумент
    required this.type,        // Именованный аргумент
  });

  @override
  State<RegisterVerificationScreen> createState() => _RegisterVerificationScreenState();
}

class _RegisterVerificationScreenState extends State<RegisterVerificationScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  int _resendCooldown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendCooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        t.cancel();
      }
    });
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildErrorSnackBar('Введите 6-значный код'),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Вызов API для верификации кода
      final response = await ApiService.verifyCode(widget.emailOrPhone, code);

      if (response['success'] == true) {
        if (widget.type == 'login') {
          // Успешная верификация для входа
          AuthService.saveTokens(response['access_token'], response['refresh_token']);
          // TODO: Перейти на главный экран
          // Navigator.pushReplacementNamed(context, '/home');
          print("Успешный вход по коду из RegisterVerificationScreen");
          // Пример перехода:
          // Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        } else if (widget.type == 'register') {
          // Успешная верификация для регистрации
          // Перейти к настройке профиля
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SetupProfileScreen(),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildErrorSnackBar(
              response['message'] ??
                  response['error'] ??
                  'Ошибка верификации',
            ),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    if (_resendCooldown > 0 || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      // Вызов API для повторной отправки кода
      final response = await ApiService.login(widget.emailOrPhone);

      if (response['success'] == true) {
        _startResendTimer();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Код отправлен повторно')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildErrorSnackBar(response['error'] ?? 'Ошибка'),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- ВСПОМОГАТЕЛЬНЫЙ МЕТОД ДЛЯ СОЗДАНИЯ SnackBar ---
  SnackBar _buildErrorSnackBar(String message) {
    return SnackBar(
      content: Text(message),
      // backgroundColor больше не используется напрямую
    );
  }
  // --- /ВСПОМОГАТЕЛЬНЫЙ МЕТОД ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подтверждение'),
        // leading можно добавить, если нужна кнопка назад на предыдущий шаг
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.email, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              'Введите код из письма/SMS',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Код отправлен на ${widget.emailOrPhone}',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Код подтверждения',
                border: OutlineInputBorder(),
                hintText: '123456',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyCode,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Подтвердить', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _resendCooldown > 0 || _isLoading ? null : _resendCode,
              child: _resendCooldown > 0
                  ? Text('Отправить код повторно через $_resendCooldown сек')
                  : const Text('Отправить код повторно'),
            ),
          ],
        ),
      ),
    );
  }
}