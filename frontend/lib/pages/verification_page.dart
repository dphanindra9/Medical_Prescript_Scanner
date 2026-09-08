import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'home_page.dart';

class VerificationPage extends StatefulWidget {
  final String phoneNumber;
  final String userName;
  final String password;

  const VerificationPage({super.key, required this.phoneNumber, required this.userName, required this.password});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final TextEditingController _codeController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleVerify() async {
    setState(() => _isLoading = true);
    try {
      // Mock UI validation: just assume 6 digits entered is fine for MVP
      // Send real signup request to backend
      final user = await _authService.signUp(widget.userName, widget.phoneNumber, widget.password);
      
      if (!mounted) return;
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage(
          userId: user['id'],
          userName: user['name'],
          phoneNumber: user['phone_number'],
        )),
        (Route<dynamic> route) => false, // Remove all previous routes
      );
    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.contains('SocketException') || errorMsg.contains('Connection refused') || errorMsg.contains('ClientException')) {
        errorMsg = 'Cannot connect to the server. Please check your network connection.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMsg),
        backgroundColor: Colors.redAccent,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBF3F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF26678C)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 16),
                // Icon
                const Icon(
                  Icons.message_rounded,
                  size: 60,
                  color: Color(0xFF26678C),
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  'Verify Phone',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the 6-digit code sent to\n${widget.phoneNumber.isEmpty ? "your phone" : widget.phoneNumber}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Code Input Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: GoogleFonts.inter(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '------',
                      counterText: '', // Hide the max length counter below the input
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Verify Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26678C),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        'Verify & Create Account',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                ),
                const SizedBox(height: 24),

                // Resend Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code? ",
                      style: GoogleFonts.inter(color: Colors.black54),
                    ),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Verification code resent!')),
                        );
                      },
                      child: Text(
                        'Resend',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF26678C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
