const List<String> petTypes = [
  'LARGE DOG',
  'SMALL DOG',
  'CAT',
  'BIRD',
  'REPTILE',
  'FISH',
  'EXOTIC',
];

String petTypeLabel(String value) {
  final lower = value.toLowerCase();
  return lower[0].toUpperCase() + lower.substring(1);
}

class PetModel {
  final int? id;
  String name;
  String breed;
  String species;
  int age;
  String careNotes;
  double? behaviorScore;
  String? review;
  String? photoUrl;

  PetModel({
    this.id,
    required this.name,
    required this.breed,
    required this.species,
    required this.age,
    required this.careNotes,
    this.behaviorScore,
    this.review,
    this.photoUrl,
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    final reviews = (json['totalReviews'] as num?)?.toInt() ?? 0;
    final score = (json['behaviourScore'] as num?)?.toDouble();

    return PetModel(
      id: (json['id'] as num?)?.toInt(),
      name: (json['name'] ?? '').toString(),
      breed: (json['breed'] ?? '').toString(),
      species: (json['species'] ?? 'Dog').toString(),
      age: (json['age'] as num?)?.toInt() ?? 0,
      careNotes: (json['careNotes'] ?? '').toString(),
      behaviorScore: reviews > 0 ? score : null,
      photoUrl: json['imageUrl']?.toString(),
    );
  }
}
