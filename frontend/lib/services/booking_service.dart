import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../models/booking_draft_model.dart';

class BookingService {

  //DASHBOARD METHODS
  
  static Future<List<BookingModel>> fetchDashboardBookings() async {
    debugPrint('FRONTEND LOG: Calling GET /api/bookings/dashboard');
    await Future.delayed(const Duration(seconds: 1)); 

    return [
      BookingModel(
        id: 'B-1001',
        type: BookingType.active,
        title: 'Camps Bay Sanctu...',
        subtitle: 'Oct 12 – 18',
        sitterName: 'Lerato Khumalo',
        avatarUrl: 'https://i.pravatar.cc/150?img=44',
        badgeText: 'DAY 3 OF 6 • ACTIVE LIVE',
        rightBadgeText: 'Care In Session',
        detailText1: 'Bella & Milo (Golden & Pug)',
        detailText2: 'Midday Beach Run Logged\nCheck-in at 13:42 • GPS Tracking Active',
      ),
      BookingModel(
        id: 'B-1002',
        type: BookingType.upcoming,
        title: 'Upcoming Stay — Constan...',
        subtitle: 'Nov 02 – Nov 08 (Confirmed)   6 Nights',
        sitterName: 'David Marais',
        avatarUrl: 'https://i.pravatar.cc/150?img=11',
        badgeText: 'PENDING START • ARMED RESPONSE REGISTERED',
        rightBadgeText: 'R2,400',
        detailText1: 'Key Handover\nLockbox #24B Co...',
        detailText2: 'Vet On Standby\nConstantia Vet Cli...',
      ),
    ];
  }

  static Future<void> createNewBooking() async {
    debugPrint('FRONTEND LOG: Calling POST /api/bookings/create');
    await Future.delayed(const Duration(seconds: 1));
    debugPrint('FRONTEND LOG: Backend acknowledged new booking created.');
  }

  
  //BOOKING FLOW METHODS
  static Future<BookingDraftModel> getBookingDraft() async {
    debugPrint('FRONTEND LOG: Calling GET /api/bookings/draft-setup');
    await Future.delayed(const Duration(seconds: 1)); 
    
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

  static Future<void> dispatchBooking(BookingDraftModel finalDraft, String instructions) async {
    debugPrint('FRONTEND LOG: Calling POST /api/bookings/dispatch with instructions: $instructions');
    await Future.delayed(const Duration(seconds: 1));
    debugPrint('FRONTEND LOG: 200 OK - Broadcast dispatched successfully.');
  }
}