import 'dart:async';
import 'dart:convert';
import '../config/api_config.dart';
import 'package:flutter/foundation.dart'; // Required for debugPrint
import 'package:http/http.dart' as http;

class SitterService {
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

// ---------- NEW: helper ----------

  // Throws with the server's error text if the status isn't 200, so failures are visible.
  static http.Response _check(http.Response res) {
    debugPrint('FRONTEND LOG: ${res.request?.method} ${res.request?.url} -> ${res.statusCode}');
    if (res.statusCode != 200) {
      throw Exception('Request failed (${res.statusCode}): ${res.body}');
    }
    return res;
  }

  // ---------- NEW: Browse sitters ----------

  static Future<List<dynamic>> getAllSitters() async {
    final res = _check(await http.get(Uri.parse('$baseUrl/api/sitters')));
    return jsonDecode(res.body) as List<dynamic>;
  }

  // ---------- NEW: Profile and account ----------

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
        'prefrences': preferences, // spelled this way to match your backend DTO
        'services': services,
      }),
    ));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> submitVerification({
    required int sitterId,
    required String type,
    required String idPhotoUrl,
    required String references,
  }) async {
    final res = _check(await http.post(
      Uri.parse('$baseUrl/api/sitters/$sitterId/verification'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'type': type,
        'idPhotoUrl': idPhotoUrl,
        'references': references,
      }),
    ));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ---------- NEW: Listings ----------

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

  // ---------- NEW: Bookings ----------

  static Future<List<dynamic>> getSitterSchedule(int sitterId) async {
    final res = _check(await http.get(
      Uri.parse('$baseUrl/api/sitters/$sitterId/bookings'),
    ));
    return jsonDecode(res.body) as List<dynamic>;
  }

  // status e.g. 'confirmed' or 'declined' (must match what your backend/DB expects)
  static Future<Map<String, dynamic>> respondToBooking({
    required int bookingId,
    required String status,
  }) async {
    final uri = Uri.parse('$baseUrl/api/sitters/bookings/$bookingId/respond')
        .replace(queryParameters: {'status': status});
    final res = _check(await http.put(uri));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // Backend returns plain text here (not JSON), so we return res.body directly.
  static Future<String> getConfirmedAddress({
    required int sitterId,
    required int bookingId,
  }) async {
    final res = _check(await http.get(
      Uri.parse('$baseUrl/api/sitters/$sitterId/bookings/$bookingId/address'),
    ));
    return res.body;
  }

  // ---------- NEW: Messages and reviews ----------

  static Future<Map<String, dynamic>> sendMessage({
    required int sitterId,
    required int homeownerId,
    required String sentBy, // e.g. 'sitter'
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