enum BookingType { active, upcoming, broadcast, completed}

class BookingModel {
  final String id;
  final String title;
  final String subtitle;
  final String badgeText;
  final String rightBadgeText;
  final String? sitterName;
  final String? avatarUrl;
  final String? detailText1;
  final String? detailText2;
  final BookingType type;


  BookingModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.rightBadgeText,
    this.sitterName,
    this.avatarUrl,
    this.detailText1,
    this.detailText2,
    required this.type,
  });
}