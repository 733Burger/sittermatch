class PetCompanion {
  final String id;
  final String category;
  final String details;
  bool isSelected;

  PetCompanion({required this.id, required this.category, required this.details, this.isSelected = false});
}

class BookingDraftModel {
  final String checkInDate;
  final String checkOutDate;
  final int nights;
  final double baseRate;
  final double multiPetFee;
  final double trustFee;
  final List<PetCompanion> companions;

  BookingDraftModel({
    required this.checkInDate,
    required this.checkOutDate,
    required this.nights,
    required this.baseRate,
    required this.multiPetFee,
    required this.trustFee,
    required this.companions,
  });

  double get estimatedTotal => baseRate + multiPetFee + trustFee;
}