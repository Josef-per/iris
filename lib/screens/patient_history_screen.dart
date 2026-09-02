import 'package:flutter/material.dart';
import 'package:iris/core/time/local_day.dart';
import 'package:iris/features/patient_history/patient_history.dart';
import 'package:iris/widgets/app_responsive.dart';
import 'package:iris/widgets/app_function_header.dart';

class PatientHistoryScreen extends StatefulWidget {
  const PatientHistoryScreen({
    super.key,
    this.dataSource,
    this.embeddedInNavigationShell = false,
  });

  final PatientHistoryDataSource? dataSource;
  final bool embeddedInNavigationShell;

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  late final PatientHistoryDataSource _dataSource;
  late Future<List<PatientHistoryEntry>> _historyFuture;
  PatientHistoryKind? _selectedKind;

  @override
  void initState() {
    super.initState();
    _dataSource = widget.dataSource ?? PatientHistoryRepository();
    _historyFuture = _dataSource.loadHistory();
  }

  void _reload() {
    setState(() {
      _historyFuture = _dataSource.loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: AppFunctionHeader(
            title: 'Meu histórico',
            description: 'Seus registros de humor, emoções e alimentação.',
          ),
        ),
        SliverToBoxAdapter(
          child: AppResponsive(
            maxWidth: 760,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 48),
            child: FutureBuilder<List<PatientHistoryEntry>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    key: const Key('patient-history-loading'),
                    child: Semantics(
                      liveRegion: true,
                      label: 'Carregando histórico',
                      child: const Padding(
                        padding: EdgeInsets.all(48),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return _HistoryMessage(
                    key: const Key('patient-history-error'),
                    icon: Icons.cloud_off_rounded,
                    title: 'Não foi possível carregar o histórico',
                    message: 'Verifique sua conexão e tente novamente.',
                    actionLabel: 'Tentar novamente',
                    onAction: _reload,
                  );
                }

                final entries = snapshot.data ?? const <PatientHistoryEntry>[];
                if (entries.isEmpty) {
                  return const _HistoryMessage(
                    key: Key('patient-history-empty'),
                    icon: Icons.history_rounded,
                    title: 'Nenhum registro ainda',
                    message:
                        'Seus registros do dia, diários emocionais e refeições aparecerão aqui.',
                  );
                }

                final filtered = _selectedKind == null
                    ? entries
                    : entries
                          .where((entry) => entry.kind == _selectedKind)
                          .toList(growable: false);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HistoryFilters(
                      selected: _selectedKind,
                      onSelected: (kind) => setState(() {
                        _selectedKind = kind;
                      }),
                    ),
                    const SizedBox(height: 18),
                    if (filtered.isEmpty)
                      const _HistoryMessage(
                        icon: Icons.filter_alt_off_outlined,
                        title: 'Nenhum registro neste filtro',
                        message:
                            'Escolha outro tipo para continuar explorando.',
                      )
                    else
                      _HistoryTimeline(entries: filtered),
                  ],
                );
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

class _HistoryFilters extends StatelessWidget {
  const _HistoryFilters({required this.selected, required this.onSelected});

  final PatientHistoryKind? selected;
  final ValueChanged<PatientHistoryKind?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('Todos'),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Emoções'),
            avatar: const Icon(Icons.favorite_outline_rounded, size: 18),
            selected: selected == PatientHistoryKind.emotional,
            onSelected: (_) => onSelected(PatientHistoryKind.emotional),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Alimentação'),
            avatar: const Icon(Icons.restaurant_rounded, size: 18),
            selected: selected == PatientHistoryKind.food,
            onSelected: (_) => onSelected(PatientHistoryKind.food),
          ),
        ],
      ),
    );
  }
}

class _HistoryTimeline extends StatelessWidget {
  const _HistoryTimeline({required this.entries});

  final List<PatientHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final sorted = List<PatientHistoryEntry>.of(entries)
      ..sort((a, b) => b.moment.compareTo(a.moment));
    final children = <Widget>[];
    String? currentDay;

    for (var index = 0; index < sorted.length; index++) {
      final entry = sorted[index];
      final day = LocalDay.key(entry.moment);
      if (day != currentDay) {
        currentDay = day;
        children.add(_DayHeader(label: _dayLabel(entry.moment, now)));
      }
      children.add(_HistoryCard(entry: entry));
      children.add(const SizedBox(height: 10));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});

  final PatientHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppSurface(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(entry.icon, color: theme.colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.title,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatTime(entry.moment.toLocal()),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(entry.description, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
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

String _dayLabel(DateTime moment, DateTime now) {
  final day = moment.toLocal();
  final today = now.toLocal();
  final isToday =
      day.year == today.year &&
      day.month == today.month &&
      day.day == today.day;
  if (isToday) {
    return 'Hoje';
  }

  final yesterday = today.subtract(const Duration(days: 1));
  final isYesterday =
      day.year == yesterday.year &&
      day.month == yesterday.month &&
      day.day == yesterday.day;
  if (isYesterday) {
    return 'Ontem';
  }

  final dayPart = day.day.toString().padLeft(2, '0');
  final monthPart = day.month.toString().padLeft(2, '0');
  return '$dayPart/$monthPart/${day.year}';
}

String _formatTime(DateTime moment) {
  final hour = moment.hour.toString().padLeft(2, '0');
  final minute = moment.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
