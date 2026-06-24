import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _dartDefinePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const _dartDefineAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get url {
    if (_url.isNotEmpty) {
      return _url;
    }

    return dotenv.maybeGet('SUPABASE_URL') ?? '';
  }

  static String get publishableKey {
    if (_dartDefinePublishableKey.isNotEmpty) {
      return _dartDefinePublishableKey;
    }

    if (_dartDefineAnonKey.isNotEmpty) {
      return _dartDefineAnonKey;
    }

    return dotenv.maybeGet('SUPABASE_PUBLISHABLE_KEY') ??
        dotenv.maybeGet('SUPABASE_ANON_KEY') ??
        '';
  }

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
