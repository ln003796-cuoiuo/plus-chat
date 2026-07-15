// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'verify_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 0;
  final _pageController = PageController();
  final _emailController = TextEditingController();

  // Controllers для других шагов регистрации (FirstName, LastName, Username, Password)
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;

  Future<void> _nextStep() async {
    if (_currentStep == 0) { // Шаг 1: Email
      if (_emailController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Введите email'), backgroundColor: Colors.red),
        );
        return;
      }
      setState(() => _loading = true);
      try {
        final res = await ApiService.registerStep1(_emailController.text);
        if (res['success'] == true) {
          _goToStep(1);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res['error'] ?? 'Ошибка при регистрации')), backgroundColor: Colors.red,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка сети: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    } else if (_currentStep == 1) { // Шаг 2: FirstName, LastName
      if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Введите имя и фамилию'), backgroundColor: Colors.red),
        );
        return;
      }
      setState(() => _loading = true);
      try {
        final res = await ApiService.registerStep3(_firstNameController.text, _lastNameController.text);
        if (res['success'] == true) {
          _goToStep(2);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res['error'] ?? 'Ошибка при регистрации')), backgroundColor: Colors.red,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка сети: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    } else if (_currentStep == 2) { // Шаг 3: Username
      if (_usernameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Введите username'), backgroundColor: Colors.red),
        );
        return;
      }
      setState(() => _loading = true);
      try {
        final res = await ApiService.registerStep4(_usernameController.text);
        if (res['success'] == true) {
          _goToStep(3);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res['error'] ?? 'Ошибка при регистрации')), backgroundColor: Colors.red,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка сети: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    } else if (_currentStep == 3) { // Шаг 4: Password
      if (_passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Введите пароль'), backgroundColor: Colors.red),
        );
        return;
      }
      setState(() => _loading = true);
      try {
        final res = await ApiService.registerStep5(_passwordController.text);
        if (res['success'] == true) {
          // Регистрация завершена, перенаправляем на SetupScreen или сразу в приложение
          // Navigator.pushReplacementNamed(context, '/setup'); // Если есть SetupScreen
          // Или
          // Navigator.pushReplacementNamed(context, '/home'); // Если SetupScreen не нужен
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res['error'] ?? 'Ошибка при регистрации')), backgroundColor: Colors.red,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка сети: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Регистрация ($_currentStep/4)'),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentStep = index),
        physics: const NeverScrollableScrollPhysics(), // Отключаем свайп
        children: [
          // Шаг 1: Email
          _buildEmailStep(),
          // Шаг 2: FirstName, LastName
          _buildNameStep(),
          // Шаг 3: Username
          _buildUsernameStep(),
          // Шаг 4: Password
          _buildPasswordStep(),
        ],
      ),
    );
  }

  Widget _buildEmailStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Введите ваш email', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _nextStep,
            child: _loading ? const CircularProgressIndicator() : const Text('Далее'),
          ),
        ],
      ),
    );
  }

  Widget _buildNameStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Введите ваше имя и фамилию', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          TextField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              labelText: 'Имя',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              labelText: 'Фамилия',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _nextStep,
            child: _loading ? const CircularProgressIndicator() : const Text('Далее'),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Придумайте username', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _nextStep,
            child: _loading ? const CircularProgressIndicator() : const Text('Далее'),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Придумайте пароль', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Пароль',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _nextStep,
            child: _loading ? const CircularProgressIndicator() : const Text('Зарегистрироваться'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}