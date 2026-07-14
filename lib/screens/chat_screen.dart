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
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _loading = true;
  String? _myUserId;
  Message? _replyTo;
  bool _showEmojiPanel = false;
  bool _showStickerPanel = false;
  bool _showGifPanel = false;
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadMyId();
    _loadMessages();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadMyId() async {
    final id = await AuthService.getUserId();
    if (mounted) setState(() => _myUserId = id);
  }

  Future<void> _loadMessages({bool loadOlder = false}) async {
    try {
      final before = loadOlder && _messages.isNotEmpty ? _messages.first.id : null;
      final msgs = await ApiService.getMessages(widget.chat.id, before: before);
      
      if (mounted) {
        setState(() {
          if (loadOlder) {
            _messages = [...msgs, ..._messages];
          } else {
            _messages = msgs;
          }
          _loading = false;
        });
        
        if (!loadOlder) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 100 && !_loading) {
      _loadMessages(loadOlder: true);
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

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _controller.clear());
    
    try {
      await ApiService.sendMessage(
        chatId: widget.chat.id,
        content: text,
        replyTo: _replyTo?.id.toString(),
      );
      
      setState(() => _replyTo = null);
      _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sendSticker(Map<String, dynamic> sticker, int packId) async {
    try {
      await ApiService.sendSticker(
        chatId: widget.chat.id,
        stickerUrl: sticker['file_url'] ?? '',
        stickerId: sticker['id']?.toString(),
      );
      _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sendGif(Map<String, dynamic> gif) async {
    try {
      await ApiService.sendGif(
        chatId: widget.chat.id,
        gifUrl: gif['gif_url'] ?? gif['url'] ?? '',
        gifId: gif['id']?.toString(),
        width: gif['width'],
        height: gif['height'],
      );
      _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onTypingChanged(String text) {
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      ApiService.sendTypingStatus(widget.chat.id, true);
    }
    
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _isTyping = false;
      ApiService.sendTypingStatus(widget.chat.id, false);
    });
  }

  Future<void> _editMessage(Message message) async {
    final controller = TextEditingController(text: message.content);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Редактировать сообщение'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty && result != message.content) {
      await ApiService.editMessage(message.id, result);
      _loadMessages();
    }
  }

  Future<void> _deleteMessage(Message message, {bool forAll = false}) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(forAll ? 'Удалить у всех?' : 'Удалить у себя?'),
        content: const Text('Это действие нельзя отменить'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await ApiService.deleteMessage(message.id, forAll: forAll);
      _loadMessages();
    }
  }

  void _showMessageOptions(Message message) {
    final isMe = message.senderId == _myUserId;
    
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Ответить'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _replyTo = message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Копировать'),
              onTap: () {
                Navigator.pop(ctx);
                // TODO: копировать в буфер
              },
            ),
            ListTile(
              leading: const Icon(Icons.push_pin),
              title: const Text('Закрепить'),
              onTap: () async {
                Navigator.pop(ctx);
                await ApiService.pinMessage(message.id, widget.chat.id);
                _loadMessages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.forward),
              title: const Text('Переслать'),
              onTap: () {
                Navigator.pop(ctx);
                // TODO: переслать
              },
            ),
            if (isMe && message.type == MessageType.text)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Редактировать'),
                onTap: () {
                  Navigator.pop(ctx);
                  _editMessage(message);
                },
              ),
            const Divider(),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Удалить у себя', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteMessage(message, forAll: false);
                },
              ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Удалить у всех', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteMessage(message, forAll: true);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            if (widget.chat.type == 'private' && widget.chat.companionId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfileScreen(userId: widget.chat.companionId!),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatInfoScreen(chat: widget.chat),
                ),
              );
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primary,
                backgroundImage: widget.chat.avatarUrl != null
                    ? NetworkImage(widget.chat.avatarUrl!)
                    : null,
                child: widget.chat.avatarUrl == null
                    ? Text(
                        widget.chat.initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.chat.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.chat.type == 'private'
                        ? (widget.chat.isOnline ? 'в сети' : 'был(а) недавно')
                        : '${widget.chat.membersCount} участников',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.chat.isMuted ? Icons.notifications_off : Icons.notifications,
            ),
            onPressed: () async {
              try {
                if (widget.chat.isMuted) {
                  await ApiService.unmuteChats([widget.chat.id]);
                } else {
                  await ApiService.muteChats([widget.chat.id]);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        widget.chat.isMuted ? 'Звук включён' : 'Звук выключен',
                      ),
                    ),
                  );
                  // Перезагружаем для обновления иконки
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => ChatScreen(chat: widget.chat)),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatInfoScreen(chat: widget.chat),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Reply preview
          if (_replyTo != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _replyTo!.sender?.displayName ?? 'Сообщение',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _replyTo!.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(() => _replyTo = null),
                  ),
                ],
              ),
            ),
          
          // Сообщения
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Начните общение!',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        reverse: true,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message.senderId == _myUserId;
                          return MessageBubble(
                            message: message,
                            isMe: isMe,
                            showSenderName: widget.chat.type != 'private' && !isMe,
                            onLongPress: () => _showMessageOptions(message),
                          );
                        },
                      ),
          ),
          
          // Панель эмодзи/стикеров/GIF
          if (_showEmojiPanel || _showStickerPanel || _showGifPanel)
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: _showEmojiPanel
                  ? _buildEmojiPanel()
                  : _showStickerPanel
                      ? StickerPicker(
                          onStickerSelected: (sticker, packId) {
                            _sendSticker(sticker, packId);
                            setState(() {
                              _showStickerPanel = false;
                            });
                          },
                        )
                      : GiphyPicker(
                          onGifSelected: (gif) {
                            _sendGif(gif);
                            setState(() {
                              _showGifPanel = false;
                            });
                          },
                        ),
            ),
          
          // Поле ввода
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
                // Кнопка эмодзи/стикеров/GIF
                PopupMenuButton<String>(
                  icon: const Icon(Icons.add_circle_outline),
                  onSelected: (value) {
                    setState(() {
                      _showEmojiPanel = value == 'emoji';
                      _showStickerPanel = value == 'sticker';
                      _showGifPanel = value == 'gif';
                    });
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'emoji',
                      child: Row(
                        children: [
                          Icon(Icons.emoji_emotions),
                          SizedBox(width: 12),
                          Text('Эмодзи'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'sticker',
                      child: Row(
                        children: [
                          Icon(Icons.sticky_note_2),
                          SizedBox(width: 12),
                          Text('Стикеры'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'gif',
                      child: Row(
                        children: [
                          Icon(Icons.gif_box),
                          SizedBox(width: 12),
                          Text('GIF'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: _onTypingChanged,
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
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Кнопка отправки
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _send,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPanel() {
    final emojis = [
      '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂',
      '🙂', '🙃', '😉', '😊', '😇', '', '😍', '🤩',
      '😘', '😗', '😚', '😙', '', '😋', '😛', '😜',
      '🤪', '😝', '🤑', '', '🤭', '', '🤔', '🤐',
      '🤨', '😐', '😑', '😶', '😏', '😒', '🙄', '😬',
      '🤥', '😌', '😔', '😪', '🤤', '😴', '😷', '🤒',
      '🤕', '🤢', '', '🤧', '🥵', '🥶', '🥴', '',
      '🤯', '', '🥳', '🥸', '😎', '🤓', '🧐', '😕',
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
      '💯', '💢', '', '💫', '💦', '', '🕳️', '💣',
      '👍', '', '👊', '✊', '🤛', '🤜', '👏', '🙌',
      '👐', '🤲', '', '🙏', '✌️', '🤞', '🤟', '🤘',
    ];
    
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _controller.text += emojis[index];
              _showEmojiPanel = false;
            });
          },
          child: Center(
            child: Text(
              emojis[index],
              style: const TextStyle(fontSize: 24),
            ),
          ),
        );
      },
    );
  }
}