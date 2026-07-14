import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _isHidden = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final user = await ApiService.getMe();
      if (mounted) {
        setState(() {
          _isHidden = user?.isHidden ?? false;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleVisibility(bool value) async {
    setState(() => _isHidden = value);
    try {
      final res = await ApiService.setProfileVisibility(value);
      if (res['success'] != true && mounted) {
        setState(() => _isHidden = !value); // Откат при ошибке
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['error'] ?? 'Ошибка'), backgroundColor: Colors.red),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(value ? 'Профиль скрыт' : 'Профиль видим')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isHidden = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сети: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Приватность'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('Скрытый профиль'),
                  subtitle: const Text(
                    'Если включено, ваш профиль не будет отображаться в поиске и рекомендациях. '
                    'Вас можно будет найти только по точной ссылке или username.',
                  ),
                  value: _isHidden,
                  onChanged: _toggleVisibility,
                  secondary: const Icon(Icons.visibility_off),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Другие настройки приватности (кто может писать, звонить) скоро будут доступны.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
    );
  }
}