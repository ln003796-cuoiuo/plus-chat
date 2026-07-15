// lib/screens/setup_screen.dart (предполагаемое имя для файла настройки профиля после регистрации)
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  String? _avatarUrl; // Можно использовать для предварительного просмотра
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Загрузка текущего профиля пользователя (если есть)
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await ApiService.getMe();
      if (mounted) {
        setState(() {
          _firstNameController.text = user.firstName ?? '';
          _lastNameController.text = user.lastName ?? '';
          _usernameController.text = user.username ?? '';
          _bioController.text = user.bio ?? '';
          _avatarUrl = user.avatarUrl;
        });
      }
    } catch (e) {
      print('Ошибка загрузки профиля: $e');
      // Можно показать сообщение пользователю
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.setupProfile(
        _firstNameController.text,
        _lastNameController.text,
        _usernameController.text,
        _bioController.text,
        _avatarUrl, // передаем URL аватара, если он был загружен
      );
      if (res['success'] == true) {
        // Профиль успешно обновлен
        // AuthService.updateCurrentUser(res['user']); // Обновить кэш пользователя
        // Navigator.pushReplacementNamed(context, '/home'); // Перейти на главный экран
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['error'] ?? 'Ошибка при сохранении профиля'), backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройка профиля'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _saveProfile,
            child: const Text('Сохранить'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Поля ввода
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'Имя'),
            ),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Фамилия'),
            ),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: 'О себе'),
              maxLines: 3,
            ),
            // Кнопка загрузки аватара
            ElevatedButton(
              onPressed: () {
                // Вызовите метод загрузки аватара из ApiService
                // После загрузки обновите _avatarUrl
                // _uploadAvatar();
              },
              child: const Text('Загрузить аватар'),
            ),
            // Предварительный просмотр аватара (если _avatarUrl не null)
            if (_avatarUrl != null) ...[
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(_avatarUrl!),
              ),
            ],
            const Spacer(), // Отодвигает кнопку вниз
            ElevatedButton(
              onPressed: _loading ? null : _saveProfile,
              child: _loading ? const CircularProgressIndicator() : const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}