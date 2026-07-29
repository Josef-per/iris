import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/professional/presentation/professional_mock_data.dart';
import 'package:iris/features/professional/presentation/professional_shared_widgets.dart';

enum _PatientFilter { all, active, inactive }

class ProfessionalPatientsView extends StatefulWidget {
  const ProfessionalPatientsView({
    super.key,
    required this.onOpenPatient,
    required this.onInvitePatient,
  });

  final ValueChanged<ProfessionalPatient> onOpenPatient;
  final VoidCallback onInvitePatient;

  @override
  State<ProfessionalPatientsView> createState() =>
      _ProfessionalPatientsViewState();
}

class _ProfessionalPatientsViewState extends State<ProfessionalPatientsView> {
  final _searchController = TextEditingController();
  _PatientFilter _filter = _PatientFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProfessionalPatient> get _filteredPatients {
    final query = _searchController.text.trim().toLowerCase();
    return ProfessionalMockData.patients.where((patient) {
      final matchesQuery =
          query.isEmpty ||
          patient.name.toLowerCase().contains(query) ||
          patient.diagnosis.toLowerCase().contains(query);
      final matchesStatus = switch (_filter) {
        _PatientFilter.all => true,
        _PatientFilter.active => patient.status == PatientStatus.active,
        _PatientFilter.inactive => patient.status == PatientStatus.inactive,
      };
      return matchesQuery && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final patients = _filteredPatients;
    return SingleChildScrollView(
      child: Column(
        children: [
          ProfessionalGradientHeader(
            title: 'Meus pacientes',
            subtitle: '${ProfessionalMockData.patients.length} pacientes',
            action: FilledButton.icon(
              onPressed: widget.onInvitePatient,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.white.withValues(alpha: .16),
                foregroundColor: AppColors.white,
              ),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Vincular paciente'),
            ),
          ),
          ProfessionalPage(
            paddingTop: 22,
            child: Column(
              children: [
                ProfessionalPanel(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Buscar paciente...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Limpar busca',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 520;
                          final segments = [
                            _FilterButton(
                              label: 'Todos',
                              selected: _filter == _PatientFilter.all,
                              onTap: () =>
                                  setState(() => _filter = _PatientFilter.all),
                            ),
                            _FilterButton(
                              label: 'Ativos',
                              selected: _filter == _PatientFilter.active,
                              onTap: () => setState(
                                () => _filter = _PatientFilter.active,
                              ),
                            ),
                            _FilterButton(
                              label: 'Inativos',
                              selected: _filter == _PatientFilter.inactive,
                              onTap: () => setState(
                                () => _filter = _PatientFilter.inactive,
                              ),
                            ),
                          ];
                          if (compact) {
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: segments,
                            );
                          }
                          return Row(
                            children: [
                              for (var i = 0; i < segments.length; i++) ...[
                                Expanded(child: segments[i]),
                                if (i < segments.length - 1)
                                  const SizedBox(width: 8),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (patients.isEmpty)
                  const _NoPatientsFound()
                else
                  ...patients.map(
                    (patient) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _PatientCard(
                        patient: patient,
                        onTap: () => widget.onOpenPatient(patient),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.purple
          : AppColors.outline.withValues(alpha: .62),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.white : AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.patient, required this.onTap});

  final ProfessionalPatient patient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          patient.name,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppColors.deepPurple),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 8,
          runSpacing: 3,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${patient.age} anos',
              style: const TextStyle(color: AppColors.deepPurple),
            ),
            const Text('•', style: TextStyle(color: AppColors.purple)),
            Text(
              patient.diagnosis,
              style: const TextStyle(color: AppColors.deepPurple),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 15,
              color: AppColors.purple,
            ),
            const SizedBox(width: 5),
            Text(
              'Último registro: ${patient.lastActivity.toLowerCase()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.purple,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );

    return ProfessionalPanel(
      onTap: onTap,
      padding: EdgeInsets.all(compact ? 16 : 20),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PatientAvatar(patient: patient, size: 58),
                    const SizedBox(width: 14),
                    Expanded(child: info),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _MoodBadge(mood: patient.mood),
                    const SizedBox(width: 8),
                    PatientStatusBadge(status: patient.status),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                PatientAvatar(patient: patient, size: 72),
                const SizedBox(width: 18),
                Expanded(child: info),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _MoodBadge(mood: patient.mood),
                    const SizedBox(height: 10),
                    PatientStatusBadge(status: patient.status),
                  ],
                ),
                const SizedBox(width: 16),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
    );
  }
}

class _MoodBadge extends StatelessWidget {
  const _MoodBadge({required this.mood});

  final String mood;

  @override
  Widget build(BuildContext context) {
    final positive = mood == 'Bem' || mood == 'Muito bem';
    final color = positive
        ? const Color(0xFF3EAF6E)
        : mood == 'Mal'
        ? AppColors.danger
        : const Color(0xFFC98A34);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive
                ? Icons.sentiment_satisfied_alt_rounded
                : mood == 'Mal'
                ? Icons.sentiment_dissatisfied_rounded
                : Icons.sentiment_neutral_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            mood,
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

class _NoPatientsFound extends StatelessWidget {
  const _NoPatientsFound();

  @override
  Widget build(BuildContext context) {
    return const ProfessionalPanel(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 42),
        child: Column(
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 48,
              color: AppColors.purple,
            ),
            SizedBox(height: 12),
            Text(
              'Nenhum paciente encontrado.',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
