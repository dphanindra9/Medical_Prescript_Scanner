import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final String initialName;
  final String phoneNumber;
  final ValueChanged<String> onNameChanged;

  const ProfilePage({
    super.key,
    required this.initialName,
    required this.phoneNumber,
    required this.onNameChanged,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  void _handleSave() {
    widget.onNameChanged(_nameController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
  }

  void _handleChangePassword() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Change Password',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Old Password',
                  labelStyle: GoogleFonts.inter(color: Colors.black54),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF26678C)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF26678C))),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: GoogleFonts.inter(color: Colors.black54),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF26678C)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF26678C))),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: GoogleFonts.inter(color: Colors.black54),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF26678C)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF26678C))),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password updated successfully!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF26678C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Update', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (enabled)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: GoogleFonts.inter(
              color: enabled ? Colors.black87 : Colors.black54,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: enabled ? const Color(0xFF26678C) : Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            // Header
            Text(
              'My Profile',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 32),
            
            // Avatar Placeholder
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.person, size: 50, color: Color(0xFF26678C)),
              ),
            ),
            const SizedBox(height: 32),

            // Form
            _buildTextField(
              controller: _nameController,
              label: 'User Name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: TextEditingController(text: widget.phoneNumber.isEmpty ? 'Not Provided' : widget.phoneNumber),
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              enabled: false,
            ),
            const SizedBox(height: 32),

            // Change Password Button
            OutlinedButton.icon(
              onPressed: _handleChangePassword,
              icon: const Icon(Icons.lock_outline, color: Color(0xFF26678C)),
              label: Text(
                'Change Password',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF26678C),
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFF26678C), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Save Button
            ElevatedButton(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF26678C),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: Text(
                'Save Changes',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Logout Button
            TextButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: Text(
                'Logout',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
