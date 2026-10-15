import 'dart:typed_data';
import 'dart:convert';

import 'package:frontend/services/auth_services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/preference_keys.dart';
import '../config/api_config.dart';

class HomeService {
  final AuthService _authService = AuthService();

  final String _baseUrl = ApiConfig.baseUrl;
  static const _timeout = Duration(seconds: 10);
  static const _uploadTimeout = Duration(seconds: 30);
  static const _maxIdBytes = 5 * 1024 * 1024;

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PreferenceKeys.userEmail);
  }

  Future<Map<String, dynamic>> fetchChecks() async {
    final homeownerId = await _authService.getUserId();
    try {
      final response = await http.get(
            Uri.parse('$_baseUrl/api/home/$homeownerId/get-checks'),
            headers: {'Content-Type': 'application/json'},
          ).timeout(_timeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final ok = response.statusCode == 200 && json['success'] == true;

      return {
        'success': ok,
        'message': json['message'],
        'idCheck': json['idCheck'],
        'addressCheck': json['addressCheck'],
        'emergencyContactCheck': json['emergencyContactCheck'],
        'emergencyContactName': json['emergencyContactName'],
        'emergencyContactNumber': json['emergencyContactNumber'],
        'verificationCount': json['verificationCount'],
        'verificationStatus': json['verificationStatus'],
      };
    } catch (e) {
      debugPrint('Error fetching checks: $e');
      return {
        'success': false,
        'message': 'Network error. Please try again later',
      };
    }
  }

  Future<Map<String, dynamic>> fetchSitters() async {
    final homeownerId = await _authService.getUserId();
    try {
      final response = await http.get(
            Uri.parse('$_baseUrl/api/sitters/$homeownerId/get-sitters'),
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

  Future<Map<String, dynamic>> submitIdentityCheck({
    required String email,
    required Uint8List bytes,
    required String filename,
  }) async {
    if (bytes.isEmpty || bytes.length > _maxIdBytes) {
      return {
        'success': false,
        'message': 'File size must be between 1 byte and 5 MB.',
      };
    }

    try {
      final request = http.MultipartRequest('POST',
        Uri.parse('$_baseUrl/api/home/identity-check'),
      );
      request.fields['email'] = email;
      request.files.add(
        http.MultipartFile.fromBytes(
          'idPhoto',
          bytes,
          filename: filename,
        ),
      );

      final streamed = await request.send().timeout(_uploadTimeout);
      final response = await http.Response.fromStream(streamed);
      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        return {
          'message': json['message'],
          'idCheck': json['idCheck'],
        };
      }
      return {
        'message': json['message'] ?? 'Upload failed.',
        'idCheck': json['idCheck'],
      };
    } catch (e) {
      debugPrint('Error submitting identity check: $e');
      return {'success': false, 'message': 'Upload failed.'};
    }
  }

  Future<Map<String, dynamic>> submitResidenceCheck({
    required String email,
    required String address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/home/residence-check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'address': address,
        }),
      ).timeout(_timeout);

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        return {
          'message': json['message'],
          'addressCheck': json['addressCheck'],
        };
      }
      return {
        'message': json['message'] ?? 'Save failed.',
        'addressCheck': json['addressCheck'],
      };
    } catch (e) {
      debugPrint('Error submitting residence check: $e');
      return {'success': false, 'message': 'Save failed.'};
    }
  }

  Future<Map<String, dynamic>> submitEmergencyCheck({
    required String email,
    required String name,
    required String phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/home/emergency-check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'name': name,
          'phoneNumber': phoneNumber,
        }),
      ).timeout(_timeout);

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        return {
          'message': json['message'],
          'emergencyContactCheck': json['emergencyContactCheck'],
        };
      }
      return {
        'message': json['message'] ?? 'Save failed.',
        'emergencyContactCheck': json['emergencyContactCheck'],
      };
    } catch (e) {
      debugPrint('Error submitting emergency check: $e');
      return {'success': false, 'message': 'Save failed.'};
    }
  }

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
  };
}

Future<Map<String, dynamic>> fetchProfile({required int userId}) async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/home/profile/$userId'),
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
}) async {
  try {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/home/profile/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'requirements': requirements,
      }),
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
  
}