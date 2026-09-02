import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';

class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.child,
    this.onClose,
    this.footer,
  });

  final Widget child;
  final Widget? footer;

  /// Chamado quando o usuário fecha o sheet pelo botão fechar. Quando omitido,
  /// o sheet apenas é fechado.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 700;
    final horizontalPadding = isCompact ? 20.0 : 32.0;

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: isCompact ? 1 : .88,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: Material(
              key: const Key('app-bottom-sheet-surface'),
              color: Theme.of(context).scaffoldBackgroundColor,
              clipBehavior: Clip.antiAlias,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 52,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            key: const Key('app-bottom-sheet-drag-handle'),
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: .4),
                              borderRadius: AppRadius.pill,
                            ),
                          ),
                          Positioned(
                            right: 4,
                            child: IconButton(
                              tooltip: 'Fechar',
                              onPressed:
                                  onClose ?? () => Navigator.maybePop(context),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          8,
                          horizontalPadding,
                          32,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 760),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                    if (footer != null) ...[
                      Divider(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          12,
                          horizontalPadding,
                          16,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 760),
                            child: footer!,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
