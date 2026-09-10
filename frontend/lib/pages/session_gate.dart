import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import 'login_page.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late Future<Map<String, dynamic>?> _session;

  @override
  void initState() {
    super.initState();
    _session = AuthService().restoreSession();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>?>(
    future: _session,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return Scaffold(body: Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Cannot connect. Check your connection and try again.'),
            TextButton(
              onPressed: () => setState(() => _session = AuthService().restoreSession()),
              child: const Text('Retry'),
            ),
          ],
        )));
      }
      final user = snapshot.data;
      if (user == null) return const LoginPage();
      return HomePage(userId: user['id'], userName: user['name'] ?? '',
        phoneNumber: user['phone_number'] ?? '');
    },
  );
}
