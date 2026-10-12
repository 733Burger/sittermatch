class SavedSitterModel {
  final int id;
  final String name;
  final String location;
  final String verificationBadge;
  final int price;
  final double rating;
  final String bioSnippet;
  final bool isVetNurse;
  final int reviewCount;
  bool isSaved;


SavedSitterModel({
    required this.id,
    required this.name,
    required this.price,
    required this.location,
    required this.verificationBadge,
    required this.rating,
    required this.reviewCount,
    required this.bioSnippet,
    this.isVetNurse = false,
    this.isSaved = false,
  });

  factory SavedSitterModel.fromJson(Map<String, dynamic> json) {
  final user = json['user'] as Map<String, dynamic>?;
  return SavedSitterModel(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: (user?['name'] ?? json['name'] ?? 'Sitter').toString(),
    price: (json['nightRate'] as num?)?.toInt() ?? 0,
    location: json['suburb']?.toString() ?? 'Location TBD',
    verificationBadge: json['isVerified'] == true ? 'VERIFIED' : 'UNVERIFIED',
    rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    reviewCount: (json['totalReviews'] as num?)?.toInt() ?? 0,
    bioSnippet: '',
    isSaved: true,
  );
}
}