class SavedSitterModel {
  final String id;
  final String name;
  final String location;
  final String verficationBadge;
  final int price;
  final double rating;
  final String bioSnippet;
  final bool isVetNurse;
  final int reviewCount;


SavedSitterModel({
    required this.id,
    required this.name,
    required this.price,
    required this.location,
    required this.verficationBadge,
    required this.rating,
    required this.reviewCount,
    required this.bioSnippet,
    this.isVetNurse = false,
  });
}