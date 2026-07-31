import 'package:iris/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientProvider {
  static SupabaseClient get client {
    if (!SupabaseConfig.isConfigured) {
      throw const SupabaseConfigException();
    }

    return Supabase.instance.client;
  }
}

class SupabaseConfigException implements Exception {
  const SupabaseConfigException();

  @override
  String toString() {
    return 'Supabase nao configurado. Use --dart-define para URL e chave publicavel.';
  }
}
