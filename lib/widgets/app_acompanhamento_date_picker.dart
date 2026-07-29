import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';

class AppAcompanhamentoDatePicker extends StatelessWidget {
  const AppAcompanhamentoDatePicker({super.key});

  // A configuração reproduz a disposição de dias do protótipo estático.
  static final DateTime _selectedDate = DateTime(2026, DateTime.june, 9);

  @override
  Widget build(BuildContext context) {
    final calendarTheme = Theme.of(context).copyWith(
      useMaterial3: false,
      datePickerTheme: DatePickerThemeData(
        weekdayStyle: const TextStyle(
          color: AppColors.deepPurple,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        dayStyle: const TextStyle(
          color: AppColors.ink,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.white;
          }
          return AppColors.ink;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.ink
              : Colors.transparent;
        }),
        dayOverlayColor: const WidgetStatePropertyAll(Colors.transparent),
        dayShape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        todayBorder: BorderSide.none,
      ),
    );

    return Column(
      children: [
        const _AcompanhamentoDatePickerHeader(),
        const SizedBox(height: 1),
        Theme(
          data: calendarTheme,
          child: SizedBox(
            height: 252,
            child: Stack(
              children: [
                AbsorbPointer(
                  child: ClipRect(
                    child: Transform.translate(
                      offset: const Offset(0, -52),
                      child: SizedBox(
                        height: 346,
                        child: CalendarDatePicker(
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035, 12, 31),
                          currentDate: DateTime(2025),
                          onDateChanged: _doNothing,
                        ),
                      ),
                    ),
                  ),
                ),
                const _NextMonthDays(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

void _doNothing(DateTime _) {}

class _AcompanhamentoDatePickerHeader extends StatelessWidget {
  const _AcompanhamentoDatePickerHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: const [
            Icon(Icons.chevron_left, color: AppColors.ink, size: 26),
            Spacer(),
            _DatePickerSelect(label: 'Set'),
            SizedBox(width: 6),
            _DatePickerSelect(label: '2026'),
            Spacer(),
            Icon(Icons.chevron_right, color: AppColors.ink, size: 26),
          ],
        ),
      ),
    );
  }
}

class _DatePickerSelect extends StatelessWidget {
  const _DatePickerSelect({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 89,
      height: 31,
      padding: const EdgeInsets.only(left: 9, right: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.deepPurple),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, color: AppColors.ink, size: 21),
        ],
      ),
    );
  }
}

class _NextMonthDays extends StatelessWidget {
  const _NextMonthDays();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 18,
      bottom: 0,
      left: 18,
      height: 42,
      child: const Row(
        children: [
          Spacer(flex: 3),
          Expanded(child: _NextMonthDay(day: '1')),
          Expanded(child: _NextMonthDay(day: '2')),
          Expanded(child: _NextMonthDay(day: '3')),
          Expanded(child: _NextMonthDay(day: '4')),
        ],
      ),
    );
  }
}

class _NextMonthDay extends StatelessWidget {
  const _NextMonthDay({required this.day});

  final String day;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        day,
        style: const TextStyle(
          color: AppColors.lavender,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
