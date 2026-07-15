// plus-chat-main/lib/main.dart
import 'package:flutter/material.dart';
import 'package:plus_chat/services/security_service.dart'; // Импортируем наш сервис
import 'screens/login_screen.dart';
import 'screens/auth_wrapper.dart'; // Предполагаем, что AuthWrapper теперь обрабатывает проверки
import 'services/update_service.dart';
import 'models/chat.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Обязательно для асинхронных операций перед runApp

  // Проверяем безопасность перед запуском приложения
  bool isSecure = await SecurityService.checkAll();
  if (!isSecure) {
    runApp(const InsecureApp());
    return; // Выходим, если проверка не пройдена
  }

  runApp(const PlusChatApp());
}

class PlusChatApp extends StatelessWidget {
  const PlusChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Плюс Чат',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF075E54),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/setup': (context) => const SetupScreen(),
        '/home': (context) => const AuthWrapper(), // AuthWrapper теперь центральный экран
        // ... другие маршруты
      },
      // Устанавливаем AuthWrapper как начальный маршрут
      initialRoute: '/home',
    );
  }
}

// --- Экран, отображаемый при обнаружении проблем с безопасностью ---
class InsecureApp extends StatelessWidget {
  const InsecureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black, // Темный фон для драматического эффекта
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.security,
                  color: Colors.red,
                  size: 80,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Приложение заблокировано',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Пользователям с root на телефоне или с патченным приложением доступ к Плюс Чат запрещён.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Завершаем приложение
                    // В мобильных приложениях нет стандартного способа "завершить процесс",
                    // но можно скрыть приложение или вызвать SystemChannels.platform.
                    // Navigator.of(context).pop(); // Не сработает, так как это главный экран.
                    // SystemChannels.platform.invokeMethod('SystemNavigator.pop'); // Устарело
                    // Рекомендуется просто не давать доступ к остальному функционалу.
                    // Для полного завершения можно использовать пакет flutter_exit_app.
                    // Установите: flutter pub add flutter_exit_app
                    // И используйте: import 'package:flutter_exit_app/flutter_exit_app.dart';
                    // FlutterExitApp.exitApp();
                    // Пока просто оставим кнопку без действия, приложение "зависнет".
                    // В реальности, дальнейший функционал будет недоступен.
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Закрыть'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}