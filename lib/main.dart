import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/verify_screen.dart';
import 'screens/home_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/search_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/gifts_screen.dart';
import 'screens/archived_chats_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/web_view_screen.dart';
import 'services/auth_service.dart';
import 'models/chat.dart';

void main() {
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
        '/home': (context) => const HomeScreen(),
        '/friends': (context) => const FriendsScreen(),
        '/contacts': (context) => const ContactsScreen(),
        '/search': (context) => const SearchScreen(),
        '/gifts': (context) => const GiftsScreen(),
        '/archived': (context) => const ArchivedChatsScreen(),
        '/change-password': (context) => const ChangePasswordScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/verify') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => VerifyScreen(
              email: args['email'] as String,
              type: args['type'] as String? ?? 'registration',
            ),
          );
        }
        if (settings.name == '/chat') {
          final chat = settings.arguments as Chat;
          return MaterialPageRoute(
            builder: (context) => ChatScreen(chat: chat),
          );
        }
        return null;
      },
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == true) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}