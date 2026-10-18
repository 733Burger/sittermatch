
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/booking_model.dart';
import '../models/booking_draft_model.dart';

class BookingService {
  static String get baseUrl => ApiConfig.baseUrl;
  static const Map<String, String> _jsonHeaders = {'Content-Type': 'application/json'};

  // Helper to validate HTTP responses and log network requests
  static http.Response _check(http.Response res) {
    debugPrint('FRONTEND LOG: ${res.request?.method} ${res.request?.url} -> ${res.statusCode}');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Request failed (${res.statusCode}): ${res.body}');
    }
    return res;
  }

  // dashboard methods 

  /// Fetches bookings from the backend and maps them to UI-ready BookingModel items.
  static Future<List<BookingModel>> fetchDashboardBookings({
    int? homeownerId,
    int? sitterId,
  }) async {
    Uri uri;
    if (homeownerId != null) {
      uri = Uri.parse('$baseUrl/api/bookings/homeowner/$homeownerId');
    } else if (sitterId != null) {
      uri = Uri.parse('$baseUrl/api/bookings/sitter/$sitterId');
    } else {
      uri = Uri.parse('$baseUrl/api/bookings');
    }

    try {
      final res = _check(await http.get(uri, headers: _jsonHeaders));
      final List<dynamic> data = jsonDecode(res.body);

      if (data.isEmpty) return [];

      return data.map<BookingModel>((item) => _mapJsonToBookingModel(item)).toList();
    } catch (e) {
      debugPrint('FRONTEND ERROR: Failed to load bookings: $e');
      rethrow;
    }
  }

  // booking creation and dispatching 

 /// Dispatches a new booking from the BookingDraftModel, notes, and selected dates and times.
  static Future<Map<String, dynamic>> dispatchBooking(
    BookingDraftModel finalDraft,
    String instructions, {
    int listingId = 18,
    int sitterId = 1,
    String bookingType = 'Standard',
    DateTime? startDateTime,
    DateTime? endDateTime,
  }) async {
    final uri = Uri.parse('$baseUrl/api/bookings/dispatch');

    final now = DateTime.now();
    final start = startDateTime ?? now.add(const Duration(days: 1));
    final end = endDateTime ?? now.add(Duration(days: 1 + finalDraft.nights));

    final payload = {
      'listingId': listingId,
      'sitterId': sitterId,
      'bookingType': bookingType,
      'startDate': start.toIso8601String(),
      'endDate': end.toIso8601String(),
      'notes': instructions.trim(),
    };

    final res = _check(await http.post(
      uri,
      headers: _jsonHeaders,
      body: jsonEncode(payload),
    ));

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Retained for backward compatibility
  static Future<void> createNewBooking({
    int listingId = 18,
    int sitterId = 1,
    String bookingType = 'Standard',
    String? notes,
  }) async {
    final now = DateTime.now();
    final payload = {
      'listingId': listingId,
      'sitterId': sitterId,
      'bookingType': bookingType,
      'startDate': now.add(const Duration(days: 1)).toIso8601String(),
      'endDate': now.add(const Duration(days: 4)).toIso8601String(),
      'notes': notes ?? '',
    };

    _check(await http.post(
      Uri.parse('$baseUrl/api/bookings/create'),
      headers: _jsonHeaders,
      body: jsonEncode(payload),
    ));
  }

  // lifecycle and status updates

  /// Updates status 
  static Future<Map<String, dynamic>> updateBookingStatus({
    required int bookingId,
    required String status,
  }) async {
    final uri = Uri.parse('$baseUrl/api/bookings/$bookingId/status')
        .replace(queryParameters: {'status': status});

    final res = _check(await http.patch(uri, headers: _jsonHeaders));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // Setup

  static Future<BookingDraftModel> getBookingDraft() async {
    return BookingDraftModel(
      checkInDate: 'Fri, 24 Nov',
      checkOutDate: 'Mon, 27 Nov',
      nights: 3,
      baseRate: 960.00,
      multiPetFee: 180.00,
      trustFee: 50.00,
      companions: [
        PetCompanion(id: 'p1', category: 'Dogs', details: '2 Selected: Bella & Milo', isSelected: true),
        PetCompanion(id: 'p2', category: 'Cats', details: '1: Luna', isSelected: true),
        PetCompanion(id: 'p3', category: 'Birds', details: 'Aviary / Parrots', isSelected: false),
        PetCompanion(id: 'p4', category: 'Small Pets', details: 'Caged / Exotics', isSelected: false),
      ],
    );
  }

  // JSON parsing helper to map backend booking JSON to frontend BookingModel

  static BookingModel _mapJsonToBookingModel(Map<String, dynamic> json) {
    final status = (json['status'] as String? ?? 'PENDING').toUpperCase();

    BookingType type;
    switch (status) {
      case 'CONFIRMED':
      case 'ACCEPTED':
      case 'ONGOING':
        type = BookingType.active;
        break;
      case 'COMPLETED':
        type = BookingType.completed;
        break;
      case 'BROADCAST':
        type = BookingType.broadcast;
        break;
      case 'PENDING':
      default:
        type = BookingType.upcoming;
        break;
    }

    final startRaw = json['startDate']?.toString() ?? '';
    final endRaw = json['endDate']?.toString() ?? '';
    final dateRange = (startRaw.isNotEmpty && endRaw.isNotEmpty)
        ? '${startRaw.split('T').first} – ${endRaw.split('T').first}'
        : 'Dates unconfirmed';

    return BookingModel(
      id: 'B-${json['id']}',
      title: json['listingTitle'] ?? 'Home Stay',
      subtitle: '$dateRange (${json['status'] ?? 'Pending'})',
      sitterName: json['sitterName'] ?? 'Assigned Sitter',
      avatarUrl: 'https://i.pravatar.cc/150?u=${json['sitterId'] ?? 'user'}',
      badgeText: status == 'ACCEPTED' || status == 'CONFIRMED'
          ? 'CONFIRMED STAY'
          : 'PENDING CONFIRMATION',
      rightBadgeText: json['bookingType'] ?? 'Standard',
      detailText1: json['notes'] != null && json['notes'].toString().isNotEmpty
          ? json['notes']
          : 'No special notes provided',
      detailText2: 'Booking ID: #${json['id']}',
      type: type,
    );
  }
}