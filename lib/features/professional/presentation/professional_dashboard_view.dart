import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/professional/presentation/professional_form_dialogs.dart';
import 'package:iris/features/professional/presentation/professional_frontend_store.dart';
import 'package:iris/features/professional/presentation/professional_models.dart';
import 'package:iris/features/professional/presentation/professional_shared_widgets.dart';

class ProfessionalDashboardView extends StatelessWidget {
  const ProfessionalDashboardView({
    super.key,
    required this.store,
    required this.onOpenPatients,
    required this.onOpenPatient,
    this.onOpenAlerts,
    this.appointmentInitialDate,
  });

  final ProfessionalFrontendStore store;
  final VoidCallback onOpenPatients;
  final ValueChanged<ProfessionalPatient> onOpenPatient;
  final VoidCallback? onOpenAlerts;
  final DateTime? appointmentInitialDate;

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
                        ? () => showProfessionalAppointmentForm(
                            context,
                            store,
                            initialDate: appointmentInitialDate,
                          )
                        : null,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Nova consulta'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _MetricsGrid(store: store, onOpenAlerts: onOpenAlerts),
            const SizedBox(height: 30),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 940;
                final calendar = _AgendaPanel(
                  store: store,
                  onOpenPatient: onOpenPatient,
                  initialDate: appointmentInitialDate,
                );
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
  const _MetricsGrid({required this.store, required this.onOpenAlerts});

  final ProfessionalFrontendStore store;
  final VoidCallback? onOpenAlerts;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semanticColors = AppSemanticColors.of(context);
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
        final columns = constraints.maxWidth >= 1120 ? 4 : 2;
        final gap = constraints.maxWidth < 520 ? 12.0 : 18.0;
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
              color: colors.primary,
            ),
            _MetricCard(
              width: width,
              icon: Icons.sentiment_satisfied_alt_rounded,
              title: 'Pacientes ativos',
              value:
                  '${store.patients.where((patient) => patient.status == PatientStatus.active).length}',
              supporting: '${store.patients.length} no total',
              color: semanticColors.success,
            ),
            _MetricCard(
              width: width,
              icon: Icons.warning_amber_rounded,
              title: 'Alertas',
              value: '${store.alerts}',
              supporting: 'Ver todos',
              color: colors.error,
              onTap: onOpenAlerts,
            ),
            _MetricCard(
              width: width,
              icon: Icons.trending_up_rounded,
              title: 'Consultas este mês',
              value: '${store.appointmentsThisMonth}',
              supporting: 'Agenda carregada',
              color: semanticColors.info,
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
    this.onTap,
  });

  final double width;
  final IconData icon;
  final String title;
  final String value;
  final String supporting;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ProfessionalPanel(
        padding: const EdgeInsets.all(18),
        child: Semantics(
          button: onTap != null,
          label: '$title: $value. $supporting',
          excludeSemantics: true,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 190;
                final iconWidget = Container(
                  width: compact ? 42 : 52,
                  height: compact ? 42 : 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: compact ? 22 : 27),
                );
                final details = Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: compact
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: compact ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: compact ? TextAlign.center : null,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (!compact)
                      Text(
                        supporting,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                );
                if (compact) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [iconWidget, const SizedBox(height: 8), details],
                  );
                }
                return ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 58),
                  child: Row(
                    children: [
                      iconWidget,
                      const SizedBox(width: 14),
                      Expanded(child: details),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AgendaPanel extends StatefulWidget {
  const _AgendaPanel({
    required this.store,
    required this.onOpenPatient,
    this.initialDate,
  });

  final ProfessionalFrontendStore store;
  final ValueChanged<ProfessionalPatient> onOpenPatient;
  final DateTime? initialDate;

  @override
  State<_AgendaPanel> createState() => _AgendaPanelState();
}

class _AgendaPanelState extends State<_AgendaPanel> {
  late DateTime _selectedDate;
  late DateTime _visibleRangeStart;

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(widget.initialDate ?? DateTime.now());
    _visibleRangeStart = _selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    final days = List.generate(
      7,
      (index) => _visibleRangeStart.add(Duration(days: index)),
    );
    final appointments =
        widget.store.appointments.where((appointment) {
          final startsAt = appointment.startsAt?.toLocal();
          return startsAt != null && _sameDay(startsAt, _selectedDate);
        }).toList()..sort((a, b) {
          final aDate = a.startsAt;
          final bDate = b.startsAt;
          if (aDate == null || bDate == null) return a.time.compareTo(b.time);
          return aDate.compareTo(bDate);
        });

    return ProfessionalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfessionalSectionTitle(
            title: 'Agenda semanal',
            subtitle: _monthAndYear(_selectedDate),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Semana anterior',
                  onPressed: () => _moveVisibleRange(-7),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                IconButton(
                  tooltip: 'Próxima semana',
                  onPressed: () => _moveVisibleRange(7),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 76,
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 332) {
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: days.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 4),
                    itemBuilder: (context, index) =>
                        _buildDayButton(days[index]),
                  );
                }
                final gap = constraints.maxWidth < 420 ? 4.0 : 8.0;
                return Row(
                  children: [
                    for (var index = 0; index < days.length; index++) ...[
                      if (index > 0) SizedBox(width: gap),
                      Expanded(child: _buildDayButton(days[index])),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Divider(color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedDayLabel(_selectedDate),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: _canManage(widget.store)
                    ? () => showProfessionalAppointmentForm(
                        context,
                        widget.store,
                        initialDate: _selectedDate,
                      )
                    : null,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Agendar'),
              ),
            ],
          ),
          if (appointments.isEmpty)
            const _DashboardEmptyState(
              icon: Icons.event_available_outlined,
              title: 'Agenda livre',
              message: 'Não há consultas agendadas para este dia.',
            )
          else
            ...appointments.map(
              (appointment) => ListTile(
                minTileHeight: 56,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule_rounded),
                title: Text(appointment.patient.name),
                subtitle: Text(appointment.type),
                trailing: Text(
                  appointment.time,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => widget.onOpenPatient(appointment.patient),
              ),
            ),
        ],
      ),
    );
  }

  void _moveVisibleRange(int days) {
    setState(() {
      _visibleRangeStart = _visibleRangeStart.add(Duration(days: days));
      _selectedDate = _visibleRangeStart;
    });
  }

  Widget _buildDayButton(DateTime day) {
    final selected = _sameDay(day, _selectedDate);
    final count = widget.store.appointments.where((appointment) {
      final startsAt = appointment.startsAt?.toLocal();
      return startsAt != null && _sameDay(startsAt, day);
    }).length;
    return _AgendaDayButton(
      day: day,
      selected: selected,
      appointmentCount: count,
      onTap: () => setState(() => _selectedDate = day),
    );
  }
}

class _AgendaDayButton extends StatelessWidget {
  const _AgendaDayButton({
    required this.day,
    required this.selected,
    required this.appointmentCount,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final int appointmentCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      label:
          '${_weekdayName(day.weekday)}, ${day.day}. '
          '$appointmentCount ${appointmentCount == 1 ? 'consulta' : 'consultas'}',
      child: Material(
        color: selected ? colorScheme.primary : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 54,
            height: 72,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _weekdayName(day.weekday).substring(0, 3),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${day.day}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: selected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: appointmentCount == 0
                        ? Colors.transparent
                        : selected
                        ? colorScheme.onPrimary
                        : colorScheme.primary,
                    shape: BoxShape.circle,
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
            Icon(icon, size: 38, color: Theme.of(context).colorScheme.primary),
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

DateTime _dateOnly(DateTime date) {
  final local = date.toLocal();
  return DateTime(local.year, local.month, local.day);
}

bool _sameDay(DateTime a, DateTime b) {
  final localA = a.toLocal();
  final localB = b.toLocal();
  return localA.year == localB.year &&
      localA.month == localB.month &&
      localA.day == localB.day;
}

String _monthAndYear(DateTime date) {
  const months = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
  final month = months[date.month - 1];
  return '${month[0].toUpperCase()}${month.substring(1)} de ${date.year}';
}

String _weekdayName(int weekday) {
  const weekdays = [
    'segunda',
    'terça',
    'quarta',
    'quinta',
    'sexta',
    'sábado',
    'domingo',
  ];
  return weekdays[weekday - 1];
}

String _selectedDayLabel(DateTime date) {
  final today = _dateOnly(DateTime.now());
  if (_sameDay(today, date)) {
    return 'Hoje, ${date.day} de ${_monthAndYear(date).split(' de ').first.toLowerCase()}';
  }
  return '${_weekdayName(date.weekday)[0].toUpperCase()}${_weekdayName(date.weekday).substring(1)}, ${date.day} de ${_monthAndYear(date).split(' de ').first.toLowerCase()}';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 440;
        final primary = Theme.of(context).colorScheme.primary;
        return Semantics(
          button: true,
          label:
              '${appointment.patient.name}, ${_appointmentLabel(appointment)}, ${appointment.type}',
          child: InkWell(
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
                      style: TextStyle(
                        color: primary,
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
                          style: Theme.of(context).textTheme.titleMedium,
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
          ),
        );
      },
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
