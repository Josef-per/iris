class ProfessionalQrPayload {
  static const scheme = 'iris';
  static const host = 'vincular';
  static const pathPrefix = 'profissional';

  static String build(String profissionalId) {
    final normalizedId = profissionalId.trim().toLowerCase();
    return '$scheme://$host/$pathPrefix/$normalizedId';
  }
}
