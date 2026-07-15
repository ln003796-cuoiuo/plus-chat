// lib/screens/chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../widgets/message_bubble.dart';
import '../widgets/giphy_picker.dart';
import '../widgets/sticker_picker.dart';
import 'chat_info_screen.dart';
import 'user_profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;

  const ChatScreen({super.key, required this.chat});

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
  bool _isPlayingVoice = false;
  String? _currentlyPlayingVoiceId;

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
              ..sort((a, b) => a.id.compareTo(b.id));

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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final message = Message(
      id: -DateTime.now().millisecondsSinceEpoch, // Temporary local ID
      chatId: widget.chat.id,
      senderId: AuthService.getCurrentUser()!.id,
      type: 'text',
      content: text,
      sentAt: DateTime.now().toIso8601String(),
      edited: false,
      forwardsCount: 0,
      attachments: [],
    );

    setState(() {
      _messages.add(message);
      _scrollToBottom();
      _controller.clear();
    });

    try {
      final res = await ApiService.sendMessage(
        widget.chat.id,
        'text',
        text,
        replyToMessageId: _replyToMessageId != null ? int.tryParse(_replyToMessageId!) : null,
        forwardFromMessageId: _forwardFromMessageId != null ? int.tryParse(_forwardFromMessageId!) : null,
      );
      if (res['success'] == true) {
        final newMessage = Message.fromJson(res['message']);
        setState(() {
          _messages.removeLast(); // Remove temporary message
          _messages.add(newMessage);
        });
        _loadMessages(); // Reload to ensure consistency
      } else {
        setState(() {
          _messages.removeLast(); // Remove temporary message on error
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['error'] ?? 'Ошибка отправки')),
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      setState(() {
        _messages.removeLast(); // Remove temporary message on exception
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сети: $e')),
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _sendVoiceMessage(String audioBase64, int duration) async {
    // Similar logic to _sendMessage but for voice
    final message = Message(
      id: -DateTime.now().millisecondsSinceEpoch,
      chatId: widget.chat.id,
      senderId: AuthService.getCurrentUser()!.id,
      type: 'voice',
      content: '', // Usually empty for voice
      mediaUrl: audioBase64, // Or save to temp URL
      duration: duration,
      sentAt: DateTime.now().toIso8601String(),
      edited: false,
      forwardsCount: 0,
      attachments: [],
    );

    setState(() {
      _messages.add(message);
      _scrollToBottom();
    });

    try {
      final res = await ApiService.sendVoiceMessage(
        widget.chat.id,
        audioBase64,
        duration,
      );
      if (res['success'] == true) {
        final newMessage = Message.fromJson(res['message']);
        setState(() {
          _messages.removeLast();
          _messages.add(newMessage);
        });
        _loadMessages();
      } else {
        setState(() {
          _messages.removeLast();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['error'] ?? 'Ошибка отправки голоса')),
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      setState(() {
        _messages.removeLast();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сети: $e')),
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _sendFileMessage(String base64, String filename, int filesize, String type) async {
    // Similar logic to _sendMessage but for files
    final message = Message(
      id: -DateTime.now().millisecondsSinceEpoch,
      chatId: widget.chat.id,
      senderId: AuthService.getCurrentUser()!.id,
      type: type, // e.g., 'file', 'document'
      content: filename,
      mediaUrl: base64, // Or save to temp URL
      fileName: filename,
      fileSize: filesize,
      sentAt: DateTime.now().toIso8601String(),
      edited: false,
      forwardsCount: 0,
      attachments: [],
    );

    setState(() {
      _messages.add(message);
      _scrollToBottom();
    });

    try {
      final res;
      if (type == 'file') {
        res = await ApiService.sendFileMessage(
          widget.chat.id,
          base64,
          filename,
          filesize,
        );
      } else {
        // Handle other types if needed
        res = {'success': false, 'error': 'Unknown file type'};
      }

      if (res['success'] == true) {
        final newMessage = Message.fromJson(res['message']);
        setState(() {
          _messages.removeLast();
          _messages.add(newMessage);
        });
        _loadMessages();
      } else {
        setState(() {
          _messages.removeLast();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['error'] ?? 'Ошибка отправки файла')),
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      setState(() {
        _messages.removeLast();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сети: $e')),
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _sendMediaMessage(String base64, String? thumbnailBase64, String filename, int filesize, String type) async {
    // Similar logic to _sendMessage but for media (photos, videos)
    final message = Message(
      id: -DateTime.now().millisecondsSinceEpoch,
      chatId: widget.chat.id,
      senderId: AuthService.getCurrentUser()!.id,
      type: type, // 'photo', 'video'
      content: '', // Usually empty for media
      mediaUrl: base64, // Or save to temp URL
      thumbnailUrl: thumbnailBase64,
      fileName: filename,
      fileSize: filesize,
      sentAt: DateTime.now().toIso8601String(),
      edited: false,
      forwardsCount: 0,
      attachments: [],
    );

    setState(() {
      _messages.add(message);
      _scrollToBottom();
    });

    try {
      final res;
      if (type == 'photo') {
        res = await ApiService.sendMediaMessage(
          widget.chat.id,
          'photo',
          base64,
          thumbnailBase64,
          filename,
          filesize,
        );
      } else if (type == 'video') {
         int duration = 0; // You need to get the duration somehow before sending
         res = await ApiService.sendVideoMessage(
           widget.chat.id,
           base64,
           thumbnailBase64,
           duration, // Provide actual duration
           filename,
           filesize,
         );
      } else {
        res = {'success': false, 'error': 'Unknown media type'};
      }

      if (res['success'] == true) {
        final newMessage = Message.fromJson(res['message']);
        setState(() {
          _messages.removeLast();
          _messages.add(newMessage);
        });
        _loadMessages();
      } else {
        setState(() {
          _messages.removeLast();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['error'] ?? 'Ошибка отправки медиа')),
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      setState(() {
        _messages.removeLast();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сети: $e')),
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _sendGifMessage(String gifUrl, String gifId) async {
    // Similar logic to _sendMessage but for GIFs
    final message = Message(
      id: -DateTime.now().millisecondsSinceEpoch,
      chatId: widget.chat.id,
      senderId: AuthService.getCurrentUser()!.id,
      type: 'gif',
      content: '', // Usually empty for GIFs
      mediaUrl: gifUrl,
      sentAt: DateTime.now().toIso8601String(),
      edited: false,
      forwardsCount: 0,
      attachments: [],
    );

    setState(() {
      _messages.add(message);
      _scrollToBottom();
    });

    try {
      final res = await ApiService.sendGifMessage(
        widget.chat.id,
        gifUrl,
        gifId,
      );
      if (res['success'] == true) {
        final newMessage = Message.fromJson(res['message']);
        setState(() {
          _messages.removeLast();
          _messages.add(newMessage);
        });
        _loadMessages();
      } else {
        setState(() {
          _messages.removeLast();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['error'] ?? 'Ошибка отправки GIF')),
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      setState(() {
        _messages.removeLast();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сети: $e')),
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _sendStickerMessage(int stickerId, int packId) async {
    // Similar logic to _sendMessage but for stickers
    final message = Message(
      id: -DateTime.now().millisecondsSinceEpoch,
      chatId: widget.chat.id,
      senderId: AuthService.getCurrentUser()!.id,
      type: 'sticker',
      content: '', // Usually empty for stickers
      sentAt: DateTime.now().toIso8601String(),
      edited: false,
      forwardsCount: 0,
      attachments: [],
    );

    setState(() {
      _messages.add(message);
      _scrollToBottom();
    });

    try {
      final res = await ApiService.sendStickerMessage(
        widget.chat.id,
        stickerId,
        packId,
      );
      if (res['success'] == true) {
        final newMessage = Message.fromJson(res['message']);
        setState(() {
          _messages.removeLast();
          _messages.add(newMessage);
        });
        _loadMessages();
      } else {
        setState(() {
          _messages.removeLast();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['error'] ?? 'Ошибка отправки стикера')),
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      setState(() {
        _messages.removeLast();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сети: $e')),
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _editMessage(Message message) async {
    final newText = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Редактировать сообщение'),
        content: TextField(
          initialValue: message.content,
          controller: _controller..text = message.content,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _controller.text),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (newText != null && newText != message.content) {
      try {
        final res = await ApiService.editMessage(
          message.chatId,
          message.id,
          newText,
        );
        if (res['success'] == true) {
          setState(() {
            final index = _messages.indexWhere((m) => m.id == message.id);
            if (index != -1) {
              _messages[index] = _messages[index].copyWith(
                content: newText,
                edited: true,
              );
            }
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res['error'] ?? 'Ошибка редактирования')),
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
  }

  Future<void> _deleteMessage(Message message) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить сообщение'),
        content: const Text('Вы уверены?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await ApiService.deleteMessage(
          message.chatId,
          message.id,
          true, // forEveryone - adjust based on user choice if needed
        );
        if (res['success'] == true) {
          setState(() {
            _messages.removeWhere((m) => m.id == message.id);
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res['error'] ?? 'Ошибка удаления')),
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
  }

  Future<void> _addReaction(Message message, String emoji) async {
    try {
      final res = await ApiService.addReaction(
        message.chatId,
        message.id,
        emoji,
      );
      if (res['success'] == true) {
        // Reload messages to reflect the reaction
        _loadMessages();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['error'] ?? 'Ошибка добавления реакции')),
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

  Future<void> _togglePinMessage(Message message) async {
    try {
      final res = await ApiService.pinMessage(
        message.chatId,
        message.id,
      );
      if (res['success'] == true) {
        // Reload messages to reflect the pin status
        _loadMessages();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['error'] ?? 'Ошибка закрепления')),
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

  void _startReply(Message message) {
    setState(() {
      _replyToMessageId = message.id.toString();
      _focusNode.requestFocus();
    });
  }

  void _startForward(Message message) {
    setState(() {
      _forwardFromMessageId = message.id.toString();
      _focusNode.requestFocus();
    });
  }

  Future<void> _toggleArchive() async {
    try {
      final res = await ApiService.archiveChat(widget.chat.id);
      if (res['success'] == true) {
        // Update local chat state if needed, or reload chats in HomeScreen
        // Example: widget.chat.isArchived = !widget.chat.isArchived;
        if (mounted) Navigator.pop(context); // Go back after archiving
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['error'] ?? 'Ошибка архивации')),
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

  Future<void> _toggleFavorite() async {
    try {
      final res = await ApiService.toggleFavorite(widget.chat.id);
      if (res['success'] == true) {
        // Update local chat state if needed, or reload chats in HomeScreen
        // Example: widget.chat.isFavorite = !widget.chat.isFavorite;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['error'] ?? 'Ошибка избранного')),
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

  Future<void> _toggleMute() async {
    try {
      int? untilTimestamp = null; // Implement mute duration selection
      final res = await ApiService.muteChat(widget.chat.id, untilTimestamp);
      if (res['success'] == true) {
        // Update local chat state if needed, or reload chats in HomeScreen
        // Example: widget.chat.isMuted = !widget.chat.isMuted;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['error'] ?? 'Ошибка отключения звука')),
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

  Future<void> _leaveChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Покинуть чат'),
        content: const Text('Вы уверены?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Покинуть'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await ApiService.leaveChat(widget.chat.id);
        if (res['success'] == true) {
          if (mounted) Navigator.pop(context); // Go back to chat list
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res['error'] ?? 'Ошибка выхода')),
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
  }

  Future<void> _deleteChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить чат'),
        content: const Text('Вы уверены?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await ApiService.deleteChat(widget.chat.id);
        if (res['success'] == true) {
          if (mounted) Navigator.pop(context); // Go back to chat list
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res['error'] ?? 'Ошибка удаления чата')),
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
  }

  // --- НАШИ ОБНОВЛЁННЫЕ МЕТОДЫ ---
  // (Вставляем сюда код из предыдущего ответа, начиная с _handleVote и заканчивая _sendLocationMessage)
  // --- /НАШИ ОБНОВЛЁННЫЕ МЕТОДЫ ---

  Widget _buildMessageBubble(Message message) {
    final currentUser = AuthService.getCurrentUser();
    final isMe = message.senderId == currentUser?.id;

    // Проверяем, является ли сообщение опросом
    if (message.type == 'poll') {
        // Здесь должна быть логика отображения опроса и обработки голосования
        // Пока что выводим заглушку
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Опрос (отображение в разработке)'),
          ),
        );
    }

    // Используем стандартный MessageBubble для других типов
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
                // Add read separator if needed
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
        // --- ОБНОВЛЁННОЕ ПОЛЕ ВВОДА ---
        // (Вставляем сюда обновлённый ChatInputField из предыдущего ответа)
        // Для простоты, покажем базовый вариант, который вызывает методы отправки
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
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: () {
                  // Show attachment options (file, media, location, poll)
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
                                // Use image_picker plugin
                                // final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
                                // if (image != null) { ... sendMediaMessage ... }
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.video_library),
                              title: const Text('Видео'),
                              onTap: () async {
                                Navigator.pop(context);
                                // Use image_picker plugin
                                // final XFile? video = await ImagePicker().pickVideo(source: ImageSource.gallery);
                                // if (video != null) { ... sendMediaMessage ... }
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.attach_file),
                              title: const Text('Файл'),
                              onTap: () async {
                                Navigator.pop(context);
                                // Use file_picker plugin
                                // FilePickerResult? result = await FilePicker.platform.pickFiles();
                                // if (result != null) { ... sendFileMessage ... }
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.location_on),
                              title: const Text('Местоположение'),
                              onTap: () async {
                                Navigator.pop(context);
                                // Navigate to LocationPickerScreen or implement inline picker
                                // Example:
                                // final result = await Navigator.push(
                                //   context,
                                //   MaterialPageRoute(builder: (context) => LocationPickerScreen()),
                                // );
                                // if (result != null) { _sendLocationMessage(...); }
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.poll),
                              title: const Text('Опрос'),
                              onTap: () async {
                                Navigator.pop(context);
                                // Navigate to CreatePollScreen
                                // Example:
                                // final pollData = await Navigator.push(
                                //   context,
                                //   MaterialPageRoute(builder: (context) => CreatePollScreen()),
                                // );
                                // if (pollData != null) { _sendPoll(pollData); }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  // onChanged: _onTypingChanged, // If needed
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
                  onSubmitted: (text) => _sendMessage(text),
                ),
              ),
              const SizedBox(width: 8),
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    String text = _controller.text.trim();
                    if (text.isNotEmpty) {
                      _sendMessage(text);
                      _controller.clear();
                    }
                  },
                )
              else
                IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: () {
                    // Start voice recording
                    // _startRecording(); // Implement recording logic
                  },
                ),
            ],
          ),
        ),
        // --- /ОБНОВЛЁННОЕ ПОЛЕ ВВОДА ---
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        // Handle back button press
        Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.chat.title ?? 'Чат'),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (String choice) {
                switch (choice) {
                  case 'info':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatInfoScreen(chat: widget.chat),
                      ),
                    );
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
        ),
        body: _buildBody(),
      ),
    );
  }
}