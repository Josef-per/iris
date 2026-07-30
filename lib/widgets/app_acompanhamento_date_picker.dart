import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';

class AppAcompanhamentoDatePicker extends StatefulWidget {
  const AppAcompanhamentoDatePicker({super.key});

  @override
  State<AppAcompanhamentoDatePicker> createState() =>
      _AppAcompanhamentoDatePickerState();
}

class _AppAcompanhamentoDatePickerState
    extends State<AppAcompanhamentoDatePicker> {
  static final _firstDate = DateTime(2020);
  static final _lastDate = DateTime(2035, 12, 31);
  static const _dayCellSize = 42.0;
  static const _calendarHorizontalPadding = 8.0;

  late DateTime _selectedDate;
  late DateTime _displayedMonth;
  late DateTime _calendarAnchorDate;
  var _calendarVersion = 0;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(2026, DateTime.september, 9);
    _displayedMonth = DateTime(2026, DateTime.september);
    _calendarAnchorDate = _selectedDate;
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _displayedMonth = DateTime(date.year, date.month);
    });
  }

  void _changeMonth(int offset) {
    final month = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + offset,
    );

    if (month.isBefore(_firstDate) || month.isAfter(_lastDate)) {
      return;
    }

    setState(() {
      _displayedMonth = month;
      _calendarAnchorDate = month;
      _calendarVersion++;
    });
  }

  void _handleDisplayedMonthChanged(DateTime month) {
    final displayedMonth = DateTime(month.year, month.month);
    if (DateUtils.isSameMonth(displayedMonth, _displayedMonth)) {
      return;
    }

    setState(() => _displayedMonth = displayedMonth);
  }

  int _visibleWeekCount(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final firstDayOffset = DateUtils.firstDayOffset(
      _displayedMonth.year,
      _displayedMonth.month,
      localizations,
    );
    final daysInMonth = DateUtils.getDaysInMonth(
      _displayedMonth.year,
      _displayedMonth.month,
    );

    return (firstDayOffset + daysInMonth + DateTime.daysPerWeek - 1) ~/
        DateTime.daysPerWeek;
  }

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
        // The visual selection is drawn in _SelectedDayOverlay so it keeps
        // the square dimensions of the Figma reference independently of the
        // Material DatePicker's internal selection state.
        dayForegroundColor: const WidgetStatePropertyAll(AppColors.ink),
        dayBackgroundColor: const WidgetStatePropertyAll(Colors.transparent),
        dayOverlayColor: const WidgetStatePropertyAll(Colors.transparent),
        dayShape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        todayBorder: BorderSide.none,
      ),
    );
    final calendarHeight = _dayCellSize * (_visibleWeekCount(context) + 1);

    return Column(
      children: [
        _AcompanhamentoDatePickerHeader(
          month: _displayedMonth,
          onPreviousMonth: () => _changeMonth(-1),
          onNextMonth: () => _changeMonth(1),
        ),
        const SizedBox(height: 1),
        Theme(
          data: calendarTheme,
          child: SizedBox(
            height: calendarHeight,
            child: Stack(
              children: [
                ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    minHeight: 346,
                    maxHeight: 346,
                    child: Transform.translate(
                      offset: const Offset(0, -52),
                      child: SizedBox(
                        height: 346,
                        child: CalendarDatePicker(
                          key: ValueKey(_calendarVersion),
                          initialDate: _calendarAnchorDate,
                          firstDate: _firstDate,
                          lastDate: _lastDate,
                          currentDate: DateTime(2025),
                          onDateChanged: _selectDate,
                          onDisplayedMonthChanged: _handleDisplayedMonthChanged,
                        ),
                      ),
                    ),
                  ),
                ),
                _SelectedDayOverlay(
                  selectedDate: _selectedDate,
                  displayedMonth: _displayedMonth,
                  dayCellSize: _dayCellSize,
                  horizontalPadding: _calendarHorizontalPadding,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AcompanhamentoDatePickerHeader extends StatelessWidget {
  const _AcompanhamentoDatePickerHeader({
    required this.month,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final DateTime month;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            _MonthNavigationButton(
              icon: Icons.chevron_left,
              onPressed: onPreviousMonth,
            ),
            const Spacer(),
            _DatePickerSelect(label: _shortMonthLabel(month.month)),
            const SizedBox(width: 6),
            _DatePickerSelect(label: '${month.year}'),
            const Spacer(),
            _MonthNavigationButton(
              icon: Icons.chevron_right,
              onPressed: onNextMonth,
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthNavigationButton extends StatelessWidget {
  const _MonthNavigationButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 26,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 26, height: 26),
        icon: Icon(icon, color: AppColors.ink, size: 26),
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

class _SelectedDayOverlay extends StatelessWidget {
  const _SelectedDayOverlay({
    required this.selectedDate,
    required this.displayedMonth,
    required this.dayCellSize,
    required this.horizontalPadding,
  });

  final DateTime selectedDate;
  final DateTime displayedMonth;
  final double dayCellSize;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    if (!DateUtils.isSameMonth(selectedDate, displayedMonth)) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final localizations = MaterialLocalizations.of(context);
            final firstDayOffset = DateUtils.firstDayOffset(
              selectedDate.year,
              selectedDate.month,
              localizations,
            );
            final dayIndex = firstDayOffset + selectedDate.day - 1;
            final column = dayIndex % DateTime.daysPerWeek;
            final row = dayIndex ~/ DateTime.daysPerWeek + 1;
            final cellWidth =
                (constraints.maxWidth - horizontalPadding * 2) /
                DateTime.daysPerWeek;
            final squareSize = dayCellSize;

            return Stack(
              children: [
                Positioned(
                  left:
                      horizontalPadding +
                      column * cellWidth +
                      (cellWidth - squareSize) / 2,
                  top: row * dayCellSize,
                  width: squareSize,
                  height: squareSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${selectedDate.day}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _shortMonthLabel(int month) {
  const labels = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];
  return labels[month - 1];
}
