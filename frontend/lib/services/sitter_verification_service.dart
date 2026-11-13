import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_services.dart';
import 'verification_check_service.dart';

/// The sitter's profile checks. Works exactly like HomeService's checks, against the
/// /api/sitter-verifications endpoints, which return the same response shape.
class SitterVerificationService implements VerificationCheckService {
  final AuthService _authService = AuthService();

  final String _baseUrl = ApiConfig.baseUrl;
  static const _timeout = Duration(seconds: 10);
  static const _uploadTimeout = Duration(seconds: 30);
  static const _maxIdBytes = 5 * 1024 * 1024;

  @override
  Future<Map<String, dynamic>> fetchChecks() async {
    final email = (await _authService.getUserEmail())?.trim() ?? '';
    if (email.isEmpty) {
      return {'success': false, 'message': 'Please log in to see your checks.'};
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/sitter-verifications/${Uri.encodeComponent(email)}/get-checks'),
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
      debugPrint('Error fetching sitter checks: $e');
      return {
        'success': false,
        'message': 'Network error. Please try again later',
      };
    }
  }

  @override
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
        Uri.parse('$_baseUrl/api/sitter-verifications/identity-check'),
      );
      request.fields['email'] = email.trim();
      request.files.add(http.MultipartFile.fromBytes('idPhoto', bytes, filename: filename));

      final streamed = await request.send().timeout(_uploadTimeout);
      final response = await http.Response.fromStream(streamed);
      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        return {'success': true, 'message': json['message']};
      }
      return {'success': false, 'message': json['message'] ?? 'Upload failed.'};
    } catch (e) {
      debugPrint('Error submitting sitter identity check: $e');
      return {'success': false, 'message': 'Upload failed.'};
    }
  }

  @override
  Future<Map<String, dynamic>> submitResidenceCheck({
    required String email,
    required String address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/sitter-verifications/residence-check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim(), 'address': address}),
      ).timeout(_timeout);

      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        return {'success': true, 'message': json['message']};
      }
      return {'success': false, 'message': json['message'] ?? 'Save failed.'};
    } catch (e) {
      debugPrint('Error submitting sitter residence check: $e');
      return {'success': false, 'message': 'Save failed.'};
    }
  }

  @override
  Future<Map<String, dynamic>> submitEmergencyCheck({
    required String email,
    required String name,
    required String phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/sitter-verifications/emergency-check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim(), 'name': name, 'phoneNumber': phoneNumber}),
      ).timeout(_timeout);

      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        return {'success': true, 'message': json['message']};
      }
      return {'success': false, 'message': json['message'] ?? 'Save failed.'};
    } catch (e) {
      debugPrint('Error submitting sitter emergency check: $e');
      return {'success': false, 'message': 'Save failed.'};
    }
  }
}
