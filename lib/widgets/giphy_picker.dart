import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GiphyPicker extends StatefulWidget {
  final Function(Map<String, dynamic> gif) onGifSelected;

  const GiphyPicker({super.key, required this.onGifSelected});

  @override
  State<GiphyPicker> createState() => _GiphyPickerState();
}

class _GiphyPickerState extends State<GiphyPicker> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<Map<String, dynamic>> _gifs = [];
  bool _loading = true;
  bool _searching = false;
  String _currentQuery = '';
  int _offset = 0;
  bool _hasMore = true;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadTrending();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadTrending() async {
    setState(() {
      _loading = true;
      _gifs = [];
      _offset = 0;
      _hasMore = true;
    });

    try {
      final gifs = await ApiService.getTrendingGifs(limit: 30);
      if (mounted) {
        setState(() {
          _gifs = gifs;
          _loading = false;
          _hasMore = gifs.length >= 30;
          _offset = gifs.length;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _searchGifs(String query) async {
    if (query.trim().isEmpty) {
      _loadTrending();
      return;
    }

    setState(() {
      _searching = true;
      _gifs = [];
      _offset = 0;
      _hasMore = true;
      _currentQuery = query;
    });

    try {
      final gifs = await ApiService.searchGifs(query, limit: 30);
      if (mounted) {
        setState(() {
          _gifs = gifs;
          _searching = false;
          _hasMore = gifs.length >= 30;
          _offset = gifs.length;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _searching) return;

    setState(() => _searching = true);

    try {
      List<Map<String, dynamic>> gifs;

      if (_currentQuery.isEmpty) {
        gifs = await ApiService.getTrendingGifs(limit: 30);
      } else {
        gifs = await ApiService.searchGifs(_currentQuery, limit: 30);
      }

      if (mounted) {
        setState(() {
          _gifs.addAll(gifs);
          _searching = false;
          _hasMore = gifs.length >= 30;
          _offset = _gifs.length;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchGifs(query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Заголовок + поиск
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.gif_box, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'GIF',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Поле поиска
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Поиск GIF...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadTrending();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Сетка GIF
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _gifs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.gif_box,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'GIF не найдены',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          childAspectRatio: 1,
                        ),
                        itemCount: _gifs.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _gifs.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          }

                          final gif = _gifs[index];
                          return _GifTile(
                            gif: gif,
                            onTap: () {
                              widget.onGifSelected(gif);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _GifTile extends StatelessWidget {
  final Map<String, dynamic> gif;
  final VoidCallback onTap;

  const _GifTile({required this.gif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final previewUrl =
        gif['preview_url'] as String? ?? gif['gif_url'] as String? ?? '';
    final title = gif['title'] as String? ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: NetworkImage(previewUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.6),
              ],
            ),
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}