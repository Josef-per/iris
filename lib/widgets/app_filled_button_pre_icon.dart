import 'package:flutter/material.dart';

class AppFilledButtonPreIcon extends StatelessWidget {
  final VoidCallback onTap;
  final String icon;
  final String text;

  const AppFilledButtonPreIcon({
    super.key,
    required this.onTap,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        width: 177,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Image.asset(icon, width: 10, height: 10),
                SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF28174E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
