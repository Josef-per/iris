import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/professional/professional_repository.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ProfessionalInviteDialog extends StatefulWidget {
  const ProfessionalInviteDialog({
    super.key,
    required this.createInvite,
    required this.revokeInvite,
  });

  final Future<ProfessionalLinkInvite> Function() createInvite;
  final Future<void> Function(String inviteId) revokeInvite;

  @override
  State<ProfessionalInviteDialog> createState() =>
      _ProfessionalInviteDialogState();
}

class _ProfessionalInviteDialogState extends State<ProfessionalInviteDialog> {
  late Future<ProfessionalLinkInvite> _inviteFuture;
  bool _revoking = false;

  @override
  void initState() {
    super.initState();
    _inviteFuture = widget.createInvite();
  }

  void _retry() {
    setState(() => _inviteFuture = widget.createInvite());
  }

  Future<void> _revoke(ProfessionalLinkInvite invite) async {
    if (_revoking) return;
    setState(() => _revoking = true);
    try {
      await widget.revokeInvite(invite.id);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Convite revogado.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _revoking = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMessages.from(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Vincular paciente'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, minHeight: 260),
        child: FutureBuilder<ProfessionalLinkInvite>(
          future: _inviteFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 42,
                    color: AppColors.danger,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    AppErrorMessages.from(snapshot.error!),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.tonalIcon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              );
            }

            final invite = snapshot.data!;
            final hour = invite.expiresAt.hour.toString().padLeft(2, '0');
            final minute = invite.expiresAt.minute.toString().padLeft(2, '0');
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Peça ao paciente para escanear o QR Code.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.lavender),
                  ),
                  child: SizedBox.square(
                    // Bound both intrinsic dimensions before reaching the
                    // LayoutBuilder inside QrImageView.
                    // Subtract dialog insets (80), content padding (48),
                    // and the QR frame padding (28) on narrow screens.
                    dimension: (MediaQuery.sizeOf(context).width - 156).clamp(
                      1.0,
                      210.0,
                    ),
                    child: QrImageView(
                      data: invite.payload,
                      backgroundColor: AppColors.white,
                      eyeStyle: const QrEyeStyle(color: AppColors.ink),
                      dataModuleStyle: const QrDataModuleStyle(
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Válido até $hour:$minute',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: invite.payload),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Código copiado.')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copiar código'),
                ),
                OutlinedButton.icon(
                  onPressed: _revoking ? null : () => _revoke(invite),
                  icon: _revoking
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.block_rounded),
                  label: Text(_revoking ? 'Revogando...' : 'Revogar convite'),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _revoking ? null : () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
