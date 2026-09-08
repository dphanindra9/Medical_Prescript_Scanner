import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart'; // To reuse baseUrl

class AuthService {
  final String _baseUrl = '${ApiService.baseUrl.replaceAll('/api', '/api/auth')}';

  Future<Map<String, dynamic>> signUp(String name, String phoneNumber, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'phoneNumber': phoneNumber,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      final token = responseData['token'];
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
      }
      return responseData['user'];
    } else {
      throw Exception(json.decode(response.body)['error'] ?? 'Failed to sign up');
    }
  }

  Future<Map<String, dynamic>> login(String phoneNumber, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'phoneNumber': phoneNumber,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final token = responseData['token'];
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
      }
      return responseData['user'];
    } else {
      throw Exception(json.decode(response.body)['error'] ?? 'Failed to log in');
    }
  }
}
