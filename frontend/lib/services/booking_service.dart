
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
    required int homeownerId,
    int? sitterId,
    String bookingType = 'Standard',
    DateTime? startDateTime,
    DateTime? endDateTime,
  }) async {
    final uri = Uri.parse('$baseUrl/api/bookings/dispatch');

    final now = DateTime.now();
    final start = startDateTime ?? now.add(const Duration(days: 1));
    final end = endDateTime ?? now.add(Duration(days: 1 + finalDraft.nights));

    final selectedPets = finalDraft.companions.where((pet) => pet.isSelected).toList();
    final petLine = selectedPets.isEmpty
        ? ''
        : 'Pets: ${selectedPets.map((pet) => pet.category).join(', ')}';
    final notes = [instructions.trim(), petLine].where((line) => line.isNotEmpty).join('\n');

    final payload = {
      'homeownerId': homeownerId,
      'sitterId': ?sitterId,
      'bookingType': bookingType,
      'startDate': _formatDateTime(start),
      'endDate': _formatDateTime(end),
      'notes': notes,
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

  static Future<BookingDraftModel> getBookingDraft(int homeownerId) async {
    List<PetCompanion> companions = [];
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/pets/homeowner/$homeownerId'),
        headers: _jsonHeaders,
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final List<dynamic> pets = jsonDecode(res.body);
        companions = pets.map((item) {
          final pet = item as Map<String, dynamic>;
          final species = (pet['species'] ?? '').toString();
          final breed = (pet['breed'] ?? '').toString();
          final age = pet['age'];
          final details = [
            if (species.isNotEmpty) species,
            if (breed.isNotEmpty) breed,
            if (age != null) 'Age $age',
          ].join(' · ');
          return PetCompanion(
            id: '${pet['id']}',
            category: (pet['name'] ?? 'Pet').toString(),
            details: details.isEmpty ? 'Registered pet' : details,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('FRONTEND ERROR: Failed to load pets for booking: $e');
    }

    return BookingDraftModel(
      checkInDate: '',
      checkOutDate: '',
      nights: 1,
      baseRate: 0,
      multiPetFee: 0,
      trustFee: 0,
      companions: companions,
    );
  }

  static String _formatDateTime(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year.toString().padLeft(4, '0')}-'
        '${two(value.month)}-${two(value.day)}T'
        '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
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