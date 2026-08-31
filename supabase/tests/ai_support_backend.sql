\set ON_ERROR_STOP on

-- Estrutura, isolamento e contrato fechado.
do $$
declare
  v_constraint text;
begin
  foreach v_constraint in array array[
    'iris_sugestoes_ia_template_valido',
    'iris_sugestoes_ia_reason_codes_validos',
    'iris_sugestoes_ia_gatilho_valido'
  ] loop
    if not exists (
      select 1
        from pg_constraint
       where conrelid = 'public.sugestoes_ia_apoio'::regclass
         and conname = v_constraint
    ) then
      raise exception 'Restricao de IA ausente: %', v_constraint;
    end if;
  end loop;

  if not exists (
    select 1
      from pg_constraint
     where conrelid = 'public.sugestoes_ia_apoio'::regclass
       and conname = 'iris_sugestoes_ia_template_valido'
       and pg_get_constraintdef(oid) like '%reflection_lighter_checkin_v1%'
       and pg_get_constraintdef(oid) like '%reflection_self_kindness_v1%'
  ) then
    raise exception 'Catalogo novo nao esta protegido no banco';
  end if;

  if not exists (
    select 1
      from pg_constraint
     where conrelid = 'public.sugestoes_ia_apoio'::regclass
       and conname = 'iris_sugestoes_ia_reason_codes_validos'
       and pg_get_constraintdef(oid) like '%TODAY_DIFFICULT_CHECKIN%'
       and pg_get_constraintdef(oid) like '%CONFIRMED_SELF_KINDNESS%'
       and pg_get_constraintdef(oid) like '%PREFERRED_FROM_PAST_INTERACTIONS%'
  ) then
    raise exception 'Reason codes novos nao estao protegidos no banco';
  end if;

  if has_table_privilege(
       'authenticated',
       'public.sugestoes_ia_apoio',
       'INSERT, UPDATE, DELETE'
     ) or has_table_privilege(
       'authenticated',
       'public.eventos_ia_apoio',
       'INSERT, UPDATE, DELETE'
     ) then
    raise exception 'Cliente ainda consegue gravar auditoria protegida diretamente';
  end if;

  if to_regprocedure(
    'public.iris_set_topico_apoio(uuid,text,boolean)'
  ) is null then
    raise exception 'RPC de topico confirmado ausente';
  end if;

  if to_regprocedure(
    'public.iris_registrar_evento_ia_apoio(uuid,text,text,uuid,timestamptz,timestamptz)'
  ) is null then
    raise exception 'RPC de interacao ausente';
  end if;

  if to_regprocedure(
    'public.iris_apagar_dados_ia_apoio()'
  ) is null then
    raise exception 'RPC de exclusao dos dados de apoio ausente';
  end if;

  if to_regprocedure(
    'public.iris_listar_eventos_ia_apoio(integer)'
  ) is null then
    raise exception 'RPC de historico estruturado ausente';
  end if;
end;
$$;

-- O paciente controla consentimento e confirma apenas topicos fechados.
set role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000002',
  false
);
select set_config(
  'request.jwt.claims',
  '{"email":"patient@example.com"}',
  false
);

select id as support_patient_id
  from public.pacientes
 where user_id = auth.uid()
 limit 1
\gset

insert into public.preferencias_ia_apoio (
  paciente_id,
  personalizacao_ativa,
  fontes_consentidas,
  categorias_permitidas,
  versao_consentimento,
  consentido_em
) values (
  :'support_patient_id'::uuid,
  true,
  array[
    'mood_history',
    'diary_topics',
    'exercise_feedback',
    'notification_interactions'
  ],
  array['reflection', 'exercise', 'human_connection'],
  'support-consent-v1',
  now()
)
on conflict (paciente_id) do update
  set personalizacao_ativa = excluded.personalizacao_ativa,
      fontes_consentidas = excluded.fontes_consentidas,
      categorias_permitidas = excluded.categorias_permitidas,
      versao_consentimento = excluded.versao_consentimento,
      consentido_em = excluded.consentido_em;

select (public.iris_upsert_daily_emotional_record(
  p_data_local => current_date,
  p_fuso_horario => 'UTC',
  p_humor => 'Regular',
  p_como_sentiu => 3,
  p_avaliacao_alimentacao => 3
)).id as support_record_id
\gset

select (public.iris_set_topico_apoio(
  :'support_record_id'::uuid,
  'self_kindness',
  true
)).id as support_topic_id
\gset

do $$
declare
  v_record_id uuid;
begin
  select id into v_record_id
    from public.registros_emocionais
   where paciente_id = public.iris_current_patient_id()
     and data_local = current_date;

  if not exists (
    select 1
      from public.topicos_apoio
     where paciente_id = public.iris_current_patient_id()
       and registro_emocional_id = v_record_id
       and topico = 'self_kindness'
       and origem = 'selecionado_paciente'
       and estado = 'confirmado'
       and confirmado_em is not null
  ) then
    raise exception 'Topico confirmado nao foi persistido corretamente';
  end if;

  begin
    perform public.iris_set_topico_apoio(
      v_record_id,
      'diagnostico_livre',
      true
    );
    raise exception 'EXPECTED_UNKNOWN_TOPIC_REJECTION';
  exception
    when others then
      if sqlerrm = 'EXPECTED_UNKNOWN_TOPIC_REJECTION' then
        raise;
      end if;
  end;
end;
$$;

reset role;

-- O backend grava uma linha efetiva e uma shadow; RLS revela apenas a efetiva.
insert into public.sugestoes_ia_apoio (
  id,
  paciente_id,
  request_id,
  gatilho,
  papel,
  modo,
  origem,
  resultado,
  template_id,
  categoria,
  reason_codes,
  fontes_usadas,
  confidence_band,
  versao_prompt,
  versao_catalogo,
  visivel_em,
  expira_em
) values
(
  '91000000-0000-4000-8000-000000000001',
  :'support_patient_id'::uuid,
  '92000000-0000-4000-8000-000000000001',
  'after_diary',
  'efetiva',
  'shadow',
  'regra_local',
  'sugerida',
  'reflection_self_kindness_v1',
  'reflection',
  array['CONFIRMED_SELF_KINDNESS'],
  array['diary_topics'],
  'high',
  'selection-v1',
  'support-v1',
  now(),
  now() + interval '1 day'
),
(
  '91000000-0000-4000-8000-000000000002',
  :'support_patient_id'::uuid,
  '92000000-0000-4000-8000-000000000001',
  'after_diary',
  'shadow',
  'shadow',
  'openai',
  'sugerida',
  'reflection_lighter_checkin_v1',
  'reflection',
  array['TODAY_LIGHTER_CHECKIN'],
  array['mood_history'],
  'high',
  'selection-v1',
  'support-v1',
  null,
  now() + interval '1 day'
);

set role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000002',
  false
);

select (
  count(*) = 1
  and bool_and(id = '91000000-0000-4000-8000-000000000001'::uuid)
) as patient_only_sees_effective
from public.sugestoes_ia_apoio
where request_id = '92000000-0000-4000-8000-000000000001'::uuid
\gset

\if :patient_only_sees_effective
\else
  \echo 'RLS revelou linha shadow ou ocultou a sugestao efetiva'
  \quit 1
\endif

select (public.iris_registrar_evento_ia_apoio(
  '91000000-0000-4000-8000-000000000001'::uuid,
  'aberta',
  'local_notification',
  '93000000-0000-4000-8000-000000000001'::uuid,
  now()
)).id as support_event_id
\gset

select (public.iris_registrar_evento_ia_apoio(
  '91000000-0000-4000-8000-000000000001'::uuid,
  'agendada',
  'local_notification',
  '93000000-0000-4000-8000-000000000002'::uuid,
  now(),
  now() + interval '1 hour'
)).id as support_scheduled_event_id
\gset

do $$
begin
  if not exists (
    select 1
      from public.eventos_ia_apoio
     where paciente_id = public.iris_current_patient_id()
       and client_event_id = '93000000-0000-4000-8000-000000000001'::uuid
       and tipo = 'aberta'
       and canal = 'local_notification'
  ) then
    raise exception 'Interacao de notificacao nao foi persistida';
  end if;

  if not exists (
    select 1
      from public.iris_listar_eventos_ia_apoio(30)
     where sugestao_id = '91000000-0000-4000-8000-000000000001'::uuid
       and tipo = 'agendada'
       and agendado_para is not null
  ) then
    raise exception 'Historico de agendamento nao foi recuperado';
  end if;

  begin
    perform public.iris_registrar_evento_ia_apoio(
      '91000000-0000-4000-8000-000000000001'::uuid,
      'gerada'
    );
    raise exception 'EXPECTED_SERVER_EVENT_REJECTION';
  exception
    when others then
      if sqlerrm = 'EXPECTED_SERVER_EVENT_REJECTION' then
        raise;
      end if;
  end;
end;
$$;

select public.iris_apagar_dados_ia_apoio();

do $$
begin
  if exists (
    select 1 from public.preferencias_ia_apoio
     where paciente_id = public.iris_current_patient_id()
  ) or exists (
    select 1 from public.topicos_apoio
     where paciente_id = public.iris_current_patient_id()
  ) or exists (
    select 1 from public.sugestoes_ia_apoio
     where paciente_id = public.iris_current_patient_id()
  ) or exists (
    select 1 from public.eventos_ia_apoio
     where paciente_id = public.iris_current_patient_id()
  ) then
    raise exception 'Dados derivados de apoio nao foram apagados';
  end if;

  if not exists (
    select 1 from public.registros_emocionais
     where paciente_id = public.iris_current_patient_id()
       and data_local = current_date
  ) then
    raise exception 'Exclusao de apoio removeu o registro emocional original';
  end if;
end;
$$;

reset role;

select 'Backend de IA e apoio validado.' as resultado;
