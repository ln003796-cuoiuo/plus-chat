// lib/screens/register_firstname_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'register_username_screen.dart'; // Переход к следующему шагу

class RegisterFirstnameScreen extends StatefulWidget {
  final String emailOrPhone; // Передаётся из предыдущего экрана
  final String verificationCode; // Передаётся из предыдущего экрана

  const RegisterFirstnameScreen({
    Key? key,
    required this.emailOrPhone,
    required this.verificationCode, // Хотя код может быть не нужен здесь, если сессия активна
  }) : super(key: key);

  @override
  State<RegisterFirstnameScreen> createState() => _RegisterFirstnameScreenState();
}

class _RegisterFirstnameScreenState extends State<RegisterFirstnameScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _loading = false;

  Future<void> _goToNextStep() async {
    if (_firstNameController.text.trim().isEmpty || _lastNameController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildErrorSnackBar('Введите имя и фамилию'),
        );
      }
      return;
    }

    setState(() => _loading = true);
    try {
      // Регистрация: отправляем имя и фамилию
      final response = await ApiService.registerStep3(
          _firstNameController.text.trim(), _lastNameController.text.trim());

      if (response['success'] == true) {
        // Данные успешно отправлены, переходим к следующему шагу (username)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegisterUsernameScreen(
              emailOrPhone: widget.emailOrPhone,
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
            ), // Передаём данные в следующий экран
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildErrorSnackBar(response['error'] ?? 'Ошибка при регистрации'),
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
        title: const Text('Ваши данные'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Расскажите немного о себе',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'Имя',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Фамилия',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _goToNextStep,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Далее'),
            ),
          ],
        ),
      ),
    );
  }
}