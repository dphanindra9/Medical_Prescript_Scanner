import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'session_client.dart';
import 'session_store.dart';

class AuthService {
  final String _baseUrl = '${ApiService.baseUrl}/auth';

  Future<Map<String, dynamic>> _authenticate(String path, Map<String, String> body) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/$path'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    ).timeout(const Duration(seconds: 15));
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(data['error'] ?? 'Unable to log in');
    }
    final user = Map<String, dynamic>.from(data['user']);
    await SessionStore.save(data['token'] as String, user);
    return user;
  }

  Future<Map<String, dynamic>> signUp(String name, String phoneNumber, String password) =>
      _authenticate('signup', {'name': name, 'phoneNumber': phoneNumber, 'password': password});

  Future<Map<String, dynamic>> login(String phoneNumber, String password) =>
      _authenticate('login', {'phoneNumber': phoneNumber, 'password': password});

  Future<Map<String, dynamic>?> restoreSession() async {
    final token = await SessionStore.token();
    if (token == null) return null;
    if (SessionStore.isExpired(token)) {
      await SessionStore.clear(rejectedToken: token);
      return null;
    }
    final client = SessionClient();
    try {
      final response = await client.get(Uri.parse('$_baseUrl/session'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 401) return null;
      if (response.statusCode != 200) throw Exception('Unable to verify session');
      return Map<String, dynamic>.from(json.decode(response.body)['user']);
    } finally {
      client.close();
    }
  }

  Future<void> logout() => SessionStore.clear();
}
