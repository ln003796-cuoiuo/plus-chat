// ============================================
// ДРУЗЬЯ
// ============================================

/// Получить список друзей
static Future<List<Map<String, dynamic>>> getFriends() async {
  final res = await _request('GET', '/friends/list');
  if (res['success'] == true && res['friends'] != null) {
    return (res['friends'] as List).map((f) => f as Map<String, dynamic>).toList();
  }
  return [];
}

/// Получить запросы в друзья
static Future<Map<String, dynamic>> getFriendRequests() async {
  final res = await _request('GET', '/friends/requests?type=all');
  if (res['success'] == true) {
    return res;
  }
  return {'incoming': [], 'outgoing': []};
}

/// Получить контакты
static Future<List<Map<String, dynamic>>> getContacts() async {
  final res = await _request('GET', '/friends/contacts/list');
  if (res['success'] == true && res['contacts'] != null) {
    return (res['contacts'] as List).map((c) => c as Map<String, dynamic>).toList();
  }
  return [];
}

/// Отправить запрос в друзья
static Future<Map<String, dynamic>> sendFriendRequest(String userId) {
  return _request('POST', '/friends/request', body: {'user_id': userId});
}

/// Принять запрос в друзья
static Future<Map<String, dynamic>> acceptFriendRequest(String requestId) {
  return _request('POST', '/friends/accept', body: {'request_id': requestId});
}

/// Отклонить запрос в друзья
static Future<Map<String, dynamic>> rejectFriendRequest(String requestId) {
  return _request('POST', '/friends/reject', body: {'request_id': requestId});
}

/// Удалить из друзей
static Future<Map<String, dynamic>> removeFriend(String userId) {
  return _request('POST', '/friends/remove', body: {'user_id': userId});
}

/// Статус дружбы
static Future<Map<String, dynamic>> getFriendStatus(String userId) async {
  final res = await _request('GET', '/friends/status?user_id=$userId');
  if (res['success'] == true) return res;
  return {'friendship_status': 'none'};
}

/// Счётчики друзей
static Future<Map<String, dynamic>> getFriendsCount() async {
  final res = await _request('GET', '/friends/count');
  if (res['success'] == true) return res;
  return {'friends': 0, 'incoming_requests': 0, 'outgoing_requests': 0, 'contacts': 0};
}

// ============================================
// ЧАТЫ — дополнительные методы
// ============================================

/// Получить архивные чаты
static Future<List<Chat>> getArchivedChats() async {
  final res = await _request('GET', '/chats/list?archived=1');
  if (res['success'] == true && res['chats'] != null) {
    return (res['chats'] as List)
        .map((c) => Chat.fromJson(c as Map<String, dynamic>))
        .toList();
  }
  return [];
}

/// Заглушить чат
static Future<Map<String, dynamic>> muteChat(String chatId) {
  return _request('POST', '/chats/actions/mute', body: {'chat_id': chatId});
}

/// Включить звук
static Future<Map<String, dynamic>> unmuteChat(String chatId) {
  return _request('POST', '/chats/actions/unmute', body: {'chat_id': chatId});
}

/// Добавить в избранное
static Future<Map<String, dynamic>> favoriteChat(String chatId) {
  return _request('POST', '/chats/actions/favorite', body: {'chat_id': chatId});
}

/// Убрать из избранного
static Future<Map<String, dynamic>> unfavoriteChat(String chatId) {
  return _request('POST', '/chats/actions/unfavorite', body: {'chat_id': chatId});
}

/// Архивировать чат
static Future<Map<String, dynamic>> archiveChat(String chatId) {
  return _request('POST', '/chats/actions/archive', body: {'chat_id': chatId});
}

/// Разархивировать
static Future<Map<String, dynamic>> unarchiveChat(String chatId) {
  return _request('POST', '/chats/actions/unarchive', body: {'chat_id': chatId});
}

// ============================================
// GIF (GIPHY)
// ============================================

/// Получить трендовые GIF
static Future<List<Map<String, dynamic>>> getTrendingGifs({int limit = 25}) async {
  final res = await _request('GET', '/gifs/trending?limit=$limit');
  if (res['success'] == true && res['gifs'] != null) {
    return (res['gifs'] as List).map((g) => g as Map<String, dynamic>).toList();
  }
  return [];
}

/// Поиск GIF
static Future<List<Map<String, dynamic>>> searchGifs(String query, {int limit = 25}) async {
  final res = await _request('GET', '/gifs/search?q=${Uri.encodeComponent(query)}&limit=$limit');
  if (res['success'] == true && res['gifs'] != null) {
    return (res['gifs'] as List).map((g) => g as Map<String, dynamic>).toList();
  }
  return [];
}

/// Отправить GIF в чат
static Future<Map<String, dynamic>> sendGif({
  required String chatId,
  required String gifId,
  required String gifUrl,
  int? width,
  int? height,
  String? replyTo,
}) {
  final body = <String, dynamic>{
    'chat_id': chatId,
    'gif_id': gifId,
    'gif_url': gifUrl,
    'width': width ?? 0,
    'height': height ?? 0,
  };
  if (replyTo != null) body['reply_to'] = replyTo;
  return _request('POST', '/messages/send-gif', body: body);
}

// ============================================
// СТИКЕРЫ
// ============================================

/// Получить список доступных паков
static Future<List<Map<String, dynamic>>> getStickerPacks() async {
  final res = await _request('GET', '/stickers/packs');
  if (res['success'] == true && res['packs'] != null) {
    return (res['packs'] as List).map((p) => p as Map<String, dynamic>).toList();
  }
  return [];
}

/// Получить содержимое пака
static Future<Map<String, dynamic>> getStickerPack(int packId) async {
  final res = await _request('GET', '/stickers/pack?id=$packId');
  if (res['success'] == true) return res;
  return {'pack': null, 'stickers': []};
}

/// Получить установленные паки
static Future<List<Map<String, dynamic>>> getInstalledPacks() async {
  final res = await _request('GET', '/stickers/installed');
  if (res['success'] == true && res['packs'] != null) {
    return (res['packs'] as List).map((p) => p as Map<String, dynamic>).toList();
  }
  return [];
}

/// Установить пак
static Future<Map<String, dynamic>> installPack(int packId) {
  return _request('POST', '/stickers/install', body: {'pack_id': packId});
}

/// Удалить пак
static Future<Map<String, dynamic>> uninstallPack(int packId) {
  return _request('POST', '/stickers/uninstall', body: {'pack_id': packId});
}

/// Отправить стикер
static Future<Map<String, dynamic>> sendSticker({
  required String chatId,
  required String stickerUrl,
  String? stickerId,
  String? emoji,
  String? replyTo,
}) {
  final body = <String, dynamic>{
    'chat_id': chatId,
    'sticker_url': stickerUrl,
  };
  if (stickerId != null) body['sticker_id'] = stickerId;
  if (emoji != null) body['emoji'] = emoji;
  if (replyTo != null) body['reply_to'] = replyTo;
  return _request('POST', '/messages/send-sticker', body: body);
}

// ============================================
// ПОДАРКИ
// ============================================

/// Получить список подарков
static Future<List<Map<String, dynamic>>> getGifts({String? category, String sort = 'popular'}) async {
  var url = '/gifts/list?sort=$sort';
  if (category != null) url += '&category=$category';
  final res = await _request('GET', url);
  if (res['success'] == true && res['gifts'] != null) {
    return (res['gifts'] as List).map((g) => g as Map<String, dynamic>).toList();
  }
  return [];
}

/// Получить категории подарков
static Future<List<Map<String, dynamic>>> getGiftCategories() async {
  final res = await _request('GET', '/gifts/categories');
  if (res['success'] == true && res['categories'] != null) {
    return (res['categories'] as List).map((c) => c as Map<String, dynamic>).toList();
  }
  return [];
}

/// Отправить подарок
static Future<Map<String, dynamic>> sendGift({
  required int giftId,
  required String receiverId,
  String? message,
  bool isAnonymous = false,
}) {
  final body = <String, dynamic>{
    'gift_id': giftId,
    'receiver_id': receiverId,
    'is_anonymous': isAnonymous,
  };
  if (message != null && message.isNotEmpty) body['message'] = message;
  return _request('POST', '/gifts/send', body: body);
}

/// Мои полученные подарки
static Future<List<Map<String, dynamic>>> getReceivedGifts() async {
  final res = await _request('GET', '/gifts/received');
  if (res['success'] == true && res['gifts'] != null) {
    return (res['gifts'] as List).map((g) => g as Map<String, dynamic>).toList();
  }
  return [];
}

/// Мои отправленные подарки
static Future<List<Map<String, dynamic>>> getSentGifts() async {
  final res = await _request('GET', '/gifts/sent');
  if (res['success'] == true && res['gifts'] != null) {
    return (res['gifts'] as List).map((g) => g as Map<String, dynamic>).toList();
  }
  return [];
}