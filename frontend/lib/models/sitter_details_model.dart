class SitterServiceItem {
  final String serviceType;
  final double price;
  const SitterServiceItem({this.serviceType = '', this.price = 0});

  factory SitterServiceItem.fromJson(Map<String, dynamic> json) {
    return SitterServiceItem(
      serviceType: json['serviceType']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SitterDetails {
  final String name;
  final String email;
  final String phoneNumber;
  final String experience;
  final double dayRate;
  final double nightRate;
  final double rating;
  final int totalReviews;
  final bool isVerified;
  final List<String> petPreferences;
  final List<SitterServiceItem> services;

  const SitterDetails({
    this.name = '',
    this.email = '',
    this.phoneNumber = '',
    this.experience = '',
    this.dayRate = 0.0,
    this.nightRate = 0.0,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.isVerified = false,
    this.petPreferences = const [],
    this.services = const [],
  });

  factory SitterDetails.fromJson(Map<String, dynamic> json) {
    final rawServices = json['services'];
    final rawPets = json['petPreferences'];

    return SitterDetails(
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phone']?.toString() ?? '',
      experience: json['experience']?.toString() ?? '',
      dayRate: (json['dayRate'] as num?)?.toDouble() ?? 0,
      nightRate: (json['nightRate'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      isVerified: json['verification'] == true,
      petPreferences: rawPets is List
          ? rawPets.map((pet) => pet.toString()).toList()
          : const [],
      services: rawServices is List
          ? rawServices
              .whereType<Map>()
              .map((item) => SitterServiceItem.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
    );
  }
}