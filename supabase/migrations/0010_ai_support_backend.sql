-- Persistencia minima e controles de rollout para Sugestoes de apoio.
--
-- Esta camada armazena somente escolhas, IDs e eventos estruturados. Nenhuma
-- tabela abaixo possui coluna para texto livre de diario, prompt ou resposta
-- textual de modelo.

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

create table if not exists public.preferencias_ia_apoio (
  paciente_id uuid primary key
    references public.pacientes(id) on delete cascade,
  personalizacao_ativa boolean not null default false,
  fontes_consentidas text[] not null default '{}'::text[],
  categorias_permitidas text[] not null default '{}'::text[],
  duracao_maxima_minutos smallint not null default 2,
  conteudos_excluidos text[] not null default '{}'::text[],
  notificacoes_ativas boolean not null default false,
  frequencia_semanal smallint not null default 0,
  janela_inicio time not null default time '09:00',
  janela_fim time not null default time '21:00',
  dias_semana smallint[] not null
    default array[1, 2, 3, 4, 5, 6, 7]::smallint[],
  fuso_horario text not null default 'UTC',
  previa_bloqueio text not null default 'generica',
  som_ativo boolean not null default false,
  vibracao_ativa boolean not null default false,
  pausado_ate timestamptz,
  versao_consentimento text,
  consentido_em timestamptz,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now(),
  constraint iris_ia_fontes_validas check (
    fontes_consentidas <@ array[
      'mood_history',
      'diary_topics',
      'exercise_feedback',
      'notification_interactions'
    ]::text[]
  ),
  constraint iris_ia_categorias_validas check (
    categorias_permitidas <@ array[
      'reflection',
      'exercise',
      'video',
      'human_connection',
      'professional_conversation'
    ]::text[]
  ),
  constraint iris_ia_conteudos_excluidos_validos check (
    conteudos_excluidos <@ array[
      'breathing_focused',
      'audio_required',
      'animation',
      'body_touch'
    ]::text[]
  ),
  constraint iris_ia_duracao_valida check (
    duracao_maxima_minutos between 1 and 10
  ),
  constraint iris_ia_frequencia_valida check (
    frequencia_semanal between 0 and 3
  ),
  constraint iris_ia_dias_validos check (
    cardinality(dias_semana) between 1 and 7
    and dias_semana <@ array[1, 2, 3, 4, 5, 6, 7]::smallint[]
  ),
  constraint iris_ia_fuso_valido check (
    btrim(fuso_horario) <> '' and length(fuso_horario) <= 64
  ),
  constraint iris_ia_previa_valida check (
    previa_bloqueio in ('nenhuma', 'generica')
  ),
  constraint iris_ia_consentimento_coerente check (
    not personalizacao_ativa
    or (
      cardinality(fontes_consentidas) > 0
      and cardinality(categorias_permitidas) > 0
      and consentido_em is not null
      and btrim(coalesce(versao_consentimento, '')) <> ''
    )
  )
);

create table if not exists public.topicos_apoio (
  id uuid primary key default extensions.gen_random_uuid(),
  paciente_id uuid not null
    references public.pacientes(id) on delete cascade,
  registro_emocional_id uuid not null
    references public.registros_emocionais(id) on delete cascade,
  topico text not null,
  origem text not null default 'selecionado_paciente',
  estado text not null default 'pendente',
  confirmado_em timestamptz,
  expira_em timestamptz not null default (now() + interval '7 days'),
  invalidado_em timestamptz,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now(),
  constraint iris_topicos_apoio_topico_valido check (
    topico in ('overload', 'loneliness', 'self_kindness')
  ),
  constraint iris_topicos_apoio_origem_valida check (
    origem = 'selecionado_paciente'
  ),
  constraint iris_topicos_apoio_estado_valido check (
    estado in ('pendente', 'confirmado', 'recusado')
  ),
  constraint iris_topicos_apoio_confirmacao_coerente check (
    (estado = 'confirmado' and confirmado_em is not null)
    or (estado <> 'confirmado' and confirmado_em is null)
  ),
  constraint iris_topicos_apoio_expiracao_valida check (
    expira_em > criado_em
  ),
  unique (paciente_id, registro_emocional_id, topico)
);

create table if not exists public.sugestoes_ia_apoio (
  id uuid primary key default extensions.gen_random_uuid(),
  paciente_id uuid not null
    references public.pacientes(id) on delete cascade,
  request_id uuid not null,
  gatilho text not null,
  papel text not null default 'efetiva',
  modo text not null,
  origem text not null,
  resultado text not null,
  template_id text,
  categoria text,
  exercicio_id text,
  reason_codes text[] not null default '{}'::text[],
  fontes_usadas text[] not null default '{}'::text[],
  confidence_band text,
  modelo text,
  versao_prompt text not null,
  versao_catalogo text not null,
  validacao_codigo text,
  saida_hash text,
  latencia_ms integer,
  tokens_entrada integer,
  tokens_saida integer,
  visivel_em timestamptz,
  expira_em timestamptz not null,
  criado_em timestamptz not null default now(),
  constraint iris_sugestoes_ia_papel_valido check (
    papel in ('efetiva', 'shadow')
  ),
  constraint iris_sugestoes_ia_modo_valido check (
    modo in ('local', 'shadow', 'pilot', 'limited')
  ),
  constraint iris_sugestoes_ia_origem_valida check (
    origem in ('regra_local', 'openai', 'fallback')
  ),
  constraint iris_sugestoes_ia_resultado_valido check (
    resultado in ('sugerida', 'silencio', 'rejeitada', 'erro')
  ),
  constraint iris_sugestoes_ia_template_valido check (
    template_id is null or template_id in (
      'reflection_difficult_checkins_v1',
      'exercise_difficult_checkins_v1',
      'reflection_overload_v1',
      'connection_loneliness_v1',
      'reflection_lighter_checkin_v1',
      'reflection_self_kindness_v1',
      'connection_after_exercise_feedback_v1'
    )
  ),
  constraint iris_sugestoes_ia_categoria_valida check (
    categoria is null or categoria in (
      'reflection',
      'exercise',
      'video',
      'human_connection',
      'professional_conversation'
    )
  ),
  constraint iris_sugestoes_ia_exercicio_valido check (
    exercicio_id is null or exercicio_id in (
      'anchor-present',
      'notice-and-name'
    )
  ),
  constraint iris_sugestoes_ia_reason_codes_validos check (
    cardinality(reason_codes) <= 4
    and reason_codes <@ array[
      'TODAY_DIFFICULT_CHECKIN',
      'TODAY_STEADY_CHECKIN',
      'TODAY_LIGHTER_CHECKIN',
      'RECENT_DIFFICULT_CHECKINS',
      'PREFERS_SHORT_PRACTICE',
      'CONFIRMED_OVERLOAD',
      'CONFIRMED_LONELINESS',
      'CONFIRMED_SELF_KINDNESS',
      'PREFERRED_FROM_PAST_INTERACTIONS',
      'PREVIOUS_EXERCISE_WAS_NOT_HELPFUL'
    ]::text[]
  ),
  constraint iris_sugestoes_ia_gatilho_valido check (
    gatilho in (
      'manual',
      'after_checkin',
      'after_diary',
      'notification_open'
    )
  ),
  constraint iris_sugestoes_ia_fontes_validas check (
    fontes_usadas <@ array[
      'mood_history',
      'diary_topics',
      'exercise_feedback',
      'notification_interactions'
    ]::text[]
  ),
  constraint iris_sugestoes_ia_confianca_valida check (
    confidence_band is null or confidence_band in ('low', 'medium', 'high')
  ),
  constraint iris_sugestoes_ia_resultado_coerente check (
    (
      resultado = 'sugerida'
      and template_id is not null
      and categoria is not null
      and cardinality(reason_codes) > 0
      and confidence_band in ('medium', 'high')
    )
    or (
      resultado <> 'sugerida'
      and template_id is null
      and categoria is null
      and exercicio_id is null
      and cardinality(reason_codes) = 0
      and confidence_band is null
    )
  ),
  constraint iris_sugestoes_ia_visibilidade_coerente check (
    visivel_em is null
    or (papel = 'efetiva' and resultado = 'sugerida')
  ),
  constraint iris_sugestoes_ia_shadow_oculto check (
    papel <> 'shadow' or visivel_em is null
  ),
  constraint iris_sugestoes_ia_hash_valido check (
    saida_hash is null or saida_hash ~ '^[0-9a-f]{64}$'
  ),
  constraint iris_sugestoes_ia_metricas_validas check (
    (latencia_ms is null or latencia_ms >= 0)
    and (tokens_entrada is null or tokens_entrada >= 0)
    and (tokens_saida is null or tokens_saida >= 0)
  ),
  constraint iris_sugestoes_ia_expiracao_valida check (
    expira_em > criado_em
  ),
  unique (paciente_id, request_id, papel)
);

create table if not exists public.eventos_ia_apoio (
  id uuid primary key default extensions.gen_random_uuid(),
  paciente_id uuid not null
    references public.pacientes(id) on delete cascade,
  sugestao_id uuid
    references public.sugestoes_ia_apoio(id) on delete cascade,
  client_event_id uuid not null,
  tipo text not null,
  canal text not null default 'app',
  ocorrido_em timestamptz not null default now(),
  agendado_para timestamptz,
  criado_em timestamptz not null default now(),
  constraint iris_eventos_ia_tipo_valido check (
    tipo in (
      'solicitada',
      'gerada',
      'agendada',
      'entregue',
      'aberta',
      'dispensada',
      'acao_iniciada',
      'acao_concluida',
      'combina_percepcao',
      'nao_combina',
      'prefere_nao_responder',
      'util',
      'neutra',
      'nao_ajudou',
      'prejudicial'
    )
  ),
  constraint iris_eventos_ia_canal_valido check (
    canal in ('app', 'local_notification', 'push')
  ),
  constraint iris_eventos_ia_instante_valido check (
    ocorrido_em <= now() + interval '5 minutes'
  ),
  unique (paciente_id, client_event_id)
);

alter table public.eventos_ia_apoio
  add column if not exists agendado_para timestamptz;

do $$
begin
  if not exists (
    select 1
      from pg_constraint
     where conrelid = 'public.eventos_ia_apoio'::regclass
       and conname = 'iris_eventos_ia_agendamento_coerente'
  ) then
    alter table public.eventos_ia_apoio
      add constraint iris_eventos_ia_agendamento_coerente check (
        (
          tipo = 'agendada'
          and agendado_para is not null
          and agendado_para > ocorrido_em
          and agendado_para <= ocorrido_em + interval '8 days'
        )
        or (tipo <> 'agendada' and agendado_para is null)
      );
  end if;
end;
$$;

create table if not exists public.rollout_ia_apoio (
  ambiente text primary key,
  apoio_ativo boolean not null default true,
  modo text not null default 'local',
  openai_ativa boolean not null default false,
  kill_switch boolean not null default true,
  percentual_shadow smallint not null default 0,
  percentual_entrega smallint not null default 0,
  texto_generativo_ativo boolean not null default false,
  modelo text,
  versao_prompt text not null default 'selection-v1',
  versao_catalogo text not null default 'support-v1',
  atualizado_por uuid references public.usuarios(id) on delete set null,
  atualizado_em timestamptz not null default now(),
  constraint iris_rollout_ia_ambiente_valido check (
    ambiente in ('development', 'staging', 'production')
  ),
  constraint iris_rollout_ia_modo_valido check (
    modo in ('local', 'shadow', 'pilot', 'limited')
  ),
  constraint iris_rollout_ia_percentuais_validos check (
    percentual_shadow between 0 and 100
    and percentual_entrega between 0 and 100
  ),
  constraint iris_rollout_ia_openai_coerente check (
    not openai_ativa or modelo is not null
  ),
  constraint iris_rollout_ia_texto_generativo_bloqueado check (
    not texto_generativo_ativo
  )
);

create table if not exists public.participantes_piloto_ia_apoio (
  paciente_id uuid primary key
    references public.pacientes(id) on delete cascade,
  ativo boolean not null default false,
  versao_consentimento text not null,
  consentido_em timestamptz not null,
  elegibilidade_adulta_verificada_em timestamptz not null,
  inscrito_por uuid references public.usuarios(id) on delete set null,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now(),
  constraint iris_participantes_piloto_consentimento_valido check (
    btrim(versao_consentimento) <> ''
  )
);

insert into public.rollout_ia_apoio (
  ambiente,
  apoio_ativo,
  modo,
  openai_ativa,
  kill_switch,
  percentual_shadow,
  percentual_entrega,
  texto_generativo_ativo,
  versao_prompt,
  versao_catalogo
)
values
(
  'development', true, 'local', false, true, 0, 0, false,
  'selection-v1', 'support-v1'
),
(
  'staging', true, 'local', false, true, 0, 0, false,
  'selection-v1', 'support-v1'
),
(
  'production', true, 'local', false, true, 0, 0, false,
  'selection-v1', 'support-v1'
)
on conflict (ambiente) do nothing;

create index if not exists iris_topicos_apoio_paciente_estado_idx
  on public.topicos_apoio(paciente_id, estado, expira_em desc);
create index if not exists iris_sugestoes_ia_paciente_criado_idx
  on public.sugestoes_ia_apoio(paciente_id, criado_em desc);
create index if not exists iris_sugestoes_ia_visiveis_idx
  on public.sugestoes_ia_apoio(paciente_id, visivel_em desc)
  where visivel_em is not null;
create index if not exists iris_eventos_ia_paciente_instante_idx
  on public.eventos_ia_apoio(paciente_id, ocorrido_em desc);
create index if not exists iris_eventos_ia_sugestao_idx
  on public.eventos_ia_apoio(sugestao_id, ocorrido_em desc);

drop trigger if exists iris_set_atualizado_em
  on public.preferencias_ia_apoio;
create trigger iris_set_atualizado_em
  before update on public.preferencias_ia_apoio
  for each row execute function public.iris_set_atualizado_em();

drop trigger if exists iris_set_atualizado_em
  on public.topicos_apoio;
create trigger iris_set_atualizado_em
  before update on public.topicos_apoio
  for each row execute function public.iris_set_atualizado_em();

drop trigger if exists iris_set_atualizado_em
  on public.rollout_ia_apoio;
create trigger iris_set_atualizado_em
  before update on public.rollout_ia_apoio
  for each row execute function public.iris_set_atualizado_em();

drop trigger if exists iris_set_atualizado_em
  on public.participantes_piloto_ia_apoio;
create trigger iris_set_atualizado_em
  before update on public.participantes_piloto_ia_apoio
  for each row execute function public.iris_set_atualizado_em();

alter table public.preferencias_ia_apoio enable row level security;
alter table public.topicos_apoio enable row level security;
alter table public.sugestoes_ia_apoio enable row level security;
alter table public.eventos_ia_apoio enable row level security;
alter table public.rollout_ia_apoio enable row level security;
alter table public.participantes_piloto_ia_apoio enable row level security;

drop policy if exists iris_preferencias_ia_patient_select
  on public.preferencias_ia_apoio;
create policy iris_preferencias_ia_patient_select
  on public.preferencias_ia_apoio
  for select
  to authenticated
  using (paciente_id = public.iris_current_patient_id());

drop policy if exists iris_preferencias_ia_patient_insert
  on public.preferencias_ia_apoio;
create policy iris_preferencias_ia_patient_insert
  on public.preferencias_ia_apoio
  for insert
  to authenticated
  with check (paciente_id = public.iris_current_patient_id());

drop policy if exists iris_preferencias_ia_patient_update
  on public.preferencias_ia_apoio;
create policy iris_preferencias_ia_patient_update
  on public.preferencias_ia_apoio
  for update
  to authenticated
  using (paciente_id = public.iris_current_patient_id())
  with check (paciente_id = public.iris_current_patient_id());

drop policy if exists iris_preferencias_ia_patient_delete
  on public.preferencias_ia_apoio;
create policy iris_preferencias_ia_patient_delete
  on public.preferencias_ia_apoio
  for delete
  to authenticated
  using (paciente_id = public.iris_current_patient_id());

drop policy if exists iris_topicos_apoio_patient_select
  on public.topicos_apoio;
create policy iris_topicos_apoio_patient_select
  on public.topicos_apoio
  for select
  to authenticated
  using (paciente_id = public.iris_current_patient_id());

drop policy if exists iris_sugestoes_ia_patient_select_visible
  on public.sugestoes_ia_apoio;
create policy iris_sugestoes_ia_patient_select_visible
  on public.sugestoes_ia_apoio
  for select
  to authenticated
  using (
    paciente_id = public.iris_current_patient_id()
    and papel = 'efetiva'
    and resultado = 'sugerida'
    and visivel_em is not null
    and expira_em > now()
  );

drop policy if exists iris_eventos_ia_patient_select
  on public.eventos_ia_apoio;
create policy iris_eventos_ia_patient_select
  on public.eventos_ia_apoio
  for select
  to authenticated
  using (paciente_id = public.iris_current_patient_id());

-- Rollout, participantes, sugestoes e eventos de servidor sao superficies
-- exclusivas do backend. Topicos so podem ser gravados pela RPC validada.
-- Ausencia de policy de escrita direta e intencional.

create or replace function public.iris_set_topico_apoio(
  p_registro_emocional_id uuid,
  p_topico text,
  p_confirmar boolean default true
)
returns public.topicos_apoio
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_patient_id uuid := public.iris_current_patient_id();
  v_result public.topicos_apoio%rowtype;
begin
  if v_patient_id is null then
    raise exception 'PATIENT_REQUIRED';
  end if;

  if p_topico not in ('overload', 'loneliness', 'self_kindness') then
    raise exception 'INVALID_SUPPORT_TOPIC';
  end if;

  if not exists (
    select 1
      from public.registros_emocionais registro
     where registro.id = p_registro_emocional_id
       and registro.paciente_id = v_patient_id
  ) then
    raise exception 'EMOTIONAL_RECORD_NOT_FOUND';
  end if;

  insert into public.topicos_apoio (
    paciente_id,
    registro_emocional_id,
    topico,
    origem,
    estado,
    confirmado_em,
    expira_em,
    invalidado_em
  )
  values (
    v_patient_id,
    p_registro_emocional_id,
    p_topico,
    'selecionado_paciente',
    case when p_confirmar then 'confirmado' else 'recusado' end,
    case when p_confirmar then now() else null end,
    now() + interval '7 days',
    null
  )
  on conflict (paciente_id, registro_emocional_id, topico) do update
    set origem = 'selecionado_paciente',
        estado = excluded.estado,
        confirmado_em = excluded.confirmado_em,
        expira_em = excluded.expira_em,
        invalidado_em = null
  returning * into v_result;

  return v_result;
end;
$$;

create or replace function public.iris_confirm_topico_apoio(
  p_topico_id uuid,
  p_confirmar boolean
)
returns public.topicos_apoio
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_patient_id uuid := public.iris_current_patient_id();
  v_result public.topicos_apoio%rowtype;
begin
  if v_patient_id is null then
    raise exception 'PATIENT_REQUIRED';
  end if;

  update public.topicos_apoio
     set estado = case when p_confirmar then 'confirmado' else 'recusado' end,
         confirmado_em = case when p_confirmar then now() else null end,
         invalidado_em = case when p_confirmar then null else now() end
   where id = p_topico_id
     and paciente_id = v_patient_id
  returning * into v_result;

  if v_result.id is null then
    raise exception 'SUPPORT_TOPIC_NOT_FOUND';
  end if;

  return v_result;
end;
$$;

-- A assinatura ganhou o instante futuro do agendamento. Removemos a versão
-- anterior para não manter um overload legado com permissões divergentes.
drop function if exists public.iris_registrar_evento_ia_apoio(
  uuid,
  text,
  text,
  uuid,
  timestamptz
);

create or replace function public.iris_registrar_evento_ia_apoio(
  p_sugestao_id uuid,
  p_tipo text,
  p_canal text default 'app',
  p_client_event_id uuid default null,
  p_ocorrido_em timestamptz default now(),
  p_agendado_para timestamptz default null
)
returns public.eventos_ia_apoio
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_patient_id uuid := public.iris_current_patient_id();
  v_result public.eventos_ia_apoio%rowtype;
begin
  if v_patient_id is null then
    raise exception 'PATIENT_REQUIRED';
  end if;

  if p_tipo not in (
    'agendada',
    'aberta',
    'dispensada',
    'acao_iniciada',
    'acao_concluida',
    'combina_percepcao',
    'nao_combina',
    'prefere_nao_responder',
    'util',
    'neutra',
    'nao_ajudou',
    'prejudicial'
  ) then
    raise exception 'INVALID_PATIENT_SUPPORT_EVENT';
  end if;

  if p_canal not in ('app', 'local_notification', 'push') then
    raise exception 'INVALID_SUPPORT_EVENT_CHANNEL';
  end if;

  if p_ocorrido_em > now() + interval '5 minutes'
      or p_ocorrido_em < now() - interval '90 days' then
    raise exception 'INVALID_SUPPORT_EVENT_TIME';
  end if;

  if (
    p_tipo = 'agendada'
    and (
      p_agendado_para is null
      or p_agendado_para <= p_ocorrido_em
      or p_agendado_para > p_ocorrido_em + interval '8 days'
    )
  ) or (p_tipo <> 'agendada' and p_agendado_para is not null) then
    raise exception 'INVALID_SUPPORT_SCHEDULE_TIME';
  end if;

  if not exists (
    select 1
      from public.sugestoes_ia_apoio sugestao
     where sugestao.id = p_sugestao_id
       and sugestao.paciente_id = v_patient_id
       and sugestao.papel = 'efetiva'
       and sugestao.resultado = 'sugerida'
       and sugestao.visivel_em is not null
  ) then
    raise exception 'SUPPORT_SUGGESTION_NOT_FOUND';
  end if;

  insert into public.eventos_ia_apoio (
    paciente_id,
    sugestao_id,
    client_event_id,
    tipo,
    canal,
    ocorrido_em,
    agendado_para
  )
  values (
    v_patient_id,
    p_sugestao_id,
    coalesce(p_client_event_id, extensions.gen_random_uuid()),
    p_tipo,
    p_canal,
    p_ocorrido_em,
    p_agendado_para
  )
  on conflict (paciente_id, client_event_id) do update
    set client_event_id = excluded.client_event_id
  returning * into v_result;

  return v_result;
end;
$$;

-- Direito de retirada: remove somente o estado criado por Sugestoes de apoio.
-- Os registros emocionais e check-ins de origem permanecem intactos.
create or replace function public.iris_apagar_dados_ia_apoio()
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_patient_id uuid := public.iris_current_patient_id();
begin
  if v_patient_id is null then
    raise exception 'PATIENT_REQUIRED';
  end if;

  delete from public.eventos_ia_apoio
   where paciente_id = v_patient_id;
  delete from public.sugestoes_ia_apoio
   where paciente_id = v_patient_id;
  delete from public.topicos_apoio
   where paciente_id = v_patient_id;
  delete from public.preferencias_ia_apoio
   where paciente_id = v_patient_id;
  delete from public.participantes_piloto_ia_apoio
   where paciente_id = v_patient_id;
end;
$$;

create or replace function public.iris_listar_eventos_ia_apoio(
  p_dias integer default 30
)
returns table (
  evento_id uuid,
  sugestao_id uuid,
  template_id text,
  categoria text,
  exercicio_id text,
  tipo text,
  canal text,
  ocorrido_em timestamptz,
  agendado_para timestamptz
)
language plpgsql
stable
security definer
set search_path = pg_catalog, public
as $$
declare
  v_patient_id uuid := public.iris_current_patient_id();
begin
  if v_patient_id is null then
    raise exception 'PATIENT_REQUIRED';
  end if;
  if p_dias < 1 or p_dias > 30 then
    raise exception 'INVALID_HISTORY_WINDOW';
  end if;

  return query
  select evento.id,
         evento.sugestao_id,
         sugestao.template_id,
         sugestao.categoria,
         sugestao.exercicio_id,
         evento.tipo,
         evento.canal,
         evento.ocorrido_em,
         evento.agendado_para
    from public.eventos_ia_apoio evento
    join public.sugestoes_ia_apoio sugestao
      on sugestao.id = evento.sugestao_id
   where evento.paciente_id = v_patient_id
     and evento.ocorrido_em >= now() - make_interval(days => p_dias)
     and sugestao.papel = 'efetiva'
     and sugestao.resultado = 'sugerida'
   order by evento.ocorrido_em desc
   limit 200;
end;
$$;

revoke all on table public.preferencias_ia_apoio
  from public, anon, authenticated;
revoke all on table public.topicos_apoio
  from public, anon, authenticated;
revoke all on table public.sugestoes_ia_apoio
  from public, anon, authenticated;
revoke all on table public.eventos_ia_apoio
  from public, anon, authenticated;
revoke all on table public.rollout_ia_apoio
  from public, anon, authenticated;
revoke all on table public.participantes_piloto_ia_apoio
  from public, anon, authenticated;

grant select, insert, update, delete on public.preferencias_ia_apoio
  to authenticated;
grant select on public.topicos_apoio to authenticated;
grant select on public.sugestoes_ia_apoio to authenticated;
grant select on public.eventos_ia_apoio to authenticated;

grant all on table public.preferencias_ia_apoio to service_role;
grant all on table public.topicos_apoio to service_role;
grant all on table public.sugestoes_ia_apoio to service_role;
grant all on table public.eventos_ia_apoio to service_role;
grant all on table public.rollout_ia_apoio to service_role;
grant all on table public.participantes_piloto_ia_apoio to service_role;

revoke all on function public.iris_set_topico_apoio(uuid, text, boolean)
  from public, anon;
grant execute on function public.iris_set_topico_apoio(uuid, text, boolean)
  to authenticated;

revoke all on function public.iris_confirm_topico_apoio(uuid, boolean)
  from public, anon;
grant execute on function public.iris_confirm_topico_apoio(uuid, boolean)
  to authenticated;

revoke all on function public.iris_registrar_evento_ia_apoio(
  uuid,
  text,
  text,
  uuid,
  timestamptz,
  timestamptz
) from public, anon;
grant execute on function public.iris_registrar_evento_ia_apoio(
  uuid,
  text,
  text,
  uuid,
  timestamptz,
  timestamptz
) to authenticated;

revoke all on function public.iris_apagar_dados_ia_apoio()
  from public, anon;
grant execute on function public.iris_apagar_dados_ia_apoio()
  to authenticated;

revoke all on function public.iris_listar_eventos_ia_apoio(integer)
  from public, anon;
grant execute on function public.iris_listar_eventos_ia_apoio(integer)
  to authenticated;

notify pgrst, 'reload schema';
