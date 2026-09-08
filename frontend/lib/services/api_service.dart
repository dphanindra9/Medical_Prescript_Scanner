import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prescription.dart';

class ApiService {
  // Use 10.0.2.2 for Emulator, 127.0.0.1 for iOS Sim / ADB reversed Physical device
  static const String baseUrl = 'http://127.0.0.1:3000/api';

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return {
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Prescription>> getPrescriptions(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/prescriptions?user_id=$userId'),
      headers: await _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Prescription.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load prescriptions');
    }
  }

  Future<Prescription> getPrescriptionById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/prescriptions/$id'),
      headers: await _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      return Prescription.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load prescription');
    }
  }

  Future<void> deletePrescription(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/prescriptions/$id'),
      headers: await _getAuthHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete prescription');
    }
  }

  Future<Prescription?> uploadPrescriptionScan(File imageFile, int userId) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/prescriptions/scan'));
    request.headers.addAll(await _getAuthHeaders());
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    request.fields['user_id'] = userId.toString();

    var response = await request.send();

    if (response.statusCode == 201) {
      var responseData = await response.stream.bytesToString();
      var jsonData = json.decode(responseData);
      
      // The API returns the saved data in data field. However we might need to fetch it by ID to get full structure
      // Let's just return a basic representation for now
      return Prescription.fromJson(jsonData['data']);
    } else {
      throw Exception('Failed to upload image');
    }
  }
}
