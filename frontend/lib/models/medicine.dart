class Medicine {
  final int? id;
  final String name;
  final String dosage;
  final String frequency;
  final String duration;

  Medicine({
    this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'],
      name: json['name'] ?? '',
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? '',
      duration: json['duration'] ?? '',
    );
  }
}
