import 'package:flutter/material.dart';
import 'package:iris/core/errors/app_error_messages.dart';
import 'package:iris/features/professional/presentation/professional_frontend_store.dart';
import 'package:iris/features/professional/presentation/professional_models.dart';
import 'package:iris/features/professional/presentation/professional_shared_widgets.dart';

String? _required(String? value) {
  return value == null || value.trim().isEmpty ? 'Campo obrigatório' : null;
}

Future<void> _waitForDialogExit() {
  return Future<void>.delayed(const Duration(milliseconds: 250));
}

void showProfessionalOperationError(BuildContext context, Object error) {
  final message = error is ProfessionalSettingsPartialUpdateException
      ? error.message
      : AppErrorMessages.from(error);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void showProfessionalPatientRequired(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(content: Text('Vincule um paciente antes de continuar.')),
    );
}

Future<bool> showProfessionalPatientForm(
  BuildContext context,
  ProfessionalFrontendStore store, {
  ProfessionalPatient? patient,
}) async {
  if (patient == null && store.isConnected) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Use o QR Code para vincular um novo paciente.'),
      ),
    );
    return false;
  }

  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(text: patient?.name);
  final age = TextEditingController(text: patient?.age.toString());
  final diagnosis = TextEditingController(text: patient?.diagnosis);
  final email = TextEditingController(text: patient?.email);
  final phone = TextEditingController(text: patient?.phone);
  final birthDate = TextEditingController(text: patient?.birthDate);
  final nextAppointment = TextEditingController(
    text: patient?.nextAppointment ?? 'A definir',
  );
  var status = patient?.status ?? PatientStatus.active;
  var saving = false;

  final saved =
      await showDialog<bool>(
        context: context,
        useRootNavigator: false,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => ProfessionalResponsiveDialog(
            title: patient == null ? 'Novo paciente' : 'Editar paciente',
            canClose: !saving,
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (store.isConnected) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Dados pessoais são gerenciados pelo paciente.',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    key: const Key('professional-patient-name'),
                    controller: name,
                    enabled: !store.isConnected,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nome'),
                    validator: store.isConnected ? null : _required,
                  ),
                  const SizedBox(height: 12),
                  _ResponsiveDialogFields(
                    children: [
                      TextFormField(
                        controller: age,
                        enabled: !store.isConnected,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Idade'),
                        validator: (value) {
                          if (store.isConnected) return null;
                          final parsed = int.tryParse(value ?? '');
                          if (parsed == null || parsed < 1) {
                            return 'Idade inválida';
                          }
                          return null;
                        },
                      ),
                      DropdownButtonFormField<PatientStatus>(
                        initialValue: status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(
                            value: PatientStatus.active,
                            child: Text('Ativo'),
                          ),
                          DropdownMenuItem(
                            value: PatientStatus.inactive,
                            child: Text('Inativo'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => status = value);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: diagnosis,
                    decoration: const InputDecoration(labelText: 'Diagnóstico'),
                    validator: store.isConnected ? null : _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: email,
                    enabled: !store.isConnected,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                    validator: (value) {
                      if (store.isConnected) return null;
                      final error = _required(value);
                      if (error != null) return error;
                      return value!.contains('@') ? null : 'E-mail inválido';
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phone,
                    enabled: !store.isConnected,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Telefone'),
                    validator: store.isConnected ? null : _required,
                  ),
                  const SizedBox(height: 12),
                  _ResponsiveDialogFields(
                    children: [
                      TextFormField(
                        controller: birthDate,
                        enabled: !store.isConnected,
                        decoration: const InputDecoration(
                          labelText: 'Nascimento',
                          hintText: 'DD/MM/AAAA',
                        ),
                        validator: store.isConnected ? null : _required,
                      ),
                      TextFormField(
                        controller: nextAppointment,
                        enabled: !store.isConnected,
                        decoration: const InputDecoration(
                          labelText: 'Próxima consulta',
                        ),
                        validator: store.isConnected ? null : _required,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                key: const Key('professional-patient-save'),
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final result = store.isConnected && patient != null
                            ? patient.copyWith(
                                diagnosis: diagnosis.text.trim(),
                                status: status,
                              )
                            : ProfessionalPatient(
                                id:
                                    patient?.id ??
                                    'patient-${DateTime.now().microsecondsSinceEpoch}',
                                name: name.text.trim(),
                                age: int.parse(age.text),
                                diagnosis: diagnosis.text.trim(),
                                lastActivity: patient?.lastActivity ?? 'Agora',
                                status: status,
                                mood: patient?.mood ?? 'Bem',
                                email: email.text.trim(),
                                phone: phone.text.trim(),
                                birthDate: birthDate.text.trim(),
                                nextAppointment: nextAppointment.text.trim(),
                              );
                        setDialogState(() => saving = true);
                        try {
                          if (patient == null) {
                            await store.addPatient(result);
                          } else {
                            await store.updatePatient(result);
                          }
                          if (context.mounted) Navigator.pop(context, true);
                        } catch (error) {
                          if (!context.mounted) return;
                          setDialogState(() => saving = false);
                          showProfessionalOperationError(context, error);
                        }
                      },
                child: Text(saving ? 'Salvando...' : 'Salvar'),
              ),
            ],
          ),
        ),
      ) ??
      false;

  await _waitForDialogExit();
  for (final controller in [
    name,
    age,
    diagnosis,
    email,
    phone,
    birthDate,
    nextAppointment,
  ]) {
    controller.dispose();
  }
  return saved;
}

class _ResponsiveDialogFields extends StatelessWidget {
  const _ResponsiveDialogFields({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                SizedBox(width: double.infinity, child: children[index]),
                if (index < children.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              Expanded(child: children[index]),
              if (index < children.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

Future<bool> showProfessionalAppointmentForm(
  BuildContext context,
  ProfessionalFrontendStore store, {
  DateTime? initialDate,
}) async {
  final eligiblePatients = store.isConnected
      ? store.patients
            .where((patient) => patient.status == PatientStatus.active)
            .toList()
      : store.patients;
  if (eligiblePatients.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          store.patients.isEmpty
              ? 'Vincule um paciente antes de continuar.'
              : 'Ative o acompanhamento de um paciente antes de agendar.',
        ),
      ),
    );
    return false;
  }

  final formKey = GlobalKey<FormState>();
  var selectedDate = initialDate ?? DateTime.now();
  final date = TextEditingController(
    text: _formatAppointmentDate(selectedDate),
  );
  final time = TextEditingController();
  var patient = eligiblePatients[0];
  var type = 'Online';
  var saving = false;

  final saved =
      await showDialog<bool>(
        context: context,
        useRootNavigator: false,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => ProfessionalResponsiveDialog(
            title: 'Nova consulta',
            maxWidth: 440,
            canClose: !saving,
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<ProfessionalPatient>(
                    initialValue: patient,
                    decoration: const InputDecoration(labelText: 'Paciente'),
                    items: eligiblePatients
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => patient = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: date,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Data',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        useRootNavigator: false,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (picked == null) return;
                      setDialogState(() {
                        selectedDate = picked;
                        date.text = _formatAppointmentDate(picked);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('professional-appointment-time'),
                    controller: time,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: 'Horário',
                      hintText: '14:30',
                    ),
                    validator: (value) {
                      final requiredError = _required(value);
                      if (requiredError != null) return requiredError;
                      final startsAt = _combineAppointmentDateAndTime(
                        selectedDate,
                        value!,
                      );
                      if (startsAt == null) return 'Use o formato HH:mm';
                      if (!startsAt.isAfter(DateTime.now())) {
                        return 'Informe uma data e horário futuros';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Formato'),
                    items: const [
                      DropdownMenuItem(value: 'Online', child: Text('Online')),
                      DropdownMenuItem(
                        value: 'Presencial',
                        child: Text('Presencial'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setDialogState(() => type = value);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                key: const Key('professional-appointment-save'),
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final cleanTime = time.text.trim();
                        final startsAt = _combineAppointmentDateAndTime(
                          selectedDate,
                          cleanTime,
                        );
                        if (startsAt == null ||
                            !startsAt.isAfter(DateTime.now())) {
                          formKey.currentState!.validate();
                          return;
                        }
                        setDialogState(() => saving = true);
                        try {
                          await store.addAppointment(
                            ProfessionalAppointment(
                              startsAt: startsAt,
                              time: cleanTime,
                              patient: patient,
                              type: type,
                            ),
                          );
                          if (context.mounted) Navigator.pop(context, true);
                        } catch (error) {
                          if (!context.mounted) return;
                          setDialogState(() => saving = false);
                          showProfessionalOperationError(context, error);
                        }
                      },
                child: Text(saving ? 'Adicionando...' : 'Adicionar'),
              ),
            ],
          ),
        ),
      ) ??
      false;
  await _waitForDialogExit();
  date.dispose();
  time.dispose();
  return saved;
}

DateTime? _parseAppointmentTime(String value) {
  final match = RegExp(
    r'^([01]?\d|2[0-3]):([0-5]\d)$',
  ).firstMatch(value.trim());
  if (match == null) return null;
  final now = DateTime.now();
  return DateTime(
    now.year,
    now.month,
    now.day,
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
  );
}

DateTime? _combineAppointmentDateAndTime(DateTime date, String time) {
  final parsedTime = _parseAppointmentTime(time);
  if (parsedTime == null) return null;
  return DateTime(
    date.year,
    date.month,
    date.day,
    parsedTime.hour,
    parsedTime.minute,
  );
}

String _formatAppointmentDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

Future<ProfessionalMedication?> showProfessionalMedicationForm(
  BuildContext context, {
  ProfessionalMedication? medication,
}) async {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(text: medication?.name);
  final dose = TextEditingController(text: medication?.dose);
  final frequency = TextEditingController(text: medication?.frequency);
  final adherence = TextEditingController(
    text: ((medication?.adherence ?? 1) * 100).round().toString(),
  );

  final result = await showDialog<ProfessionalMedication>(
    context: context,
    useRootNavigator: false,
    builder: (context) => ProfessionalResponsiveDialog(
      title: medication == null ? 'Nova medicação' : 'Editar medicação',
      maxWidth: 440,
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('professional-medication-name'),
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Medicação'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: dose,
              decoration: const InputDecoration(labelText: 'Dose'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: frequency,
              decoration: const InputDecoration(labelText: 'Frequência'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: adherence,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Adesão (%)'),
              validator: (value) {
                final parsed = double.tryParse(value ?? '');
                if (parsed == null || parsed < 0 || parsed > 100) {
                  return 'Use um valor entre 0 e 100';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('professional-medication-save'),
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              ProfessionalMedication(
                name: name.text.trim(),
                dose: dose.text.trim(),
                frequency: frequency.text.trim(),
                adherence: double.parse(adherence.text) / 100,
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  );

  await _waitForDialogExit();
  name.dispose();
  dose.dispose();
  frequency.dispose();
  adherence.dispose();
  return result;
}

Future<String?> showProfessionalTextItemForm(
  BuildContext context, {
  required String title,
  required String label,
  String? initialValue,
  int maxLines = 1,
}) async {
  final formKey = GlobalKey<FormState>();
  final controller = TextEditingController(text: initialValue);
  final result = await showDialog<String>(
    context: context,
    useRootNavigator: false,
    builder: (context) => ProfessionalResponsiveDialog(
      title: title,
      maxWidth: 440,
      content: Form(
        key: formKey,
        child: TextFormField(
          key: const Key('professional-text-item'),
          controller: controller,
          autofocus: true,
          minLines: maxLines > 1 ? 3 : 1,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label),
          validator: _required,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('professional-text-item-save'),
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            Navigator.pop(context, controller.text.trim());
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
  await _waitForDialogExit();
  controller.dispose();
  return result;
}

Future<bool> showProfessionalDeleteConfirmation(
  BuildContext context, {
  required String item,
}) async {
  return await showDialog<bool>(
        context: context,
        useRootNavigator: false,
        builder: (context) => ProfessionalResponsiveDialog(
          title: 'Remover item?',
          maxWidth: 420,
          content: Text(item),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remover'),
            ),
          ],
        ),
      ) ??
      false;
}
