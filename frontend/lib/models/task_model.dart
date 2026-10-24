/// One item on a homeowner's stay checklist. On a booking, [done] and [checkedAt]
/// say whether the sitter ticked it off on that day.
class StayTask {
  final int id;
  final String title;
  final String? note;
  final bool done;
  final DateTime? checkedAt;

  const StayTask({
    required this.id,
    required this.title,
    this.note,
    this.done = false,
    this.checkedAt,
  });

  factory StayTask.fromJson(Map<String, dynamic> json) => StayTask(
        id: (json['id'] as num).toInt(),
        title: (json['title'] ?? '').toString(),
        note: (json['note'] as String?)?.trim().isEmpty == true ? null : json['note'] as String?,
        done: json['done'] == true,
        checkedAt: DateTime.tryParse('${json['checkedAt']}'),
      );
}
