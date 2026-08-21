import 'package:url_launcher/url_launcher.dart';

/// Abre uma discagem telefônica real (ex.: `tel:192`).
///
/// O protótipo permite injetar um lançador falso nos testes para não depender
/// de plataforma.
typedef PhoneLauncher = Future<bool> Function(String phoneNumber);

/// Lançador padrão usando `tel:`; em plataformas sem discagem (ex.: web sem
/// telefone) retorna [false] sem erro.
Future<bool> defaultPhoneLauncher(String phoneNumber) async {
  final uri = Uri(scheme: 'tel', path: phoneNumber);
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri);
}