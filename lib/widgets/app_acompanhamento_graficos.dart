import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';

class AppAcompanhamentoGraficos extends StatelessWidget {
  const AppAcompanhamentoGraficos({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AcompanhamentoGraficoCard(
          title: 'Gráfico de Humor',
          levelLabels: ['MB', 'B', 'N', 'M', 'MM'],
          values: <double>[0, 2, 1, 3, 2, 4, 1],
        ),
        SizedBox(height: 20),
        _AcompanhamentoGraficoCard(
          title: 'Gráfico de Alimentação',
          levelLabels: ['MB', 'B', 'N', 'R', 'MR'],
          values: <double>[0, 2, 1, 3, 2, 4, 1],
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
    this.withAreaFill = false,
  });

  final String title;
  final List<String> levelLabels;
  final List<double> values;
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
            child: CustomPaint(
              painter: _AcompanhamentoLineChartPainter(
                levelLabels: levelLabels,
                values: values,
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
    required this.withAreaFill,
  });

  final List<String> levelLabels;
  final List<double> values;
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

    const dateLabels = ['01/09', '03/09', '05/09', '07/09'];
    const dateIndexes = [0, 2, 4, 6];
    for (var index = 0; index < dateLabels.length; index++) {
      final x = points[dateIndexes[index]].dx;
      _paintLabel(
        canvas,
        dateLabels[index],
        labelStyle,
        Offset(x - 18, chartRect.bottom + 28),
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

  @override
  bool shouldRepaint(covariant _AcompanhamentoLineChartPainter oldDelegate) =>
      oldDelegate.levelLabels != levelLabels ||
      oldDelegate.values != values ||
      oldDelegate.withAreaFill != withAreaFill;
}
