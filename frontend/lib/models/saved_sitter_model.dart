class SavedSitterModel {
  final int id;
  final String name;
  final String location;
  final double dayRate;
  final double nightRate;
  final double rating;
  final int reviewCount;
  bool isSaved;

  SavedSitterModel({
    required this.id,
    required this.name,
    required this.dayRate,
    required this.nightRate,
    required this.location,
    required this.rating,
    required this.reviewCount,
    this.isSaved = false,
  });

  factory SavedSitterModel.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num?)?.toInt() ?? 0;
    return SavedSitterModel(
      id: id,
      name: json['name']?.toString() ?? 'Sitter',
      dayRate: (json['dayRate'] as num?)?.toDouble() ?? 0.0,
      nightRate: (json['nightRate'] as num?)?.toDouble() ?? 0.0,
      location: json['suburb']?.toString() ?? 'Location TBD',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['totalReviews'] as num?)?.toInt() ?? 0,
      isSaved: json['isSaved'] as bool? ?? false,
    );
  }

  static List<SavedSitterModel> listFromJson(Object? raw) {
    if (raw is! List) return [];
    return raw
        .map((item) =>
            SavedSitterModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}