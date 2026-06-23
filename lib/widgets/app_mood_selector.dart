import 'package:flutter/material.dart';

class AppMoodSelector extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final String image;
  final String selectedImage;
  final String text;

  const AppMoodSelector({
    super.key,
    required this.selected,
    required this.onTap,
    required this.image,
    required this.selectedImage,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 45,
                width: 45,
                child: Align(
                  alignment: Alignment.center,
                  child: Image.asset(
                    selected ? selectedImage : image,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                text,
                style: TextStyle(color: const Color(0xFF28174E), fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
