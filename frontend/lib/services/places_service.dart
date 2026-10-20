import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class PlaceSuggestion {
  final String placeId;
  final String description;

  const PlaceSuggestion({required this.placeId, required this.description});
}

class PlacesApi {
  static const _timeout = Duration(seconds: 10);

  static String newSessionToken() {
    final rand = Random.secure();
    String block(int length) =>
        List.generate(length, (_) => rand.nextInt(16).toRadixString(16)).join();
    return '${block(8)}-${block(4)}-${block(4)}-${block(4)}-${block(12)}';
  }

  Future<List<PlaceSuggestion>> autocomplete({
    required String input,
    required String sessionToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/places/autocomplete').replace(
      queryParameters: {
        'input': input,
        'sessionToken': sessionToken,
      },
    );
    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Address search failed');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return PlaceSuggestion(
            placeId: (map['placeId'] ?? '').toString(),
            description: (map['description'] ?? '').toString(),
          );
        })
        .where((suggestion) =>
            suggestion.placeId.isNotEmpty && suggestion.description.isNotEmpty)
        .toList();
  }
}
