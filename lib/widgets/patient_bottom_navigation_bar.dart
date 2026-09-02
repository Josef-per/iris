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
      destination: PatientDestination.home,
      label: 'Hoje',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _PatientNavigationItem(
      destination: PatientDestination.history,
      label: 'Registros',
      icon: Icons.history_rounded,
      selectedIcon: Icons.history_rounded,
    ),
    _PatientNavigationItem(
      destination: PatientDestination.carePlan,
      label: 'Plano de cuidado',
      compactLabel: 'Plano',
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
    final effectiveDestination = switch (selectedDestination) {
      PatientDestination.reminders ||
      PatientDestination.supportSuggestions => PatientDestination.home,
      _ => selectedDestination,
    };
    return Material(
      color: colors.surface,
      elevation: 8,
      shadowColor: colors.shadow.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 76,
        child: Row(
          children: [
            for (final item in _items)
              Expanded(
                child: _PatientNavigationButton(
                  item: item,
                  selected: effectiveDestination == item.destination,
                  onPressed: () => onDestinationSelected(item.destination),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PatientNavigationRail extends StatelessWidget {
  const PatientNavigationRail({
    super.key,
    required this.selectedDestination,
    required this.onDestinationSelected,
  });

  final PatientDestination selectedDestination;
  final ValueChanged<PatientDestination> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final effectiveDestination = switch (selectedDestination) {
      PatientDestination.reminders ||
      PatientDestination.supportSuggestions => PatientDestination.home,
      _ => selectedDestination,
    };
    final selectedIndex = PatientBottomNavigationBar._items.indexWhere(
      (item) => item.destination == effectiveDestination,
    );

    return NavigationRail(
      extended: true,
      minExtendedWidth: 224,
      groupAlignment: -.72,
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      onDestinationSelected: (index) => onDestinationSelected(
        PatientBottomNavigationBar._items[index].destination,
      ),
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        child: Row(
          children: [
            Icon(
              Icons.favorite_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Text('Íris', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
      destinations: [
        for (final item in PatientBottomNavigationBar._items)
          NavigationRailDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: Text(item.label),
          ),
      ],
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
    final foreground = selected ? colors.primary : colors.onSurfaceVariant;
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: selected ? 42 : 38,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? colors.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        selected ? item.selectedIcon : item.icon,
                        key: ValueKey(selected),
                        color: foreground,
                        size: 23,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                    child: Text(
                      item.compactLabel ?? item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
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
    this.compactLabel,
  });

  final PatientDestination destination;
  final String label;
  final String? compactLabel;
  final IconData icon;
  final IconData selectedIcon;
}
