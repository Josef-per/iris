import 'package:flutter/material.dart';
import 'package:iris/features/professional/presentation/professional_frontend_store.dart';
import 'package:iris/features/professional/presentation/professional_mock_data.dart';

String? _required(String? value) {
  return value == null || value.trim().isEmpty ? 'Campo obrigatório' : null;
}

Future<void> _waitForDialogExit() {
  return Future<void>.delayed(const Duration(milliseconds: 250));
}

Future<bool> showProfessionalPatientForm(
  BuildContext context,
  ProfessionalFrontendStore store, {
  ProfessionalPatient? patient,
}) async {
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

  final saved =
      await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(patient == null ? 'Novo paciente' : 'Editar paciente'),
            content: SizedBox(
              width: 560,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        key: const Key('professional-patient-name'),
                        controller: name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Nome'),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      _ResponsiveDialogFields(
                        children: [
                          TextFormField(
                            controller: age,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Idade',
                            ),
                            validator: (value) {
                              final parsed = int.tryParse(value ?? '');
                              if (parsed == null || parsed < 1) {
                                return 'Idade inválida';
                              }
                              return null;
                            },
                          ),
                          DropdownButtonFormField<PatientStatus>(
                            initialValue: status,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                            ),
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
                        decoration: const InputDecoration(
                          labelText: 'Diagnóstico',
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'E-mail'),
                        validator: (value) {
                          final error = _required(value);
                          if (error != null) return error;
                          return value!.contains('@')
                              ? null
                              : 'E-mail inválido';
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Telefone',
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      _ResponsiveDialogFields(
                        children: [
                          TextFormField(
                            controller: birthDate,
                            decoration: const InputDecoration(
                              labelText: 'Nascimento',
                              hintText: 'DD/MM/AAAA',
                            ),
                            validator: _required,
                          ),
                          TextFormField(
                            controller: nextAppointment,
                            decoration: const InputDecoration(
                              labelText: 'Próxima consulta',
                            ),
                            validator: _required,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                key: const Key('professional-patient-save'),
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  final result = ProfessionalPatient(
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
                  if (patient == null) {
                    store.addPatient(result);
                  } else {
                    store.updatePatient(result);
                  }
                  Navigator.pop(context, true);
                },
                child: const Text('Salvar'),
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
  ProfessionalFrontendStore store,
) async {
  final formKey = GlobalKey<FormState>();
  final time = TextEditingController();
  var patient = store.patients.first;
  var type = 'Online';

  final saved =
      await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Nova consulta'),
            content: SizedBox(
              width: 440,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<ProfessionalPatient>(
                      initialValue: patient,
                      decoration: const InputDecoration(labelText: 'Paciente'),
                      items: store.patients
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
                      key: const Key('professional-appointment-time'),
                      controller: time,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(
                        labelText: 'Horário',
                        hintText: '14:30',
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(labelText: 'Formato'),
                      items: const [
                        DropdownMenuItem(
                          value: 'Online',
                          child: Text('Online'),
                        ),
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
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                key: const Key('professional-appointment-save'),
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  store.addAppointment(
                    ProfessionalAppointment(
                      time: time.text.trim(),
                      patient: patient,
                      type: type,
                    ),
                  );
                  Navigator.pop(context, true);
                },
                child: const Text('Adicionar'),
              ),
            ],
          ),
        ),
      ) ??
      false;
  await _waitForDialogExit();
  time.dispose();
  return saved;
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
    builder: (context) => AlertDialog(
      title: Text(medication == null ? 'Nova medicação' : 'Editar medicação'),
      content: SizedBox(
        width: 440,
        child: Form(
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
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 440,
        child: Form(
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
        builder: (context) => AlertDialog(
          title: const Text('Remover item?'),
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
