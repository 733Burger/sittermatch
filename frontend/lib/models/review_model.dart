/// A review one side of a stay wrote about the other.
class StayReview {
  final int id;
  final int? bookingId;
  final String reviewedBy; // SITTER or HOMEOWNER
  final int rating;
  final String comment;
  final String status; // PENDING until an admin approves it, then PUBLISHED
  final String reviewerName;
  final String revieweeName;
  final DateTime? createdAt;

  const StayReview({
    required this.id,
    this.bookingId,
    required this.reviewedBy,
    required this.rating,
    required this.comment,
    required this.status,
    required this.reviewerName,
    required this.revieweeName,
    this.createdAt,
  });

  bool get isBySitter => reviewedBy == 'SITTER';
  bool get isPublished => status == 'PUBLISHED';

  /// e.g. "12 Oct 2026", or empty for older reviews saved without a date.
  String get dateLabel {
    final d = createdAt;
    if (d == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  factory StayReview.fromJson(Map<String, dynamic> j) => StayReview(
        id: (j['id'] as num).toInt(),
        bookingId: (j['bookingId'] as num?)?.toInt(),
        reviewedBy: (j['reviewedBy'] ?? '').toString().toUpperCase(),
        rating: (j['rating'] as num?)?.toInt() ?? 0,
        comment: (j['comments'] ?? '').toString(),
        status: (j['status'] ?? '').toString().toUpperCase(),
        reviewerName: (j['reviewerName'] ?? '').toString(),
        revieweeName: (j['revieweeName'] ?? '').toString(),
        createdAt: DateTime.tryParse('${j['createdAt']}'),
      );
}

/// A sitter's review of one pet after a stay.
class PetReview {
  final int id;
  final int petId;
  final String petName;
  final int rating;
  final String notes;
  final String sitterName;
  final String dateLabel;

  const PetReview({
    required this.id,
    required this.petId,
    required this.petName,
    required this.rating,
    required this.notes,
    required this.sitterName,
    required this.dateLabel,
  });

  factory PetReview.fromJson(Map<String, dynamic> j) => PetReview(
        id: (j['id'] as num).toInt(),
        petId: (j['petId'] as num).toInt(),
        petName: (j['petName'] ?? 'Pet').toString(),
        rating: (j['rating'] as num?)?.toInt() ?? 0,
        notes: (j['notes'] ?? '').toString(),
        sitterName: (j['sitterName'] ?? 'Sitter').toString(),
        dateLabel: (j['createdAt'] ?? '').toString(),
      );
}
