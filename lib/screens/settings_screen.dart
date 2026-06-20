import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Выйти', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await AuthService.logout();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Редактировать профиль'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Изменить пароль'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Экран смены пароля
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Тема оформления'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Выбор темы
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Уведомления'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Настройки уведомлений
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Язык'),
            subtitle: const Text('Русский'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Выбор языка
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('О приложении'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Плюс Чат',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2026 PlusChat Team',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Политика конфиденциальности'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Открыть WebView с политикой
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Пользовательское соглашение'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Открыть WebView с соглашением
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Выйти из аккаунта', style: TextStyle(color: Colors.red)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}