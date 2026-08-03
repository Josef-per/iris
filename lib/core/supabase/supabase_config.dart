import 'package:flutter/foundation.dart';

class SupabaseConfig {
  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _authRedirectUrl = String.fromEnvironment(
    'SUPABASE_AUTH_REDIRECT_URL',
  );
  static const _dartDefinePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const _dartDefineAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get url {
    return _url.trim();
  }

  static String get publishableKey {
    if (_dartDefinePublishableKey.isNotEmpty) {
      return _dartDefinePublishableKey;
    }

    if (_dartDefineAnonKey.isNotEmpty) {
      return _dartDefineAnonKey;
    }
    return '';
  }

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;

  /// Callback usado pelos emails de confirmacao e recuperacao de senha.
  ///
  /// O valor precisa estar cadastrado em Authentication > URL Configuration
  /// no projeto Supabase. Em builds web, defina SUPABASE_AUTH_REDIRECT_URL com
  /// a URL publica da aplicacao.
  static String get authRedirectUrl {
    final configuredUrl = _authRedirectUrl.trim();
    if (configuredUrl.isNotEmpty) return configuredUrl;
    if (kIsWeb) return Uri.base.origin;
    return 'io.supabase.iris://auth-callback';
  }
}
