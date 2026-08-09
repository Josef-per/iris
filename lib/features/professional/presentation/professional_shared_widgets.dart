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
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: compact ? 28 : 34,
                  ),
                ),
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
        Semantics(
          header: true,
          child: Text(
            title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.white,
              fontSize: compact ? 30 : 38,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.white),
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
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.lg),
        ),
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
    final colors = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: AppRadius.large,
      side: BorderSide(color: borderColor ?? colors.outlineVariant),
    );
    final content = Padding(padding: padding, child: child);

    return Semantics(
      button: onTap != null,
      child: Material(
        color: colors.surface,
        elevation: AppElevation.none,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

/// Uma única superfície para listas, evitando um card e uma sombra por linha.
class ProfessionalListSurface extends StatelessWidget {
  const ProfessionalListSurface({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index < children.length - 1)
                Divider(height: 1, color: colors.outlineVariant),
            ],
          ],
        ),
      ),
    );
  }
}

class ProfessionalEmptyState extends StatelessWidget {
  const ProfessionalEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.secondaryAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ProfessionalPanel(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: theme.colorScheme.primary),
                const SizedBox(height: AppSpacing.md),
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                if (action != null || secondaryAction != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [?secondaryAction, ?action],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog de formulário que vira uma superfície de largura total em telas
/// estreitas e mantém um único scroll para conteúdo longo.
class ProfessionalResponsiveDialog extends StatelessWidget {
  const ProfessionalResponsiveDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.maxWidth = 560,
    this.canClose = true,
    this.blockingMessage = 'Salvando. Aguarde a conclusão para fechar.',
  });

  final String title;
  final Widget content;
  final List<Widget> actions;
  final double maxWidth;
  final bool canClose;
  final String blockingMessage;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final compact = media.size.width < 600;
    final heading = Semantics(
      header: true,
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
    );

    late final Widget dialog;
    if (!compact) {
      final contentWidth = (media.size.width - 160).clamp(320.0, maxWidth);
      dialog = AlertDialog(
        title: heading,
        content: SizedBox(
          width: contentWidth,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!canClose) ...[
                  _ProfessionalDialogBlockingNotice(message: blockingMessage),
                  const SizedBox(height: AppSpacing.md),
                ],
                content,
              ],
            ),
          ),
        ),
        actions: actions,
      );
    } else {
      final colors = Theme.of(context).colorScheme;
      dialog = Dialog.fullscreen(
        child: SafeArea(
          child: Column(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSize.minimumTapTarget + AppSpacing.md,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.xs,
                    AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: heading),
                      Tooltip(
                        message: canClose ? 'Fechar' : blockingMessage,
                        child: IconButton(
                          onPressed: canClose
                              ? () => Navigator.maybePop(context)
                              : null,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: colors.outlineVariant),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!canClose) ...[
                        _ProfessionalDialogBlockingNotice(
                          message: blockingMessage,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      content,
                    ],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(top: BorderSide(color: colors.outlineVariant)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: OverflowBar(
                      alignment: MainAxisAlignment.end,
                      overflowAlignment: OverflowBarAlignment.end,
                      spacing: AppSpacing.xs,
                      overflowSpacing: AppSpacing.xs,
                      children: actions,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope<Object?>(
      canPop: canClose,
      child: Semantics(
        liveRegion: !canClose,
        label: canClose ? null : blockingMessage,
        child: dialog,
      ),
    );
  }
}

class _ProfessionalDialogBlockingNotice extends StatelessWidget {
  const _ProfessionalDialogBlockingNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: semantic.infoContainer,
          borderRadius: AppRadius.small,
        ),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: semantic.onInfoContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: semantic.onInfoContainer),
              ),
            ),
          ],
        ),
      ),
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
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
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
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Text(
        patient.initials,
        style: TextStyle(
          color: colors.onPrimaryContainer,
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
    final colors = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final background = active
        ? semantic.successContainer
        : colors.surfaceContainerHighest;
    final foreground = active
        ? semantic.onSuccessContainer
        : colors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'Ativo' : 'Inativo',
            style: TextStyle(
              color: foreground,
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
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: AppRadius.small,
          ),
          child: Icon(icon, color: colors.onPrimaryContainer, size: 19),
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
