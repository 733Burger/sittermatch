import 'dart:convert';
import '../config/api_config.dart';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/saved_sitter_model.dart';

class SavedSitterService {

  // Use central ApiConfig for environment flexibility
  static String get baseUrl => '${ApiConfig.baseUrl}/api/saved-sitters';
  static Future<List<SavedSitterModel>> getSavedSitters() async {
    debugPrint('FRONTEND LOG: Calling Get /api/sitters/saved');
    await Future.delayed(const Duration(seconds: 1));

    return [
      SavedSitterModel(
        id: 1,
        name: 'Lerato Khum...',
        price: 320,
        location: 'Camps Bay, Cape Town',
        verificationBadge: 'SAPS VERIFIED',
        rating: 4.95,
        reviewCount: 38,
        bioSnippet: '"Specialized in sensitive seniors, daily..."',
      ),
      SavedSitterModel(
        id: 2,
        name: 'David Marais',
        price: 350,
        location: 'Constantia, Cape Town',
        verificationBadge: 'SAPS VERIFIED',
        rating: 5.0,
        reviewCount: 42,
        bioSnippet: '"Estate surveillance accredited. Highly..."',
      ),
      SavedSitterModel(
        id: 3,
        name: 'Nomvula Sit...',
        price: 300,
        location: 'Rondebosch, Cape Town',
        verificationBadge: 'VET NURSE • POLICE CHECKED',
        rating: 4.98,
        reviewCount: 29,
        bioSnippet: '"Post-operative care, subcutaneous..."',
        isVetNurse: true,
      ),
    ];
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