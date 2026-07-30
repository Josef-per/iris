import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';

class AppAcompanhamentoLinhaTempoDecorator extends StatelessWidget {
  const AppAcompanhamentoLinhaTempoDecorator({
    super.key,
    required this.markerOffsets,
    this.lineLength = 60,
  });

  final List<double> markerOffsets;
  final double lineLength;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _LinhaTempoDecoratorPainter(
          markerOffsets: markerOffsets,
          lineLength: lineLength,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _LinhaTempoDecoratorPainter extends CustomPainter {
  const _LinhaTempoDecoratorPainter({
    required this.markerOffsets,
    required this.lineLength,
  });

  final List<double> markerOffsets;
  final double lineLength;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.lavender
      ..strokeWidth = 1.5;
    final markerPaint = Paint()..color = AppColors.purple;

    for (final offset in markerOffsets) {
      canvas.drawLine(
        Offset(10, offset + 6),
        Offset(10, offset + lineLength),
        linePaint,
      );
      canvas.drawCircle(Offset(10, offset), 5, markerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinhaTempoDecoratorPainter oldDelegate) =>
      oldDelegate.markerOffsets != markerOffsets ||
      oldDelegate.lineLength != lineLength;
}
