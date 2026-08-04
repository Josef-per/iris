import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/widgets/config/settings/settings_category_header.dart';

class LanguageSettings extends StatelessWidget {
  const LanguageSettings({
    super.key,
    this.language = 'Português (Brasil)',
    this.onTap,
  });

  final String language;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SettingsCategoryHeader(
            icon: Icons.language_outlined,
            title: 'Idioma',
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(9),
              child: Ink(
                height: 37,
                padding: const EdgeInsets.symmetric(horizontal: 11),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.deepPurple),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        language,
                        style: const TextStyle(
                          color: AppColors.deepPurple,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.ink,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
