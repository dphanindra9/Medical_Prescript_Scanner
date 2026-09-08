import 'medicine.dart';

class Prescription {
  final int id;
  final String patientName;
  final String doctorName;
  final String prescriptionDate;
  final String instructions;
  final String rawText;
  final String? imagePath;
  final List<Medicine> medicines;

  Prescription({
    required this.id,
    required this.patientName,
    required this.doctorName,
    required this.prescriptionDate,
    required this.instructions,
    required this.rawText,
    this.imagePath,
    required this.medicines,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    var medList = json['medicines'] as List? ?? [];
    List<Medicine> medicines = medList.map((m) => Medicine.fromJson(m)).toList();

    return Prescription(
      id: json['id'],
      patientName: json['patient_name'] ?? '',
      doctorName: json['doctor_name'] ?? '',
      prescriptionDate: json['prescription_date'] ?? '',
      instructions: json['instructions'] ?? '',
      rawText: json['raw_text'] ?? '',
      imagePath: json['image_path'],
      medicines: medicines,
    );
  }
}
