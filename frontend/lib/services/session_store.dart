import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  static final expired = ValueNotifier<bool>(false);

  static Future<String?> token() async =>
      (await SharedPreferences.getInstance()).getString('jwt_token');

  static bool isExpired(String token, {DateTime? now}) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final claims = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final expiry = claims['exp'];
      return expiry is! num ||
          (now ?? DateTime.now()).millisecondsSinceEpoch >= expiry * 1000;
    } catch (_) {
      return true;
    }
  }

  static Future<void> save(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_user', json.encode(user));
    await prefs.setString('jwt_token', token);
    expired.value = false;
  }

  static Future<void> renew(String previous, String renewed) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('jwt_token') == previous) {
      await prefs.setString('jwt_token', renewed);
    }
  }

  static Future<void> clear({String? rejectedToken}) async {
    final prefs = await SharedPreferences.getInstance();
    if (rejectedToken != null && prefs.getString('jwt_token') != rejectedToken) return;
    await prefs.remove('jwt_token');
    await prefs.remove('session_user');
    expired.value = true;
  }
}
