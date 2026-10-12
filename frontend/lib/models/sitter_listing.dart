class SitterListing {
  final int id;
  final String name;
  final String suburb;
  final double rating;
  final int totalReviews;
  final double nightRate;
  final String? imageUrl;
  // final List<String> completedChecks;

  const SitterListing({
    required this.id,
    required this.name,
    required this.suburb,
    required this.rating,
    required this.totalReviews,
    required this.nightRate,
    this.imageUrl,
    // required this.completedChecks,
  });

  factory SitterListing.fromJson(Map<String, dynamic> json) {
    // final serviceTypes = (json['serviceTypes'] as List?) ?.map((e) => e.toString()).toList() ?? <String>[];
    // final petTypes = (json['petTypes'] as List?) ?.map((e) => e.toString()).toList() ?? <String>[];
    final id = (json['id'] as num?)?.toInt() ?? 0;
    return SitterListing(
      id: id,
      name: json['name']?.toString() ?? 'Sitter',
      suburb: json['suburb']?.toString() ?? 'Location TBD',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      nightRate: (json['nightRate'] as num?)?.toDouble() ?? 0.0,
      imageUrl: 'https://i.pravatar.cc/150?u=$id', // fake for now
      // completedChecks: [
      //   if (json['isVerified'] == true) 'Verified',
      //   ...serviceTypes.take(2),
      //   ...petTypes.take(1),
      // ],
    );
  }

  static List<SitterListing> listFromJson(Object? raw) {
    if (raw is! List) return [];
    return raw
        .map((item) =>
            SitterListing.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}