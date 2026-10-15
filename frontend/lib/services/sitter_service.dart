import 'dart:async';
import 'dart:convert';

import '../config/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SitterService {
  final String _baseUrl = ApiConfig.baseUrl;
  static const _timeout = Duration(seconds: 10);

  Future<Map<String, dynamic>> getSitterDetails({required int sitterId}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/sitters/$sitterId/get-sitter-details'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final ok = response.statusCode == 200 && json['success'] == true;

      return {
        'success': ok,
        'message': json['message'],
        'name': json['name'],
        'email': json['email'],
        'phone': json['phone'],
        'experience': json['experience'],
        'dayRate': json['dayRate'],
        'nightRate': json['nightRate'],
        'rating': json['rating'],
        'totalReviews': json['totalReview'],
        'verification': json['isVerified'],
        'services' : json['services'],
        'petPreferences' : json['petPreferences']
      };
    } catch (e) {
      debugPrint('Error fetching checks: $e');
      return {
        'success': false,
        'message': 'Network error. Please try again later',
      };
    }
  }
  
// Android emulator: 10.0.2.2 | Chrome/desktop: localhost | real phone: your PC's IP
  static String get baseUrl => ApiConfig.baseUrl;
  static const Map<String, String> _jsonHeaders = {'Content-Type': 'application/json'};

  static Future<Map<String, dynamic>> getSitterProfile(String sitterId) async {
    debugPrint('FRONTEND LOG: Calling GET /api/sitters/$sitterId');
    await Future.delayed(const Duration(seconds: 1)); 
    return {'status': 'success', 'message': 'Profile loaded'};
  }

  static Future<void> initiateChat(String sitterId) async {
    debugPrint('FRONTEND LOG: Calling POST /api/messages/send for Sitter $sitterId');
    await Future.delayed(const Duration(seconds: 1));
    debugPrint('FRONTEND LOG: Backend acknowledged chat initiation.');
  }

  //  Helpers 

  // Throws with the server's error text if the status isn't 200, so failures are visible.
  static http.Response _check(http.Response res) {
    debugPrint('FRONTEND LOG: ${res.request?.method} ${res.request?.url} -> ${res.statusCode}');
    if (res.statusCode != 200) {
      throw Exception('Request failed (${res.statusCode}): ${res.body}');
    }
    return res;
  }

  // Sitter Verification 

  static Future<Map<String, dynamic>> getVerificationChecks(String email) async {
    final encodedEmail = Uri.encodeComponent(email.trim());
    final res = _check(await http.get(
      Uri.parse('$baseUrl/api/sitter-verifications/$encodedEmail/get-checks'),
    ));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> submitIdentityCheck({
    required String email,
    required List<int> imageBytes,
    String filename = 'id_photo.jpg',
  }) async {
    final uri = Uri.parse('$baseUrl/api/sitter-verifications/identity-check');
    final request = http.MultipartRequest('POST', uri)
      ..fields['email'] = email.trim()
      ..files.add(http.MultipartFile.fromBytes(
        'idPhoto',
        imageBytes,
        filename: filename,
      ));

    final streamedResponse = await request.send();
    final res = _check(await http.Response.fromStream(streamedResponse));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> submitResidenceCheck({
    required String email,
    required String address,
  }) async {
    final res = _check(await http.post(
      Uri.parse('$baseUrl/api/sitter-verifications/residence-check'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'email': email.trim(),
        'address': address.trim(),
      }),
    ));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> submitEmergencyCheck({
    required String email,
    required String name,
    required String phoneNumber,
  }) async {
    final res = _check(await http.post(
      Uri.parse('$baseUrl/api/sitter-verifications/emergency-check'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'email': email.trim(),
        'name': name.trim(),
        'phoneNumber': phoneNumber.trim(),
      }),
    ));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // Compatibility stub retained so any legacy screen references do not break
  // static Future<Map<String, dynamic>> submitVerification({
  //   required int sitterId,
  //   required String type,
  //   required String idPhotoUrl,
  //   required String references,
  // }) async {
  //   final res = _check(await http.post(
  //     Uri.parse('$baseUrl/api/sitters/$sitterId/verification'),
  //     headers: _jsonHeaders,
  //     body: jsonEncode({
  //       'type': type,
  //       'idPhotoUrl': idPhotoUrl,
  //       'references': references,
  //     }),
  //   ));
  //   return jsonDecode(res.body) as Map<String, dynamic>;
  // }

  //  Browse sitters 

  static Future<List<dynamic>> getAllSitters() async {
    final res = _check(await http.get(Uri.parse('$baseUrl/api/sitters')));
    return jsonDecode(res.body) as List<dynamic>;
  }

  // Profile and account 

  static Future<Map<String, dynamic>> updateProfile({
    required int sitterId,
    required double dayRate,
    required double nightRate,
    required int experience,
    required List<String> preferences,
    required List<String> services,
  }) async {
    final res = _check(await http.put(
      Uri.parse('$baseUrl/api/sitters/$sitterId/profile'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'dayRate': dayRate,
        'nightRate': nightRate,
        'experience': experience,
        'prefrences': preferences,
        'services': services,
      }),
    ));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  //  Listings 

  static Future<List<dynamic>> findNearbyListings(String suburb) async {
    final uri = Uri.parse('$baseUrl/api/sitters/listings/nearby')
        .replace(queryParameters: {'suburb': suburb});
    final res = _check(await http.get(uri));
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getListingDetails(int listingId) async {
    final res = _check(await http.get(
      Uri.parse('$baseUrl/api/sitters/listings/$listingId'),
    ));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // Bookings 

  static Future<List<dynamic>> getSitterSchedule(int sitterId) async {
    final res = _check(await http.get(
      Uri.parse('$baseUrl/api/sitters/$sitterId/bookings'),
    ));
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> respondToBooking({
    required int bookingId,
    required String status,
  }) async {
    final uri = Uri.parse('$baseUrl/api/sitters/bookings/$bookingId/respond')
        .replace(queryParameters: {'status': status});
    final res = _check(await http.put(uri));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<String> getConfirmedAddress({
    required int sitterId,
    required int bookingId,
  }) async {
    final res = _check(await http.get(
      Uri.parse('$baseUrl/api/sitters/$sitterId/bookings/$bookingId/address'),
    ));
    return res.body;
  }

  //  Messages and reviews

  static Future<Map<String, dynamic>> sendMessage({
    required int sitterId,
    required int homeownerId,
    required String sentBy,
    required String content,
  }) async {
    final res = _check(await http.post(
      Uri.parse('$baseUrl/api/sitters/$sitterId/messages'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'homeownerId': homeownerId,
        'sentBy': sentBy,
        'content': content,
      }),
    ));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> reviewHomeowner({
    required int sitterId,
    required int bookingId,
    required int homeownerId,
    required int rating,
    required String comments,
  }) async {
    final res = _check(await http.post(
      Uri.parse('$baseUrl/api/sitters/$sitterId/reviews/homeowner'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'bookingId': bookingId,
        'homeownerId': homeownerId,
        'rating': rating,
        'comments': comments,
      }),
    ));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> reviewPet({
    required int sitterId,
    required int bookingId,
    required int petId,
    required int rating,
    required String notes,
  }) async {
    final res = _check(await http.post(
      Uri.parse('$baseUrl/api/sitters/$sitterId/reviews/pet'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'bookingId': bookingId,
        'petId': petId,
        'rating': rating,
        'notes': notes,
      }),
    ));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}