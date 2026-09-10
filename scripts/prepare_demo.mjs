import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { randomBytes } from 'node:crypto';
import { api, projectRef } from './supabase_admin.mjs';

const path = 'demo-access.local.json';
const state = existsSync(path) ? JSON.parse(readFileSync(path, 'utf8')) : {
  projectRef,
  professional: {
    email: `iris-demo-profissional-${randomBytes(5).toString('hex')}@example.invalid`,
    password: randomBytes(24).toString('base64url'),
    name: 'Profissional Demo Iris (ficticio)',
  },
  patient: {
    email: `iris-demo-paciente-${randomBytes(5).toString('hex')}@example.invalid`,
    password: randomBytes(24).toString('base64url'),
    name: 'Paciente Demo Iris (ficticio)',
  },
};
if (state.projectRef !== projectRef) throw new Error('Arquivo da demo pertence a outro projeto.');
const save = () => writeFileSync(path, `${JSON.stringify(state, null, 2)}\n`, { mode: 0o600 });
save();

async function account(record, role) {
  if (!record.id) {
    const existing = await api(`/rest/v1/usuarios?select=id&email=eq.${encodeURIComponent(record.email)}`, undefined, { admin: true });
    if (existing.length) record.id = existing[0].id;
    else {
      const created = await api('/auth/v1/admin/users', {
        email: record.email, password: record.password, email_confirm: true,
        user_metadata: { display_name: record.name, tipo_usuario: role, iris_demo: true },
      }, { admin: true });
      record.id = created.id;
    }
    save();
  }
  const session = await api('/auth/v1/token?grant_type=password', {
    email: record.email, password: record.password,
  });
  const token = session.access_token;
  if (!token || session.user.id !== record.id) throw new Error('Conta de demonstracao divergente.');
  const type = await api('/rest/v1/rpc/iris_bootstrap_current_user', {
    p_display_name: record.name, p_requested_type: role,
    ...(role === 'profissional' ? { p_specialty: 'Psicologia', p_registration: 'DEMO-FICTICIO' } : {}),
  }, { token });
  if (type !== role) throw new Error('Papel da conta divergente.');
  return token;
}

const professionalToken = await account(state.professional, 'profissional');
const patientToken = await account(state.patient, 'paciente');
const [professional] = await api(`/rest/v1/profissionais?select=id&user_id=eq.${state.professional.id}`, undefined, { token: professionalToken });
const [patient] = await api(`/rest/v1/pacientes?select=id&user_id=eq.${state.patient.id}`, undefined, { token: patientToken });
await api('/rest/v1/rpc/iris_set_professional_credential_status', {
  p_professional_id: professional.id, p_status: 'ativo',
}, { admin: true });
if (!state.linkId) {
  const [invite] = await api('/rest/v1/rpc/iris_create_professional_invite', {
    p_ttl_minutes: 30, p_max_uses: 1,
  }, { token: professionalToken });
  const [link] = await api('/rest/v1/rpc/iris_redeem_professional_invite', {
    p_token: invite.token,
  }, { token: patientToken });
  state.linkId = link.link_id;
  save();
}
if (!state.seeded) {
  await api('/rest/v1/preferencias_ia_apoio?on_conflict=paciente_id', {
    paciente_id: patient.id, personalizacao_ativa: true,
    fontes_consentidas: ['diary_text', 'mood_history'],
    categorias_permitidas: ['reflection', 'exercise'], duracao_maxima_minutos: 2,
    versao_consentimento: 'support-consent-v2', consentido_em: new Date().toISOString(),
    fuso_horario: 'America/Sao_Paulo',
  }, { token: patientToken, headers: { Prefer: 'resolution=merge-duplicates,return=minimal' } });
  const day = new Intl.DateTimeFormat('en-CA', { timeZone: 'America/Sao_Paulo' }).format(new Date());
  await api('/rest/v1/rpc/iris_upsert_daily_emotional_record', {
    p_data_local: day, p_fuso_horario: 'America/Sao_Paulo', p_como_sentiu: 3,
    p_diario_emocional: 'Registro ficticio de demonstracao: hoje organizei minhas tarefas e reservei um momento para conversar com uma pessoa de confianca.',
  }, { token: patientToken });
  await api('/rest/v1/rpc/iris_save_care_plan', {
    p_vinculo_id: state.linkId,
    p_orientation: 'Plano ficticio da demonstracao academica do Iris. Sem orientacoes clinicas reais.',
    p_share_with_patient: true, p_notify_missed_checkins: false,
    p_crisis_steps: [], p_goals: [], p_medications: [],
  }, { token: professionalToken });
  state.seeded = true;
  save();
}
for (const [role, token] of [['paciente', patientToken], ['profissional', professionalToken]]) {
  const links = await api(`/rest/v1/paciente_profissional?select=id,status,autorizacao_status&id=eq.${state.linkId}`, undefined, { token });
  if (links.length !== 1 || links[0].status !== 'ativo' || links[0].autorizacao_status !== 'ativo') {
    throw new Error(`Vinculo indisponivel para ${role}.`);
  }
}
state.verifiedAt = new Date().toISOString();
save();
console.log(`Contas confirmadas, login e vinculo verificados. Credenciais em ${path} (ignorado pelo Git).`);
