import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';

class AppBottomSheet extends StatelessWidget {
  final Widget child;

  const AppBottomSheet({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FractionallySizedBox(
        heightFactor: MediaQuery.sizeOf(context).width < 700 ? .9 : .82,
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: .35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: child,
                      ),
                    ),
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
