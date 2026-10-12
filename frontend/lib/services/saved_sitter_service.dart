import 'dart:convert';
import '../config/api_config.dart';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/saved_sitter_model.dart';
import 'auth_services.dart';

class SavedSitterService {

  // Use central ApiConfig for environment flexibility
  static String get baseUrl => '${ApiConfig.baseUrl}/api/saved-sitters';

  static Future<List<SavedSitterModel>> getSavedSitters() async {
    final homeownerId = await AuthService().getUserId();
    if (homeownerId == null) throw Exception('No logged-in user');

    final url = Uri.parse('$baseUrl/$homeownerId');
    debugPrint('FRONTEND LOG: GET $url');
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to load saved sitters (${response.statusCode})');
    }

    final raw = jsonDecode(response.body) as List;
    return raw
        .map((e) => SavedSitterModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

// Toggle save/unsave state on backend
  static Future<bool> toggleSaveSitter({
    required int homeownerId,
    required int sitterId,
    required bool isCurrentlySaved,
  }) async {
    try {
      if (isCurrentlySaved) {
        final url = Uri.parse('$baseUrl?homeownerId=$homeownerId&sitterId=$sitterId');
        debugPrint('FRONTEND LOG: DELETE $url');
        final response = await http.delete(url);
        return response.statusCode == 200 || response.statusCode == 204;
      } else {
        final url = Uri.parse(baseUrl);
        debugPrint('FRONTEND LOG: POST $url');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'homeownerId': homeownerId,
            'sitterId': sitterId,
          }),
        );
        return response.statusCode == 200 || response.statusCode == 201;
      }
    } catch (e) {
      debugPrint('Error calling toggleSaveSitter: $e');
      rethrow;
    }
  }


}