import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import 'user_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<User> _results = [];
  List<User> _recommendations = []; // ✅ Рекомендации при пустом запросе
  bool _loading = false;
  bool _loadingRecommendations = false;
  Timer? _debounce;
  String _searchType = 'all'; // all, username, name

  @override
  void initState() {
    super.initState();
    _loadRecommendations(); // ✅ Загружаем рекомендации сразу
  }

  Future<void> _loadRecommendations() async {
    setState(() => _loadingRecommendations = true);
    try {
      // Загружаем популярных/недавних пользователей
      final users = await ApiService.searchUsers(query: 'a', type: 'all', limit: 20);
      if (mounted) {
        setState(() {
          _recommendations = users;
          _loadingRecommendations = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingRecommendations = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (value.trim().length >= 2) {
        _search(value.trim());
      } else {
        setState(() => _results = []);
      }
    });
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    try {
      final users = await ApiService.searchUsers(
        query: query,
        type: _searchType,
        limit: 30,
      );
      if (mounted) {
        setState(() {
          _results = users;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Обычный Scaffold со стрелкой назад (не AppScaffold с меню)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Поле поиска
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Поиск по username, имени или email...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _controller.clear();
                              setState(() => _results = []);
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    autofocus: true,
                  ),
                ),
                const SizedBox(height: 12),
                // ✅ Переключатель типа поиска
                SegmentedButton(
                  selected: _searchType,
                  onSelected: (type) {
                    setState(() => _searchType = type);
                    if (_controller.text.trim().length >= 2) {
                      _search(_controller.text.trim());
                    }
                  },
                ),
              ],
            ),
          ),
          // Результаты или рекомендации
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _controller.text.trim().length >= 2
                    ? _results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'Ничего не найдено',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final user = _results[index];
                              return _buildUserTile(user);
                            },
                          )
                    : _loadingRecommendations
                        ? const Center(child: CircularProgressIndicator())
                        : _recommendations.isEmpty
                            ? Center(
                                child: Text(
                                  'Начните вводить имя',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _recommendations.length,
                                itemBuilder: (context, index) {
                                  final user = _recommendations[index];
                                  return _buildUserTile(user);
                                },
                              ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(User user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.avatarUrl != null
            ? NetworkImage(user.avatarUrl!)
            : null,
        child: user.avatarUrl == null
            ? Text(user.firstName.isNotEmpty
                ? user.firstName[0].toUpperCase()
                : '?')
            : null,
      ),
      title: Text('${user.firstName} ${user.lastName}'.trim()),
      subtitle: Text('@${user.username}'),
      trailing: user.isOnline
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            )
          : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserProfileScreen(userId: user.id),
          ),
        );
      },
    );
  }
}

// ✅ Компонент SegmentedButton для выбора типа поиска
class SegmentedButton extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const SegmentedButton({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildSegment('all', 'Все', Icons.people),
          const SizedBox(width: 4),
          _buildSegment('username', 'Username', Icons.alternate_email),
          const SizedBox(width: 4),
          _buildSegment('name', 'Имя', Icons.badge),
        ],
      ),
    );
  }

  Widget _buildSegment(String value, String label, IconData icon) {
    final isSelected = selected == value;
    return Expanded(
      child: InkWell(
        onTap: () => onSelected(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.teal[700] : Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.teal[700] : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}