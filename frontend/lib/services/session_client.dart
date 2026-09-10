import 'package:http/http.dart' as http;
import 'session_store.dart';

class SessionClient extends http.BaseClient {
  final http.Client _inner;
  SessionClient({http.Client? inner}) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await SessionStore.token();
    request.headers.remove('Authorization');
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    final response = await _inner.send(request);
    if (token != null) {
      if (response.statusCode == 401) {
        await SessionStore.clear(rejectedToken: token);
      } else {
        final renewed = response.headers['x-session-token'];
        if (renewed != null) await SessionStore.renew(token, renewed);
      }
    }
    return response;
  }

  @override
  void close() => _inner.close();
}
