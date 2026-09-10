import 'package:flutter/material.dart';
import '../widgets/delete_confirmation_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../services/notification_service.dart';

import '../models/reminder.dart';

class AddReminderPage extends StatefulWidget {
  final Reminder? reminder;
  const AddReminderPage({super.key, this.reminder});

  @override
  State<AddReminderPage> createState() => _AddReminderPageState();
}

class _AddReminderPageState extends State<AddReminderPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _countController = TextEditingController();
  
  List<TimeOfDay> _selectedTimes = [];
  final List<String> _daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _selectedDays = [];

  bool _isIdentifying = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.reminder != null) {
      _nameController.text = widget.reminder!.medicineName;
      _countController.text = widget.reminder!.pillCount.toString();
      _selectedDays.addAll(widget.reminder!.days);
      
      for (final timeStr in widget.reminder!.timings) {
        final parts = timeStr.split(':');
        if (parts.length == 2) {
          _selectedTimes.add(TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          ));
        }
      }
    }
  }

  Future<void> _identifyFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() => _isIdentifying = true);
      try {
        final result = await _apiService.identifyMedicineImage(File(pickedFile.path));
        if (result['error'] == true) {
          _showError(result['message'] ?? 'Image not clear.');
        } else {
          setState(() {
            _nameController.text = result['name'] ?? '';
          });
        }
      } catch (e) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      } finally {
        setState(() => _isIdentifying = false);
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _pickTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null && !_selectedTimes.contains(time)) {
      setState(() {
        _selectedTimes.add(time);
      });
    }
  }

  void _toggleDay(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  Future<void> _saveReminder() async {
    final name = _nameController.text.trim();
    final countText = _countController.text.trim();

    if (name.isEmpty) {
      _showError('Please enter a medicine name');
      return;
    }
    if (_selectedTimes.isEmpty) {
      _showError('Please add at least one timing');
      return;
    }
    if (_selectedDays.isEmpty) {
      _showError('Please select at least one day');
      return;
    }

    int count = int.tryParse(countText) ?? 0;
    
    // Format times
    List<String> timingsStr = _selectedTimes.map((t) {
      final hour = t.hour.toString().padLeft(2, '0');
      final min = t.minute.toString().padLeft(2, '0');
      return '$hour:$min';
    }).toList();

    setState(() => _isSaving = true);
    try {
      Reminder savedReminder;
      if (widget.reminder != null) {
        // Edit mode
        savedReminder = await _apiService.updateReminder(widget.reminder!.id, name, count, timingsStr, _selectedDays);
        // Cancel old notifications
        for (var i = 0; i < widget.reminder!.timings.length; i++) {
           await NotificationService().cancelReminder(int.parse('${widget.reminder!.id}$i'));
        }
      } else {
        // Add mode
        savedReminder = await _apiService.addReminder(name, count, timingsStr, _selectedDays);
      }
      
      // Schedule notifications for each new time
      for (var i = 0; i < _selectedTimes.length; i++) {
        final time = _selectedTimes[i];
        final notifId = int.parse('${savedReminder.id}$i'); 
        await NotificationService().scheduleMedicineReminder(
          notifId,
          name,
          time.hour,
          time.minute,
        );
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to refresh list
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
      setState(() => _isSaving = false);
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
        title: Text(widget.reminder != null ? 'Edit Reminder' : 'Add Reminder', style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medicine Name
            Text('Medicine Name', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. Paracetamol 500mg',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                suffixIcon: _isIdentifying
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : IconButton(
                        icon: const Icon(Icons.camera_alt, color: Color(0xFF26678C)),
                        onPressed: _identifyFromCamera,
                        tooltip: 'Scan Medicine Label',
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Pill Count
            Text('Pill Count (Inventory)', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _countController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g. 30',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            // Timings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Timings', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                TextButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.add_alarm, color: Color(0xFF26678C)),
                  label: Text('Add Time', style: GoogleFonts.inter(color: const Color(0xFF26678C))),
                ),
              ],
            ),
            if (_selectedTimes.isNotEmpty)
              Wrap(
                spacing: 8,
                children: _selectedTimes.map((time) {
                  return Chip(
                    label: Text(time.format(context), style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                    onDeleted: () async {
                      final confirmed = await confirmDeletion(context,
                        item: 'the ${time.format(context)} reminder time');
                      if (!confirmed || !mounted) return;
                      setState(() {
                        _selectedTimes.remove(time);
                      });
                    },
                    backgroundColor: Colors.white,
                  );
                }).toList(),
              )
            else
              Text('No times added yet', style: GoogleFonts.inter(color: Colors.grey)),
            
            const SizedBox(height: 24),

            // Days of week
            Text('Days to Take', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _daysOfWeek.map((day) {
                final isSelected = _selectedDays.contains(day);
                return GestureDetector(
                  onTap: () => _toggleDay(day),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF26678C) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? const Color(0xFF26678C) : Colors.grey.shade300),
                    ),
                    child: Text(
                      day,
                      style: GoogleFonts.inter(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF26678C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _saveReminder,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Save Reminder', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
