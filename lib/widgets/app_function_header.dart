import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/widgets/app_responsive.dart';

/// Shared patient-area header with a title and description.
class AppFunctionHeader extends StatelessWidget {
  const AppFunctionHeader({
    super.key,
    required this.title,
    required this.description,
    this.maxWidth = 760,
    this.footer,
  });

  final String title;
  final String description;
  final double maxWidth;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return AppGradientHeader(
      padding: EdgeInsets.zero,
      child: SafeArea(
        bottom: false,
        child: AppResponsive(
          maxWidth: maxWidth,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: AppColors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      textAlign: TextAlign.left,
                      style: const TextStyle(color: AppColors.white),
                    ),
                  ],
                ),
              ),
              if (footer != null) ...[const SizedBox(height: 22), footer!],
            ],
          ),
        ),
      ),
    );
  }
}
