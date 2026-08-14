import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/care_plan/patient_care_plan.dart';
import 'package:iris/features/care_plan/patient_care_plan_repository.dart';
import 'package:iris/widgets/app_responsive.dart';

class PatientCarePlanScreen extends StatefulWidget {
  const PatientCarePlanScreen({super.key, this.dataSource, this.onBack});

  final PatientCarePlanDataSource? dataSource;
  final VoidCallback? onBack;

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
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppGradientHeader(
              child: AppResponsive(
                maxWidth: 760,
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      tooltip: 'Voltar',
                      onPressed:
                          widget.onBack ?? () => Navigator.maybePop(context),
                      style: IconButton.styleFrom(
                        foregroundColor: AppColors.white,
                        backgroundColor: AppColors.white.withValues(alpha: .1),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Plano de cuidado',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: AppColors.white),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Orientações compartilhadas pela sua equipe.',
                      style: TextStyle(color: AppColors.white),
                    ),
                  ],
                ),
              ),
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
      ),
    );
  }
}

class _CarePlanCard extends StatelessWidget {
  const _CarePlanCard({required this.plan});

  final PatientCarePlan plan;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semanticColors = AppSemanticColors.of(context);
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite_rounded, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Atualizado em ${_formatDate(plan.updatedAt)}',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (plan.guidance != null) ...[
            const SizedBox(height: 22),
            const _SectionTitle('Orientações'),
            const SizedBox(height: 8),
            Text(plan.guidance!, style: const TextStyle(height: 1.45)),
          ],
          if (plan.goals.isNotEmpty) ...[
            const SizedBox(height: 22),
            const _SectionTitle('Metas'),
            const SizedBox(height: 8),
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
          if (plan.medications.isNotEmpty) ...[
            const SizedBox(height: 22),
            const _SectionTitle('Medicações'),
            const SizedBox(height: 8),
            for (final medication in plan.medications)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.medication_outlined, color: colors.primary),
                title: Text(medication.name),
                subtitle: Text('${medication.dose} · ${medication.frequency}'),
              ),
          ],
          if (plan.crisisSteps.isNotEmpty) ...[
            const SizedBox(height: 22),
            const _SectionTitle('Passos em momento de crise'),
            const SizedBox(height: 8),
            for (var index = 0; index < plan.crisisSteps.length; index++)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 13,
                  backgroundColor: colors.primaryContainer,
                  foregroundColor: colors.onPrimaryContainer,
                  child: Text('${index + 1}'),
                ),
                title: Text(plan.crisisSteps[index]),
              ),
          ],
          if (plan.guidance == null &&
              plan.goals.isEmpty &&
              plan.medications.isEmpty &&
              plan.crisisSteps.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 18),
              child: Text(
                'Este plano ainda não possui orientações cadastradas.',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
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
