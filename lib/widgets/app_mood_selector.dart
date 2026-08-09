import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';

class AppMoodSelector extends StatelessWidget {
  const AppMoodSelector({
    super.key,
    required this.selected,
    required this.onTap,
    required this.image,
    required this.selectedImage,
    required this.text,
    this.width = 72,
  });

  final bool selected;
  final VoidCallback onTap;
  final String image;
  final String selectedImage;
  final String text;
  final double width;

  @override
  Widget build(BuildContext context) {
    final semanticLabel = text.replaceAll('\n', ' ');
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: SizedBox(
        width: width,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final iconSize = (constraints.maxWidth - 8).clamp(32.0, 44.0);
            return Material(
              color: selected
                  ? AppColors.lavender.withValues(alpha: .42)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: ExcludeSemantics(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox.square(
                          dimension: iconSize,
                          child: Image.asset(
                            selected ? selectedImage : image,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          text,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontSize: 13, height: 1.2),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
