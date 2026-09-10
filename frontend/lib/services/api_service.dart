import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prescription.dart';
import '../models/reminder.dart';
import 'session_client.dart';

class ApiService {
  static final http.Client _client = SessionClient();
  // Override API_BASE_URL with the computer's LAN address for a physical phone.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return {
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Prescription>> getPrescriptions(int userId) async {
    final response = await _client.get(
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
    final response = await _client.get(
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
    final response = await _client.delete(
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

    var response = await _client.send(request);

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

  // --- Reminders API ---

  Future<({Reminder reminder, bool notifyLowStock})> setDoseTaken(
    int id, String date, String time, bool taken,
  ) async {
    final headers = await _getAuthHeaders();
    headers['Content-Type'] = 'application/json';
    final response = await _client.put(
      Uri.parse('$baseUrl/reminders/$id/dose'),
      headers: headers,
      body: json.encode({'date': date, 'time': time, 'taken': taken}),
    ).timeout(const Duration(seconds: 15));
    final data = json.decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Failed to update inventory');
    }
    return (
      reminder: Reminder.fromJson(data['reminder']),
      notifyLowStock: data['notify_low_stock'] == true,
    );
  }

  Future<List<Reminder>> getReminders() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/reminders'),
      headers: await _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Reminder.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load reminders');
    }
  }

  Future<Reminder> addReminder(String name, int count, List<String> timings, List<String> days) async {
    final headers = await _getAuthHeaders();
    headers['Content-Type'] = 'application/json';

    final response = await _client.post(
      Uri.parse('$baseUrl/reminders'),
      headers: headers,
      body: json.encode({
        'medicine_name': name,
        'pill_count': count,
        'timings': timings,
        'days': days,
      }),
    );

    if (response.statusCode == 201) {
      final jsonResponse = json.decode(response.body);
      return Reminder.fromJson(jsonResponse['reminder']);
    } else {
      throw Exception('Failed to add reminder');
    }
  }

  Future<Reminder> updateReminder(int id, String name, int count, List<String> timings, List<String> days) async {
    final headers = await _getAuthHeaders();
    headers['Content-Type'] = 'application/json';

    final response = await _client.put(
      Uri.parse('$baseUrl/reminders/$id'),
      headers: headers,
      body: json.encode({
        'medicine_name': name,
        'pill_count': count,
        'timings': timings,
        'days': days,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return Reminder.fromJson(jsonResponse['reminder']);
    } else {
      throw Exception('Failed to update reminder');
    }
  }

  Future<void> deleteReminder(int id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/reminders/$id'),
      headers: await _getAuthHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete reminder');
    }
  }

  Future<Map<String, dynamic>> identifyMedicineImage(File imageFile) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/reminders/identify'));
    request.headers.addAll(await _getAuthHeaders());
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    var response = await _client.send(request);
    var responseData = await response.stream.bytesToString();
    var jsonData = json.decode(responseData);

    if (response.statusCode == 200) {
      return jsonData;
    } else {
      throw Exception(jsonData['message'] ?? 'Failed to identify image');
    }
  }
}
