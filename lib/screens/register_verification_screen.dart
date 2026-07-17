// lib/screens/register_verification_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class RegisterVerificationScreen extends StatefulWidget {
  final String identifier;
  final bool isLogin; // Указывает, что это верификация для входа, а не регистрации

  const RegisterVerificationScreen({
    Key? key,
    required this.identifier,
    required this.isLogin, // Уточни, нужен ли type, если только для регистрации
  }) : super(key: key);

  @override
  State<RegisterVerificationScreen> createState() => _RegisterVerificationScreenState();
}

class _RegisterVerificationScreenState extends State<RegisterVerificationScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  Timer? _timer;
  int _secondsLeft = 60; // Таймер для повторной отправки
  bool _resendEnabled = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _resendEnabled = false;
    _secondsLeft = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          _resendEnabled = true;
          timer.cancel();
        }
      });
    });
  }

  // --- ВСПОМОГАТЕЛЬНЫЙ МЕТОД ДЛЯ СОЗДАНИЯ SnackBar ---
  SnackBar _buildErrorSnackBar(String message) {
    return SnackBar(
      content: Text(message),
      // backgroundColor больше не используется напрямую
    );
  }
  // --- /ВСПОМОГАТЕЛЬНЫЙ МЕТОД ---

  Future<void> _verifyCode() async {
    if (_codeController.text.isEmpty) {
      if (mounted) {
        // --- ИСПРАВЛЕНО: строка 40 ---
        ScaffoldMessenger.of(context).showSnackBar(
          _buildErrorSnackBar('Введите код подтверждения'),
        );
      }
      return;
    }

    setState(() => _loading = true);
    try {
      // Регистрация: verifyCode используется после registerStep1
      // final response = await ApiService.verifyCode(widget.identifier, _codeController.text);

      // ИЛИ если используется registerStep2:
      final response = await ApiService.registerStep2(widget.identifier, _codeController.text);

      if (response['success'] == true) {
        if (widget.isLogin) {
          // Успешная верификация кода для *входа*
          // AuthService.saveTokens(response['access_token'], response['refresh_token']);
          // Navigator.pushReplacementNamed(context, '/home');
        } else {
          // Успешная верификация кода для *регистрации*
          // Переход к следующему шагу регистрации (например, SetupProfileScreen)
          Navigator.pushNamed(
            context,
            '/setup', // Убедитесь, что маршрут '/setup' определён
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

  Future<void> _resendCode() async {
    if (!_resendEnabled) return;

    setState(() => _loading = true);
    try {
      // Отправляем код заново (предполагается, что на сервере есть эндпоинт resend-verification)
      // final response = await ApiService.resendVerificationCode(widget.identifier);
      // Временно используем login для повторной отправки, если сервер поддерживает
      final response = await ApiService.login(widget.identifier);

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Код отправлен снова')),
          );
        }
        _startTimer(); // Перезапускаем таймер
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подтверждение'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Введите код, отправленный на\n${widget.identifier}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
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
              maxLength: 6, // Обычно 6 цифр
              onChanged: (value) {
                if (value.length == 6) {
                  // Автоматически попытаться верифицировать, если код введен полностью
                  // _verifyCode(); // Опционально
                }
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _resendEnabled ? _resendCode : null,
                  child: Text(
                    _resendEnabled ? 'Отправить снова' : 'Повторить через $_secondsLeft',
                    style: TextStyle(
                      color: _resendEnabled ? Theme.of(context).primaryColor : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _verifyCode,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Подтвердить'),
            ),
          ],
        ),
      ),
    );
  }
}