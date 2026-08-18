\set ON_ERROR_STOP on

do $$
begin
  if to_regprocedure(
    'public.iris_upsert_daily_emotional_record(date,text,text,text,integer,integer,text[],text[],boolean)'
  ) is null then
    raise exception 'RPC de upsert emocional diario ausente';
  end if;

  if has_table_privilege(
       'authenticated',
       'public.registros_emocionais',
       'INSERT, UPDATE, DELETE'
     ) or has_table_privilege(
       'anon',
       'public.registros_emocionais',
       'INSERT, UPDATE, DELETE'
     ) then
    raise exception 'DML emocional direto ainda esta concedido ao cliente';
  end if;

  if not exists (
    select 1
      from pg_indexes
     where schemaname = 'public'
       and indexname = 'iris_emocionais_paciente_dia_unique'
  ) then
    raise exception 'Chave unica de registro emocional diario ausente';
  end if;

  if (
    select data_type
      from information_schema.columns
     where table_schema = 'public'
       and table_name = 'registros_emocionais'
       and column_name = 'sintomas_emocionais_hoje'
  ) <> 'ARRAY' then
    raise exception 'Coluna de sintomas emocionais nao e um array';
  end if;

  if (
    select udt_name
      from information_schema.columns
     where table_schema = 'public'
       and table_name = 'registros_emocionais'
       and column_name = 'sintomas_emocionais_hoje'
  ) <> '_text' then
    raise exception 'Sintomas emocionais ainda usam indices posicionais';
  end if;

  if (
    select count(*)
      from public.registros_emocionais
     where paciente_id = '20000000-0000-4000-8000-000000000001'
       and data_local = date '2025-03-14'
  ) <> 1 then
    raise exception 'Duplicatas emocionais legadas nao foram consolidadas';
  end if;

  if not exists (
    select 1
      from public.registros_emocionais
     where id = '40000000-0000-4000-8000-000000000083'
       and paciente_id = '20000000-0000-4000-8000-000000000001'
       and data_local = date '2025-03-14'
       and data_registro = timestamptz '2025-03-14 09:00:00+00'
       and diario_emocional = 'Diario posterior ao check-in'
       and como_sentiu = 4
       and avaliacao_alimentacao = 4
       and cardinality(sintomas_emocionais_hoje) = 0
       and cardinality(sintomas_fisicos_hoje) = 0
  ) then
    raise exception 'Consolidacao perdeu o check-in clinico mais recente';
  end if;
end;
$$;

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

select
  (resultado).id as diary_record_id,
  (resultado).data_registro as diary_recorded_at,
  (resultado).atualizado_em as diary_updated_at
from (
  select public.iris_upsert_daily_emotional_record(
    p_data_local => current_date,
    p_fuso_horario => 'UTC',
    p_diario_emocional => 'Entrada inicial'
  ) as resultado
) chamada
\gset

select pg_sleep(0.02);

select
  (resultado).id as checkin_record_id,
  (resultado).data_registro as checkin_recorded_at,
  (resultado).atualizado_em as checkin_updated_at
from (
  select public.iris_upsert_daily_emotional_record(
    p_data_local => current_date,
    p_fuso_horario => 'UTC',
    p_humor => 'Mal',
    p_como_sentiu => 2,
    p_avaliacao_alimentacao => 3,
    p_sintomas_emocionais_hoje => array[
      'vomito_autoinduzido',
      'compulsao'
    ],
    p_sintomas_fisicos_hoje => array['desmaio']
  ) as resultado
) chamada
\gset

select pg_sleep(0.02);

select
  (resultado).id as diary_update_record_id,
  (resultado).data_registro as diary_update_recorded_at,
  (resultado).atualizado_em as diary_update_updated_at
from (
  select public.iris_upsert_daily_emotional_record(
    p_data_local => current_date,
    p_fuso_horario => 'UTC',
    p_diario_emocional => 'Entrada atualizada sem renovar alerta'
  ) as resultado
) chamada
\gset

reset role;

select (
  :'diary_record_id' = :'checkin_record_id'
  and :'checkin_record_id' = :'diary_update_record_id'
  and count(*) = 1
  and max(diario_emocional) = 'Entrada atualizada sem renovar alerta'
  and max(como_sentiu) = 2
  and bool_or('desmaio' = any(sintomas_fisicos_hoje))
  and :'checkin_recorded_at'::timestamptz
    > :'diary_recorded_at'::timestamptz
  and :'diary_update_recorded_at'::timestamptz
    = :'checkin_recorded_at'::timestamptz
  and :'diary_update_updated_at'::timestamptz
    > :'checkin_updated_at'::timestamptz
) as daily_upsert_is_atomic
from public.registros_emocionais
where paciente_id = (
  select id
    from public.pacientes
   where user_id = '00000000-0000-0000-0000-000000000002'
)
  and data_local = current_date
\gset

\if :daily_upsert_is_atomic
\else
  \echo 'Upsert diario fragmentou ou perdeu campos do registro'
  \quit 1
\endif

set role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000002',
  false
);

do $$
declare
  v_patient_id uuid;
  v_record_id uuid;
begin
  select id into v_patient_id
    from public.pacientes
   where user_id = auth.uid();

  select id into v_record_id
    from public.registros_emocionais
   where paciente_id = v_patient_id
     and data_local = current_date;

  begin
    insert into public.registros_emocionais (
      paciente_id,
      data_local,
      fuso_horario
    ) values (v_patient_id, current_date - 1, 'UTC');
    raise exception 'EXPECTED_DIRECT_INSERT_REJECTION';
  exception
    when insufficient_privilege then null;
  end;

  begin
    update public.registros_emocionais
       set diario_emocional = 'DML direto indevido'
     where id = v_record_id;
    raise exception 'EXPECTED_DIRECT_UPDATE_REJECTION';
  exception
    when insufficient_privilege then null;
  end;

  begin
    delete from public.registros_emocionais where id = v_record_id;
    raise exception 'EXPECTED_DIRECT_DELETE_REJECTION';
  exception
    when insufficient_privilege then null;
  end;
end;
$$;

reset role;
set role anon;
select set_config('request.jwt.claim.sub', '', false);
select set_config('request.jwt.claims', '{}', false);

do $$
begin
  begin
    perform public.iris_upsert_daily_emotional_record(
      p_data_local => current_date,
      p_fuso_horario => 'UTC',
      p_diario_emocional => 'Anonimo indevido'
    );
    raise exception 'EXPECTED_ANON_RPC_REJECTION';
  exception
    when insufficient_privilege then null;
  end;
end;
$$;

reset role;
set role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000001',
  false
);
select set_config(
  'request.jwt.claims',
  '{"email":"pro1@example.com"}',
  false
);

do $$
begin
  begin
    perform public.iris_upsert_daily_emotional_record(
      p_data_local => current_date,
      p_fuso_horario => 'UTC',
      p_diario_emocional => 'Profissional indevido'
    );
    raise exception 'EXPECTED_PROFESSIONAL_RPC_REJECTION';
  exception
    when others then
      if sqlerrm = 'EXPECTED_PROFESSIONAL_RPC_REJECTION'
         or position('PATIENT_REQUIRED' in sqlerrm) = 0 then
        raise;
      end if;
  end;
end;
$$;

reset role;

do $$
declare
  v_patient_id uuid;
  v_link_id uuid;
begin
  select id into v_patient_id
    from public.pacientes
   where user_id = '00000000-0000-0000-0000-000000000002';

  select id into v_link_id
    from public.paciente_profissional
   where paciente_id = v_patient_id
     and autorizacao_status = 'ativo'
   limit 1;

  begin
    insert into public.registros_alimentares (
      paciente_id,
      descricao_refeicao,
      nivel_fome
    ) values (v_patient_id, 'Valor invalido', 11);
    raise exception 'EXPECTED_HUNGER_REJECTION';
  exception
    when check_violation then null;
  end;

  begin
    insert into public.consultas (
      vinculo_id,
      inicio_em,
      modalidade,
      status
    ) values (v_link_id, now() - interval '1 minute', 'online', 'agendada');
    raise exception 'EXPECTED_PAST_APPOINTMENT_REJECTION';
  exception
    when others then
      if sqlerrm = 'EXPECTED_PAST_APPOINTMENT_REJECTION'
         or position('APPOINTMENT_MUST_BE_FUTURE' in sqlerrm) = 0 then
        raise;
      end if;
  end;

  begin
    insert into public.consultas (
      vinculo_id,
      inicio_em,
      modalidade,
      status
    ) values (v_link_id, now() + interval '1 day', 'telepatia', 'agendada');
    raise exception 'EXPECTED_MODALITY_REJECTION';
  exception
    when check_violation then null;
  end;
end;
$$;

select 'Integridade de dados clinicos validada.' as resultado;
