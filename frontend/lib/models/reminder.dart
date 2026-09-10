class Reminder {
  final int id;
  final String medicineName;
  final int pillCount;
  final List<String> timings;
  final List<String> days;
  final String createdAt;
  final Map<String, bool> takenDoses;

  Reminder({
    required this.id,
    required this.medicineName,
    required this.pillCount,
    required this.timings,
    required this.days,
    required this.createdAt,
    this.takenDoses = const {},
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      medicineName: json['medicine_name'] ?? '',
      pillCount: json['pill_count'] ?? 0,
      timings: List<String>.from(json['timings'] ?? []),
      days: List<String>.from(json['days'] ?? []),
      createdAt: json['created_at'] ?? '',
      takenDoses: Map<String, bool>.from(json['taken_doses'] ?? {}),
    );
  }
}
