import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../models/reminder.dart';
import '../services/notification_service.dart';
import 'add_reminder_page.dart';

class ReminderDetailPage extends StatefulWidget {
  final Reminder reminder;
  final VoidCallback onUpdated;

  const ReminderDetailPage({super.key, required this.reminder, required this.onUpdated});

  @override
  State<ReminderDetailPage> createState() => _ReminderDetailPageState();
}

class _ReminderDetailPageState extends State<ReminderDetailPage> {
  late Reminder _reminder;
  Timer? _minuteTimer;
  Map<String, bool> _takenStatus = {};
  bool _savingDose = false;
  
  late DateTime _selectedDate;
  late DateTime _startDate;
  late List<DateTime> _weekDates;

  @override
  void initState() {
    super.initState();
    _reminder = widget.reminder;
    final now = DateTime.now();
    final created = DateTime.tryParse(_reminder.createdAt)?.toLocal() ?? now;
    _startDate = DateTime(created.year, created.month, created.day);
    _selectedDate = DateTime(now.year, now.month, now.day);
    if (_selectedDate.isBefore(_startDate)) _selectedDate = _startDate;
    _generateWeekDates();
    _loadTakenStatus();
    
    _minuteTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _minuteTimer?.cancel();
    super.dispose();
  }

  void _generateWeekDates() {
    // Hide dates before this medicine was added.
    final currentDayOfWeek = _selectedDate.weekday; // 1 = Mon, 7 = Sun
    final monday = _selectedDate.subtract(Duration(days: currentDayOfWeek - 1));
    
    _weekDates = List.generate(7, (index) =>
      DateTime(monday.year, monday.month, monday.day + index))
        .where((date) => !date.isBefore(_startDate)).toList();
  }

  void _loadTakenStatus() {
    _takenStatus = Map<String, bool>.from(_reminder.takenDoses);
  }

  Future<void> _toggleTaken(String time, int indexInReminder) async {
    if (_savingDose || _selectedDate.isBefore(_startDate)) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final key = '${dateStr}_$time';
    final newStatus = !(_takenStatus[key] ?? false);
    final isToday = _isToday(_selectedDate);
    setState(() => _savingDose = true);
    try {
      final result = await ApiService().setDoseTaken(_reminder.id, dateStr, time, newStatus);
      if (mounted) {
        setState(() {
          _reminder = result.reminder;
          _loadTakenStatus();
        });
        widget.onUpdated();
      }
      try {
        if (result.notifyLowStock) {
          await NotificationService().showLowStockNotification(
            result.reminder.id, result.reminder.medicineName, result.reminder.pillCount,
          );
        }
        if (newStatus && isToday) {
          await NotificationService().cancelReminder(int.parse('${_reminder.id}$indexInReminder'));
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Inventory saved, but notifications could not be updated.'),
          ));
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ));
      }
    } finally {
      if (mounted) setState(() => _savingDose = false);
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isTimeUnlocked(String timeStr, DateTime selectedDate) {
    if (selectedDate.isBefore(_startDate)) return false;
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      final now = DateTime.now();
      
      // If it's a past date, it's always unlocked
      if (selectedDate.year < now.year || 
         (selectedDate.year == now.year && selectedDate.month < now.month) ||
         (selectedDate.year == now.year && selectedDate.month == now.month && selectedDate.day < now.day)) {
        return true;
      }
      
      // If it's a future date, it's locked
      if (selectedDate.year > now.year || 
         (selectedDate.year == now.year && selectedDate.month > now.month) ||
         (selectedDate.year == now.year && selectedDate.month == now.month && selectedDate.day > now.day)) {
        return false;
      }
      
      // If it's today, check the exact time
      final targetTime = DateTime(now.year, now.month, now.day, hour, minute);
      final unlockTime = targetTime.subtract(const Duration(minutes: 10));
      return now.isAfter(unlockTime) || now.isAtSameMomentAs(unlockTime);
    } catch (e) {
      return false;
    }
  }

  bool _isScheduledForSelectedDay() {
    if (_selectedDate.isBefore(_startDate)) return false;
    final dayName = DateFormat('E').format(_selectedDate); // 'Mon', 'Tue', etc.
    return _reminder.days.contains(dayName);
  }

  Future<void> _editReminder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddReminderPage(reminder: _reminder)),
    );
    
    if (result == true && mounted) {
      widget.onUpdated(); // Refresh parent list
      Navigator.pop(context); // Close details page so user can open it again fresh
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBF3F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEBF3F9),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text('Medicine Details', style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF26678C)),
            onPressed: _editReminder,
          ),
        ],
      ),
      body: Column(
        children: [
          // Medicine Header Info
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _reminder.medicineName,
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  'Inventory: ${_reminder.pillCount} pills left',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: _reminder.timings.map((t) => Chip(
                    label: Text(t, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF26678C))),
                    backgroundColor: const Color(0xFFEBF3F9),
                    side: BorderSide.none,
                  )).toList(),
                )
              ],
            ),
          ),

          // Weekly Calendar View
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _weekDates.map((date) {
                final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
                final dayName = DateFormat('E').format(date).substring(0, 1); // M, T, W...
                final dayNum = date.day.toString();

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  child: Container(
                    width: 42,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF26678C) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? const Color(0xFF26678C) : Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Text(
                          dayName,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isSelected ? Colors.white70 : Colors.black54,
                            fontWeight: FontWeight.w500
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dayNum,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 32),

          // Checkboxes for the selected day
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Schedule for ${DateFormat('EEEE, MMM d').format(_selectedDate)}',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  
                  if (!_isScheduledForSelectedDay())
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Text(
                          "No medicines scheduled for this day.",
                          style: GoogleFonts.inter(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _reminder.timings.length,
                        itemBuilder: (context, index) {
                          final time = _reminder.timings[index];
                          final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
                          final key = '${dateStr}_$time';
                          final isTaken = _takenStatus[key] ?? false;
                          final isUnlocked = _isTimeUnlocked(time, _selectedDate);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FBFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isTaken,
                                  onChanged: isUnlocked && !_savingDose ? (val) => _toggleTaken(time, index) : null,
                                  activeColor: const Color(0xFF26678C),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    time,
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: isUnlocked ? Colors.black87 : Colors.grey,
                                      decoration: isTaken ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ),
                                if (!isUnlocked)
                                  const Icon(Icons.lock_clock, color: Colors.grey),
                                if (isTaken)
                                  const Icon(Icons.check_circle, color: Color(0xFF26678C)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
