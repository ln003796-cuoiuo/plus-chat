// lib/widgets/chat_input_field.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../models/chat.dart';
import 'emoji_picker.dart'; // Импортируем виджеты
import 'sticker_picker.dart'; // Эти файлы нужно будет создать или обновить
import 'gif_picker.dart'; // или использовать существующий GiphyPicker
import 'location_picker_screen.dart'; // Новый экран

class ChatInputField extends StatefulWidget {
  final FocusNode focusNode;
  final TextEditingController controller;
  final Chat chat;
  final Function(String) onSend;
  final Function(String, int) onVoiceRecorded;
  final Function(String, String, int, String) onFileSelected;
  final Function(String, String?, String, int, String) onMediaSelected;
  final Function(String, String) onGifSelected;
  final Function(int, int) onStickerSelected;
  final Function(Map<String, dynamic>) onPollCreated; // Добавляем
  final Function(double, double, String?) onLocationSelected; // Добавляем

  const ChatInputField({
    Key? key,
    required this.focusNode,
    required this.controller,
    required this.chat,
    required this.onSend,
    required this.onVoiceRecorded,
    required this.onFileSelected,
    required this.onMediaSelected,
    required this.onGifSelected,
    required this.onStickerSelected,
    required this.onPollCreated, // Добавляем
    required this.onLocationSelected, // Добавляем
  }) : super(key: key);

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  bool _isRecording = false;
  bool _showEmojiPanel = false;
  bool _showStickerPanel = false;
  bool _showGifPanel = false;

  // --- НОВОЕ: метод для показа панели прикрепления ---
  void _showAttachOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Фото'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    // Конвертируем в base64 и отправляем как медиа
                    String base64 = await image.readAsBytes().then((bytes) => base64Encode(bytes));
                    widget.onMediaSelected(base64, null, image.name, image.lengthSync(), 'photo');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Сделать фото'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await ImagePicker().pickImage(source: ImageSource.camera);
                  if (image != null) {
                    String base64 = await image.readAsBytes().then((bytes) => base64Encode(bytes));
                    widget.onMediaSelected(base64, null, image.name, image.lengthSync(), 'photo');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('Видео'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? video = await ImagePicker().pickVideo(source: ImageSource.gallery);
                  if (video != null) {
                    String base64 = await video.readAsBytes().then((bytes) => base64Encode(bytes));
                    // Требуется получение миниатюры, если поддерживается
                    widget.onMediaSelected(base64, null, video.name, video.lengthSync(), 'video');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.movie_creation),
                title: const Text('Сделать видео'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? video = await ImagePicker().pickVideo(source: ImageSource.camera);
                  if (video != null) {
                    String base64 = await video.readAsBytes().then((bytes) => base64Encode(bytes));
                    widget.onMediaSelected(base64, null, video.name, video.lengthSync(), 'video');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file),
                title: const Text('Файл'),
                onTap: () async {
                  Navigator.pop(context);
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
                  if (result != null) {
                    PlatformFile file = result.files.single;
                    String base64 = base64Encode(file.bytes!);
                    widget.onFileSelected(base64, file.name, file.size, 'file');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Местоположение'),
                onTap: () async {
                  Navigator.pop(context);
                  // Переход на новый экран выбора местоположения
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationPickerScreen(),
                    ),
                  );
                  if (result != null) {
                    final lat = result['latitude'] as double;
                    final lng = result['longitude'] as double;
                    final addr = result['address'] as String?;
                    widget.onLocationSelected(lat, lng, addr);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.poll),
                title: const Text('Опрос'),
                onTap: () async {
                  Navigator.pop(context);
                  // Переход на экран создания опроса
                  final pollData = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreatePollScreen(
                        onSubmit: (data) {}, // Этот обратный вызов не нужен, т.к. мы обработаем результат в ChatScreen
                      ),
                    ),
                  );
                  if (pollData != null) {
                    widget.onPollCreated(pollData);
                  }
                },
              ),
              // Добавляем кнопки для эмодзи, стикеров, гифок?
              // Или пусть они вызываются из основной панели ввода?
              // Пока оставим только основные.
            ],
          ),
        );
      },
    );
  }
  // --- /НОВОЕ ---

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // --- ПАНЕЛЬ ЭМОДЗИ/СТИКЕРОВ/GIF ---
        if (_showEmojiPanel || _showStickerPanel || _showGifPanel)
          Container(
            height: 300, // Высота панели
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: _showEmojiPanel
                ? EmojiPicker(
                    onEmojiSelected: (emoji) {
                      setState(() {
                        widget.controller.text += emoji;
                        _showEmojiPanel = false;
                      });
                    },
                  )
                : _showStickerPanel
                    ? StickerPicker(
                        onStickerSelected: (sticker, packId) {
                          // Вызываем переданный обратный вызов для отправки стикера
                          widget.onStickerSelected(sticker['id'], packId);
                          setState(() {
                            _showStickerPanel = false;
                          });
                        },
                      )
                    : GiphyPicker( // Предполагаем, что такой виджет существует или будет создан
                        onGifSelected: (gif) {
                          widget.onGifSelected(gif['url'], gif['id']);
                          setState(() {
                            _showGifPanel = false;
                          });
                        },
                      ),
          ),
        // --- /ПАНЕЛЬ ---

        // --- ПОЛЕ ВВОДА ---
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // --- КНОПКА ПРИКРЕПЛЕНИЯ ---
              PopupMenuButton<String>(
                icon: const Icon(Icons.attach_file),
                onSelected: (value) {
                  // Убираем переключение панелей из этой кнопки
                  // setState(() {
                  //   _showEmojiPanel = value == 'emoji';
                  //   _showStickerPanel = value == 'sticker';
                  //   _showGifPanel = value == 'gif';
                  // });
                  // Вызываем метод для показа опций прикрепления
                  _showAttachOptions();
                },
                itemBuilder: (ctx) => [
                  // Убираем эмодзи, стикеры, гифки из этого меню
                  // const PopupMenuItem(value: 'emoji', child: Row(children: [Icon(Icons.emoji_emotions), SizedBox(width: 12), Text('Эмодзи'),],),),
                  // const PopupMenuItem(value: 'sticker', child: Row(children: [Icon(Icons.sticky_note_2), SizedBox(width: 12), Text('Стикеры'),],),),
                  // const PopupMenuItem(value: 'gif', child: Row(children: [Icon(Icons.gif_box), SizedBox(width: 12), Text('GIF'),],),),
                  // Добавим пункт "Местоположение" или "Опрос" сюда, если хотим
                  // const PopupMenuItem(value: 'location', child: Row(children: [Icon(Icons.location_on), SizedBox(width: 12), Text('Местоположение'),],),),
                  // const PopupMenuItem(value: 'poll', child: Row(children: [Icon(Icons.poll), SizedBox(width: 12), Text('Опрос'),],),),
                  // Но лучше пусть они будут в основном меню прикрепления
                ],
              ),
              // --- /КНОПКА ПРИКРЕПЛЕНИЯ ---

              const SizedBox(width: 4),

              // --- КНОПКА ЭМОДЗИ (НОВАЯ) ---
              IconButton(
                icon: const Icon(Icons.emoji_emotions_outlined),
                onPressed: () {
                  setState(() {
                    _showEmojiPanel = !_showEmojiPanel;
                    _showStickerPanel = false; // Скрываем другие панели
                    _showGifPanel = false;
                  });
                },
              ),
              // --- /КНОПКА ЭМОДЗИ ---

              // --- КНОПКА СТИКЕРОВ (НОВАЯ) ---
              IconButton(
                icon: const Icon(Icons.sticky_note_2_outlined),
                onPressed: () {
                  setState(() {
                    _showStickerPanel = !_showStickerPanel;
                    _showEmojiPanel = false; // Скрываем другие панели
                    _showGifPanel = false;
                  });
                },
              ),
              // --- /КНОПКА СТИКЕРОВ ---

              // --- КНОПКА GIF (НОВАЯ) ---
              IconButton(
                icon: const Icon(Icons.gif_box_outlined),
                onPressed: () {
                  setState(() {
                    _showGifPanel = !_showGifPanel;
                    _showEmojiPanel = false; // Скрываем другие панели
                    _showStickerPanel = false;
                  });
                },
              ),
              // --- /КНОПКА GIF ---

              const SizedBox(width: 4),

              Expanded(
                child: TextField(
                  controller: widget.controller,
                  // onChanged: _onTypingChanged, // Если нужен вызов из ChatScreen
                  decoration: InputDecoration(
                    hintText: 'Сообщение...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  maxLines: 4,
                  minLines: 1,
                  onSubmitted: (text) => widget.onSend(text),
                ),
              ),
              const SizedBox(width: 8),
              if (widget.controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    String text = widget.controller.text.trim();
                    if (text.isNotEmpty) {
                      widget.onSend(text);
                      widget.controller.clear();
                    }
                  },
                )
              else
                IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: () {
                    // Логика записи голосового сообщения
                    // _startRecording(); // Реализовать
                  },
                ),
            ],
          ),
        ),
        // --- /ПОЛЕ ВВОДА ---
      ],
    );
  }
}