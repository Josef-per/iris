import 'package:flutter/material.dart';

class AppIconsButtons extends StatelessWidget {
  final VoidCallback onTap;
  final double width;
  final double height;
  final String iconPath;
  final String? tooltip;

  const AppIconsButtons({
    super.key,
    required this.onTap,
    required this.width,
    required this.height,
    required this.iconPath,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: Image.asset(
              iconPath,
              width: width,
              height: height,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
