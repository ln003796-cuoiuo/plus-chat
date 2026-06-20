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
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _useCodeLogin = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_useCodeLogin) {
        final response = await ApiService.loginWithCodeRequest(
          identifier: _identifierController.text.trim(),
        );
        if (response['success'] == true) {
          if (mounted) {
            Navigator.pushNamed(
              context,
              '/verify',
              arguments: {
                'email': response['email']?.toString() ??
                    _identifierController.text.trim(),
                'type': 'login',
              },
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response['error'] ?? 'Ошибка'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        final response = await ApiService.login(
          email: _identifierController.text.trim(),
          password: _passwordController.text,
        );
        if (response['success'] == true) {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response['error'] ?? 'Ошибка входа'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сети: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                // Логотип
                const Icon(Icons.chat_bubble, size: 80, color: Color(0xFF075E54)),
                const SizedBox(height: 20),
                const Text(
                  'Плюс Чат',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Email / Username
                TextFormField(
                  controller: _identifierController,
                  decoration: const InputDecoration(
                    labelText: 'Email или Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите email или username';
                    }
                    return null;
                  },
                ),

                // Пароль (только если не вход по коду)
                if (!_useCodeLogin) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Пароль',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите пароль';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 24),

                // Кнопка входа
                FilledButton(
                  onPressed: _isLoading ? null : _login,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Войти', style: TextStyle(fontSize: 16)),
                ),

                const SizedBox(height: 16),

                // Войти по коду / по паролю
                TextButton(
                  onPressed: () {
                    setState(() {
                      _useCodeLogin = !_useCodeLogin;
                      _passwordController.clear();
                    });
                  },
                  child: Text(
                    _useCodeLogin
                        ? 'Войти по паролю'
                        : 'Войти по коду из почты',
                  ),
                ),

                const SizedBox(height: 16),

                // Регистрация
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text('Нет аккаунта? Зарегистрироваться'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}