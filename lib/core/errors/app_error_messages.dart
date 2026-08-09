import 'package:iris/core/supabase/supabase_client_provider.dart';
import 'package:iris/features/auth/auth_service.dart';
import 'package:iris/features/professional/data/supabase_professional_workspace_backend.dart';
import 'package:iris/features/users/user_repository.dart';
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
      return 'O serviço está temporariamente indisponível. Tente novamente mais tarde.';
    }

    if (error is AccountTypeMismatchException) {
      return 'Esta conta pertence a outro perfil. Selecione “Sou paciente” ou “Sou profissional” corretamente e tente novamente.';
    }

    if (error is UserRoleConflictException) {
      return 'Esta conta já está vinculada a outro tipo de perfil.';
    }

    if (error is ProfessionalWorkspaceException) {
      return error.message;
    }

    final message = error.toString().toLowerCase();

    if (message.contains('usuario nao autenticado')) {
      return 'Entre na sua conta para salvar seus registros.';
    }

    if (message.contains('codigo qr invalido')) {
      return 'Código QR inválido. Tente escanear novamente ou insira o código manualmente.';
    }

    if (message.contains('profissional nao encontrado')) {
      return 'Profissional não encontrado. Confira o QR Code com seu psiquiatra.';
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
      return 'O envio de novos e-mails foi limitado por alguns instantes. Aguarde cerca de 1 minuto e tente novamente. Se a conta já foi criada, verifique seu e-mail e a caixa de spam.';
    }

    if (code == 'email_exists' ||
        code == 'user_already_exists' ||
        message.contains('already registered')) {
      return 'Esse e-mail já está cadastrado. Tente entrar com ele.';
    }

    if (code == 'email_not_confirmed' || message.contains('not confirmed')) {
      return 'Confirme seu e-mail antes de entrar.';
    }

    if (code == 'invalid_credentials' ||
        message.contains('invalid login credentials')) {
      return 'E-mail ou senha incorretos.';
    }

    if (code == 'weak_password' || error is AuthWeakPasswordException) {
      return 'A senha ainda está fraca. Use pelo menos 8 caracteres e evite senhas muito simples.';
    }

    if (error.statusCode == '429') {
      return 'Muitas tentativas em pouco tempo. Aguarde alguns instantes e tente novamente.';
    }

    if (message.contains('signup is disabled')) {
      return 'Novos cadastros estão temporariamente indisponíveis.';
    }

    if (message.contains('database error') ||
        message.contains('saving new user') ||
        code == 'unexpected_failure') {
      return 'Não foi possível concluir o cadastro agora. Tente novamente mais tarde.';
    }

    return 'Não foi possível autenticar agora. Tente novamente.';
  }

  static String _fromDatabase(PostgrestException error) {
    final message = error.message.toLowerCase();
    final code = error.code;

    if (code == 'PGRST202' && message.contains('iris_bootstrap_current_user')) {
      return 'O serviço está temporariamente indisponível. Tente novamente mais tarde.';
    }

    if (code == 'PGRST202') {
      return 'O serviço está temporariamente indisponível. Tente novamente mais tarde.';
    }

    if (code == 'PGRST205') {
      return 'O serviço está temporariamente indisponível. Tente novamente mais tarde.';
    }

    if (code == '42804' &&
        message.contains('structure of query does not match function result')) {
      return 'Não foi possível validar o QR Code agora. Tente novamente mais tarde.';
    }

    if (message.contains('invalid_or_expired_invite') ||
        message.contains('invite_already_used') ||
        message.contains('invite_unavailable')) {
      return 'Este QR Code expirou, foi revogado ou já foi utilizado.';
    }

    if (message.contains('invalid_invite')) {
      return 'Código QR inválido.';
    }

    if (message.contains('professional_not_approved') ||
        message.contains('professional_not_active')) {
      return 'Seu cadastro profissional aguarda aprovação.';
    }

    if (message.contains('professional_required')) {
      return 'Entre com uma conta profissional para continuar.';
    }

    if (message.contains('patient_required')) {
      return 'Entre com uma conta de paciente para vincular o profissional.';
    }

    if (message.contains('auth_required')) {
      return 'Sua sessão expirou. Entre novamente.';
    }

    if (message.contains('account_inactive')) {
      return 'Esta conta está desativada. Procure o suporte.';
    }

    if (message.contains('email_required')) {
      return 'Sua conta não possui um email válido.';
    }

    if (message.contains('invalid_account_type')) {
      return 'Escolha “Sou paciente” ou “Sou profissional”.';
    }

    if (message.contains('link_access_denied')) {
      return 'Este paciente não está disponível para sua conta.';
    }

    if (message.contains('invalid_follow_up_status')) {
      return 'Escolha o status ativo ou inativo.';
    }

    if (message.contains('appointment_must_be_future')) {
      return 'Informe uma data e um horário futuros para a consulta.';
    }

    if (message.contains('invalid_local_date')) {
      return 'A data do aparelho não corresponde ao dia atual. Confira data e fuso horário e tente novamente.';
    }

    if (message.contains('invalid_time_zone')) {
      return 'Não foi possível validar o fuso horário do aparelho.';
    }

    if (message.contains('invalid_mood_score') ||
        message.contains('invalid_food_score')) {
      return 'Selecione respostas válidas para concluir o check-in.';
    }

    if (message.contains('invalid_credential_status')) {
      return 'Status de credenciamento inválido.';
    }

    if (message.contains('name_required')) {
      return 'Informe seu nome.';
    }

    if (code == '42P01') {
      return 'O serviço está temporariamente indisponível. Tente novamente mais tarde.';
    }

    if (code == '42501' || message.contains('row-level security')) {
      return 'Sua conta não tem permissão para esta ação. Entre novamente ou procure o suporte.';
    }

    if (code == '23503') {
      return 'Não foi possível encontrar um registro relacionado.';
    }

    if (code == '23505') {
      return 'Esse registro já existe.';
    }

    if (code == '23514') {
      return 'Confira os dados informados antes de salvar.';
    }

    return 'Não foi possível salvar ou carregar os dados agora.';
  }
}
