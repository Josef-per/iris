import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/professional/presentation/professional_form_dialogs.dart';
import 'package:iris/features/professional/presentation/professional_frontend_store.dart';
import 'package:iris/features/professional/presentation/professional_mock_data.dart';
import 'package:iris/features/professional/presentation/professional_shared_widgets.dart';

class ProfessionalDashboardView extends StatelessWidget {
  const ProfessionalDashboardView({
    super.key,
    required this.store,
    required this.onOpenPatients,
    required this.onOpenPatient,
  });

  final ProfessionalFrontendStore store;
  final VoidCallback onOpenPatients;
  final ValueChanged<ProfessionalPatient> onOpenPatient;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ProfessionalPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfessionalPageHeader(
              title: 'Olá, Dra. Júlia! 👋',
              subtitle: 'Resumo do dia',
              action: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: onOpenPatients,
                    icon: const Icon(Icons.people_alt_outlined),
                    label: const Text('Pacientes'),
                  ),
                  FilledButton.icon(
                    key: const Key('professional-add-appointment'),
                    onPressed: () =>
                        showProfessionalAppointmentForm(context, store),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Nova consulta'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _MetricsGrid(store: store),
            const SizedBox(height: 30),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 940;
                final calendar = const _CalendarPanel();
                final appointments = _AppointmentsPanel(
                  store: store,
                  onOpenPatient: onOpenPatient,
                  onOpenPatients: onOpenPatients,
                );
                if (!wide) {
                  return Column(
                    children: [
                      calendar,
                      const SizedBox(height: 24),
                      appointments,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(flex: 11, child: _CalendarPanel()),
                    const SizedBox(width: 24),
                    Expanded(flex: 10, child: appointments),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.store});

  final ProfessionalFrontendStore store;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1120
            ? 4
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        const gap = 18.0;
        final width = (constraints.maxWidth - (gap * (columns - 1))) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            _MetricCard(
              width: width,
              icon: Icons.calendar_month_outlined,
              title: 'Consultas hoje',
              value: '${store.appointments.length}',
              supporting: store.appointments.isEmpty
                  ? 'Sem consultas'
                  : 'Próxima: ${store.appointments.first.time}',
              color: AppColors.deepPurple,
            ),
            _MetricCard(
              width: width,
              icon: Icons.sentiment_satisfied_alt_rounded,
              title: 'Pacientes ativos',
              value:
                  '${store.patients.where((patient) => patient.status == PatientStatus.active).length}',
              supporting: '${store.patients.length} no total',
              color: AppColors.success,
            ),
            _MetricCard(
              width: width,
              icon: Icons.warning_amber_rounded,
              title: 'Alertas',
              value: '0',
              supporting: 'Ver todos',
              color: AppColors.danger,
            ),
            _MetricCard(
              width: width,
              icon: Icons.trending_up_rounded,
              title: 'Consultas este mês',
              value: '42',
              supporting: 'Crescimento de 12%',
              color: const Color(0xFF466BC7),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.value,
    required this.supporting,
    required this.color,
  });

  final double width;
  final IconData icon;
  final String title;
  final String value;
  final String supporting;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ProfessionalPanel(
        borderColor: AppColors.purple,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .16),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 27),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    supporting,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarPanel extends StatelessWidget {
  const _CalendarPanel();

  @override
  Widget build(BuildContext context) {
    return ProfessionalPanel(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: AspectRatio(
          aspectRatio: 1402 / 1122,
          child: Image.asset(
            'assets/images/professional_calendar.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _AppointmentsPanel extends StatelessWidget {
  const _AppointmentsPanel({
    required this.store,
    required this.onOpenPatient,
    required this.onOpenPatients,
  });

  final ProfessionalFrontendStore store;
  final ValueChanged<ProfessionalPatient> onOpenPatient;
  final VoidCallback onOpenPatients;

  @override
  Widget build(BuildContext context) {
    final appointments = store.appointments;
    return ProfessionalPanel(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 14),
      child: Column(
        children: [
          ProfessionalSectionTitle(
            title: 'Próximas consultas',
            trailing: IconButton.filledTonal(
              tooltip: 'Nova consulta',
              onPressed: () => showProfessionalAppointmentForm(context, store),
              icon: const Icon(Icons.add_rounded),
            ),
          ),
          const SizedBox(height: 10),
          ...appointments.map(
            (appointment) => _AppointmentRow(
              appointment: appointment,
              onTap: () => onOpenPatient(appointment.patient),
              onRemove: () async {
                final confirmed = await showProfessionalDeleteConfirmation(
                  context,
                  item: '${appointment.patient.name} às ${appointment.time}',
                );
                if (confirmed) store.removeAppointment(appointment);
              },
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: onOpenPatients,
            child: const Text('Ver pacientes'),
          ),
        ],
      ),
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({
    required this.appointment,
    required this.onTap,
    required this.onRemove,
  });

  final ProfessionalAppointment appointment;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 480;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: compact ? 44 : 54,
              child: Text(
                appointment.time,
                style: const TextStyle(
                  color: AppColors.deepPurple,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            PatientAvatar(patient: appointment.patient, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.patient.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.deepPurple,
                    ),
                  ),
                  Text(
                    appointment.type,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            if (!compact)
              FilledButton.tonal(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Abrir'),
              ),
            PopupMenuButton<String>(
              tooltip: 'Ações da consulta',
              onSelected: (value) {
                if (value == 'remove') onRemove();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'remove',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline_rounded),
                    title: Text('Remover'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
