enum MealType {
  cafeDaManha('cafe_da_manha', 'Café da manhã'),
  almoco('almoco', 'Almoço'),
  jantar('jantar', 'Jantar'),
  lanche('lanche', 'Lanche');

  const MealType(this.code, this.label);

  final String code;
  final String label;

  static MealType? fromCode(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    for (final type in MealType.values) {
      if (type.code == text) {
        return type;
      }
    }
    return null;
  }

  static String labelOf(Object? code) => fromCode(code)?.label ?? 'Refeição';
}
