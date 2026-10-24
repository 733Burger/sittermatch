enum BookingType { active, upcoming, broadcast, completed}

/// A service a booking can ask for, matched the same way the backend matches it.
enum ServiceKind { night, visit, walk }

const Map<ServiceKind, String> bookingServiceLabels = {
  ServiceKind.night: 'Overnight stay',
  ServiceKind.visit: 'Drop-in feeding visit',
  ServiceKind.walk: 'Dog walk',
};

/// The services a booking type such as "Stay Night & Walk Dog" asks for.
Set<ServiceKind> servicesForBookingType(String bookingType) {
  final t = bookingType.toUpperCase();
  return {
    if (t.contains('NIGHT')) ServiceKind.night,
    if (t.contains('DROP') || t.contains('VISIT') || t.contains('FEED')) ServiceKind.visit,
    if (t.contains('WALK')) ServiceKind.walk,
  };
}

/// The services a sitter offers, from their profile's service codes (STAY_OVER_NIGHT, FEED_PET, WALK_PET).
Set<ServiceKind> servicesFromSitterCodes(Iterable<String> codes) {
  return codes.expand((code) => servicesForBookingType(code)).toSet();
}

class BookingModel {
  final String id;
  final String title;
  final String subtitle;
  final String badgeText;
  final String rightBadgeText;
  final String? sitterName;
  final String? avatarUrl;
  final String? detailText1;
  final String? detailText2;
  final BookingType type;
  final int? bookingId;
  final String rawStatus;
  final int? sitterId;
  final int? homeownerId;
  final String? homeownerName;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? homeownerNotes;
  // Sitters' offers while the booking is pending. A sitter only gets their own.
  final List<SitterOffer> offers;
  // Whether each side has written a review for this booking (approved by an admin or not).
  final bool homeownerReviewed;
  final bool sitterReviewed;

  BookingModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.rightBadgeText,
    this.sitterName,
    this.avatarUrl,
    this.detailText1,
    this.detailText2,
    required this.type,
    this.bookingId,
    this.rawStatus = 'PENDING',
    this.sitterId,
    this.homeownerId,
    this.homeownerName,
    this.startDate,
    this.endDate,
    this.homeownerNotes,
    this.offers = const [],
    this.homeownerReviewed = false,
    this.sitterReviewed = false,
  });

  bool get isCompleted => rawStatus == 'COMPLETED';

  /// Whether this sitter has an offer waiting on the booking. REQUESTED is how a sitter's
  /// request was stored before offers existed.
  bool hasOfferFrom(int? sitterId) =>
      rawStatus == 'REQUESTED' || (sitterId != null && offers.any((o) => o.sitterId == sitterId));

  /// An accepted booking whose dates include today. The backend never sets an
  /// ONGOING status itself, so the stay is ongoing once its start date arrives.
  bool get isOngoing {
    if (rawStatus == 'ONGOING') return true;
    if (rawStatus != 'ACCEPTED' && rawStatus != 'CONFIRMED') return false;
    if (startDate == null || endDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate!.year, startDate!.month, startDate!.day);
    final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
    return !today.isBefore(start) && !today.isAfter(end);
  }
}

/// One sitter's offer to take a pending booking, with their prices.
class SitterOffer {
  final int sitterId;
  final String sitterName;
  final double rating;
  final int reviewCount;
  final double? pricePerNight;
  final double? pricePerVisit;
  final double? pricePerWalk;
  final DateTime? createdAt;

  const SitterOffer({
    required this.sitterId,
    required this.sitterName,
    this.rating = 0,
    this.reviewCount = 0,
    this.pricePerNight,
    this.pricePerVisit,
    this.pricePerWalk,
    this.createdAt,
  });

  factory SitterOffer.fromJson(Map<String, dynamic> j) => SitterOffer(
        sitterId: (j['sitterId'] as num).toInt(),
        sitterName: (j['sitterName'] ?? 'Sitter').toString(),
        rating: (j['sitterRating'] as num?)?.toDouble() ?? 0,
        reviewCount: (j['sitterReviewCount'] as num?)?.toInt() ?? 0,
        pricePerNight: (j['pricePerNight'] as num?)?.toDouble(),
        pricePerVisit: (j['pricePerVisit'] as num?)?.toDouble(),
        pricePerWalk: (j['pricePerWalk'] as num?)?.toDouble(),
        createdAt: DateTime.tryParse('${j['createdAt']}'),
      );
}

/// The open booking between a sitter and a homeowner, with its offered prices.
class BookingOffer {
  final int id;
  final String status; // REQUESTED while a sitter's offer waits for the homeowner, then ACCEPTED, ...
  final int? sitterId;
  final String bookingType;
  final DateTime? start;
  final DateTime? end;
  final String notes;
  double? pricePerNight;
  double? pricePerVisit;
  double? pricePerWalk;

  BookingOffer({
    required this.id,
    required this.status,
    this.sitterId,
    required this.bookingType,
    required this.start,
    required this.end,
    required this.notes,
    this.pricePerNight,
    this.pricePerVisit,
    this.pricePerWalk,
  });

  int get nights {
    if (start == null || end == null) return 1;
    final n = DateTime(end!.year, end!.month, end!.day)
        .difference(DateTime(start!.year, start!.month, start!.day))
        .inDays;
    return n < 1 ? 1 : n;
  }

  factory BookingOffer.fromJson(Map<String, dynamic> j) => BookingOffer(
        id: (j['id'] as num).toInt(),
        status: (j['status'] ?? 'PENDING').toString().toUpperCase(),
        sitterId: (j['sitterId'] as num?)?.toInt(),
        bookingType: (j['bookingType'] ?? 'Standard').toString(),
        start: DateTime.tryParse('${j['startDate']}'),
        end: DateTime.tryParse('${j['endDate']}'),
        notes: (j['notes'] ?? '').toString(),
        pricePerNight: (j['pricePerNight'] as num?)?.toDouble(),
        pricePerVisit: (j['pricePerVisit'] as num?)?.toDouble(),
        pricePerWalk: (j['pricePerWalk'] as num?)?.toDouble(),
      );
}