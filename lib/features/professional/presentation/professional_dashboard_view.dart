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
              title: 'Olá, ${_displayName(store.settings.name)}! 👋',
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
                    onPressed: _canManage(store)
                        ? () => showProfessionalAppointmentForm(context, store)
                        : null,
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
                final calendar = _CalendarPanel(store: store);
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
                    Expanded(flex: 11, child: calendar),
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
    final today = DateTime.now();
    final appointmentsToday = store.isConnected
        ? store.appointments.where((appointment) {
            final startsAt = appointment.startsAt?.toLocal();
            return startsAt != null &&
                startsAt.year == today.year &&
                startsAt.month == today.month &&
                startsAt.day == today.day;
          }).length
        : store.appointments.length;
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
              title: store.isConnected ? 'Restantes hoje' : 'Consultas hoje',
              value: '$appointmentsToday',
              supporting: appointmentsToday == 0
                  ? 'Sem consultas'
                  : 'Agenda do dia',
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
              value: '${store.alerts}',
              supporting: 'Ver todos',
              color: AppColors.danger,
            ),
            _MetricCard(
              width: width,
              icon: Icons.trending_up_rounded,
              title: 'Consultas este mês',
              value: '${store.appointmentsThisMonth}',
              supporting: 'Agenda carregada',
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
  const _CalendarPanel({required this.store});

  final ProfessionalFrontendStore store;

  @override
  Widget build(BuildContext context) {
    if (store.isConnected) {
      final now = DateTime.now();
      final todayAppointments = store.appointments
          .where((appointment) {
            final startsAt = appointment.startsAt?.toLocal();
            return startsAt != null &&
                startsAt.year == now.year &&
                startsAt.month == now.month &&
                startsAt.day == now.day;
          })
          .toList(growable: false);
      return ProfessionalPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ProfessionalSectionTitle(title: 'Próximas de hoje'),
            const SizedBox(height: 18),
            if (todayAppointments.isEmpty)
              const _DashboardEmptyState(
                icon: Icons.event_available_outlined,
                title: 'Agenda livre',
                message: 'Não há consultas agendadas para hoje.',
              )
            else
              ...todayAppointments.map(
                (appointment) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.schedule_rounded,
                    color: AppColors.deepPurple,
                  ),
                  title: Text(appointment.patient.name),
                  subtitle: Text(appointment.type),
                  trailing: Text(
                    appointment.time,
                    style: const TextStyle(
                      color: AppColors.deepPurple,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
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
              onPressed: _canManage(store)
                  ? () => showProfessionalAppointmentForm(context, store)
                  : null,
              icon: const Icon(Icons.add_rounded),
            ),
          ),
          const SizedBox(height: 10),
          if (appointments.isEmpty)
            const _DashboardEmptyState(
              icon: Icons.calendar_today_outlined,
              title: 'Nenhuma consulta',
              message: 'Adicione uma consulta para organizar sua agenda.',
            )
          else
            ...appointments.map(
              (appointment) => _AppointmentRow(
                appointment: appointment,
                canEdit:
                    _canManage(store) &&
                    (!store.isConnected ||
                        appointment.patient.status == PatientStatus.active),
                onTap: () => onOpenPatient(appointment.patient),
                onRemove: () async {
                  final confirmed = await showProfessionalDeleteConfirmation(
                    context,
                    item: '${appointment.patient.name} às ${appointment.time}',
                  );
                  if (!confirmed) return;
                  try {
                    await store.removeAppointment(appointment);
                  } catch (error) {
                    if (context.mounted) {
                      showProfessionalOperationError(context, error);
                    }
                  }
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

class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 38, color: AppColors.purple),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

String _displayName(String name) {
  final cleanName = name.trim();
  if (cleanName.isEmpty) return 'profissional';
  return cleanName.split(RegExp(r'\s+'))[0];
}

bool _canManage(ProfessionalFrontendStore store) {
  return !store.isConnected || store.settings.credentialStatus == 'ativo';
}

class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({
    required this.appointment,
    required this.canEdit,
    required this.onTap,
    required this.onRemove,
  });

  final ProfessionalAppointment appointment;
  final bool canEdit;
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
              width: compact ? 58 : 72,
              child: Text(
                _appointmentLabel(appointment),
                style: const TextStyle(
                  color: AppColors.deepPurple,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
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
              enabled: canEdit,
              tooltip: canEdit
                  ? 'Ações da consulta'
                  : 'Ative o acompanhamento para alterar',
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

String _appointmentLabel(ProfessionalAppointment appointment) {
  final startsAt = appointment.startsAt?.toLocal();
  if (startsAt == null) return appointment.time;
  final now = DateTime.now();
  if (startsAt.year == now.year &&
      startsAt.month == now.month &&
      startsAt.day == now.day) {
    return appointment.time;
  }
  final day = startsAt.day.toString().padLeft(2, '0');
  final month = startsAt.month.toString().padLeft(2, '0');
  return '$day/$month\n${appointment.time}';
}
