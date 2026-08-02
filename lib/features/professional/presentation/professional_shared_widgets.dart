import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/professional/presentation/professional_models.dart';

class ProfessionalPage extends StatelessWidget {
  const ProfessionalPage({
    super.key,
    required this.child,
    this.maxWidth = 1480,
    this.paddingTop = 32,
  });

  final Widget child;
  final double maxWidth;
  final double paddingTop;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < 480
        ? 16.0
        : width < 900
        ? 24.0
        : 32.0;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontal, paddingTop, horizontal, 40),
          child: child,
        ),
      ),
    );
  }
}

class ProfessionalPageHeader extends StatelessWidget {
  const ProfessionalPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
    this.leading,
  });

  final String title;
  final String subtitle;
  final Widget? action;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 650;
    final titleBlock = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 12)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontSize: compact ? 28 : 34),
              ),
              const SizedBox(height: 6),
              Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );

    if (action == null) return titleBlock;
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [titleBlock, const SizedBox(height: 18), action!],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 24),
        action!,
      ],
    );
  }
}

class ProfessionalGradientHeader extends StatelessWidget {
  const ProfessionalGradientHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 650;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: AppColors.white,
            fontSize: compact ? 30 : 38,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.lavender.withValues(alpha: .8),
          ),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 32,
        compact ? 24 : 32,
        compact ? 20 : 32,
        compact ? 34 : 44,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: compact && action != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [text, const SizedBox(height: 20), action!],
            )
          : Row(
              children: [
                Expanded(child: text),
                if (action != null) ...[const SizedBox(width: 24), action!],
              ],
            ),
    );
  }
}

class ProfessionalPanel extends StatelessWidget {
  const ProfessionalPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final panel = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: padding,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              borderColor ??
              (dark ? const Color(0xFF443653) : AppColors.outline),
        ),
        boxShadow: [
          BoxShadow(
            color: dark ? const Color(0x26000000) : const Color(0x0D28174E),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );

    if (onTap == null) return panel;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: panel,
    );
  }
}

class ProfessionalSectionTitle extends StatelessWidget {
  const ProfessionalSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 16), trailing!],
      ],
    );
  }
}

class PatientAvatar extends StatelessWidget {
  const PatientAvatar({super.key, required this.patient, this.size = 52});

  final ProfessionalPatient patient;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.lavender, AppColors.purple.withValues(alpha: .72)],
        ),
        shape: BoxShape.circle,
      ),
      child: Text(
        patient.initials,
        style: TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w800,
          fontSize: size * .31,
        ),
      ),
    );
  }
}

class PatientStatusBadge extends StatelessWidget {
  const PatientStatusBadge({super.key, required this.status});

  final PatientStatus status;

  @override
  Widget build(BuildContext context) {
    final active = status == PatientStatus.active;
    final color = active ? AppColors.success : AppColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'Ativo' : 'Inativo',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfessionalInfoRow extends StatelessWidget {
  const ProfessionalInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.lavender.withValues(alpha: .35),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.deepPurple, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}
