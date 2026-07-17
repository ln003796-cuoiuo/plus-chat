// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'register_screen.dart'; // Предполагаем, что файл RegisterScreen существует
import 'register_verification_screen.dart'; // Предполагаем, что файл RegisterVerificationScreen существует

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(); // Для Email/Телефона при входе по паролю
  final _passwordController = TextEditingController(); // Для Пароля
  final _codeIdentifierController = TextEditingController(); // Для Email/Телефона при входе по коду
  bool _showPassword = false; // Для скрытия/показа пароля
  bool _loading = false;

  // --- ВСПОМОГАТЕЛЬНЫЙ МЕТОД ДЛЯ СОЗДАНИЯ SnackBar ---
  SnackBar _buildErrorSnackBar(String message) {
    return SnackBar(
      content: Text(message),
      // backgroundColor больше не используется напрямую
    );
  }
  // --- /ВСПОМОГАТЕЛЬНЫЙ МЕТОД ---

  Future<void> _loginWithPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final identifier = _identifierController.text.trim();
      final password = _passwordController.text.trim();

      // Вызов API для входа по паролю
      final response = await ApiService.loginWithPassword(identifier, password);

      if (response['success'] == true) {
        // Успешный вход, сохранение токенов и переход в приложение
        AuthService.saveTokens(response['access_token'], response['refresh_token']);
        // TODO: Перейти на главный экран (например, /home)
        // Navigator.pushReplacementNamed(context, '/home');
        print("Успешный вход по паролю");
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildErrorSnackBar(response['error'] ?? 'Ошибка при входе'),
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

  Future<void> _requestVerificationCode() async {
    final identifier = _codeIdentifierController.text.trim();
    if (identifier.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildErrorSnackBar('Введите email или телефон'),
        );
      }
      return;
    }

    setState(() => _loading = true);
    try {
      // Вызов API для отправки кода (предполагается, что login теперь отправляет код)
      final response = await ApiService.login(identifier);

      if (response['success'] == true) {
        // Успешно отправлен код, перейти к экрану верификации
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegisterVerificationScreen(
              emailOrPhone: identifier,
              isLogin: true, // Передаём, что это вход, а не регистрация
            ),
          ),
        );
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- ЛОГОТИП В ВЕРХНЕЙ ЧАСТИ (ЗАМЕНИТЕ НА СВОЙ ASSET) ---
            // Image.asset('assets/logo.png', height: 40), // Пример
            // Или просто текст
            Text('Плюс Чат', style: Theme.of(context).textTheme.headlineSmall),
            // --- /ЛОГОТИП ---
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- ПОЛЯ ДЛЯ ВХОДА ПО ПАРОЛЮ ---
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
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                ),
                obscureText: !_showPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите пароль';
                  }
                  // Добавьте валидацию пароля (длина, сложность)
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // --- КНОПКА ВОЙТИ ---
              ElevatedButton(
                onPressed: _loading ? null : _loginWithPassword,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Войти'),
              ),
              const SizedBox(height: 24),
              // --- РАЗДЕЛИТЕЛЬ ---
              const Divider(thickness: 1),
              const SizedBox(height: 8),
              const Text('Или'),
              const SizedBox(height: 8),
              const Divider(thickness: 1),
              const SizedBox(height: 24),
              // --- ПОЛЕ ДЛЯ ВХОДА ПО КОДУ ---
              TextFormField(
                controller: _codeIdentifierController,
                decoration: const InputDecoration(
                  labelText: 'Email или Телефон (для входа по коду)',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              // --- КНОПКА ВОЙТИ ПО КОДУ ---
              ElevatedButton(
                onPressed: _loading ? null : _requestVerificationCode,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Войти по коду'),
              ),
              const SizedBox(height: 16),
              // --- КНОПКА ЗАРЕГИСТРИРОВАТЬСЯ ---
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'), // Предполагаем маршрут /register
                child: const Text('Нет аккаунта? Зарегистрироваться'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}