import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/app_scaffold.dart';
import 'web_view_screen.dart';
import 'privacy_settings_screen.dart';

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
    return AppScaffold(
      title: 'Настройки',
      child: ListView(
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
              Navigator.pushNamed(context, '/change-password');
            },
          ),
          ListTile(
            leading: const Icon(Icons.visibility_off_outlined),
            title: const Text('Приватность'),
            subtitle: const Text('Скрытый профиль и настройки видимости'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Тема оформления'),
            subtitle: const Text('Светлая'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showThemeDialog(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Уведомления'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Скоро будет доступно')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Язык'),
            subtitle: const Text('Русский'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Скоро будет доступно')),
              );
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
                applicationVersion: '1.0.1',
                applicationLegalese: '© 2026 PlusChat Team',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Политика конфиденциальности'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WebViewScreen(
                    title: 'Политика конфиденциальности',
                    content: _privacyText,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Пользовательское соглашение'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WebViewScreen(
                    title: 'Пользовательское соглашение',
                    content: _termsText,
                  ),
                ),
              );
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

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выбор темы'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              title: const Text('Светлая'),
              value: 'light',
              groupValue: 'light',
              onChanged: (v) => Navigator.pop(ctx),
            ),
            RadioListTile(
              title: const Text('Тёмная'),
              value: 'dark',
              groupValue: 'light',
              onChanged: (v) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Тёмная тема скоро будет доступна')),
                );
              },
            ),
            RadioListTile(
              title: const Text('Системная'),
              value: 'system',
              groupValue: 'light',
              onChanged: (v) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Скоро будет доступно')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static const String _privacyText = '''
ПОЛИТИКА КОНФИДЕНЦИАЛЬНОСТИ

Дата вступления в силу: 1 января 2026 г.

1. СБОР ИНФОРМАЦИИ
Мы собираем информацию, которую вы предоставляете при регистрации: имя, email, username.

2. ИСПОЛЬЗОВАНИЕ ИНФОРМАЦИИ
Ваша информация используется для:
- Создания и ведения вашего аккаунта
- Обеспечения работы мессенджера
- Улучшения качества сервиса

3. БЕЗОПАСНОСТЬ
Мы используем современные методы шифрования для защиты ваших данных.

4. КОНТАКТЫ
По вопросам конфиденциальности: privacy@плюсчат.рф
''';

  static const String _termsText = '''
ПОЛЬЗОВАТЕЛЬСКОЕ СОГЛАШЕНИЕ

Дата вступления в силу: 1 января 2026 г.

1. ПРИНЯТИЕ УСЛОВИЙ
Используя приложение "Плюс Чат", вы соглашаетесь с настоящими условиями.

2. ПРАВИЛА ИСПОЛЬЗОВАНИЯ
Запрещается:
- Использование сервиса для незаконной деятельности
- Рассылка спама
- Оскорбление других пользователей
- Выдача себя за другое лицо

3. ОТВЕТСТВЕННОСТЬ
Пользователь несёт ответственность за содержание своих сообщений.

4. ИЗМЕНЕНИЕ УСЛОВИЙ
Мы оставляем за собой право изменять условия использования.

5. КОНТАКТЫ
По вопросам: support@плюсчат.рф
''';
}