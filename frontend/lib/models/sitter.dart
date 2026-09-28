class Sitter {
  final int id;
  final String name;
  final String email;
  final String phone;
  final double rating;
  final int totalReviews;
  final double hourlyRate;
  final double dailyRate;
  final String experience;
  final List<String> serviceTypes;
  final List<String> petTypes;
  final bool isVerified;

  Sitter({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.rating,
    required this.totalReviews,
    required this.hourlyRate,
    required this.dailyRate,
    required this.experience,
    required this.serviceTypes,
    required this.petTypes,
    required this.isVerified,
  });

  factory Sitter.fromJson(Map<String, dynamic> json) {
    return Sitter(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Sitter',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] ?? 0,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      dailyRate: (json['dailyRate'] as num?)?.toDouble() ?? 0.0,
      experience: json['experience'] ?? '',
      serviceTypes: List<String>.from(json['serviceTypes'] ?? []),
      petTypes: List<String>.from(json['petTypes'] ?? []),
      isVerified: json['isVerified'] ?? false,
    );
  }
}