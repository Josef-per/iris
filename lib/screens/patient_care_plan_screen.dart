import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/care_plan/patient_care_plan.dart';
import 'package:iris/features/care_plan/patient_care_plan_repository.dart';
import 'package:iris/widgets/app_responsive.dart';
import 'package:iris/widgets/app_function_header.dart';

class PatientCarePlanScreen extends StatefulWidget {
  const PatientCarePlanScreen({
    super.key,
    this.dataSource,
    this.embeddedInNavigationShell = false,
  });

  final PatientCarePlanDataSource? dataSource;

  /// Quando aberto pelo menu fixo do paciente, o Scaffold pertence ao shell
  /// de navegação. Assim a tela mantém exatamente o mesmo conteúdo e não cria
  /// um Scaffold dentro de outro, o que deslocava o cabeçalho.
  final bool embeddedInNavigationShell;

  @override
  State<PatientCarePlanScreen> createState() => _PatientCarePlanScreenState();
}

class _PatientCarePlanScreenState extends State<PatientCarePlanScreen> {
  late final PatientCarePlanDataSource _dataSource;
  late Future<List<PatientCarePlan>> _plansFuture;

  @override
  void initState() {
    super.initState();
    _dataSource = widget.dataSource ?? PatientCarePlanRepository();
    _plansFuture = _dataSource.listSharedPlans();
  }

  void _reload() {
    setState(() {
      _plansFuture = _dataSource.listSharedPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: AppFunctionHeader(
            title: 'Plano de cuidado',
            description: 'Orientações compartilhadas pela sua equipe.',
          ),
        ),
        SliverToBoxAdapter(
          child: AppResponsive(
            maxWidth: 760,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 48),
            child: FutureBuilder<List<PatientCarePlan>>(
              future: _plansFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    key: Key('patient-care-plan-loading'),
                    child: Semantics(
                      liveRegion: true,
                      label: 'Carregando plano de cuidado',
                      child: const Padding(
                        padding: EdgeInsets.all(48),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return _CarePlanMessage(
                    key: const Key('patient-care-plan-error'),
                    icon: Icons.cloud_off_rounded,
                    title: 'Não foi possível carregar o plano',
                    message: 'Verifique sua conexão e tente novamente.',
                    actionLabel: 'Tentar novamente',
                    onAction: _reload,
                  );
                }

                final plans = snapshot.data ?? const <PatientCarePlan>[];
                if (plans.isEmpty) {
                  return const _CarePlanMessage(
                    key: Key('patient-care-plan-empty'),
                    icon: Icons.assignment_outlined,
                    title: 'Nenhum plano compartilhado',
                    message:
                        'Quando sua equipe compartilhar um plano, ele aparecerá aqui.',
                  );
                }

                // O plano de cuidado é único: mesmo que a fonte devolva
                // várias linhas (vínculos legados duplicados), mantém apenas
                // o mais recente para não duplicar as orientações.
                var latest = plans.first;
                for (final plan in plans.skip(1)) {
                  if (plan.updatedAt.isAfter(latest.updatedAt)) {
                    latest = plan;
                  }
                }

                return _CarePlanCard(plan: latest);
              },
            ),
          ),
        ),
      ],
    );

    if (widget.embeddedInNavigationShell) return content;
    return Scaffold(body: content);
  }
}

class _CarePlanCard extends StatelessWidget {
  const _CarePlanCard({required this.plan});

  final PatientCarePlan plan;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semanticColors = AppSemanticColors.of(context);
    final hasContent =
        plan.guidance != null ||
        plan.goals.isNotEmpty ||
        plan.medications.isNotEmpty ||
        plan.crisisSteps.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.verified_outlined, color: colors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Compartilhado pela sua equipe · Atualizado em ${_formatDate(plan.updatedAt)}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        if (plan.crisisSteps.isNotEmpty) ...[
          const SizedBox(height: 18),
          _PlanSectionCard(
            icon: Icons.health_and_safety_outlined,
            title: 'Passos em momento de crise',
            color: colors.primaryContainer.withValues(alpha: .55),
            child: Column(
              children: [
                for (var index = 0; index < plan.crisisSteps.length; index++)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 13,
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(plan.crisisSteps[index]),
                  ),
              ],
            ),
          ),
        ],
        if (plan.guidance != null) ...[
          const SizedBox(height: 14),
          _PlanSectionCard(
            icon: Icons.favorite_outline_rounded,
            title: 'Orientações',
            child: Text(plan.guidance!, style: const TextStyle(height: 1.5)),
          ),
        ],
        if (plan.goals.isNotEmpty) ...[
          const SizedBox(height: 14),
          _PlanSectionCard(
            icon: Icons.flag_outlined,
            title: 'Metas',
            child: Column(
              children: [
                for (final goal in plan.goals)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      goal.isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: goal.isCompleted
                          ? semanticColors.success
                          : colors.primary,
                    ),
                    title: Text(goal.description),
                  ),
              ],
            ),
          ),
        ],
        if (plan.medications.isNotEmpty) ...[
          const SizedBox(height: 14),
          _PlanSectionCard(
            icon: Icons.medication_outlined,
            title: 'Medicações',
            child: Column(
              children: [
                for (final medication in plan.medications)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.medication_liquid_outlined,
                      color: colors.primary,
                    ),
                    title: Text(medication.name),
                    subtitle: Text(_medicationDetails(medication)),
                  ),
              ],
            ),
          ),
        ],
        if (!hasContent) ...[
          const SizedBox(height: 18),
          AppSurface(
            child: Text(
              'Este plano ainda não possui orientações cadastradas.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }
}

class _PlanSectionCard extends StatelessWidget {
  const _PlanSectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.color,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppSurface(
      padding: const EdgeInsets.all(20),
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(child: _SectionTitle(title)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _CarePlanMessage extends StatelessWidget {
  const _CarePlanMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      child: Column(
        children: [
          Icon(icon, size: 44, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _medicationDetails(PatientCareMedication medication) {
  final adherence = (medication.adherence * 100).round();
  return [
    if (medication.dose.isNotEmpty) medication.dose,
    if (medication.frequency.isNotEmpty) medication.frequency,
    'Adesão: $adherence%',
  ].join(' · ');
}
