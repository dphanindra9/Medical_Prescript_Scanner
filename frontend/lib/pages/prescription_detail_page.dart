import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/prescription.dart';
import '../services/api_service.dart';

class PrescriptionDetailPage extends StatelessWidget {
  final Prescription prescription;

  const PrescriptionDetailPage({super.key, required this.prescription});

  @override
  Widget build(BuildContext context) {
    // Construct the image URL based on the backend API
    final String imageUrl = '${ApiService.baseUrl.replaceAll('/api', '')}/uploads/${prescription.imagePath}';

    return Scaffold(
      backgroundColor: const Color(0xFFEBF3F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEBF3F9),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Document Details',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Preview Card
            if (prescription.imagePath != null)
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
            
            // Patient & Doctor Info Card
            _buildSectionCard(
              title: 'Prescription Info',
              icon: Icons.info_outline,
              children: [
                _buildInfoRow('Doctor', prescription.doctorName.isEmpty ? 'Unknown' : 'Dr. ${prescription.doctorName}'),
                _buildInfoRow('Patient', prescription.patientName),
                _buildInfoRow('Date', prescription.prescriptionDate),
              ],
            ),
            const SizedBox(height: 16),

            // Medicines List Card
            _buildSectionCard(
              title: 'Medicines',
              icon: Icons.medical_services_outlined,
              children: prescription.medicines.isEmpty
                  ? [Text('No medicines found', style: GoogleFonts.inter(color: Colors.grey))]
                  : prescription.medicines.map((med) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(med.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('Dosage: ${med.dosage}', style: GoogleFonts.inter(color: Colors.black87, fontSize: 14)),
                            Text('Frequency: ${med.frequency}', style: GoogleFonts.inter(color: Colors.black87, fontSize: 14)),
                            Text('Duration: ${med.duration}', style: GoogleFonts.inter(color: Colors.black87, fontSize: 14)),
                            const Divider(),
                          ],
                        ),
                      )).toList(),
            ),
            const SizedBox(height: 16),

            // Instructions Card
            if (prescription.instructions.isNotEmpty)
              _buildSectionCard(
                title: 'Instructions / Notes',
                icon: Icons.notes,
                children: [
                  Text(
                    prescription.instructions,
                    style: GoogleFonts.inter(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF26678C), size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF26678C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
