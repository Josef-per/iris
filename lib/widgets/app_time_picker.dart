import 'package:flutter/material.dart';

class AppTimePicker extends StatefulWidget {
  const AppTimePicker({super.key});

  @override
  State<AppTimePicker> createState() => _AppTimePicker();
}

class _AppTimePicker extends State<AppTimePicker> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 12, minute: 20);

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      initialEntryMode: TimePickerEntryMode.inputOnly,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: _pickTime,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF8A72D6)),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Text(
              _selectedTime.format(context),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF28174E),
              ),
            ),

            const Spacer(),

            const Icon(Icons.access_time_outlined, color: Color(0xFF8A72D6)),
          ],
        ),
      ),
    );
  }
}
