import 'package:iris/core/qr/professional_qr_payload.dart';

class ProfessionalQrParser {
  static final _tokenPattern = RegExp(r'^[0-9a-fA-F]{64}$');

  static String? parseInviteToken(String rawValue) {
    final value = rawValue.trim();

    if (_tokenPattern.hasMatch(value)) return value.toLowerCase();

    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != ProfessionalQrPayload.scheme ||
        uri.host != ProfessionalQrPayload.host ||
        uri.pathSegments.length != 1 ||
        uri.pathSegments.single != ProfessionalQrPayload.path ||
        uri.fragment.isNotEmpty ||
        uri.queryParameters.length != 2 ||
        uri.queryParametersAll['v']?.length != 1 ||
        uri.queryParametersAll['token']?.length != 1 ||
        uri.queryParameters['v'] != ProfessionalQrPayload.version) {
      return null;
    }

    final token = uri.queryParameters['token'];
    if (token == null || !_tokenPattern.hasMatch(token)) return null;
    return token.toLowerCase();
  }

  @Deprecated('Use parseInviteToken para convites temporários.')
  static String? parseProfissionalId(String rawValue) =>
      parseInviteToken(rawValue);
}
