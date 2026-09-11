import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/widgets/app_responsive.dart';

class AppAuthLayout extends StatelessWidget {
  const AppAuthLayout({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
  });

  final String? title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = colors.brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? [AppColors.darkBackground, AppColors.darkSurface]
                : [const Color(0xFFF0EAFC), AppColors.porcelain, Colors.white],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final compact = constraints.maxWidth < 600;
              final verticalPadding = compact ? 24.0 : 40.0;
              final form = ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _AuthCard(compact: compact, child: child),
              );

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(vertical: verticalPadding),
                child: AppResponsive(
                  maxWidth: 1120,
                  padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 40),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: math.max(
                        0,
                        constraints.maxHeight - verticalPadding * 2,
                      ),
                    ),
                    child: wide
                        ? Row(
                            children: [
                              Expanded(
                                child: _Brand(
                                  title: title,
                                  subtitle: subtitle,
                                  wide: true,
                                ),
                              ),
                              const SizedBox(width: 56),
                              Expanded(child: form),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _Brand(
                                title: title,
                                subtitle: subtitle,
                                wide: false,
                              ),
                              const SizedBox(height: 24),
                              form,
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

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.compact, required this.child});

  final bool compact;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final border = OutlineInputBorder(
      borderRadius: AppRadius.medium,
      borderSide: BorderSide(color: colors.outline),
    );

    return AppSurface(
      padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
      child: Theme(
        data: theme.copyWith(
          inputDecorationTheme: theme.inputDecorationTheme.copyWith(
            filled: true,
            fillColor: colors.surfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            prefixIconColor: colors.onSurfaceVariant,
            suffixIconColor: colors.onSurfaceVariant,
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size(
                AppSize.minimumTapTarget,
                AppSize.prominentControlHeight,
              ),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({
    required this.title,
    required this.subtitle,
    required this.wide,
  });

  final String? title;
  final String? subtitle;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = wide ? AppColors.white : theme.colorScheme.primary;
    final content = Column(
      crossAxisAlignment: wide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/images/Login.svg',
          width: wide ? 200 : 216,
          height: wide ? 92 : 104,
          fit: BoxFit.contain,
          colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
          semanticsLabel: 'Íris',
        ),
        if (title != null) ...[
          SizedBox(height: wide ? 56 : AppSpacing.xs),
          Text(
            title!,
            textAlign: wide ? TextAlign.start : TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              color: foreground,
              fontSize: wide ? 40 : 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -.8,
            ),
          ),
        ],
        if (subtitle != null) ...[
          SizedBox(height: wide ? AppSpacing.sm : AppSpacing.xs),
          Text(
            subtitle!,
            textAlign: wide ? TextAlign.start : TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: wide
                  ? AppColors.white.withValues(alpha: .88)
                  : theme.colorScheme.onSurfaceVariant,
              fontSize: wide ? 16 : 14,
              height: 1.5,
            ),
          ),
        ],
        if (wide) ...[
          const SizedBox(height: 64),
          const Row(
            children: [
              Icon(Icons.spa_outlined, color: AppColors.lavender, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Um passo de cada vez. No seu ritmo.',
                  style: TextStyle(color: AppColors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ],
    );

    if (!wide) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: content,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: Stack(
          children: [
            const Positioned(
              top: -100,
              right: -110,
              child: _BrandRing(diameter: 320),
            ),
            const Positioned(
              bottom: -170,
              left: -100,
              child: _BrandRing(diameter: 360),
            ),
            Padding(padding: const EdgeInsets.all(40), child: content),
          ],
        ),
      ),
    );
  }
}

class _BrandRing extends StatelessWidget {
  const _BrandRing({required this.diameter});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.white.withValues(alpha: .08),
            width: 36,
          ),
        ),
      ),
    );
  }
}
