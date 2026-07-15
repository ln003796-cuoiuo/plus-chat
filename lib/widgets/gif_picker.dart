// lib/widgets/gif_picker.dart (Пример простого пикера, если не существует)
// Если GiphyPicker уже есть, просто используем его в ChatInputField
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GiphyPicker extends StatefulWidget {
  final Function(Map<String, dynamic>) onGifSelected;

  const GiphyPicker({Key? key, required this.onGifSelected}) : super(key: key);

  @override
  State<GiphyPicker> createState() => _GiphyPickerState();
}

class _GiphyPickerState extends State<GiphyPicker> {
  List<Map<String, dynamic>> _gifs = [];
  bool _loading = false;
  String _searchQuery = '';
  int _offset = 0;
  final int _limit = 24;

  @override
  void initState() {
    super.initState();
    _loadGifs();
  }

  Future<void> _loadGifs({bool append = false}) async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final res = await ApiService.getGifs(query: _searchQuery, offset: _offset, limit: _limit);
      final newGifs = (res['gifs'] as List? ?? []).cast<Map<String, dynamic>>();

      if (mounted) {
        setState(() {
          if (append) {
            _gifs.addAll(newGifs);
          } else {
            _gifs = newGifs;
          }
          _offset += newGifs.length;
          _loading = false;
        });
      }
    } catch (e) {
      print('Ошибка загрузки гифок: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String query) {
    _searchQuery = query;
    _offset = 0;
    _loadGifs(append: false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            onSubmitted: _onSearch,
            decoration: const InputDecoration(
              hintText: 'Поиск GIF...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: _loading && _gifs.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                      _loadGifs(append: true);
                    }
                    return false;
                  },
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: _gifs.length + (_loading ? 1 : 0), // +1 для индикатора загрузки
                    itemBuilder: (context, index) {
                      if (index >= _gifs.length) {
                        return const Center(child: CircularProgressIndicator()); // Индикатор загрузки внизу
                      }
                      final gif = _gifs[index];
                      return GestureDetector(
                        onTap: () => widget.onGifSelected(gif),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              gif['url'] ?? gif['images']['fixed_height']['url'], // Адаптируйте под структуру API
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}