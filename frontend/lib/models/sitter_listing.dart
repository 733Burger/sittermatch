class SitterListing {
  final int id;
  final String name;
  final String suburb;
  final double rating;
  final int totalReviews;
  final double nightRate;
  final String? imageUrl;
  final bool isSaved;
  final double? distanceKm;
  final bool isVerified;
  final List<String> serviceTypes;
  final List<String> petTypes;

  const SitterListing({
    required this.id,
    required this.name,
    required this.suburb,
    required this.rating,
    required this.totalReviews,
    required this.nightRate,
    this.imageUrl,
    this.isSaved = false,
    this.distanceKm,
    this.isVerified = false,
    this.serviceTypes = const [],
    this.petTypes = const [],
    // required this.completedChecks,
  });

  factory SitterListing.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num?)?.toInt() ?? 0;
    return SitterListing(
      id: id,
      name: json['name']?.toString() ?? 'Sitter',
      suburb: json['suburb']?.toString() ?? 'Location TBD',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      nightRate: (json['nightRate'] as num?)?.toDouble() ?? 0.0,
      imageUrl: 'https://i.pravatar.cc/150?u=$id',// fake for now
      isSaved: json['isSaved'] as bool? ?? false,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      isVerified: json['isVerified'] as bool? ?? false,
      serviceTypes: _stringList(json['serviceTypes']),
      petTypes: _stringList(json['petTypes']),
    );
  }

  static List<String> _stringList(Object? raw) =>
      raw is List ? raw.map((item) => item.toString()).toList() : const [];

  static List<SitterListing> listFromJson(Object? raw) {
    if (raw is! List) return [];
    return raw
        .map((item) =>
            SitterListing.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}