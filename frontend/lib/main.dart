import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/login_page.dart';
import 'services/notification_service.dart';
import 'dart:async';
import 'pages/session_gate.dart';
import 'services/auth_service.dart';
import 'services/session_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const PrescriptionScannerApp());
}

class PrescriptionScannerApp extends StatefulWidget {
  const PrescriptionScannerApp({super.key});

  @override
  State<PrescriptionScannerApp> createState() => _PrescriptionScannerAppState();
}

class _PrescriptionScannerAppState extends State<PrescriptionScannerApp>
    with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  Timer? _sessionTimer;
  bool _checkingSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SessionStore.expired.addListener(_onSessionExpired);
    _sessionTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _refreshSession();
      }
    });
  }

  void _onSessionExpired() {
    if (!SessionStore.expired.value) return;
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false,
    );
  }

  Future<void> _refreshSession() async {
    if (_checkingSession) return;
    _checkingSession = true;
    try {
      await AuthService().restoreSession();
    } catch (_) {
      // A network outage must not remove a valid saved session.
    } finally {
      _checkingSession = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshSession();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    SessionStore.expired.removeListener(_onSessionExpired);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'My Medicine Reminder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const SessionGate(),
    );
  }
}
