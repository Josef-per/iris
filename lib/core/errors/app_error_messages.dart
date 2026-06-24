import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppErrorMessages {
  static String from(Object error) {
    if (error is AuthException) {
      return _fromAuth(error);
    }

    if (error is PostgrestException) {
      return _fromDatabase(error);
    }

    if (error is SupabaseConfigException) {
      return 'Configure SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY no arquivo .env.';
    }

    final message = error.toString().toLowerCase();

    if (message.contains('usuario nao autenticado')) {
      return 'Entre na sua conta para salvar seus registros.';
    }

    if (message.contains('codigo qr invalido')) {
      return 'Codigo QR invalido. Tente escanear novamente ou insira o codigo manualmente.';
    }

    if (message.contains('profissional nao encontrado')) {
      return 'Profissional nao encontrado. Confira o QR Code com seu psiquiatra.';
    }

    return 'Algo deu errado. Tente novamente.';
  }

  static String _fromAuth(AuthException error) {
    final message = error.message.toLowerCase();
    final code = error.code;

    if (code == 'over_email_send_rate_limit' ||
        message.contains('email rate limit') ||
        message.contains('blocked new email') ||
        message.contains('blocked new emails')) {
      return 'O Supabase bloqueou novos emails por alguns instantes. Aguarde cerca de 1 minuto e tente novamente. Se a conta ja foi criada, verifique seu email ou sua caixa de spam.';
    }

    if (code == 'email_exists' ||
        code == 'user_already_exists' ||
        message.contains('already registered')) {
      return 'Esse email ja esta cadastrado. Tente entrar com ele.';
    }

    if (code == 'email_not_confirmed' || message.contains('not confirmed')) {
      return 'Confirme seu email antes de entrar.';
    }

    if (code == 'invalid_credentials' ||
        message.contains('invalid login credentials')) {
      return 'Email ou senha incorretos.';
    }

    if (code == 'weak_password' || error is AuthWeakPasswordException) {
      return 'A senha ainda esta fraca. Use pelo menos 8 caracteres e evite senhas muito simples.';
    }

    if (error.statusCode == '429') {
      return 'Muitas tentativas em pouco tempo. Aguarde alguns instantes e tente novamente.';
    }

    if (message.contains('signup is disabled')) {
      return 'Cadastro desativado no Supabase Auth.';
    }

    if (message.contains('database error') ||
        message.contains('saving new user') ||
        code == 'unexpected_failure') {
      return 'O Supabase criou uma falha no gatilho de cadastro do banco. Aplique a migration 0004 e tente novamente.';
    }

    return 'Nao foi possivel autenticar agora. Tente novamente.';
  }

  static String _fromDatabase(PostgrestException error) {
    final message = error.message.toLowerCase();
    final code = error.code;

    if (code == '42P01') {
      return 'Tabela do banco nao encontrada. Aplique as migrations do Supabase.';
    }

    if (code == '42501' || message.contains('row-level security')) {
      return 'Voce nao tem permissao para essa acao. Verifique a sessao e as policies RLS.';
    }

    if (code == '23503') {
      return 'Nao foi possivel encontrar um registro relacionado no banco.';
    }

    if (code == '23505') {
      return 'Esse registro ja existe.';
    }

    if (code == '23514') {
      return 'Confira os dados informados antes de salvar.';
    }

    return 'Nao foi possivel salvar ou carregar os dados agora.';
  }
}
