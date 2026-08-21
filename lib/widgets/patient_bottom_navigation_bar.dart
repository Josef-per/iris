import 'package:flutter/material.dart';
import 'package:iris/core/navigation/iris_router.dart';

class PatientBottomNavigationBar extends StatelessWidget {
  const PatientBottomNavigationBar({
    super.key,
    required this.selectedDestination,
    required this.onDestinationSelected,
  });

  final PatientDestination selectedDestination;
  final ValueChanged<PatientDestination> onDestinationSelected;

  static const _items = <_PatientNavigationItem>[
    _PatientNavigationItem(
      destination: PatientDestination.reminders,
      label: 'Lembretes',
      icon: Icons.notifications_none_rounded,
      selectedIcon: Icons.notifications_rounded,
    ),
    _PatientNavigationItem(
      destination: PatientDestination.history,
      label: 'Histórico',
      icon: Icons.history_rounded,
      selectedIcon: Icons.history_rounded,
    ),
    _PatientNavigationItem(
      destination: PatientDestination.carePlan,
      label: 'Plano de cuidado',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment_rounded,
    ),
    _PatientNavigationItem(
      destination: PatientDestination.profile,
      label: 'Perfil',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      elevation: 10,
      shadowColor: colors.shadow.withValues(alpha: .18),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            for (final item in _items)
              Expanded(
                child: _PatientNavigationButton(
                  item: item,
                  selected: selectedDestination == item.destination,
                  onPressed: () => onDestinationSelected(item.destination),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PatientNavigationButton extends StatelessWidget {
  const _PatientNavigationButton({
    required this.item,
    required this.selected,
    required this.onPressed,
  });

  final _PatientNavigationItem item;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = selected
        ? colors.onPrimaryContainer
        : colors.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Tooltip(
        message: item.label,
        child: InkWell(
          key: Key('patient-nav-${item.destination.name}'),
          onTap: onPressed,
          child: ExcludeSemantics(
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 52,
                height: 44,
                decoration: BoxDecoration(
                  color: selected ? colors.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  color: foreground,
                  size: 25,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PatientNavigationItem {
  const _PatientNavigationItem({
    required this.destination,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final PatientDestination destination;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
