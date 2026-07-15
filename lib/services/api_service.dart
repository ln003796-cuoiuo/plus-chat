// lib/services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/user.dart';
import '../models/chat.dart';
import '../models/message.dart';

class ApiService {
  static const String baseUrl = 'https://xn--80avljg2a1c.xn--p1ai'; // IDN domain

  static Future<Map<String, dynamic>> _request(String method,
      String endpoint, {
        Map<String, dynamic>? body,
        bool auth = true,
      }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (auth) {
      final token = await AuthService.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        throw Exception('No access token available');
      }
    }

    http.Response response;
    if (body != null) {
      response = await http.post(url, headers: headers, body: jsonEncode(body));
    } else {
      if (method.toUpperCase() == 'GET') {
        response = await http.get(url, headers: headers);
      } else if (method.toUpperCase() == 'POST') {
        response = await http.post(url, headers: headers); // Bodyless POST
      } else {
        throw Exception('Unsupported method without body: $method');
      }
    }

    final responseBody = response.body;
    final responseJson = jsonDecode(responseBody);

    if (response.statusCode == 401) {
      // Token might be expired, try to refresh
      final refreshed = await AuthService.refreshToken();
      if (refreshed) {
        // Retry the request with the new token
        return _request(method, endpoint, body: body, auth: auth);
      } else {
        // Refresh failed, logout user
        await AuthService.logout();
        throw Exception('Authentication failed and refresh token invalid.');
      }
    }

    if (response.statusCode >= 400) {
      throw Exception(responseJson['error'] ?? 'Request failed with status ${response.statusCode}');
    }

    return responseJson;
  }

  // --- AUTH ---

  static Future<Map<String, dynamic>> login(String emailOrPhone) async {
    return _request('POST', '/auth/login', body: {'email_or_phone': emailOrPhone}, auth: false);
  }

  static Future<Map<String, dynamic>> verifyCode(String emailOrPhone, String code) async {
    return _request('POST', '/auth/verify-code', body: {'email_or_phone': emailOrPhone, 'code': code}, auth: false);
  }

  static Future<Map<String, dynamic>> registerStep1(String email) async {
    return _request('POST', '/auth/register-step1', body: {'email': email}, auth: false);
  }

  static Future<Map<String, dynamic>> registerStep2(String email, String code) async {
    return _request('POST', '/auth/register-step2', body: {'email': email, 'code': code}, auth: false);
  }

  static Future<Map<String, dynamic>> registerStep3(String firstName, String lastName) async {
    return _request('POST', '/auth/register-step3', body: {'first_name': firstName, 'last_name': lastName}, auth: true);
  }

  static Future<Map<String, dynamic>> registerStep4(String username) async {
    return _request('POST', '/auth/register-step4', body: {'username': username}, auth: true);
  }

  static Future<Map<String, dynamic>> registerStep5(String password) async {
    return _request('POST', '/auth/register-step5', body: {'password': password}, auth: true);
  }

  static Future<Map<String, dynamic>> setupProfile(String firstName, String lastName, String username, String bio, String? avatarUrl) async {
    return _request('POST', '/users/setup-profile', body: {
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'bio': bio,
      'avatar_url': avatarUrl,
    }, auth: true);
  }

  static Future<void> logout() async {
    try {
      await _request('POST', '/auth/logout', auth: true);
    } catch (e) {
      debugPrint('Logout error (ignored): $e');
    }
    await AuthService.logout();
  }

  static Future<Map<String, dynamic>> refreshToken() async {
    final refreshToken = await AuthService.getRefreshToken();
    if (refreshToken == null) {
      throw Exception('No refresh token available');
    }
    final res = await _request('POST', '/auth/refresh', body: {'refresh_token': refreshToken}, auth: false);
    await AuthService.saveTokens(res['access_token'], res['refresh_token']);
    return res;
  }

  // --- USERS ---

  static Future<User> getMe() async {
    final res = await _request('GET', '/users/me');
    return User.fromJson(res['user']);
  }

  static Future<Map<String, dynamic>> getUserById(int userId) async {
    final res = await _request('GET', '/users/$userId');
    return res;
  }

  static Future<Map<String, dynamic>> searchUsers(String query) async {
    final res = await _request('GET', '/users/search?q=$query');
    return res;
  }

  static Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> profileData) async {
    return _request('POST', '/users/update-profile', body: profileData);
  }

  static Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    return _request('POST', '/users/change-password', body: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  static Future<Map<String, dynamic>> uploadAvatar(String base64Image) async {
    return _request('POST', '/users/upload-avatar', body: {'image': base64Image});
  }

  static Future<Map<String, dynamic>> setCustomStatus(String text, String emoji) async {
    return _request('POST', '/users/set-custom-status', body: {'text': text, 'emoji': emoji});
  }

  static Future<Map<String, dynamic>> removeCustomStatus() async {
    return _request('POST', '/users/remove-custom-status');
  }

  static Future<Map<String, dynamic>> getOnlineStatus(int userId) async {
    final res = await _request('GET', '/users/$userId/online-status');
    return res;
  }

  static Future<Map<String, dynamic>> getTypingStatus(int userId, String chatId) async {
    final res = await _request('GET', '/users/$userId/typing-status?chat_id=$chatId');
    return res;
  }

  static Future<Map<String, dynamic>> getUserGifts(int userId) async {
    final res = await _request('GET', '/users/$userId/gifts');
    return res;
  }

  static Future<Map<String, dynamic>> getStickers() async {
    final res = await _request('GET', '/stickers');
    return res;
  }

  static Future<Map<String, dynamic>> getInstalledStickerPacks() async {
    final res = await _request('GET', '/stickers/installed');
    return res;
  }

  static Future<Map<String, dynamic>> installStickerPack(int packId) async {
    return _request('POST', '/stickers/install-pack', body: {'pack_id': packId});
  }

  static Future<Map<String, dynamic>> uninstallStickerPack(int packId) async {
    return _request('POST', '/stickers/uninstall-pack', body: {'pack_id': packId});
  }

  static Future<Map<String, dynamic>> getGifs({String? query, int offset = 0, int limit = 24}) async {
    String endpoint = '/gifs';
    if (query != null && query.isNotEmpty) {
      endpoint += '?q=$query&offset=$offset&limit=$limit';
    } else {
      endpoint += '?offset=$offset&limit=$limit';
    }
    final res = await _request('GET', endpoint);
    return res;
  }

  // --- CHATS ---

  static Future<Map<String, dynamic>> getChats() async {
    final res = await _request('GET', '/chats');
    return res;
  }

  static Future<Map<String, dynamic>> createPrivateChat(int userId) async {
    return _request('POST', '/chats/create-private', body: {'user_id': userId});
  }

  static Future<Map<String, dynamic>> createGroupChat(String title, String description, List<int> userIds) async {
    return _request('POST', '/chats/create-group', body: {
      'title': title,
      'description': description,
      'user_ids': userIds,
    });
  }

  static Future<Map<String, dynamic>> createChannelChat(String title, String description) async {
    return _request('POST', '/chats/create-channel', body: {
      'title': title,
      'description': description,
    });
  }

  static Future<Map<String, dynamic>> getChatById(String chatId) async {
    final res = await _request('GET', '/chats/$chatId');
    return res;
  }

  static Future<Map<String, dynamic>> updateChat(String chatId, Map<String, dynamic> data) async {
    return _request('POST', '/chats/$chatId/update', body: data);
  }

  static Future<Map<String, dynamic>> archiveChat(String chatId) async {
    return _request('POST', '/chats/$chatId/archive');
  }

  static Future<Map<String, dynamic>> unarchiveChat(String chatId) async {
    return _request('POST', '/chats/$chatId/unarchive');
  }

  static Future<Map<String, dynamic>> toggleFavorite(String chatId) async {
    return _request('POST', '/chats/$chatId/toggle-favorite');
  }

  static Future<Map<String, dynamic>> muteChat(String chatId, int? untilTimestamp) async {
    return _request('POST', '/chats/$chatId/mute', body: {'until': untilTimestamp});
  }

  static Future<Map<String, dynamic>> unmuteChat(String chatId) async {
    return _request('POST', '/chats/$chatId/unmute');
  }

  static Future<Map<String, dynamic>> leaveChat(String chatId) async {
    return _request('POST', '/chats/$chatId/leave');
  }

  static Future<Map<String, dynamic>> deleteChat(String chatId) async {
    return _request('POST', '/chats/$chatId/delete');
  }

  static Future<Map<String, dynamic>> getChatMembers(String chatId) async {
    final res = await _request('GET', '/chats/$chatId/members');
    return res;
  }

  static Future<Map<String, dynamic>> addMemberToChat(String chatId, int userId) async {
    return _request('POST', '/chats/$chatId/add-member', body: {'user_id': userId});
  }

  static Future<Map<String, dynamic>> removeMemberFromChat(String chatId, int userId) async {
    return _request('POST', '/chats/$chatId/remove-member', body: {'user_id': userId});
  }

  static Future<Map<String, dynamic>> promoteMember(String chatId, int userId) async {
    return _request('POST', '/chats/$chatId/promote-member', body: {'user_id': userId});
  }

  static Future<Map<String, dynamic>> demoteMember(String chatId, int userId) async {
    return _request('POST', '/chats/$chatId/demote-member', body: {'user_id': userId});
  }

  static Future<Map<String, dynamic>> pinMessage(String chatId, int messageId) async {
    return _request('POST', '/chats/$chatId/pin-message', body: {'message_id': messageId});
  }

  static Future<Map<String, dynamic>> unpinMessage(String chatId, int messageId) async {
    return _request('POST', '/chats/$chatId/unpin-message', body: {'message_id': messageId});
  }

  // --- MESSAGES ---

  static Future<Map<String, dynamic>> getMessages(String chatId, {int limit = 50, int? offset, bool older = false}) async {
    String queryString = '?limit=$limit';
    if (offset != null) queryString += '&offset=$offset';
    if (older) queryString += '&older=true';
    final res = await _request('GET', '/chats/$chatId/messages$queryString');
    return res;
  }

  static Future<Map<String, dynamic>> sendMessage(String chatId, String type, String content,
      {List<String>? attachments, int? replyToMessageId, int? forwardFromMessageId}) async {
    return _request('POST', '/messages/send', body: {
      'chat_id': chatId,
      'type': type,
      'content': content,
      if (attachments != null) 'attachments': attachments,
      if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
      if (forwardFromMessageId != null) 'forward_from_message_id': forwardFromMessageId,
    });
  }

  static Future<Map<String, dynamic>> sendVoiceMessage(String chatId, String audioBase64, int duration) async {
    return _request('POST', '/messages/send-voice', body: {
      'chat_id': chatId,
      'audio': audioBase64,
      'duration': duration,
    });
  }

  static Future<Map<String, dynamic>> sendMediaMessage(String chatId, String type, String mediaBase64, String? thumbnailBase64, String? fileName, int? fileSize) async {
    return _request('POST', '/messages/send-media', body: {
      'chat_id': chatId,
      'type': type,
      'media': mediaBase64,
      if (thumbnailBase64 != null) 'thumbnail': thumbnailBase64,
      if (fileName != null) 'filename': fileName,
      if (fileSize != null) 'filesize': fileSize,
    });
  }

  static Future<Map<String, dynamic>> sendVideoMessage(String chatId, String videoBase64, String? thumbnailBase64, int duration, String? fileName, int? fileSize) async {
    return _request('POST', '/messages/send-video', body: {
      'chat_id': chatId,
      'video': videoBase64,
      if (thumbnailBase64 != null) 'thumbnail': thumbnailBase64,
      'duration': duration,
      if (fileName != null) 'filename': fileName,
      if (fileSize != null) 'filesize': fileSize,
    });
  }

  static Future<Map<String, dynamic>> sendFileMessage(String chatId, String fileBase64, String fileName, int fileSize) async {
    return _request('POST', '/messages/send-file', body: {
      'chat_id': chatId,
      'file': fileBase64,
      'filename': fileName,
      'filesize': fileSize,
    });
  }

  static Future<Map<String, dynamic>> sendLocationMessage(String chatId, double latitude, double longitude) async {
    return _request('POST', '/messages/send-location', body: {
      'chat_id': chatId,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  static Future<Map<String, dynamic>> sendContactMessage(String chatId, int contactUserId) async {
    return _request('POST', '/messages/send-contact', body: {
      'chat_id': chatId,
      'contact_user_id': contactUserId,
    });
  }

  static Future<Map<String, dynamic>> sendStickerMessage(String chatId, int stickerId, int packId) async {
    return _request('POST', '/messages/send-sticker', body: {
      'chat_id': chatId,
      'sticker_id': stickerId,
      'pack_id': packId,
    });
  }

  static Future<Map<String, dynamic>> sendGifMessage(String chatId, String gifUrl, String gifId) async {
    return _request('POST', '/messages/send-gif', body: {
      'chat_id': chatId,
      'gif_url': gifUrl,
      'gif_id': gifId,
    });
  }

  static Future<Map<String, dynamic>> sendGiftMessage(String chatId, int giftId) async {
    return _request('POST', '/messages/send-gift', body: {
      'chat_id': chatId,
      'gift_id': giftId,
    });
  }

  static Future<Map<String, dynamic>> editMessage(String chatId, int messageId, String newContent) async {
    return _request('POST', '/messages/$messageId/edit', body: {
      'chat_id': chatId,
      'content': newContent,
    });
  }

  static Future<Map<String, dynamic>> deleteMessage(String chatId, int messageId, bool forEveryone) async {
    return _request('POST', '/messages/$messageId/delete', body: {
      'chat_id': chatId,
      'for_everyone': forEveryone,
    });
  }

  static Future<Map<String, dynamic>> forwardMessages(String targetChatId, List<Map<String, dynamic>> messages) async {
    return _request('POST', '/messages/forward', body: {
      'target_chat_id': targetChatId,
      'messages': messages,
    });
  }

  static Future<Map<String, dynamic>> addReaction(String chatId, int messageId, String emoji) async {
    return _request('POST', '/messages/$messageId/reactions/add', body: {
      'chat_id': chatId,
      'emoji': emoji,
    });
  }

  static Future<Map<String, dynamic>> removeReaction(String chatId, int messageId, String emoji) async {
    return _request('POST', '/messages/$messageId/reactions/remove', body: {
      'chat_id': chatId,
      'emoji': emoji,
    });
  }

  static Future<Map<String, dynamic>> markAsRead(String chatId, int upToMessageId) async {
    return _request('POST', '/chats/$chatId/mark-as-read', body: {'up_to_message_id': upToMessageId});
  }

  // --- FRIENDS ---

  static Future<Map<String, dynamic>> getFriends() async {
    final res = await _request('GET', '/friends');
    return res;
  }

  static Future<Map<String, dynamic>> getFriendRequests() async {
    final res = await _request('GET', '/friends/requests');
    return res;
  }

  static Future<Map<String, dynamic>> sendFriendRequest(int userId) async {
    return _request('POST', '/friends/request', body: {'user_id': userId});
  }

  static Future<Map<String, dynamic>> acceptFriendRequest(int userId) async {
    return _request('POST', '/friends/accept', body: {'user_id': userId});
  }

  static Future<Map<String, dynamic>> declineFriendRequest(int userId) async {
    return _request('POST', '/friends/decline', body: {'user_id': userId});
  }

  static Future<Map<String, dynamic>> removeFriend(int userId) async {
    return _request('POST', '/friends/remove', body: {'user_id': userId});
  }

  // --- GIFS ---

  static Future<Map<String, dynamic>> getTrendingGifs({int offset = 0, int limit = 24}) async {
    final res = await _request('GET', '/gifs/trending?offset=$offset&limit=$limit');
    return res;
  }

  // --- GIF SEARCH ---

  static Future<Map<String, dynamic>> searchGifs(String query, {int offset = 0, int limit = 24}) async {
    final res = await _request('GET', '/gifs/search?q=$query&offset=$offset&limit=$limit');
    return res;
  }

  // --- GIF CATEGORIES ---

  static Future<Map<String, dynamic>> getGifCategories() async {
    final res = await _request('GET', '/gifs/categories');
    return res;
  }

  // --- GIF BY CATEGORY ---

  static Future<Map<String, dynamic>> getGifsByCategory(String categoryId, {int offset = 0, int limit = 24}) async {
    final res = await _request('GET', '/gifs/category/$categoryId?offset=$offset&limit=$limit');
    return res;
  }

  // --- GIF TRENDING SEARCH TERMS ---

  static Future<Map<String, dynamic>> getTrendingSearchTerms() async {
    final res = await _request('GET', '/gifs/trending-searches');
    return res;
  }

  // --- GIF TRANSLATE ---

  static Future<Map<String, dynamic>> translateGifTerm(String term) async {
    final res = await _request('GET', '/gifs/translate-term?term=$term');
    return res;
  }

  // --- GIF RANDOM ---

  static Future<Map<String, dynamic>> getRandomGif({String? tag}) async {
    String endpoint = '/gifs/random';
    if (tag != null && tag.isNotEmpty) {
      endpoint += '?tag=$tag';
    }
    final res = await _request('GET', endpoint);
    return res;
  }

  // --- GIF UPLOAD ---

  static Future<Map<String, dynamic>> uploadGif(String gifBase64, String title, String tags) async {
    return _request('POST', '/gifs/upload', body: {
      'gif': gifBase64,
      'title': title,
      'tags': tags,
    });
  }

  // --- GIF DELETE ---

  static Future<Map<String, dynamic>> deleteGif(String gifId) async {
    return _request('POST', '/gifs/$gifId/delete');
  }

  // --- GIF FAVORITE ---

  static Future<Map<String, dynamic>> toggleGifFavorite(String gifId) async {
    return _request('POST', '/gifs/$gifId/toggle-favorite');
  }

  // --- GIF REPORT ---

  static Future<Map<String, dynamic>> reportGif(String gifId, String reason) async {
    return _request('POST', '/gifs/$gifId/report', body: {'reason': reason});
  }

  // --- GIF SHARE ---

  static Future<Map<String, dynamic>> shareGif(String gifId) async {
    return _request('POST', '/gifs/$gifId/share');
  }

  // --- GIF GET BY ID ---

  static Future<Map<String, dynamic>> getGifById(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId');
    return res;
  }

  // --- GIF GET USER GIFS ---

  static Future<Map<String, dynamic>> getUserGifs(int userId) async {
    final res = await _request('GET', '/gifs/user/$userId');
    return res;
  }

  // --- GIF GET FAVORITE GIFS ---

  static Future<Map<String, dynamic>> getFavoriteGifs() async {
    final res = await _request('GET', '/gifs/favorites');
    return res;
  }

  // --- GIF GET RECENT GIFS ---

  static Future<Map<String, dynamic>> getRecentGifs({int limit = 24}) async {
    final res = await _request('GET', '/gifs/recent?limit=$limit');
    return res;
  }

  // --- GIF GET TRENDING GIFS BY TAG ---

  static Future<Map<String, dynamic>> getTrendingGifsByTag(String tag, {int offset = 0, int limit = 24}) async {
    final res = await _request('GET', '/gifs/trending-by-tag?tag=$tag&offset=$offset&limit=$limit');
    return res;
  }

  // --- GIF GET STICKER PACKS FOR GIF ---

  static Future<Map<String, dynamic>> getStickerPacksForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/sticker-packs');
    return res;
  }

  // --- GIF GET EMOJI FOR GIF ---

  static Future<Map<String, dynamic>> getEmojiForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/emoji');
    return res;
  }

  // --- GIF GET COLOR PALETTE ---

  static Future<Map<String, dynamic>> getColorPaletteForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/color-palette');
    return res;
  }

  // --- GIF GET PREVIEW IMAGE ---

  static Future<Map<String, dynamic>> getPreviewImageForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/preview-image');
    return res;
  }

  // --- GIF GET HD VIDEO ---

  static Future<Map<String, dynamic>> getHdVideoForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/hd-video');
    return res;
  }

  // --- GIF GET MP4 ---

  static Future<Map<String, dynamic>> getMp4ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/mp4');
    return res;
  }

  // --- GIF GET WEBM ---

  static Future<Map<String, dynamic>> getWebmForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/webm');
    return res;
  }

  // --- GIF GET SIZE ---

  static Future<Map<String, dynamic>> getSizeForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/size');
    return res;
  }

  // --- GIF GET DURATION ---

  static Future<Map<String, dynamic>> getDurationForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/duration');
    return res;
  }

  // --- GIF GET FRAMES ---

  static Future<Map<String, dynamic>> getFramesForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/frames');
    return res;
  }

  // --- GIF GET LOOP COUNT ---

  static Future<Map<String, dynamic>> getLoopCountForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/loop-count');
    return res;
  }

  // --- GIF GET OPTIMIZED VERSION ---

  static Future<Map<String, dynamic>> getOptimizedVersionForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/optimized-version');
    return res;
  }

  // --- GIF GET COMPRESSED VERSION ---

  static Future<Map<String, dynamic>> getCompressedVersionForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/compressed-version');
    return res;
  }

  // --- GIF GET THUMBNAIL ---

  static Future<Map<String, dynamic>> getThumbnailForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/thumbnail');
    return res;
  }

  // --- GIF GET SMALL THUMBNAIL ---

  static Future<Map<String, dynamic>> getSmallThumbnailForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/small-thumbnail');
    return res;
  }

  // --- GIF GET ORIGINAL ---

  static Future<Map<String, dynamic>> getOriginalForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/original');
    return res;
  }

  // --- GIF GET ANIMATED WEBP ---

  static Future<Map<String, dynamic>> getAnimatedWebpForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-webp');
    return res;
  }

  // --- GIF GET ANIMATED AVIF ---

  static Future<Map<String, dynamic>> getAnimatedAvifForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-avif');
    return res;
  }

  // --- GIF GET ANIMATED PNG ---

  static Future<Map<String, dynamic>> getAnimatedPngForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-png');
    return res;
  }

  // --- GIF GET ANIMATED JPG ---

  static Future<Map<String, dynamic>> getAnimatedJpgForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-jpg');
    return res;
  }

  // --- GIF GET ANIMATED BMP ---

  static Future<Map<String, dynamic>> getAnimatedBmpForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-bmp');
    return res;
  }

  // --- GIF GET ANIMATED TIFF ---

  static Future<Map<String, dynamic>> getAnimatedTiffForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-tiff');
    return res;
  }

  // --- GIF GET ANIMATED PSD ---

  static Future<Map<String, dynamic>> getAnimatedPsdForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-psd');
    return res;
  }

  // --- GIF GET ANIMATED AI ---

  static Future<Map<String, dynamic>> getAnimatedAiForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-ai');
    return res;
  }

  // --- GIF GET ANIMATED EPS ---

  static Future<Map<String, dynamic>> getAnimatedEpsForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-eps');
    return res;
  }

  // --- GIF GET ANIMATED PDF ---

  static Future<Map<String, dynamic>> getAnimatedPdfForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-pdf');
    return res;
  }

  // --- GIF GET ANIMATED SVG ---

  static Future<Map<String, dynamic>> getAnimatedSvgForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-svg');
    return res;
  }

  // --- GIF GET ANIMATED HTML ---

  static Future<Map<String, dynamic>> getAnimatedHtmlForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-html');
    return res;
  }

  // --- GIF GET ANIMATED CSS ---

  static Future<Map<String, dynamic>> getAnimatedCssForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-css');
    return res;
  }

  // --- GIF GET ANIMATED JS ---

  static Future<Map<String, dynamic>> getAnimatedJsForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-js');
    return res;
  }

  // --- GIF GET ANIMATED TS ---

  static Future<Map<String, dynamic>> getAnimatedTsForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-ts');
    return res;
  }

  // --- GIF GET ANIMATED DART ---

  static Future<Map<String, dynamic>> getAnimatedDartForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-dart');
    return res;
  }

  // --- GIF GET ANIMATED FLUTTER ---

  static Future<Map<String, dynamic>> getAnimatedFlutterForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-flutter');
    return res;
  }

  // --- GIF GET ANIMATED REACT ---

  static Future<Map<String, dynamic>> getAnimatedReactForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-react');
    return res;
  }

  // --- GIF GET ANIMATED VUE ---

  static Future<Map<String, dynamic>> getAnimatedVueForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-vue');
    return res;
  }

  // --- GIF GET ANIMATED ANGULAR ---

  static Future<Map<String, dynamic>> getAnimatedAngularForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-angular');
    return res;
  }

  // --- GIF GET ANIMATED SVELTE ---

  static Future<Map<String, dynamic>> getAnimatedSvelteForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-svelte');
    return res;
  }

  // --- GIF GET ANIMATED NEXT ---

  static Future<Map<String, dynamic>> getAnimatedNextForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-next');
    return res;
  }

  // --- GIF GET ANIMATED NUXT ---

  static Future<Map<String, dynamic>> getAnimatedNuxtForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-nuxt');
    return res;
  }

  // --- GIF GET ANIMATED GATSBY ---

  static Future<Map<String, dynamic>> getAnimatedGatsbyForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-gatsby');
    return res;
  }

  // --- GIF GET ANIMATED GRIDSOME ---

  static Future<Map<String, dynamic>> getAnimatedGridsomeForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-gridsome');
    return res;
  }

  // --- GIF GET ANIMATED HUGO ---

  static Future<Map<String, dynamic>> getAnimatedHugoForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-hugo');
    return res;
  }

  // --- GIF GET ANIMATED JEKYLL ---

  static Future<Map<String, dynamic>> getAnimatedJekyllForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-jekyll');
    return res;
  }

  // --- GIF GET ANIMATED WORDPRESS ---

  static Future<Map<String, dynamic>> getAnimatedWordpressForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-wordpress');
    return res;
  }

  // --- GIF GET ANIMATED DRUPAL ---

  static Future<Map<String, dynamic>> getAnimatedDrupalForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-drupal');
    return res;
  }

  // --- GIF GET ANIMATED JOOMLA ---

  static Future<Map<String, dynamic>> getAnimatedJoomlaForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-joomla');
    return res;
  }

  // --- GIF GET ANIMATED MAGENTO ---

  static Future<Map<String, dynamic>> getAnimatedMagentoForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-magento');
    return res;
  }

  // --- GIF GET ANIMATED SHOPIFY ---

  static Future<Map<String, dynamic>> getAnimatedShopifyForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-shopify');
    return res;
  }

  // --- GIF GET ANIMATED WOOCOMMERCE ---

  static Future<Map<String, dynamic>> getAnimatedWoocommerceForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-woocommerce');
    return res;
  }

  // --- GIF GET ANIMATED PRESTASHOP ---

  static Future<Map<String, dynamic>> getAnimatedPrestashopForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-prestashop');
    return res;
  }

  // --- GIF GET ANIMATED BIGCOMMERCE ---

  static Future<Map<String, dynamic>> getAnimatedBigcommerceForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-bigcommerce');
    return res;
  }

  // --- GIF GET ANIMATED ECWID ---

  static Future<Map<String, dynamic>> getAnimatedEcwidForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-ecwid');
    return res;
  }

  // --- GIF GET ANIMATED SQUARESPACE ---

  static Future<Map<String, dynamic>> getAnimatedSquarespaceForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-squarespace');
    return res;
  }

  // --- GIF GET ANIMATED WEBFLOW ---

  static Future<Map<String, dynamic>> getAnimatedWebflowForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-webflow');
    return res;
  }

  // --- GIF GET ANIMATED FIGMA ---

  static Future<Map<String, dynamic>> getAnimatedFigmaForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-figma');
    return res;
  }

  // --- GIF GET ANIMATED SKETCH ---

  static Future<Map<String, dynamic>> getAnimatedSketchForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-sketch');
    return res;
  }

  // --- GIF GET ANIMATED ADOBE XD ---

  static Future<Map<String, dynamic>> getAnimatedAdobeXdForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-adobe-xd');
    return res;
  }

  // --- GIF GET ANIMATED PHOTOSHOP ---

  static Future<Map<String, dynamic>> getAnimatedPhotoshopForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-photoshop');
    return res;
  }

  // --- GIF GET ANIMATED ILLUSTRATOR ---

  static Future<Map<String, dynamic>> getAnimatedIllustratorForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-illustrator');
    return res;
  }

  // --- GIF GET ANIMATED AFTER EFFECTS ---

  static Future<Map<String, dynamic>> getAnimatedAfterEffectsForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-after-effects');
    return res;
  }

  // --- GIF GET ANIMATED PREMIERE PRO ---

  static Future<Map<String, dynamic>> getAnimatedPremiereProForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-premiere-pro');
    return res;
  }

  // --- GIF GET ANIMATED DAVINCI RESOLVE ---

  static Future<Map<String, dynamic>> getAnimatedDavinciResolveForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-davinci-resolve');
    return res;
  }

  // --- GIF GET ANIMATED FINAL CUT PRO ---

  static Future<Map<String, dynamic>> getAnimatedFinalCutProForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-final-cut-pro');
    return res;
  }

  // --- GIF GET ANIMATED IMOVIE ---

  static Future<Map<String, dynamic>> getAnimatedImovieForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-imovie');
    return res;
  }

  // --- GIF GET ANIMATED MOTION ---

  static Future<Map<String, dynamic>> getAnimatedMotionForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-motion');
    return res;
  }

  // --- GIF GET ANIMATED BLAND ---

  static Future<Map<String, dynamic>> getAnimatedBlandForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-bland');
    return res;
  }

  // --- GIF GET ANIMATED RUNWAY ML ---

  static Future<Map<String, dynamic>> getAnimatedRunwayMlForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-runway-ml');
    return res;
  }

  // --- GIF GET ANIMATED SYNTHESIA ---

  static Future<Map<String, dynamic>> getAnimatedSynthesiaForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-synthesia');
    return res;
  }

  // --- GIF GET ANIMATED PEECH ---

  static Future<Map<String, dynamic>> getAnimatedPeecForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-peec');
    return res;
  }

  // --- GIF GET ANIMATED LALA LAND ---

  static Future<Map<String, dynamic>> getAnimatedLalaLandForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-lala-land');
    return res;
  }

  // --- GIF GET ANIMATED BOHEMIAN RHAPSODY ---

  static Future<Map<String, dynamic>> getAnimatedBohemianRhapsodyForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-bohemian-rhapsody');
    return res;
  }

  // --- GIF GET ANIMATED WE WILL ROCK YOU ---

  static Future<Map<String, dynamic>> getAnimatedWeWillRockYouForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-we-will-rock-you');
    return res;
  }

  // --- GIF GET ANIMATED SOMEWHERE OVER THE RAINBOW ---

  static Future<Map<String, dynamic>> getAnimatedSomewhereOverTheRainbowForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-somewhere-over-the-rainbow');
    return res;
  }

  // --- GIF GET ANIMATED WHAT A WONDERFUL WORLD ---

  static Future<Map<String, dynamic>> getAnimatedWhatAWonderfulWorldForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-what-a-wonderful-world');
    return res;
  }

  // --- GIF GET ANIMATED MY WAY ---

  static Future<Map<String, dynamic>> getAnimatedMyWayForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-my-way');
    return res;
  }

  // --- GIF GET ANIMATED NEW YORK NEW YORK ---

  static Future<Map<String, dynamic>> getAnimatedNewYorkNewYorkForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-new-york-new-york');
    return res;
  }

  // --- GIF GET ANIMATED STRANGELOVE ---

  static Future<Map<String, dynamic>> getAnimatedStrangeloveForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-strangelove');
    return res;
  }

  // --- GIF GET ANIMATED DOCTOR ZHIVAGO ---

  static Future<Map<String, dynamic>> getAnimatedDoctorZhivagoForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-doctor-zhivago');
    return res;
  }

  // --- GIF GET ANIMATED THE UMBRELLAS OF CHERBOURG ---

  static Future<Map<String, dynamic>> getAnimatedTheUmbrellasOfCherbourgForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-umbrellas-of-cherbourg');
    return res;
  }

  // --- GIF GET ANIMATED THE RED BALLOON ---

  static Future<Map<String, dynamic>> getAnimatedTheRedBalloonForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-red-balloon');
    return res;
  }

  // --- GIF GET ANIMATED THE WILD PARROT ---

  static Future<Map<String, dynamic>> getAnimatedTheWildParrotForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-wild-parrot');
    return res;
  }

  // --- GIF GET ANIMATED THE LITTLE MERMAID ---

  static Future<Map<String, dynamic>> getAnimatedTheLittleMermaidForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-little-mermaid');
    return res;
  }

  // --- GIF GET ANIMATED THE LION KING ---

  static Future<Map<String, dynamic>> getAnimatedTheLionKingForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-lion-king');
    return res;
  }

  // --- GIF GET ANIMATED ALADDIN ---

  static Future<Map<String, dynamic>> getAnimatedAladdinForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-aladdin');
    return res;
  }

  // --- GIF GET ANIMATED BEAUTY AND THE BEAST ---

  static Future<Map<String, dynamic>> getAnimatedBeautyAndTheBeastForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-beauty-and-the-beast');
    return res;
  }

  // --- GIF GET ANIMATED THE EMPEROR'S NEW GROOVE ---

  static Future<Map<String, dynamic>> getAnimatedTheEmperorsNewGrooveForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-emperors-new-groove');
    return res;
  }

  // --- GIF GET ANIMATED HERCULES ---

  static Future<Map<String, dynamic>> getAnimatedHerculesForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-hercules');
    return res;
  }

  // --- GIF GET ANIMATED MULAN ---

  static Future<Map<String, dynamic>> getAnimatedMulanForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-mulan');
    return res;
  }

  // --- GIF GET ANIMATED TARZAN ---

  static Future<Map<String, dynamic>> getAnimatedTarzanForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-tarzan');
    return res;
  }

  // --- GIF GET ANIMATED LADY AND THE TRAMP ---

  static Future<Map<String, dynamic>> getAnimatedLadyAndTheTrampForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-lady-and-the-tramp');
    return res;
  }

  // --- GIF GET ANIMATED OLIVER AND COMPANY ---

  static Future<Map<String, dynamic>> getAnimatedOliverAndCompanyForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-oliver-and-company');
    return res;
  }

  // --- GIF GET ANIMATED THE ARISTOCATS ---

  static Future<Map<String, dynamic>> getAnimatedTheAristocatsForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-aristocats');
    return res;
  }

  // --- GIF GET ANIMATED THE JUNGLE BOOK ---

  static Future<Map<String, dynamic>> getAnimatedTheJungleBookForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-jungle-book');
    return res;
  }

  // --- GIF GET ANIMATED ROBIN HOOD ---

  static Future<Map<String, dynamic>> getAnimatedRobinHoodForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-robin-hood');
    return res;
  }

  // --- GIF GET ANIMATED THE SWORD IN THE STONE ---

  static Future<Map<String, dynamic>> getAnimatedTheSwordInTheStoneForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-sword-in-the-stone');
    return res;
  }

  // --- GIF GET ANIMATED SLEEPING BEAUTY ---

  static Future<Map<String, dynamic>> getAnimatedSleepingBeautyForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-sleeping-beauty');
    return res;
  }

  // --- GIF GET ANIMATED CINDERELLA ---

  static Future<Map<String, dynamic>> getAnimatedCinderellaForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-cinderella');
    return res;
  }

  // --- GIF GET ANIMATED SNOW WHITE AND THE SEVEN DWARFS ---

  static Future<Map<String, dynamic>> getAnimatedSnowWhiteAndTheSevenDwarfsForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-snow-white-and-the-seven-dwarfs');
    return res;
  }

  // --- GIF GET ANIMATED PINOCCHIO ---

  static Future<Map<String, dynamic>> getAnimatedPinocchioForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-pinocchio');
    return res;
  }

  // --- GIF GET ANIMATED DUMBO ---

  static Future<Map<String, dynamic>> getAnimatedDumboForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-dumbo');
    return res;
  }

  // --- GIF GET ANIMATED BAMBI ---

  static Future<Map<String, dynamic>> getAnimatedBambiForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-bambi');
    return res;
  }

  // --- GIF GET ANIMATED FANTASIA ---

  static Future<Map<String, dynamic>> getAnimatedFantasiaForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-fantasia');
    return res;
  }

  // --- GIF GET ANIMATED THE SILENCE OF THE LAMBS ---

  static Future<Map<String, dynamic>> getAnimatedSilenceOfTheLambsForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-silence-of-the-lambs');
    return res;
  }

  // --- GIF GET ANIMATED PULP FICTION ---

  static Future<Map<String, dynamic>> getAnimatedPulpFictionForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-pulp-fiction');
    return res;
  }

  // --- GIF GET ANIMATED THE GODFATHER ---

  static Future<Map<String, dynamic>> getAnimatedGodfatherForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-godfather');
    return res;
  }

  // --- GIF GET ANIMATED THE DARK KNIGHT ---

  static Future<Map<String, dynamic>> getAnimatedDarkKnightForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-dark-knight');
    return res;
  }

  // --- GIF GET ANIMATED SCHINDLER'S LIST ---

  static Future<Map<String, dynamic>> getAnimatedSchindlersListForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-schindlers-list');
    return res;
  }

  // --- GIF GET ANIMATED FORREST GUMP ---

  static Future<Map<String, dynamic>> getAnimatedForrestGumpForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-forrest-gump');
    return res;
  }

  // --- GIF GET ANIMATED FIGHT CLUB ---

  static Future<Map<String, dynamic>> getAnimatedFightClubForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-fight-club');
    return res;
  }

  // --- GIF GET ANIMATED INCEPTION ---

  static Future<Map<String, dynamic>> getAnimatedInceptionForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-inception');
    return res;
  }

  // --- GIF GET ANIMATED THE MATRIX ---

  static Future<Map<String, dynamic>> getAnimatedMatrixForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-matrix');
    return res;
  }

  // --- GIF GET ANIMATED INTERSTELLAR ---

  static Future<Map<String, dynamic>> getAnimatedInterstellarForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-interstellar');
    return res;
  }

  // --- GIF GET ANIMATED TITANIC ---

  static Future<Map<String, dynamic>> getAnimatedTitanicForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-titanic');
    return res;
  }

  // --- GIF GET ANIMATED THE TOWERING INFERNO ---

  static Future<Map<String, dynamic>> getAnimatedToweringInfernoForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-towering-inferno');
    return res;
  }

  // --- GIF GET ANIMATED THE POSEIDON ADVENTURE ---

  static Future<Map<String, dynamic>> getAnimatedPoseidonAdventureForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-poseidon-adventure');
    return res;
  }

  // --- GIF GET ANIMATED THE TAKING OF PELHAM ONE TWO THREE ---

  static Future<Map<String, dynamic>> getAnimatedTakingOfPelhamOneTwoThreeForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-taking-of-pelham-one-two-three');
    return res;
  }

  // --- GIF GET ANIMATED THE FRENCH CONNECTION ---

  static Future<Map<String, dynamic>> getAnimatedFrenchConnectionForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-french-connection');
    return res;
  }

  // --- GIF GET ANIMATED DIRTY HARRY ---

  static Future<Map<String, dynamic>> getAnimatedDirtyHarryForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-dirty-harry');
    return res;
  }

  // --- GIF GET ANIMATED COOGAN'S BLUFF ---

  static Future<Map<String, dynamic>> getAnimatedCoogansBluffForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-coogans-bluff');
    return res;
  }

  // --- GIF GET ANIMATED MAGNUM FORCE ---

  static Future<Map<String, dynamic>> getAnimatedMagnumForceForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-magnum-force');
    return res;
  }

  // --- GIF GET ANIMATED THE ENFORCER ---

  static Future<Map<String, dynamic>> getAnimatedTheEnforcerForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-enforcer');
    return res;
  }

  // --- GIF GET ANIMATED SORCERER ---

  static Future<Map<String, dynamic>> getAnimatedSorcererForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-sorcerer');
    return res;
  }

  // --- GIF GET ANIMATED ESCAPE FROM NEW YORK ---

  static Future<Map<String, dynamic>> getAnimatedEscapeFromNewYorkForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-escape-from-new-york');
    return res;
  }

  // --- GIF GET ANIMATED CLIFFHANGER ---

  static Future<Map<String, dynamic>> getAnimatedCliffhangerForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-cliffhanger');
    return res;
  }

  // --- GIF GET ANIMATED THE LONGEST YARD ---

  static Future<Map<String, dynamic>> getAnimatedTheLongestYardForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-longest-yard');
    return res;
  }

  // --- GIF GET ANIMATED FIDDLER ON THE ROOF ---

  static Future<Map<String, dynamic>> getAnimatedFiddlerOnTheRoofForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-fiddler-on-the-roof');
    return res;
  }

  // --- GIF GET ANIMATED THE MUSIC MAN ---

  static Future<Map<String, dynamic>> getAnimatedTheMusicManForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-music-man');
    return res;
  }

  // --- GIF GET ANIMATED THE SOUND OF MUSIC ---

  static Future<Map<String, dynamic>> getAnimatedTheSoundOfMusicForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-sound-of-music');
    return res;
  }

  // --- GIF GET ANIMATED WEST SIDE STORY ---

  static Future<Map<String, dynamic>> getAnimatedWestSideStoryForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-west-side-story');
    return res;
  }

  // --- GIF GET ANIMATED GYPSY ---

  static Future<Map<String, dynamic>> getAnimatedGypsyForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-gypsy');
    return res;
  }

  // --- GIF GET ANIMATED ANNE OF THE THOUSAND DAYS ---

  static Future<Map<String, dynamic>> getAnimatedAnneOfTheThousandDaysForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-anne-of-the-thousand-days');
    return res;
  }

  // --- GIF GET ANIMATED THE AGONY AND THE ECSTASY ---

  static Future<Map<String, dynamic>> getAnimatedTheAgonyAndTheEcstasyForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-agony-and-the-ecstasy');
    return res;
  }

  // --- GIF GET ANIMATED THE CRIMSON PIRATE ---

  static Future<Map<String, dynamic>> getAnimatedTheCrimsonPirateForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-crimson-pirate');
    return res;
  }

  // --- GIF GET ANIMATED SON OF FLANDERS ---

  static Future<Map<String, dynamic>> getAnimatedSonOfFlandersForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-son-of-flanders');
    return res;
  }

  // --- GIF GET ANIMATED THE BLACK PIRATE ---

  static Future<Map<String, dynamic>> getAnimatedTheBlackPirateForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-black-pirate');
    return res;
  }

  // --- GIF GET ANIMATED SCARAMOUCHE ---

  static Future<Map<String, dynamic>> getAnimatedScaramoucheForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-scaramouche');
    return res;
  }

  // --- GIF GET ANIMATED THE ADVENTURES OF ROBIN HOOD ---

  static Future<Map<String, dynamic>> getAnimatedTheAdventuresOfRobinHoodForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-adventures-of-robin-hood');
    return res;
  }

  // --- GIF GET ANIMATED THE SEA HAWK ---

  static Future<Map<String, dynamic>> getAnimatedTheSeaHawkForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-sea-hawk');
    return res;
  }

  // --- GIF GET ANIMATED NIKITA ---

  static Future<Map<String, dynamic>> getAnimatedNikitaForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-nikita');
    return res;
  }

  // --- GIF GET ANIMATED LA FEMME NIKITA ---

  static Future<Map<String, dynamic>> getAnimatedLaFemmeNikitaForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-la-femme-nikita');
    return res;
  }

  // --- GIF GET ANIMATED THE NET ---

  static Future<Map<String, dynamic>> getAnimatedTheNetForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-net');
    return res;
  }

  // --- GIF GET ANIMATED THE MATRIX RELOADED ---

  static Future<Map<String, dynamic>> getAnimatedMatrixReloadedForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-matrix-reloaded');
    return res;
  }

  // --- GIF GET ANIMATED THE MATRIX REVOLUTIONS ---

  static Future<Map<String, dynamic>> getAnimatedMatrixRevolutionsForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-matrix-revolutions');
    return res;
  }

  // --- GIF GET ANIMATED PROMETHEUS ---

  static Future<Map<String, dynamic>> getAnimatedPrometheusForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-prometheus');
    return res;
  }

  // --- GIF GET ANIMATED ALIEN ---

  static Future<Map<String, dynamic>> getAnimatedAlienForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-alien');
    return res;
  }

  // --- GIF GET ANIMATED ALIENS ---

  static Future<Map<String, dynamic>> getAnimatedAliensForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-aliens');
    return res;
  }

  // --- GIF GET ANIMATED ALIEN³ ---

  static Future<Map<String, dynamic>> getAnimatedAlien3ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-alien3');
    return res;
  }

  // --- GIF GET ANIMATED ALIEN: RESURRECTION ---

  static Future<Map<String, dynamic>> getAnimatedAlienResurrectionForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-alien-resurrection');
    return res;
  }

  // --- GIF GET ANIMATED PROMETHEUS: THE AWAKENING ---

  static Future<Map<String, dynamic>> getAnimatedPrometheusTheAwakeningForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-prometheus-the-awakening');
    return res;
  }

  // --- GIF GET ANIMATED ALIEN: COVENANT ---

  static Future<Map<String, dynamic>> getAnimatedAlienCovenantForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-alien-covenant');
    return res;
  }

  // --- GIF GET ANIMATED THE FORBIDDEN PLANET ---

  static Future<Map<String, dynamic>> getAnimatedTheForbiddenPlanetForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-forbidden-planet');
    return res;
  }

  // --- GIF GET ANIMATED THE DAY THE EARTH STOOD STILL ---

  static Future<Map<String, dynamic>> getAnimatedTheDayTheEarthStoodStillForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-day-the-earth-stood-still');
    return res;
  }

  // --- GIF GET ANIMATED THE THING FROM ANOTHER WORLD ---

  static Future<Map<String, dynamic>> getAnimatedTheThingFromAnotherWorldForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-thing-from-another-world');
    return res;
  }

  // --- GIF GET ANIMATED IT CAME FROM OUTER SPACE ---

  static Future<Map<String, dynamic>> getAnimatedItCameFromOuterSpaceForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-it-came-from-outer-space');
    return res;
  }

  // --- GIF GET ANIMATED THE INCREDIBLE SHRINKING MAN ---

  static Future<Map<String, dynamic>> getAnimatedTheIncredibleShrinkingManForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-incredible-shrinking-man');
    return res;
  }

  // --- GIF GET ANIMATED THE WAR OF THE WORLDS ---

  static Future<Map<String, dynamic>> getAnimatedTheWarOfTheWorldsForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-war-of-the-worlds');
    return res;
  }

  // --- GIF GET ANIMATED THE TIME MACHINE ---

  static Future<Map<String, dynamic>> getAnimatedTheTimeMachineForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-time-machine');
    return res;
  }

  // --- GIF GET ANIMATED THE ISLAND OF DR. MOREAU ---

  static Future<Map<String, dynamic>> getAnimatedTheIslandOfDrMoreauForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-island-of-dr-moreau');
    return res;
  }

  // --- GIF GET ANIMATED THE FLY ---

  static Future<Map<String, dynamic>> getAnimatedTheFlyForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-fly');
    return res;
  }

  // --- GIF GET ANIMATED THE WASP WOMAN ---

  static Future<Map<String, dynamic>> getAnimatedTheWaspWomanForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-wasp-woman');
    return res;
  }

  // --- GIF GET ANIMATED THE CURSE OF THE PINK PANTHER ---

  static Future<Map<String, dynamic>> getAnimatedTheCurseOfThePinkPantherForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-curse-of-the-pink-panther');
    return res;
  }

  // --- GIF GET ANIMATED THE PINK PANTHER STRIKES AGAIN ---

  static Future<Map<String, dynamic>> getAnimatedThePinkPantherStrikesAgainForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther-strikes-again');
    return res;
  }

  // --- GIF GET ANIMATED THE PINK PANTHER ---

  static Future<Map<String, dynamic>> getAnimatedThePinkPantherForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther');
    return res;
  }

  // --- GIF GET ANIMATED A SHOT IN THE DARK ---

  static Future<Map<String, dynamic>> getAnimatedAShotInTheDarkForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-a-shot-in-the-dark');
    return res;
  }

  // --- GIF GET ANIMATED RETURN OF THE PINK PANTHER ---

  static Future<Map<String, dynamic>> getAnimatedReturnOfThePinkPantherForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-return-of-the-pink-panther');
    return res;
  }

  // --- GIF GET ANIMATED THE PINK PANTHER ---

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther2ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther2');
    return res;
  }

  // --- GIF GET ANIMATED THE PINK PANTHER ---

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther3ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther3');
    return res;
  }

  // --- GIF GET ANIMATED THE PINK PANTHER ---

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther4ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther4');
    return res;
  }

  // --- GIF GET ANIMATED THE PINK PANTHER ---

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther5ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther5');
    return res;
  }

  // --- GIF GET ANIMATED THE PINK PANTHER ---

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther6ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther6');
    return res;
  }

  // --- GIF GET ANIMATED THE PINK PANTHER ---

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther7ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther7');
    return res;
  }

  // --- GIF GET ANIMATED THE PINK PANTHER ---

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther8ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther8');
    return res;
  }

  // --- GIF GET ANIMATED THE PINK PANTHER ---

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther9ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther9');
    return res;
  }

  // --- GIF GET ANIMATED THE PINK PANTHER ---

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther10ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther10');
    return res;
  }

  // --- GIF GET ANIMATED THE PINK PANTHER ---

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther11ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther11');
    return res;
  }

  // --- GIF GET ANIMATED THE PINK PANTHER ---

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther12ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther12');
    return res;
  }

  // --- GIF GET ANIMATED THE PINK PANTHER ---

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther13ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther13');
    return res;
  }

  // --- GIF GET ANIMATED THE PINK PANTHER ---

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther14ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther14');
    return res;
  }

  // --- GIF GET ANIMATED THE PINK PANTHER ---

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther15ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther15');
    return res;
  }

  // --- GIF GET ANIMATED THE PINK PANTHER ---

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther16ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther16');
    return res;
  }

  // --- GIF GET ANIMATED THE PINK PANTHER ---

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther17ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther17');
    return res;
  }

  // --- GIF GET ANIMATED THE PINK PANTHER ---

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther18ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther18');
    return res;
  }

  // --- GIF GET ANIMATED THE PINK PANTHER ---

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther19ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther19');
    return res;
  }

  // --- GIF GET ANIMATED THE PINK PANTHER ---

  static Future<Map<String, dynamic>> getAnimatedThePinkPanther20ForGif(String gifId) async {
    final res = await _request('GET', '/gifs/$gifId/animated-the-pink-panther20');
    return res;
  }

  static String formatTimeAgo(String dateTimeString) {
    try {
      final date = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(date);

      final days = difference.inDays;
      final hours = difference.inHours.remainder(24);
      final minutes = difference.inMinutes.remainder(60);

      if (days > 0) {
        return '$days д';
      } else if (hours > 0) {
        return '$hours ч';
      } else if (minutes > 0) {
        return '$minutes м';
      } else {
        return 'Только что';
      }
    } catch (e) {
      debugPrint('Error parsing time: $e');
      return 'Неизвестно';
    }
  }

  static String formatTime(String dateTimeString) {
    try {
      final date = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(date.year, date.month, date.day);

      if (messageDate == today) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (messageDate == today.subtract(const Duration(days: 1))) {
        return 'Вчера';
      } else {
        return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      return '';
    }
  }
}