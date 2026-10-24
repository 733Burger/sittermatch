import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/booking_model.dart';
import '../models/booking_draft_model.dart';
import '../models/pet_model.dart';

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

  /// Permanently deletes a booking (homeowner cancelling it).
  static Future<void> deleteBooking(int bookingId) async {
    _check(await http.delete(
      Uri.parse('$baseUrl/api/bookings/$bookingId'),
      headers: _jsonHeaders,
    ));
  }

  // offers

  /// Sitter sends an offer on a pending booking. The backend messages the homeowner.
  /// [extraPrices] holds prices for services the booking asks for that the sitter doesn't offer.
  /// Several sitters can offer on an open booking; the homeowner accepts one.
  static Future<BookingOffer> requestAccept(
    int bookingId, {
    int? sitterId,
    Map<ServiceKind, double> extraPrices = const {},
  }) async {
    final res = _check(await http.post(
      Uri.parse('$baseUrl/api/bookings/$bookingId/request-accept')
          .replace(queryParameters: sitterId == null ? null : {'sitterId': '$sitterId'}),
      headers: _jsonHeaders,
      body: jsonEncode({
        'pricePerNight': ?extraPrices[ServiceKind.night],
        'pricePerVisit': ?extraPrices[ServiceKind.visit],
        'pricePerWalk': ?extraPrices[ServiceKind.walk],
      }),
    ));
    return BookingOffer.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Sitter declines an open booking: it is hidden from them but stays open for other sitters.
  static Future<void> dismissOpenBooking(int bookingId, int sitterId) async {
    _check(await http.post(
      Uri.parse('$baseUrl/api/bookings/$bookingId/dismiss').replace(queryParameters: {'sitterId': '$sitterId'}),
      headers: _jsonHeaders,
    ));
  }

  /// Homeowner accepts one sitter's offer. The other offers on the booking are removed.
  static Future<void> acceptOffer(int bookingId, int sitterId) async {
    _check(await http.post(
      Uri.parse('$baseUrl/api/bookings/$bookingId/offers/accept').replace(queryParameters: {'sitterId': '$sitterId'}),
      headers: _jsonHeaders,
    ));
  }

  /// Homeowner turns down a sitter's offer, or the sitter withdraws it.
  static Future<void> declineOffer(int bookingId, int sitterId) async {
    _check(await http.post(
      Uri.parse('$baseUrl/api/bookings/$bookingId/offers/decline').replace(queryParameters: {'sitterId': '$sitterId'}),
      headers: _jsonHeaders,
    ));
  }

  /// Homeowner changes one or more prices in a sitter's offer (only the non-null ones are sent).
  static Future<BookingOffer> updatePrices(
    int bookingId, {
    int? sitterId,
    double? pricePerNight,
    double? pricePerVisit,
    double? pricePerWalk,
  }) async {
    final res = _check(await http.patch(
      Uri.parse('$baseUrl/api/bookings/$bookingId/prices')
          .replace(queryParameters: sitterId == null ? null : {'sitterId': '$sitterId'}),
      headers: _jsonHeaders,
      body: jsonEncode({
        'pricePerNight': ?pricePerNight,
        'pricePerVisit': ?pricePerVisit,
        'pricePerWalk': ?pricePerWalk,
      }),
    ));
    return BookingOffer.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// The open booking between these two people, or null if there is none.
  static Future<BookingOffer?> fetchBookingBetween({
    required int sitterId,
    required int homeownerId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/bookings/between')
        .replace(queryParameters: {'sitterId': '$sitterId', 'homeownerId': '$homeownerId'});
    final res = await http.get(uri, headers: _jsonHeaders);
    if (res.statusCode == 204 || res.body.isEmpty) return null;
    _check(res);
    return BookingOffer.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// The pets registered on a homeowner's profile.
  static Future<List<PetModel>> fetchHomeownerPets(int homeownerId) async {
    final res = _check(await http.get(
      Uri.parse('$baseUrl/api/pets/homeowner/$homeownerId'),
      headers: _jsonHeaders,
    ));
    final List<dynamic> data = jsonDecode(res.body);
    return data.map((item) => PetModel.fromJson(item as Map<String, dynamic>)).toList();
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
      // Both null while the booking is open and no sitter has taken it.
      sitterName: json['sitterName'] as String?,
      avatarUrl: json['sitterId'] == null ? null : 'https://i.pravatar.cc/150?u=${json['sitterId']}',
      badgeText: status == 'ACCEPTED' || status == 'CONFIRMED'
          ? 'CONFIRMED STAY'
          : 'PENDING CONFIRMATION',
      rightBadgeText: json['bookingType'] ?? 'Standard',
      detailText1: json['notes'] != null && json['notes'].toString().isNotEmpty
          ? json['notes']
          : 'No special notes provided',
      detailText2: 'Booking ID: #${json['id']}',
      type: type,
      bookingId: (json['id'] as num?)?.toInt(),
      rawStatus: status,
      sitterId: (json['sitterId'] as num?)?.toInt(),
      homeownerId: (json['homeownerId'] as num?)?.toInt(),
      homeownerName: json['homeownerName'] as String?,
      startDate: DateTime.tryParse(startRaw),
      endDate: DateTime.tryParse(endRaw),
      homeownerNotes: json['notes']?.toString().isNotEmpty == true ? json['notes'].toString() : null,
      offers: ((json['offers'] as List?) ?? [])
          .map((o) => SitterOffer.fromJson(o as Map<String, dynamic>))
          .toList(),
      homeownerReviewed: json['homeownerReviewed'] == true,
      sitterReviewed: json['sitterReviewed'] == true,
    );
  }
}