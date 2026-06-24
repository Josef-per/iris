import 'package:iris/core/qr/professional_qr_payload.dart';

class ProfessionalQrParser {
  static final _uuidPattern = RegExp(
    r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
  );

  static String? parseProfissionalId(String rawValue) {
    final value = rawValue.trim();

    if (value.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(value);
    if (uri != null &&
        uri.scheme == ProfessionalQrPayload.scheme &&
        uri.host == ProfessionalQrPayload.host) {
      final segments = uri.pathSegments;
      if (segments.length >= 2 &&
          segments[segments.length - 2] == ProfessionalQrPayload.pathPrefix) {
        final candidate = segments.last;
        if (_uuidPattern.hasMatch(candidate)) {
          return candidate.toLowerCase();
        }
      }
    }

    final directMatch = _uuidPattern.firstMatch(value);
    if (directMatch != null && directMatch.group(0) == value) {
      return value.toLowerCase();
    }

    if (uri != null) {
      for (final segment in uri.pathSegments.reversed) {
        final match = _uuidPattern.firstMatch(segment);
        if (match != null) {
          return match.group(0)!.toLowerCase();
        }
      }

      for (final queryValue in uri.queryParameters.values) {
        final match = _uuidPattern.firstMatch(queryValue);
        if (match != null) {
          return match.group(0)!.toLowerCase();
        }
      }
    }

    final embeddedMatch = _uuidPattern.firstMatch(value);
    return embeddedMatch?.group(0)?.toLowerCase();
  }
}
