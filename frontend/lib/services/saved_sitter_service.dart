import 'dart:convert';
import '../config/api_config.dart';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_services.dart';

class SavedSitterService {
  final AuthService _authService = AuthService();

  final String _baseUrl = ApiConfig.baseUrl;
  static const _timeout = Duration(seconds: 10);
  // Use central ApiConfig for environment flexibility
  static String get baseUrl => '${ApiConfig.baseUrl}/api/saved-sitters';

  Future<Map<String, dynamic>> fetchSavedSitters() async {
    final homeownerId = await _authService.getUserId();
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/saved-sitters/$homeownerId/get-saved-sitters'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      final sitters = jsonDecode(response.body) as List<dynamic>;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Sitters retrieved successfully',
          'sitters': sitters,
        };
      }
      return {
        'success': false,
        'message': 'Failed to load sitters',
        'sitters': <dynamic>[],
      };
    } catch (e) {
      debugPrint('Error fetch sitters: $e');
      return {
        'success': false,
        'message': 'Network error. Please try again later',
        'sitters': <dynamic>[],
      };
    }
  }

  // static Future<List<SavedSitterModel>> getSavedSitters() async {
  //   final homeownerId = await AuthService().getUserId();
  //   if (homeownerId == null) throw Exception('No logged-in user');

  //   final url = Uri.parse('$baseUrl/$homeownerId');
  //   debugPrint('FRONTEND LOG: GET $url');
  //   final response = await http.get(url);
  //   if (response.statusCode != 200) {
  //     throw Exception('Failed to load saved sitters (${response.statusCode})');
  //   }

  //   final raw = jsonDecode(response.body) as List;
  //   return raw
  //       .map((e) => SavedSitterModel.fromJson(Map<String, dynamic>.from(e as Map)))
  //       .toList();
  // }

  Future<Map<String, dynamic>> toggleSavedSitter({
    required int homeownerId,
    required int sitterId,
    required bool isCurrentlySaved,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/saved-sitters/toggle-sitters'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'homeownerId': homeownerId,
          'sitterId': sitterId,
          'isCurrentlySaved': isCurrentlySaved
        }),
      ).timeout(_timeout);

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        return {
          'success': json['success'],
          'message': json['message']
        };
      }
      return {
        'success': json['success'] ?? false,
        'message': json['message'] ?? 'Save failed.'
      };
    } catch (e) {
      debugPrint('Error when toggling sitter: $e');
      return {'success': false, 'message': 'Toggle failed.'};
    }
  }
}