
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';
import '../config/api_config.dart';

class ProfileService {
  final String _baseUrl = ApiConfig.baseUrl;
  static const _timeout = Duration(seconds: 10);

  Map<String, dynamic> _parseProfile(http.Response response) {
  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return {
    'success': response.statusCode == 200 && json['success'] == true,
    'message': json['message'],
    'name': json['name'],
    'email': json['email'],
    'phone': json['phone'],
    'address': json['address'],
    'requirements': json['requirements'],
    'latitude': (json['latitude'] as num?)?.toDouble(),
    'longitude': (json['longitude'] as num?)?.toDouble(),
    'suburb': json['suburb'],
    'city': json['city'],
  };
}

Future<Map<String, dynamic>> fetchProfile({required int userId}) async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/profile/get-profile/$userId'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(_timeout);
    return _parseProfile(response);
  } catch (e) {
    debugPrint('Error fetching profile: $e');
    return {'success': false, 'message': 'Network error. Please try again later'};
  }
}

Future<Map<String, dynamic>> updateProfile({
  required int userId,
  required String name,
  required String email,
  required String phone,
  required String address,
  required String requirements,
  String? placeId,
  String? sessionToken,
}) async {
  try {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'requirements': requirements,
    };
    if (placeId != null && placeId.isNotEmpty) {
      body['placeId'] = placeId;
      body['sessionToken'] = sessionToken;
    }
    final response = await http.put(
      Uri.parse('$_baseUrl/api/profile/update-profile/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(_timeout);
    return _parseProfile(response);
  } catch (e) {
    debugPrint('Error updating profile: $e');
    return {'success': false, 'message': 'Network error. Please try again later'};
  }
}

Future<Map<String, dynamic>> fetchPets({required int homeownerId}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/pets/homeowner/$homeownerId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return {'success': true, 'pets': jsonDecode(response.body) as List<dynamic>};
      }
      return {'success': false, 'message': 'Failed to load pets', 'pets': <dynamic>[]};
    } catch (e) {
      debugPrint('Error fetching pets: $e');
      return {'success': false, 'message': 'Network error. Please try again later', 'pets': <dynamic>[]};
    }
  }

  Future<Map<String, dynamic>> addPet({
    required int homeownerId,
    required String name,
    required String species,
    required String breed,
    required int age,
    required String careNotes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/pets/homeowner/$homeownerId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'species': species,
          'breed': breed,
          'age': age,
          'careNotes': careNotes,
        }),
      ).timeout(_timeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': response.statusCode == 200 && json['success'] == true,
        'message': json['message'],
      };
    } catch (e) {
      debugPrint('Error adding pet: $e');
      return {'success': false, 'message': 'Network error. Please try again later'};
    }
  }

  Future<Map<String, dynamic>> updatePet({
  required int homeownerId,
  required int petId,
  required String name,
  required String species,
  required String breed,
  required int age,
  required String careNotes,
}) async {
  try {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/pets/homeowner/$homeownerId/$petId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'species': species,
        'breed': breed,
        'age': age,
        'careNotes': careNotes,
      }),
    ).timeout(_timeout);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return {
      'success': response.statusCode == 200 && json['success'] == true,
      'message': json['message'],
    };
  } catch (e) {
    debugPrint('Error updating pet: $e');
    return {'success': false, 'message': 'Network error. Please try again later'};
  }
}

Future<Map<String, dynamic>> deletePet({
  required int homeownerId,
  required int petId,
}) async {
  try {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/pets/homeowner/$homeownerId/$petId'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(_timeout);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return {
      'success': response.statusCode == 200 && json['success'] == true,
      'message': json['message'],
    };
  } catch (e) {
    debugPrint('Error deleting pet: $e');
    return {'success': false, 'message': 'Network error. Please try again later'};
  }
}

  // Sitter profile

  Map<String, dynamic> _parseSitterProfile(http.Response response) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return {
      'success': response.statusCode == 200 && json['success'] == true,
      'message': json['message'],
      'name': json['name'],
      'email': json['email'],
      'phone': json['phone'],
      'experience': json['experience'],
      'rating': (json['rating'] as num?)?.toDouble(),
      'totalReviews': (json['totalReviews'] as num?)?.toInt(),
      'serviceArea': json['serviceArea'],
      'suburb': json['suburb'],
      'city': json['city'],
      'latitude': (json['latitude'] as num?)?.toDouble(),
      'longitude': (json['longitude'] as num?)?.toDouble(),
      'petPreferences': json['petPreferences'],
      'services': json['services'],
    };
  }

  Future<Map<String, dynamic>> fetchSitterProfile({required int userId}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/profile/get-sitter-profile/$userId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);
      return _parseSitterProfile(response);
    } catch (e) {
      debugPrint('Error fetching sitter profile: $e');
      return {'success': false, 'message': 'Network error. Please try again later'};
    }
  }

  Future<Map<String, dynamic>> updateSitterProfile({
    required int userId,
    String? name,
    String? email,
    String? phone,
    String? experience,
    List<Map<String, dynamic>>? services,
    List<String>? petPreferences,
    String? serviceArea,
    String? placeId,
    String? sessionToken,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/profile/update-sitter-profile/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'experience': experience,
          'services': services,
          'petPreferences': petPreferences,
          'serviceArea': serviceArea,
          'placeId': placeId,
          'sessionToken': sessionToken,
        }),
      ).timeout(_timeout);
      return _parseSitterProfile(response);
    } catch (e) {
      debugPrint('Error updating sitter profile: $e');
      return {'success': false, 'message': 'Network error. Please try again later'};
    }
  }
}