class SitterListing {
  final int id;
  final String name;
  final String suburb;
  final double rating;
  final int totalReviews;
  final double nightRate;
  final String? imageUrl;
  final List<String> completedChecks;

  SitterListing({
    required this.id,
    required this.name,
    required this.suburb,
    required this.rating,
    required this.totalReviews,
    required this.nightRate,
    this.imageUrl,
    required this.completedChecks,
  });
}