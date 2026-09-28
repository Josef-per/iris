import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/core/theme/app_theme.dart';
import 'package:iris/features/emergency_contact/emergency_contact.dart';
import 'package:iris/features/emergency_contact/emergency_contact_repository.dart';
import 'package:iris/widgets/app_responsive.dart';

class EmergencyContactEditor extends StatefulWidget {
  const EmergencyContactEditor({super.key, this.dataSource});

  final EmergencyContactDataSource? dataSource;

  @override
  State<EmergencyContactEditor> createState() => _EmergencyContactEditorState();
}

class _EmergencyContactEditorState extends State<EmergencyContactEditor> {
  late final EmergencyContactDataSource _source =
      widget.dataSource ?? EmergencyContactRepository();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  late Future<EmergencyContact?> _contact;
  EmergencyContact? _saved;
  bool _editing = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _contact = _source.load();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _edit() {
    _name.text = _saved?.name ?? '';
    _phone.text = _saved?.phone ?? '';
    setState(() => _editing = true);
  }

  void _reload() => setState(() => _contact = _source.load());

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final contact = EmergencyContact(
      name: _name.text.trim(),
      phone: EmergencyContact.normalizePhone(_phone.text)!,
    );
    setState(() => _busy = true);
    try {
      await _source.save(contact);
      if (!mounted) return;
      setState(() {
        _saved = contact;
        _contact = Future.value(contact);
        _editing = false;
      });
      _message('Contato de emergência salvo.');
    } catch (error) {
      if (mounted) _message(AppErrorMessages.from(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover contato de emergência?'),
        content: const Text('Você poderá cadastrar outro contato depois.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _source.delete();
      if (!mounted) return;
      setState(() {
        _saved = null;
        _contact = Future.value(null);
        _editing = false;
      });
      _message('Contato de emergência removido.');
    } catch (error) {
      if (mounted) _message(AppErrorMessages.from(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => AppSurface(
    child: FutureBuilder<EmergencyContact?>(
      future: _contact,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Não foi possível carregar o contato de emergência.'),
              TextButton(
                onPressed: _reload,
                child: const Text('Tentar novamente'),
              ),
            ],
          );
        }
        _saved = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Contato de emergência',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Escolha uma pessoa segura. O app só abre a discagem quando você tocar em ligar.',
            ),
            const SizedBox(height: 16),
            if (_editing) ...[
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      key: const Key('emergency-contact-name'),
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'Nome da pessoa',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Informe o nome.'
                          : null,
                    ),
                    TextFormField(
                      key: const Key('emergency-contact-phone'),
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      maxLength: 25,
                      decoration: const InputDecoration(
                        labelText: 'Telefone com DDD',
                      ),
                      validator: (value) =>
                          EmergencyContact.normalizePhone(value ?? '') == null
                          ? 'Informe um telefone válido com DDD.'
                          : null,
                    ),
                  ],
                ),
              ),
              FilledButton(
                key: const Key('emergency-contact-save'),
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Salvando...' : 'Salvar contato'),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() => _editing = false),
                child: const Text('Cancelar'),
              ),
            ] else ...[
              if (_saved == null)
                const Text('Nenhum contato cadastrado.')
              else ...[
                Text(
                  _saved!.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(_saved!.phone),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('emergency-contact-edit'),
                onPressed: _busy ? null : _edit,
                icon: const Icon(Icons.edit_outlined),
                label: Text(
                  _saved == null ? 'Cadastrar contato' : 'Editar contato',
                ),
              ),
              if (_saved != null)
                TextButton(
                  key: const Key('emergency-contact-delete'),
                  onPressed: _busy ? null : _delete,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                  child: const Text('Remover contato'),
                ),
            ],
          ],
        );
      },
    ),
  );
}
