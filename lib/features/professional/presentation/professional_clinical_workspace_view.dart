import 'package:flutter/material.dart';
import 'package:iris/core/navigation/professional_destination.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/professional/presentation/professional_care_plan_view.dart';
import 'package:iris/features/professional/presentation/professional_frontend_store.dart';
import 'package:iris/features/professional/presentation/professional_models.dart';
import 'package:iris/features/professional/presentation/professional_notes_view.dart';

class ProfessionalClinicalWorkspaceView extends StatelessWidget {
  const ProfessionalClinicalWorkspaceView({
    super.key,
    required this.store,
    required this.activeDestination,
    required this.initialPatient,
    required this.onDestinationChanged,
    required this.onOpenPatient,
    required this.onPatientChanged,
    required this.onDirtyChanged,
  }) : assert(
         activeDestination == ProfessionalDestination.carePlan ||
             activeDestination == ProfessionalDestination.notes,
       );

  final ProfessionalFrontendStore store;
  final ProfessionalDestination activeDestination;
  final ProfessionalPatient? initialPatient;
  final ValueChanged<ProfessionalDestination> onDestinationChanged;
  final ValueChanged<ProfessionalPatient> onOpenPatient;
  final ValueChanged<ProfessionalPatient> onPatientChanged;
  final ValueChanged<bool> onDirtyChanged;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = activeDestination == ProfessionalDestination.carePlan
        ? 0
        : 1;
    return Column(
      children: [
        _ClinicalSectionTabs(
          activeDestination: activeDestination,
          onDestinationChanged: onDestinationChanged,
        ),
        Expanded(
          child: IndexedStack(
            index: selectedIndex,
            children: [
              ProfessionalCarePlanView(
                key: const PageStorageKey('clinical-care-plan'),
                store: store,
                initialPatient: initialPatient,
                onOpenPatient: onOpenPatient,
                onPatientChanged: onPatientChanged,
                onDirtyChanged: onDirtyChanged,
              ),
              ProfessionalNotesView(
                key: const PageStorageKey('clinical-notes'),
                store: store,
                onOpenPatient: onOpenPatient,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClinicalSectionTabs extends StatelessWidget {
  const _ClinicalSectionTabs({
    required this.activeDestination,
    required this.onDestinationChanged,
  });

  final ProfessionalDestination activeDestination;
  final ValueChanged<ProfessionalDestination> onDestinationChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      key: const Key('professional-clinical-tabs'),
      color: colors.surface,
      shape: Border(bottom: BorderSide(color: colors.outlineVariant)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth < 480
              ? 16.0
              : constraints.maxWidth < 900
              ? 24.0
              : 32.0;
          final showIcons = constraints.maxWidth >= 420;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1480),
              child: Padding(
                padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 12),
                child: Semantics(
                  container: true,
                  label: 'Seções do acompanhamento clínico',
                  child: Row(
                    children: [
                      Expanded(
                        child: _ClinicalTab(
                          key: const Key('clinical-tab-care-plan'),
                          label: 'Plano de cuidado',
                          icon: Icons.health_and_safety_outlined,
                          selected:
                              activeDestination ==
                              ProfessionalDestination.carePlan,
                          showIcon: showIcons,
                          onTap: () => onDestinationChanged(
                            ProfessionalDestination.carePlan,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ClinicalTab(
                          key: const Key('clinical-tab-notes'),
                          label: 'Anotações clínicas',
                          icon: Icons.auto_stories_outlined,
                          selected:
                              activeDestination ==
                              ProfessionalDestination.notes,
                          showIcon: showIcons,
                          onTap: () => onDestinationChanged(
                            ProfessionalDestination.notes,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ClinicalTab extends StatelessWidget {
  const _ClinicalTab({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.showIcon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool showIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = selected
        ? colors.onPrimaryContainer
        : colors.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? colors.primaryContainer : Colors.transparent,
        borderRadius: AppRadius.medium,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: selected ? null : onTap,
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showIcon) ...[
                  Icon(icon, size: 20, color: foreground),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
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
