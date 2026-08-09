import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/widgets/app_responsive.dart';

class AppAuthLayout extends StatelessWidget {
  const AppAuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final compact = constraints.maxWidth < 420;
              final veryCompact = constraints.maxWidth < 360;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(vertical: compact ? 16 : 28),
                child: AppResponsive(
                  maxWidth: 1120,
                  padding: EdgeInsets.symmetric(
                    horizontal: veryCompact
                        ? 16
                        : compact
                        ? 20
                        : 32,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - (compact ? 32 : 56),
                    ),
                    child: wide
                        ? Row(
                            children: [
                              Expanded(
                                child: _Brand(
                                  title: title,
                                  subtitle: subtitle,
                                  compact: false,
                                ),
                              ),
                              const SizedBox(width: 72),
                              Expanded(child: AppSurface(child: child)),
                            ],
                          )
                        : Column(
                            children: [
                              _Brand(
                                title: title,
                                subtitle: subtitle,
                                compact: compact,
                              ),
                              SizedBox(height: compact ? 20 : 32),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 520,
                                ),
                                child: AppSurface(
                                  padding: EdgeInsets.all(compact ? 20 : 24),
                                  child: child,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({
    required this.title,
    required this.subtitle,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/Login.svg',
            width: compact ? 190 : 250,
            height: compact ? 82 : 120,
            fit: BoxFit.contain,
            semanticsLabel: 'Íris',
          ),
          SizedBox(height: compact ? 14 : 24),
          Text(
            title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.white,
              fontSize: compact ? 30 : null,
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.white,
              fontSize: compact ? 14 : null,
            ),
          ),
        ],
      ),
    );
  }
}
