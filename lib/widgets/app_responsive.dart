import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';

class AppResponsive extends StatelessWidget {
  const AppResponsive({
    super.key,
    required this.child,
    this.maxWidth = 1180,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 700;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1000;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < 480
        ? 20.0
        : width < 900
        ? 32.0
        : 48.0;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding:
              padding ??
              EdgeInsets.symmetric(horizontal: horizontal, vertical: 28),
          child: child,
        ),
      ),
    );
  }
}

class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.color = AppColors.white,
    this.borderRadius = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.outline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D28174E),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AppGradientHeader extends StatelessWidget {
  const AppGradientHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 28, 24, 72),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: child,
    );
  }
}
