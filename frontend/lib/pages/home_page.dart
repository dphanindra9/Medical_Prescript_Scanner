import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/prescription.dart';
import 'scanner_page.dart';
import 'profile_page.dart';
import 'prescription_detail_page.dart';
import 'reminder_detail_page.dart';
import '../models/reminder.dart';
import 'add_reminder_page.dart';
import '../widgets/delete_confirmation_dialog.dart';
class HomePage extends StatefulWidget {
  final int userId;
  final String userName;
  final String phoneNumber;
  
  const HomePage({super.key, this.userId = 0, this.userName = 'User', this.phoneNumber = ''});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService apiService = ApiService();
  List<Prescription> prescriptions = [];
  List<Reminder> reminders = [];
  bool isLoading = true;
  bool isLoadingReminders = true;
  bool _deleting = false;
  
  int _currentIndex = 0;
  late String _currentUserName;

  @override
  void initState() {
    super.initState();
    _currentUserName = widget.userName;
    fetchPrescriptions();
    fetchReminders();
  }


  Future<void> fetchReminders() async {
    try {
      final data = await apiService.getReminders();
      if (mounted) {
        setState(() {
          reminders = data;
          isLoadingReminders = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingReminders = false);
    }
  }

  Future<void> fetchPrescriptions() async {
    try {
      final data = await apiService.getPrescriptions(widget.userId);
      if (mounted) {
        setState(() {
          prescriptions = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString().replaceAll('Exception: ', '');
        if (errorMsg.contains('SocketException') || errorMsg.contains('Connection refused') || errorMsg.contains('ClientException')) {
          errorMsg = 'Network error while fetching prescriptions.';
        }
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  Future<void> _confirmAndDelete(String item, Future<void> Function() delete,
      Future<void> Function() refresh) async {
    if (_deleting) return;
    setState(() => _deleting = true);
    try {
      final confirmed = await confirmDeletion(context, item: item);
      if (!confirmed || !mounted) return;
      await delete();
      if (mounted) await refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not delete the item. Please try again.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  String _formatDate(String rawDate) {
    if (rawDate.isEmpty) return 'Unknown Date';
    // If the date is already a string like "2023-09-05", we could parse it.
    // For MVP, we'll try to parse it, otherwise return as is.
    try {
      // Assuming SQLite date or a standard string format. If not, fallback.
      DateTime date = DateTime.parse(rawDate);
      return DateFormat('MMM d').format(date);
    } catch (e) {
      return rawDate;
    }
  }

  String _getMedicinesList(Prescription p) {
    if (p.medicines.isEmpty) return 'No medicines found';
    final names = p.medicines.map((m) => m.name).take(3).join(', ');
    return p.medicines.length > 3 ? '$names...' : names;
  }

  Widget _buildHomeTab(String today) {
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $_currentUserName 👋',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Today, $today',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              labelColor: const Color(0xFF26678C),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF26678C),
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Documents'),
                Tab(text: 'Reminders'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  // --- DOCUMENTS TAB ---
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : prescriptions.isEmpty
                          ? Center(
                              child: Text(
                                "No prescriptions scanned yet.",
                                style: GoogleFonts.inter(fontSize: 16, color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              itemCount: prescriptions.length,
                              itemBuilder: (context, index) {
                            final p = prescriptions[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PrescriptionDetailPage(prescription: p),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
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
                              child: Row(
                                children: [
                                  // Thumbnail Placeholder
                                  Container(
                                    width: 70,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD7B992), // Mockup brownish clipboard color
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 50,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Icon(Icons.receipt_long, color: Colors.grey, size: 30),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _formatDate(p.prescriptionDate.isNotEmpty
                                                    ? p.prescriptionDate
                                                    : p.id.toString()), // Fallback to ID or "Unknown"
                                                style: GoogleFonts.inter(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                                              tooltip: 'Delete prescription',
                                              onPressed: _deleting ? null : () => _confirmAndDelete(
                                                'this prescription',
                                                () => apiService.deletePrescription(p.id),
                                                fetchPrescriptions,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          p.doctorName.isNotEmpty
                                              ? 'Dr. ${p.doctorName}'
                                              : 'Unknown Doctor',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _getMedicinesList(p),
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            );
                          },
                        ),
                  // --- REMINDERS TAB ---
                  isLoadingReminders
                      ? const Center(child: CircularProgressIndicator())
                      : reminders.isEmpty
                          ? Center(
                              child: Text("No reminders for today.", style: GoogleFonts.inter(fontSize: 16, color: Colors.grey)),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              itemCount: reminders.length,
                              itemBuilder: (context, index) {
                                final r = reminders[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ReminderDetailPage(
                                          reminder: r,
                                          onUpdated: fetchReminders,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(r.medicineName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                                                  IconButton(
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                                    tooltip: 'Delete reminder',
                                                    onPressed: _deleting ? null : () => _confirmAndDelete(
                                                      'the reminder for "${r.medicineName}"',
                                                      () => apiService.deleteReminder(r.id),
                                                      fetchReminders,
                                                    ),
                                                  )
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text('Timings: ${r.timings.join(', ')}', style: GoogleFonts.inter(color: Colors.black54, fontSize: 13)),
                                              const SizedBox(height: 4),
                                              Text('Days: ${r.days.join(', ')}', style: GoogleFonts.inter(color: Colors.black54, fontSize: 13)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.document_scanner, color: Color(0xFF26678C)),
              title: Text('Scan Prescription', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ScannerPage(userId: widget.userId)),
                );
                if (result == true) fetchPrescriptions();
              },
            ),
            ListTile(
              leading: const Icon(Icons.alarm_add, color: Color(0xFF26678C)),
              title: Text('Add Medicine Reminder', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddReminderPage()),
                );
                if (result == true) fetchReminders();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('MMM d').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFEBF3F9), // Light blue-grey background
      body: _currentIndex == 0 
          ? _buildHomeTab(today)
          : ProfilePage(
              initialName: _currentUserName,
              phoneNumber: widget.phoneNumber,
              onNameChanged: (newName) {
                setState(() {
                  _currentUserName = newName;
                });
              },
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        height: 65,
        width: 65,
        margin: const EdgeInsets.only(top: 30),
        child: FloatingActionButton(
          onPressed: _showAddOptions,
          backgroundColor: const Color(0xFF26678C),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.add, size: 35, color: Colors.white),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        elevation: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home, color: _currentIndex == 0 ? const Color(0xFF26678C) : Colors.grey),
                    Text('Home', style: GoogleFonts.inter(fontSize: 10, color: _currentIndex == 0 ? const Color(0xFF26678C) : Colors.grey, fontWeight: _currentIndex == 0 ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 30),
                child: GestureDetector(
                  onTap: () {
                    // MVP: Could navigate to scanner directly, or just stay as visual element.
                    // The FAB handles the scanner already.
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.center_focus_strong, color: Colors.grey),
                      Text('Scanner', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 40), // Empty space for FAB
              GestureDetector(
                onTap: () {
                  // History mock
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history, color: Colors.grey),
                    Text('History', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 1), // Index 1 is Profile
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline, color: _currentIndex == 1 ? const Color(0xFF26678C) : Colors.grey),
                    Text('Profile', style: GoogleFonts.inter(fontSize: 10, color: _currentIndex == 1 ? const Color(0xFF26678C) : Colors.grey, fontWeight: _currentIndex == 1 ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
