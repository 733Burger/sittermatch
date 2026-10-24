import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/task_model.dart';

/// The homeowner's stay checklist, and the sitter ticking it off on a booking.
class TaskService {
  static String get baseUrl => ApiConfig.baseUrl;
  static const Map<String, String> _jsonHeaders = {'Content-Type': 'application/json'};

  static http.Response _check(http.Response res) {
    debugPrint('FRONTEND LOG: ${res.request?.method} ${res.request?.url} -> ${res.statusCode}');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String message = 'Request failed (${res.statusCode})';
      try {
        message = (jsonDecode(res.body) as Map<String, dynamic>)['message']?.toString() ?? message;
      } catch (_) {}
      throw Exception(message);
    }
    return res;
  }

  static List<StayTask> _parseList(String body) =>
      (jsonDecode(body) as List).map((t) => StayTask.fromJson(t as Map<String, dynamic>)).toList();

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---------- Homeowner's checklist ----------

  static Future<List<StayTask>> fetchHomeownerTasks(int homeownerId) async {
    final res = _check(await http.get(Uri.parse('$baseUrl/api/home/$homeownerId/tasks'), headers: _jsonHeaders));
    return _parseList(res.body);
  }

  static Future<StayTask> addTask(int homeownerId, {required String title, String? note}) async {
    final res = _check(await http.post(
      Uri.parse('$baseUrl/api/home/$homeownerId/tasks'),
      headers: _jsonHeaders,
      body: jsonEncode({'title': title, 'note': note}),
    ));
    return StayTask.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<StayTask> updateTask(int homeownerId, int taskId, {required String title, String? note}) async {
    final res = _check(await http.put(
      Uri.parse('$baseUrl/api/home/$homeownerId/tasks/$taskId'),
      headers: _jsonHeaders,
      body: jsonEncode({'title': title, 'note': note}),
    ));
    return StayTask.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<void> deleteTask(int homeownerId, int taskId) async {
    _check(await http.delete(Uri.parse('$baseUrl/api/home/$homeownerId/tasks/$taskId'), headers: _jsonHeaders));
  }

  // ---------- A booking's checklist for one day ----------

  static Future<List<StayTask>> fetchBookingTasks(int bookingId, DateTime day) async {
    final uri = Uri.parse('$baseUrl/api/bookings/$bookingId/tasks').replace(queryParameters: {'date': _day(day)});
    return _parseList(_check(await http.get(uri, headers: _jsonHeaders)).body);
  }

  /// Ticks a task off (or unticks it) for that day. Returns the day's updated checklist.
  static Future<List<StayTask>> setTaskDone(int bookingId, int taskId, DateTime day, bool done) async {
    final uri = Uri.parse('$baseUrl/api/bookings/$bookingId/tasks/$taskId')
        .replace(queryParameters: {'date': _day(day), 'done': '$done'});
    return _parseList(_check(await http.put(uri, headers: _jsonHeaders)).body);
  }
}
