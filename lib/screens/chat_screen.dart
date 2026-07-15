// lib/screens/chat_screen.dart
// ... (остальные импорты)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для вибрации
import 'dart:async';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../models/poll.dart'; // Импортируем модель Poll
import '../widgets/chat_input_field.dart';
import '../widgets/message_bubble.dart';
import '../widgets/app_scaffold.dart';
import 'create_poll_screen.dart'; // Импортируем новый экран

// ... (остальные объявления классов и виджетов)

class ChatScreen extends StatefulWidget {
  final Chat chat;

  const ChatScreen({Key? key, required this.chat}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _pollTimer;
  List<Message> _messages = [];
  bool _loading = true;
  bool _isLoadingOlder = false;
  String? _replyToMessageId;
  String? _forwardFromMessageId;
  bool _isRecording = false;
  bool _isPlayingVoice = false; // Для индикации воспроизведения голоса
  String? _currentlyPlayingVoiceId; // ID текущего воспроизводимого голосового сообщения
  // --- ДОБАВЛЕНО: кэш опросов ---
  Map<int, Poll?> _pollCache = {};
  // --- /ДОБАВЛЕНО ---

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _loadMessages(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _scrollController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool loadOlder = false, bool silent = false}) async {
    try {
      if (!silent) setState(() => _loading = true);
      int offset = 0;
      if (loadOlder) {
        offset = _messages.firstOrNull?.id ?? 0;
      }
      final res = await ApiService.getMessages(
        widget.chat.id,
        limit: 50,
        offset: offset,
        older: loadOlder,
      );

      if (res['success'] == true && res['messages'] != null && mounted) {
        final newMessages = (res['messages'] as List)
            .map((json) => Message.fromJson(json))
            .toList()
              ..sort((a, b) => a.id.compareTo(b.id)); // Сортировка по ID

        if (loadOlder) {
          setState(() {
            _messages.insertAll(0, newMessages);
            _loading = false;
            _isLoadingOlder = false;
          });
        } else {
          setState(() {
            _messages.clear();
            _messages.addAll(newMessages);
            _loading = false;
          });
          if (!loadOlder) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }
        }

        // --- ОБНОВЛЕНО: кэшируем опросы из новых сообщений ---
        for (final msg in newMessages) {
          if (msg.type == 'poll' && msg.poll != null) {
             _pollCache[msg.id] = msg.poll!;
          }
        }
        // --- /ОБНОВЛЕНО ---
      }
    } catch (e) {
      print('Ошибка загрузки сообщений: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // --- НОВЫЕ МЕТОДЫ ДЛЯ ОПРОСОВ ---

  Future<void> _handleVote(int messageId, int optionId) async {
    if (_pollCache[messageId]?.hasVoted == true) {
        // Уже голосовали, не даем голосовать снова
        return;
    }
    try {
      final voteRes = await ApiService.voteInPoll(messageId: messageId, optionId: optionId);
      if (voteRes['success'] == true) {
        // Обновляем кэш и перерисовываем сообщение
        final updatedPoll = Poll.fromJson(voteRes);
        setState(() {
          _pollCache[messageId] = updatedPoll;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(voteRes['error'] ?? 'Ошибка голосования')),
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сети: $e')),
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Widget _buildPollWidget(int messageId, Poll poll) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            poll.question,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (poll.isQuiz && poll.hasVoted)
            Text(
              poll.correctOptionId != null
                  ? (poll.options.any((o) => o.optionNumber == poll.correctOptionId && o.isCorrect!) ? '(Правильный ответ)' : '')
                  : '',
              style: TextStyle(color: poll.correctOptionId != null ? (poll.options.any((o) => o.optionNumber == poll.correctOptionId && o.isCorrect!) ? Colors.green : Colors.red) : Colors.grey),
            ),
          const SizedBox(height: 8),
          ...poll.options.asMap().entries.map((entry) {
            int index = entry.key;
            PollOption option = entry.value;
            bool canVote = !poll.hasVoted;
            bool isCorrect = poll.isQuiz && poll.hasVoted && (option.isCorrect ?? false);
            bool isSelected = option.isSelected;

            return GestureDetector(
              onTap: canVote ? () => _handleVote(messageId, option.optionId) : null,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: canVote
                      ? (isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey[200])
                      : (isSelected ? Colors.blue.withOpacity(0.1) : (isCorrect ? Colors.green.withOpacity(0.1) : Colors.grey[100])),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: canVote
                        ? (isSelected ? Colors.blue : Colors.grey[300]!)
                        : (isCorrect ? Colors.green : Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  children: [
                    if (canVote)
                      Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isSelected ? Colors.blue : Colors.grey),
                          color: isSelected ? Colors.blue : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                            : null,
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.text,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (!canVote) // Показываем статистику после голосования
                            LinearProgressIndicator(
                              value: option.percentage / 100,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isSelected ? Colors.blue : (isCorrect ? Colors.green : Colors.grey),
                              ),
                            ),
                          if (!canVote)
                            Text(
                              '${option.votes} голосов (${option.percentage}%)',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          if (poll.totalVotes > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '${poll.totalVotes} голосов',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }
  // --- /НОВЫЕ МЕТОДЫ ---

  // --- ОБНОВЛЁННЫЙ МЕТОД ОТРИСОВКИ СООБЩЕНИЯ ---
  Widget _buildMessageBubble(Message message) {
    final currentUser = AuthService.getCurrentUser();
    final isMe = message.senderId == currentUser?.id;
    final isPoll = message.type == 'poll';

    // Основная логика отрисовки
    if (isPoll) {
      // Если сообщение - опрос, отображаем виджет опроса
      Poll? pollToShow = message.poll ?? _pollCache[message.id];
      if (pollToShow != null) {
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            child: _buildPollWidget(message.id, pollToShow),
          ),
        );
      } else {
        // Заглушка, если опрос не загружен
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Загрузка опроса...'),
          ),
        );
      }
    } else {
      // Иначе используем стандартный MessageBubble
      return MessageBubble(
        message: message,
        isMe: isMe,
        onReply: (msg) => _startReply(msg),
        onForward: (msg) => _startForward(msg),
        onReact: (msg, emoji) => _addReaction(msg, emoji),
        onDelete: (msg) => _deleteMessage(msg),
        onEdit: (msg) => _editMessage(msg),
        onPin: (msg) => _togglePinMessage(msg),
      );
    }
  }
  // --- /ОБНОВЛЁННЫЙ МЕТОД ---

  // ... (остальные методы _ChatScreenState остаются без изменений, за исключением _buildBody)
  // --- ОБНОВЛЁННЫЙ _buildBody ---
  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty) {
      return const Center(child: Text('Нет сообщений'));
    }

    return Column(
      children: [
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels == 0 &&
                  scrollInfo.metrics.extentBefore > 0 &&
                  !_isLoadingOlder) {
                setState(() {
                  _isLoadingOlder = true;
                });
                _loadMessages(loadOlder: true);
              }
              return false;
            },
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                // Добавляем разделитель "Прочитано" если нужно
                if (index == _messages.length - 1 &&
                    widget.chat.lastReadMessageId != null &&
                    message.id > widget.chat.lastReadMessageId!) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'Прочитано',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ),
                      _buildMessageBubble(message),
                    ],
                  );
                }
                return _buildMessageBubble(message);
              },
            ),
          ),
        ),
        ChatInputField(
          focusNode: _focusNode,
          controller: _controller,
          chat: widget.chat,
          onSend: (text) => _sendMessage(text),
          onVoiceRecorded: (audioBase64, duration) => _sendVoiceMessage(audioBase64, duration),
          onFileSelected: (base64, filename, filesize, type) => _sendFileMessage(base64, filename, filesize, type),
          onMediaSelected: (base64, thumbnailBase64, filename, filesize, type) => _sendMediaMessage(base64, thumbnailBase64, filename, filesize, type),
          onGifSelected: (gifUrl, gifId) => _sendGifMessage(gifUrl, gifId),
          onStickerSelected: (stickerId, packId) => _sendStickerMessage(stickerId, packId),
          onPollCreated: (pollData) => _sendPoll(pollData), // Добавляем обработчик
          onLocationSelected: (lat, lng, address) => _sendLocationMessage(lat, lng, address), // Добавляем обработчик
        ),
      ],
    );
  }
  // --- /ОБНОВЛЁННЫЙ _buildBody ---

  // --- НОВЫЙ МЕТОД ДЛЯ ОТПРАВКИ ОПРОСА ---
  Future<void> _sendPoll(Map<String, dynamic> pollData) async {
    try {
      final pollRes = await ApiService.sendPoll(
        chatId: widget.chat.id,
        question: pollData['question'],
        options: pollData['options'],
        isQuiz: pollData['isQuiz'],
        correctOptionId: pollData['isQuiz'] ? pollData['correctOptionId'] : null,
      );
      if (pollRes['success'] == true) {
        // Опрос отправлен, перезагружаем сообщения
        _loadMessages();
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(pollRes['error'] ?? 'Ошибка отправки опроса')),
             backgroundColor: Colors.red,
           );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сети: $e')),
          backgroundColor: Colors.red,
        );
      }
    }
  }
  // --- /НОВЫЙ МЕТОД ---

  // --- МЕТОДЫ ОТПРАВКИ СООБЩЕНИЙ (остаются без изменений, но используют обновлённый _loadMessages) ---
  // ... (все методы _send... остаются, но вызывают _loadMessages() при успехе)
  // --- /МЕТОДЫ ОТПРАВКИ ---

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        // Обработка нажатия назад
        Navigator.pop(context);
      },
      child: AppScaffold(
        title: widget.chat.title ?? 'Чат',
        showBackButton: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String choice) {
              switch (choice) {
                case 'info':
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => ChatInfoScreen(chat: widget.chat)));
                  break;
                case 'archive':
                  _toggleArchive();
                  break;
                case 'favorite':
                  _toggleFavorite();
                  break;
                case 'mute':
                  _toggleMute();
                  break;
                case 'leave':
                  _leaveChat();
                  break;
                case 'delete':
                  _deleteChat();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'info',
                child: Text('Информация'),
              ),
              PopupMenuItem<String>(
                value: widget.chat.isArchived ? 'unarchive' : 'archive',
                child: Text(widget.chat.isArchived ? 'Разархивировать' : 'В архив'),
              ),
              PopupMenuItem<String>(
                value: widget.chat.isFavorite ? 'unfavorite' : 'favorite',
                child: Text(widget.chat.isFavorite ? 'Убрать из избранного' : 'В избранное'),
              ),
              PopupMenuItem<String>(
                value: widget.chat.isMuted ? 'unmute' : 'mute',
                child: Text(widget.chat.isMuted ? 'Включить уведомления' : 'Выключить уведомления'),
              ),
              if (widget.chat.type != 'private')
                const PopupMenuItem<String>(
                  value: 'leave',
                  child: Text('Покинуть чат'),
                ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('Удалить чат'),
              ),
            ],
          ),
        ],
        body: _buildBody(), // Используем обновлённый _buildBody
      ),
    );
  }
}