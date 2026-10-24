import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/review_model.dart';

class ReviewService {
  static String get baseUrl => ApiConfig.baseUrl;
  static const Map<String, String> _headers = {'Content-Type': 'application/json'};

  /// Saves a review and marks the booking completed. The review only shows on profiles once an
  /// admin approves it. Throws with the backend's message if it can't be saved.
  static Future<void> submitStayReview({
    required int bookingId,
    int? sitterId,
    int? homeownerId,
    required String reviewedBy, // "SITTER" or "HOMEOWNER"
    required int rating,
    required String comments,
    List<Map<String, dynamic>>? petReviews,
  }) async {
    final uri = Uri.parse('$baseUrl/api/reviews/submit');

    final payload = {
      'bookingId': bookingId,
      'sitterId': sitterId,
      'homeownerId': homeownerId,
      'reviewedBy': reviewedBy,
      'rating': rating,
      'comments': comments,
      'petReviews': petReviews ?? [],
    };

    final res = await http.post(uri, headers: _headers, body: jsonEncode(payload));
    debugPrint('FRONTEND LOG: POST ${uri.path} -> ${res.statusCode}');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_message(res) ?? 'Could not submit the review (${res.statusCode}).');
    }
  }

  /// Approved reviews homeowners wrote about a sitter.
  static Future<List<StayReview>> fetchSitterReviews(int sitterId) =>
      _fetch('$baseUrl/api/reviews/sitter/$sitterId');

  /// Approved reviews sitters wrote about a homeowner.
  static Future<List<StayReview>> fetchHomeownerReviews(int homeownerId) =>
      _fetch('$baseUrl/api/reviews/homeowner/$homeownerId');

  /// Both reviews on one booking, including ones still waiting for approval.
  static Future<List<StayReview>> fetchBookingReviews(int bookingId) =>
      _fetch('$baseUrl/api/reviews/booking/$bookingId');

  /// Approved reviews sitters wrote about a homeowner's pets.
  static Future<List<PetReview>> fetchHomeownerPetReviews(int homeownerId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/reviews/homeowner/$homeownerId/pets'), headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Could not load pet reviews (${res.statusCode}).');
    }
    final List<dynamic> data = jsonDecode(res.body);
    return data.map((r) => PetReview.fromJson(r as Map<String, dynamic>)).toList();
  }

  static Future<List<StayReview>> _fetch(String url) async {
    final res = await http.get(Uri.parse(url), headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Could not load reviews (${res.statusCode}).');
    }
    final List<dynamic> data = jsonDecode(res.body);
    return data.map((r) => StayReview.fromJson(r as Map<String, dynamic>)).toList();
  }

  static String? _message(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      return body is Map ? body['message']?.toString() : null;
    } catch (_) {
      return null;
    }
  }
}
