class DatabaseTables {
  static const usuarios = 'usuarios';
  static const perfis = 'perfis';
  static const pacientes = 'pacientes';
  static const profissionais = 'profissionais';
  static const pacienteProfissional = 'paciente_profissional';
  static const registrosAlimentares = 'registros_alimentares';
  static const registrosEmocionais = 'registros_emocionais';
  static const topicosApoio = 'topicos_apoio';
  static const consultas = 'consultas';
  static const anotacoesClinicas = 'anotacoes_clinicas';
  static const planosCuidado = 'planos_cuidado';
  static const metasCuidado = 'metas_cuidado';
  static const medicacoesPlano = 'medicacoes_plano';
  static const convitesVinculoProfissional = 'convites_vinculo_profissional';
  static const lembretes = 'lembretes';
}

class PatientProfessionalStatus {
  static const ativo = 'ativo';
  static const inativo = 'inativo';
}

class UserTypes {
  static const paciente = 'paciente';
  static const profissional = 'profissional';
}
