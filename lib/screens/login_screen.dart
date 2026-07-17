// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  String _loginMethod = 'code'; // 'code' или 'password'
  bool _loading = false;

  Future<void> _requestVerificationCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final identifier = _identifierController.text.trim();
      final response = await ApiService.login(identifier);

      if (response['success'] == true) {
        // Перенаправление на экран верификации
        Navigator.pushNamed(
          context,
          '/verify', // Предполагается, что маршрут '/verify' определён
          arguments: {
            'identifier': identifier,
            'isLogin': true, // Указывает, что это вход, а не регистрация
          },
        );
      } else {
        if (mounted) {
          // --- ИСПРАВЛЕНО: строка 82 ---
          ScaffoldMessenger.of(context).showSnackBar(
            _buildErrorSnackBar(response['error'] ?? 'Ошибка при входе'),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // --- ИСПРАВЛЕНО: строка 48 ---
        ScaffoldMessenger.of(context).showSnackBar(
          _buildErrorSnackBar('Ошибка сети: $e'),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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

  Future<void> _loginWithPassword() async {
    // TODO: Реализовать вход по паролю
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final identifier = _identifierController.text.trim();
      // final password = _passwordController.text; // Нужно добавить контроллер для пароля
      // final response = await ApiService.loginWithPassword(identifier, password);

      // if (response['success'] == true) {
      //   // Сохранение токенов и переход в приложение
      //   // AuthService.saveTokens(response['access_token'], response['refresh_token']);
      //   // Navigator.pushReplacementNamed(context, '/home');
      // } else {
      //   if (mounted) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       _buildErrorSnackBar(response['error'] ?? 'Ошибка при входе')),
      //     );
      //   }
      // }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _identifierController,
                decoration: const InputDecoration(
                  labelText: 'Email или Телефон',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите email или телефон';
                  }
                  // Добавьте валидацию email/телефона
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ToggleButtons(
                isSelected: [_loginMethod == 'code', _loginMethod == 'password'],
                onPressed: (index) {
                  setState(() {
                    _loginMethod = index == 0 ? 'code' : 'password';
                  });
                },
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('По коду')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('По паролю')),
                ],
              ),
              const SizedBox(height: 24),
              if (_loginMethod == 'password') ...[
                // TextFormField( // Нужно раскомментировать и добавить контроллер для пароля
                //   controller: _passwordController,
                //   decoration: const InputDecoration(
                //     labelText: 'Пароль',
                //     prefixIcon: Icon(Icons.lock),
                //   ),
                //   obscureText: true,
                //   validator: (value) {
                //     if (value == null || value.isEmpty) {
                //       return 'Введите пароль';
                //     }
                //     // Добавьте валидацию пароля
                //     return null;
                //   },
                // ),
                // const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: _loading ? null : (_loginMethod == 'code' ? _requestVerificationCode : _loginWithPassword),
                child: _loading
                    ? const CircularProgressIndicator()
                    : Text(_loginMethod == 'code' ? 'Получить код' : 'Войти'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'), // Предполагается, что маршрут '/register' определён
                child: const Text('Нет аккаунта? Зарегистрироваться'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}