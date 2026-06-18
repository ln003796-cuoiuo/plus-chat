Future<void> _send() async {
  final text = _controller.text.trim();
  if (text.isEmpty) return;
  
  _controller.clear();
  setState(() {
    _sending = true;
    _replyTo = null;
  });

  try {
    final message = await ApiService.sendMessage(
      chatId: widget.chat.id,
      content: text,
      replyTo: _replyTo?.id.toString(),  // ← .toString() обязательно!
    );
    
    if (message != null) {
      await _loadMessages(silent: true);
      _scrollToBottom();
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка отправки: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _sending = false);
  }
}