class PatientSymptom {
  const PatientSymptom({
    required this.code,
    required this.label,
    required this.legacyIndex,
  });

  final String code;
  final String label;
  final int legacyIndex;
}

class PatientSymptoms {
  const PatientSymptoms._();

  static const emotional = <PatientSymptom>[
    PatientSymptom(code: 'inseguranca', label: 'Insegurança', legacyIndex: 0),
    PatientSymptom(code: 'culpa', label: 'Culpa', legacyIndex: 1),
    PatientSymptom(
      code: 'vomito_autoinduzido',
      label: 'Vômito autoinduzido',
      legacyIndex: 2,
    ),
    PatientSymptom(code: 'medo', label: 'Medo', legacyIndex: 3),
    PatientSymptom(code: 'compulsao', label: 'Compulsão', legacyIndex: 4),
    PatientSymptom(code: 'ansiedade', label: 'Ansiedade', legacyIndex: 5),
  ];

  static const physical = <PatientSymptom>[
    PatientSymptom(
      code: 'cansaco_excessivo',
      label: 'Cansaço excessivo',
      legacyIndex: 0,
    ),
    PatientSymptom(
      code: 'alteracao_pressao',
      label: 'Alteração na pressão',
      legacyIndex: 1,
    ),
    PatientSymptom(
      code: 'problemas_digestivos',
      label: 'Problemas digestivos',
      legacyIndex: 2,
    ),
    PatientSymptom(
      code: 'queda_cabelo',
      label: 'Queda de cabelo',
      legacyIndex: 3,
    ),
    PatientSymptom(
      code: 'dificuldade_concentracao',
      label: 'Dificuldade de concentração',
      legacyIndex: 4,
    ),
    PatientSymptom(code: 'desmaio', label: 'Desmaio', legacyIndex: 5),
    PatientSymptom(code: 'fraqueza', label: 'Fraqueza', legacyIndex: 6),
    PatientSymptom(code: 'tontura', label: 'Tontura', legacyIndex: 7),
    PatientSymptom(code: 'nausea', label: 'Náuseas', legacyIndex: 8),
    PatientSymptom(code: 'dor_cabeca', label: 'Dor de cabeça', legacyIndex: 9),
  ];

  static Set<String> decode(
    Object? storedValue,
    List<PatientSymptom> definitions,
  ) {
    if (storedValue is! List) {
      return <String>{};
    }

    final legacyCodes = {
      for (final symptom in definitions) symptom.legacyIndex: symptom.code,
    };
    final result = <String>{};

    for (final value in storedValue) {
      if (value is int) {
        final code = legacyCodes[value];
        if (code != null) {
          result.add(code);
        }
        continue;
      }

      final text = value?.toString().trim() ?? '';
      if (text.isEmpty) {
        continue;
      }
      final legacyIndex = int.tryParse(text);
      if (legacyIndex != null) {
        final code = legacyCodes[legacyIndex];
        if (code != null) {
          result.add(code);
        }
      } else {
        result.add(text);
      }
    }

    return result;
  }

  static List<int> selectedIndexes(
    Set<String> selectedCodes,
    List<PatientSymptom> definitions,
  ) => [
    for (var index = 0; index < definitions.length; index++)
      if (selectedCodes.contains(definitions[index].code)) index,
  ];
}
