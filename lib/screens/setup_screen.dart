import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'chats_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  bool _loading = false;
  bool _usernameAvailable = true;

  Future<void> _checkUsername() async {
    final u = _userCtrl.text.trim();
    if (u.length < 3) return;
    final res = await ApiService.checkUsername(u);
    if (mounted) setState(() => _usernameAvailable = res['available'] == true);
  }

  Future<void> _save() async {
    if (_firstCtrl.text.isEmpty) {
      _showError('Укажите имя');
      return;
    }
    if (!_usernameAvailable) {
      _showError('Username занят');
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await ApiService.setupProfile(
        username: _userCtrl.text.trim(),
        firstName: _firstCtrl.text.trim(),
        lastName: _lastCtrl.text.trim(),
      );

      if (res['success'] == true && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ChatsScreen()),
        );
      } else {
        _showError(res['error'] ?? 'Ошибка');
      }
    } catch (e) {
      _showError('Ошибка сети: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройка профиля')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Почти готово!',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text('Заполните профиль, чтобы друзья могли вас найти'),
              const SizedBox(height: 32),
              TextField(
                controller: _firstCtrl,
                decoration: const InputDecoration(
                  labelText: 'Имя *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lastCtrl,
                decoration: const InputDecoration(
                  labelText: 'Фамилия',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _userCtrl,
                onChanged: (_) => _checkUsername(),
                decoration: InputDecoration(
                  labelText: 'Username (@)',
                  prefixText: '@',
                  border: const OutlineInputBorder(),
                  errorText: _usernameAvailable || _userCtrl.text.length < 3
                      ? null
                      : 'Этот username занят',
                  suffixIcon: _userCtrl.text.length >= 3
                      ? Icon(_usernameAvailable
                          ? Icons.check_circle
                          : Icons.cancel,
                          color: _usernameAvailable ? Colors.green : Colors.red)
                      : null,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _loading ? null : _save,
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Начать общение',
                        style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}