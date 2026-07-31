class ProfessionalQrPayload {
  static const scheme = 'iris';
  static const host = 'vincular';
  static const path = 'profissional';
  static const version = '1';
  static final _tokenPattern = RegExp(r'^[0-9a-f]{64}$');

  static String build(String inviteToken) {
    final token = inviteToken.trim().toLowerCase();
    if (!_tokenPattern.hasMatch(token)) {
      throw const FormatException('Token de convite inválido.');
    }
    return Uri(
      scheme: scheme,
      host: host,
      pathSegments: const [path],
      queryParameters: {'v': version, 'token': token},
    ).toString();
  }
}
