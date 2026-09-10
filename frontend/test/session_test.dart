import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/session_client.dart';
import 'package:frontend/services/session_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SessionStore.save('original-token', {'id': 1, 'name': 'Test'});
  });

  test('requests use the saved token and persist a renewed token', () async {
    final client = SessionClient(inner: MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer original-token');
      return http.Response('{}', 200, headers: {'x-session-token': 'renewed-token'});
    }));
    await client.get(Uri.parse('http://localhost/session'));
    expect(await SessionStore.token(), 'renewed-token');
    expect(SessionStore.expired.value, false);
    client.close();
  });

  test('expired session clears token and signals login', () async {
    final client = SessionClient(inner: MockClient((_) async => http.Response('{}', 401)));
    await client.get(Uri.parse('http://localhost/session'));
    expect(await SessionStore.token(), isNull);
    expect((await SharedPreferences.getInstance()).getString('session_user'), isNull);
    expect(SessionStore.expired.value, true);
    client.close();
  });

  test('network failure retains saved session', () async {
    final client = SessionClient(inner: MockClient((_) async => throw const SocketException('offline')));
    await expectLater(client.get(Uri.parse('http://localhost/session')), throwsA(isA<SocketException>()));
    expect(await SessionStore.token(), 'original-token');
    expect(SessionStore.expired.value, false);
    client.close();
  });

  test('a late response cannot overwrite or clear a newer login', () async {
    await SessionStore.save('new-login', {'id': 2});
    await SessionStore.renew('original-token', 'stale-renewal');
    await SessionStore.clear(rejectedToken: 'original-token');
    expect(await SessionStore.token(), 'new-login');
    expect(SessionStore.expired.value, false);
  });

  test('logout clears saved credentials', () async {
    await SessionStore.clear();
    expect(await SessionStore.token(), isNull);
    expect(SessionStore.expired.value, true);
  });

  test('expiry is detected at the exact boundary, even without a connection', () {
    final expiry = DateTime.utc(2026, 9, 30);
    final payload = base64Url.encode(utf8.encode(json.encode({
      'exp': expiry.millisecondsSinceEpoch ~/ 1000,
    })));
    final token = 'header.$payload.signature';
    expect(SessionStore.isExpired(token, now: expiry.subtract(const Duration(seconds: 1))), false);
    expect(SessionStore.isExpired(token, now: expiry), true);
    expect(SessionStore.isExpired('broken'), true);
  });
}
