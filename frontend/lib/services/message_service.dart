import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

const List<String> _chatMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const List<String> _chatWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String formatChatTime(DateTime? time) {
  if (time == null) return '';

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(time.year, time.month, time.day);
  final daysAgo = today.difference(day).inDays;

  if (daysAgo <= 0) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  if (daysAgo == 1) return 'Yesterday';
  if (daysAgo < 7) return _chatWeekdays[time.weekday - 1];
  return '${_chatMonths[time.month - 1]} ${time.day}';
}

class Conversation {
  final int partnerId;
  final String partnerName;
  final String lastMessage;
  final DateTime? lastSentAt;
  final int unread;

  const Conversation({
    required this.partnerId,
    required this.partnerName,
    required this.lastMessage,
    required this.lastSentAt,
    required this.unread,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      partnerId: (json['partnerId'] as num?)?.toInt() ?? 0,
      partnerName: json['partnerName'] as String? ?? 'Unknown',
      lastMessage: json['lastMessage'] as String? ?? '',
      lastSentAt: DateTime.tryParse(json['lastSentAt'] as String? ?? ''),
      unread: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class DirectMessage {
  final int id;
  final String text;
  final String sentBy;
  final DateTime? sentAt;

  const DirectMessage({
    required this.id,
    required this.text,
    required this.sentBy,
    required this.sentAt,
  });

  factory DirectMessage.fromJson(Map<String, dynamic> json) {
    return DirectMessage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      text: json['message'] as String? ?? '',
      sentBy: (json['sentBy'] as String? ?? '').toUpperCase(),
      sentAt: DateTime.tryParse(json['sentAt'] as String? ?? ''),
    );
  }
}

class MessageService {
  static final String _baseUrl = ApiConfig.baseUrl;
  static const _timeout = Duration(seconds: 10);

  static Future<List<Conversation>> fetchConversations({
    required int userId,
    required String role,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/messages/conversations').replace(
      queryParameters: {'userId': '$userId', 'role': role},
    );

    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Could not load conversations (${response.statusCode})');
    }

    final List<dynamic> list = jsonDecode(response.body);
    return list.map((e) => Conversation.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<DirectMessage>> fetchThread({
    required int sitterId,
    required int homeownerId,
    required String viewerRole,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/messages/thread').replace(
      queryParameters: {
        'sitterId': '$sitterId',
        'homeownerId': '$homeownerId',
        'viewerRole': viewerRole,
      },
    );

    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Could not load messages (${response.statusCode})');
    }

    final List<dynamic> list = jsonDecode(response.body);
    return list.map((e) => DirectMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<DirectMessage> sendMessage({
    required int sitterId,
    required int homeownerId,
    required String sentBy,
    required String message,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/messages/send'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'sitterId': sitterId,
            'homeownerId': homeownerId,
            'sentBy': sentBy,
            'message': message,
          }),
        )
        .timeout(_timeout);

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && json['success'] == true) {
      return DirectMessage.fromJson(json['message'] as Map<String, dynamic>);
    }

    final reason = json['message'];
    throw Exception(reason is String ? reason : 'Could not send message.');
  }
}