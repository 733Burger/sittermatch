class SitterListing {
  final int id;
  final String name;
  final String suburb;
  final double rating;
  final int totalReviews;
  final double nightRate;
  final String? imageUrl;
  final List<String> completedChecks;

  const SitterListing({
    required this.id,
    required this.name,
    required this.suburb,
    required this.rating,
    required this.totalReviews,
    required this.nightRate,
    this.imageUrl,
    required this.completedChecks,
  });

  factory SitterListing.fromJson(Map<String, dynamic> json) {
    final checks = json['completedChecks'];
    return SitterListing(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? 'Sitter',
      suburb: json['suburb']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      nightRate: (json['nightRate'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl']?.toString(),
      completedChecks: checks is List
          ? checks.map((check) => check.toString()).toList()
          : const [],
    );
  }

  static List<SitterListing> listFromJson(Object? json) {
    if (json is! List) return const [];
    return json
        .whereType<Map<String, dynamic>>()
        .map(SitterListing.fromJson)
        .toList();
  }
}
