class EmergencyContact {
  const EmergencyContact({required this.name, required this.phone});

  final String name;
  final String phone;

  factory EmergencyContact.fromMap(Map<String, dynamic> map) =>
      EmergencyContact(
        name: (map['nome'] as String).trim(),
        phone: (map['telefone'] as String).trim(),
      );

  static String? normalizePhone(String input) {
    final value = input.trim().replaceAll(RegExp(r'[\s().-]'), '');
    if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(value)) return null;
    return value;
  }
}
