import 'package:flutter/material.dart';

enum AppReminderMenuAction { edit, delete }

class AppLembretesContent extends StatelessWidget {
  const AppLembretesContent({
    super.key,
    required this.icon,
    required this.categoryLabel,
    required this.textName,
    required this.textTime,
    required this.isActive,
    required this.onSwitchChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final IconData icon;
  final String categoryLabel;
  final String textName;
  final String textTime;
  final bool isActive;
  final ValueChanged<bool> onSwitchChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      label: '$categoryLabel: $textName, às $textTime',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
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
              child: Icon(icon, color: theme.colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    textName,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    textTime,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isActive ? 'Ativo' : 'Pausado',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 4),
                      Semantics(
                        label: '${isActive ? 'Pausar' : 'Ativar'} $textName',
                        child: Switch(
                          value: isActive,
                          onChanged: onSwitchChanged,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<AppReminderMenuAction>(
              tooltip: 'Mais ações para $textName',
              constraints: const BoxConstraints(minWidth: 180),
              onSelected: (action) {
                switch (action) {
                  case AppReminderMenuAction.edit:
                    onEdit();
                  case AppReminderMenuAction.delete:
                    onDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: AppReminderMenuAction.edit,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Editar'),
                  ),
                ),
                PopupMenuItem(
                  value: AppReminderMenuAction.delete,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: theme.colorScheme.error,
                    ),
                    title: Text(
                      'Excluir',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ),
              ],
              icon: const Icon(Icons.more_vert_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
