import 'dart:typed_data';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/preference_keys.dart';
import '../config/api_config.dart';

class HomeService {
  final String _baseUrl = ApiConfig.baseUrl;
  static const _timeout = Duration(seconds: 10);
  static const _uploadTimeout = Duration(seconds: 30);
  static const _maxIdBytes = 5 * 1024 * 1024;

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PreferenceKeys.userEmail);
  }

  Future<Map<String, dynamic>> fetchChecks({
    required String email,
  }) async {
    final encodedEmail = Uri.encodeComponent(email);
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/home/$encodedEmail/checks'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        return {
          'success': true,
          'idCheck': json['idCheck'],
          'addressCheck': json['addressCheck'],
          'emergencyContactCheck': json['emergencyContactCheck'],
          'emergencyContactName': json['emergencyContactName'],
          'emergencyContactNumber': json['emergencyContactNumber'],
        };
      }
      return {
        'success': false,
        'idCheck': json['idCheck'],
        'addressCheck': json['addressCheck'],
        'emergencyContactCheck': json['emergencyContactCheck'],
      };
    } catch (e) {
      debugPrint('Error fetching checks: $e');
      return {'success': false, 'message': 'Network error. Please try again later'};
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
      final request = http.MultipartRequest(
        'POST',
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
          'success': true,
          'message': json['message'],
          'idCheck': json['idCheck'],
        };
      }
      return {
        'success': false,
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
          'success': true,
          'message': json['message'],
          'addressCheck': json['addressCheck'],
        };
      }
      return {
        'success': false,
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
          'success': true,
          'message': json['message'],
          'emergencyContactCheck': json['emergencyContactCheck'],
        };
      }
      return {
        'success': false,
        'message': json['message'] ?? 'Save failed.',
        'emergencyContactCheck': json['emergencyContactCheck'],
      };
    } catch (e) {
      debugPrint('Error submitting emergency check: $e');
      return {'success': false, 'message': 'Save failed.'};
    }
  }
}