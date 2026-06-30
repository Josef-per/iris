import 'package:flutter/material.dart';

class AppIconsButtons extends StatelessWidget {
  final VoidCallback onTap;
  final double width;
  final double height;
  final String iconPath;

  const AppIconsButtons({
    super.key,
    required this.onTap,
    required this.width,
    required this.height,
    required this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(color: Colors.transparent),
          width: width,
          height: height,
          child: Image.asset(iconPath, width: width, height: height),
        ),
      ),
    );
  }
}
