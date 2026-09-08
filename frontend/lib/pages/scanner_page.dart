import 'package:flutter/material.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../services/api_service.dart';

class ScannerPage extends StatefulWidget {
  final int userId;
  const ScannerPage({super.key, required this.userId});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  List<String> _pictures = [];
  bool _isProcessing = false;
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _scanDocument();
  }

  Future<void> _scanDocument() async {
    try {
      List<String>? pictures = await CunningDocumentScanner.getPictures();
      if (pictures != null && pictures.isNotEmpty) {
        setState(() {
          _pictures = pictures;
        });
      } else {
        // User canceled
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning document: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _saveScan() async {
    if (_pictures.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // For MVP, we'll just process the first page
      File imageFile = File(_pictures.first);
      await apiService.uploadPrescriptionScan(imageFile, widget.userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Prescription saved successfully!')),
        );
        Navigator.pop(context, true); // true to indicate success and trigger reload
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString().replaceAll('Exception: ', '');
        if (errorMsg.contains('SocketException') || errorMsg.contains('Connection refused') || errorMsg.contains('ClientException')) {
          errorMsg = 'Network error while uploading scan. Please check your connection.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Preview', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    "Processing Prescription...\nExtracting text with OCR...",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 16),
                  ),
                ],
              ),
            )
          : _pictures.isEmpty
              ? Center(child: Text('No image scanned.'))
              : Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Image.file(File(_pictures.first)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _scanDocument,
                            icon: Icon(Icons.refresh),
                            label: Text('Retake', style: GoogleFonts.inter()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _saveScan,
                            icon: Icon(Icons.check),
                            label: Text('Confirm & Save', style: GoogleFonts.inter()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
