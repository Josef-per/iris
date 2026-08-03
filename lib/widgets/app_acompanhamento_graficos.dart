import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';

class AppAcompanhamentoGraficos extends StatelessWidget {
  const AppAcompanhamentoGraficos({super.key, required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final weekStart = _startOfWeek(selectedDate);
    final weekDays = List<DateTime>.generate(
      DateTime.daysPerWeek,
      (index) => weekStart.add(Duration(days: index)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AcompanhamentoGraficoCard(
          title: 'Gráfico de Humor',
          levelLabels: const ['MB', 'B', 'N', 'M', 'MM'],
          values: const [],
          weekDays: weekDays,
        ),
        const SizedBox(height: 20),
        _AcompanhamentoGraficoCard(
          title: 'Gráfico de Alimentação',
          levelLabels: const ['MB', 'B', 'N', 'R', 'MR'],
          values: const [],
          weekDays: weekDays,
          withAreaFill: true,
        ),
      ],
    );
  }
}

class _AcompanhamentoGraficoCard extends StatelessWidget {
  const _AcompanhamentoGraficoCard({
    required this.title,
    required this.levelLabels,
    required this.values,
    required this.weekDays,
    this.withAreaFill = false,
  });

  final String title;
  final List<String> levelLabels;
  final List<double> values;
  final List<DateTime> weekDays;
  final bool withAreaFill;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 256,
      padding: const EdgeInsets.fromLTRB(12, 11, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F28174E),
            blurRadius: 7,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: values.isEmpty
                ? const Center(
                    child: Text(
                      'Sem dados registrados nesta semana.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                : CustomPaint(
                    painter: _AcompanhamentoLineChartPainter(
                      levelLabels: levelLabels,
                      values: values,
                      weekDays: weekDays,
                      withAreaFill: withAreaFill,
                    ),
                    child: const SizedBox.expand(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AcompanhamentoLineChartPainter extends CustomPainter {
  const _AcompanhamentoLineChartPainter({
    required this.levelLabels,
    required this.values,
    required this.weekDays,
    required this.withAreaFill,
  });

  final List<String> levelLabels;
  final List<double> values;
  final List<DateTime> weekDays;
  final bool withAreaFill;

  @override
  void paint(Canvas canvas, Size size) {
    const labelStyle = TextStyle(
      color: AppColors.ink,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
    final chartRect = Rect.fromLTRB(31, 24, size.width, size.height - 40);
    final gridPaint = Paint()
      ..color = AppColors.deepPurple.withValues(alpha: .72)
      ..strokeWidth = 1;

    for (var index = 0; index < levelLabels.length; index++) {
      final y =
          chartRect.top + chartRect.height * index / (levelLabels.length - 1);
      _paintDashedLine(
        canvas,
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
      _paintLabel(canvas, levelLabels[index], labelStyle, Offset(0, y - 9));
    }

    final points = <Offset>[
      for (var index = 0; index < values.length; index++)
        Offset(
          chartRect.left + chartRect.width * index / (values.length - 1),
          chartRect.bottom - chartRect.height * values[index] / 4,
        ),
    ];
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }

    if (withAreaFill) {
      final fillPath = Path.from(linePath)
        ..lineTo(points.last.dx, chartRect.bottom)
        ..lineTo(points.first.dx, chartRect.bottom)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.lavender.withValues(alpha: .72),
              AppColors.lavender.withValues(alpha: 0),
            ],
          ).createShader(chartRect),
      );
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = withAreaFill ? AppColors.lavender : AppColors.purple
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    for (var index = 0; index < weekDays.length; index++) {
      _paintCenteredLabel(
        canvas,
        _formatDayLabel(weekDays[index]),
        labelStyle,
        Offset(points[index].dx, chartRect.bottom + 28),
      );
    }
  }

  void _paintDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 3.0;
    const dashSpace = 4.0;
    var x = start.dx;
    while (x < end.dx) {
      canvas.drawLine(
        Offset(x, start.dy),
        Offset(x + dashWidth, start.dy),
        paint,
      );
      x += dashWidth + dashSpace;
    }
  }

  void _paintLabel(Canvas canvas, String text, TextStyle style, Offset offset) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, offset);
  }

  void _paintCenteredLabel(
    Canvas canvas,
    String text,
    TextStyle style,
    Offset center,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - (textPainter.width / 2), center.dy),
    );
  }

  @override
  bool shouldRepaint(covariant _AcompanhamentoLineChartPainter oldDelegate) =>
      oldDelegate.levelLabels != levelLabels ||
      oldDelegate.values != values ||
      oldDelegate.weekDays != weekDays ||
      oldDelegate.withAreaFill != withAreaFill;
}

DateTime _startOfWeek(DateTime date) {
  final dateOnly = DateTime(date.year, date.month, date.day);
  return dateOnly.subtract(Duration(days: dateOnly.weekday - DateTime.monday));
}

String _formatDayLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month';
}
