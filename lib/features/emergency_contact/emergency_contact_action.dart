import 'package:flutter/material.dart';
import 'package:iris/features/emergency_contact/emergency_contact.dart';
import 'package:iris/features/emergency_contact/emergency_contact_repository.dart';
import 'package:iris/features/support_exercises/presentation/support_phone_launcher.dart';
import 'package:iris/features/support_exercises/presentation/widgets/option_card.dart';

class EmergencyContactAction extends StatefulWidget {
  const EmergencyContactAction({
    super.key,
    required this.actionKey,
    required this.phoneLauncher,
    this.dataSource,
  });

  final Key actionKey;
  final PhoneLauncher phoneLauncher;
  final EmergencyContactDataSource? dataSource;

  @override
  State<EmergencyContactAction> createState() => _EmergencyContactActionState();
}

class _EmergencyContactActionState extends State<EmergencyContactAction> {
  late final EmergencyContactDataSource _source =
      widget.dataSource ?? EmergencyContactRepository();
  late final Future<EmergencyContact?> _contact = _source.load();

  Future<void> _call(EmergencyContact contact) async {
    final phone = EmergencyContact.normalizePhone(contact.phone);
    if (phone == null) return;
    final opened = await widget.phoneLauncher(phone);
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível abrir a discagem. Ligue você mesmo para $phone.',
          ),
        ),
      );
  }

  Future<void> _showMissing() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Chamar uma pessoa de confiança'),
      content: const Text(
        'Nenhuma mensagem será enviada. Cadastre uma pessoa segura em Perfil > Contato de emergência para poder ligar daqui.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendi'),
        ),
      ],
    ),
  );

  Future<void> _showUnavailable() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Contato indisponível'),
      content: const Text(
        'Não foi possível carregar seu contato agora. Confira o cadastro no perfil ou tente novamente mais tarde. Nenhuma ligação foi iniciada.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendi'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<EmergencyContact?>(
    future: _contact,
    builder: (context, snapshot) {
      final contact = snapshot.data;
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        );
      }
      final unavailable = snapshot.hasError;
      return OptionCard(
        key: widget.actionKey,
        label: contact == null || unavailable
            ? 'Chamar uma pessoa de confiança'
            : 'Ligar para ${contact.name}',
        subtitle: unavailable
            ? 'Contato indisponível — confira o perfil'
            : contact == null
            ? 'Cadastre um contato no perfil — nenhuma mensagem será enviada'
            : '${contact.phone} · Abre a discagem somente após seu toque',
        selected: false,
        icon: Icons.favorite_rounded,
        onTap: unavailable
            ? _showUnavailable
            : contact == null
            ? _showMissing
            : () => _call(contact),
      );
    },
  );
}
