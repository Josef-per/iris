\set ON_ERROR_STOP on

-- 1. Estrutura e restricoes.

do $$
begin
  if (
    select data_type
      from information_schema.columns
     where table_schema = 'public'
       and table_name = 'registros_alimentares'
       and column_name = 'tipo_refeicao'
  ) is distinct from 'text' then
    raise exception 'Coluna tipo_refeicao ausente ou com tipo errado';
  end if;

  if not exists (
    select 1
      from pg_constraint
     where conrelid = 'public.registros_alimentares'::regclass
       and conname = 'iris_alimentares_tipo_valido'
  ) then
    raise exception 'Check de tipo de refeicao ausente';
  end if;

  if not exists (
    select 1
      from pg_constraint
     where conrelid = 'public.lembretes'::regclass
       and conname = 'iris_lembretes_tipo_valido'
  ) then
    raise exception 'Check de tipo de lembrete ausente';
  end if;

  if not exists (
    select 1
      from pg_constraint
     where conrelid = 'public.lembretes'::regclass
       and conname = 'iris_lembretes_titulo_valido'
  ) then
    raise exception 'Check de titulo de lembrete ausente';
  end if;

  if not exists (
    select 1
      from pg_indexes
     where schemaname = 'public'
       and indexname = 'iris_lembretes_paciente_idx'
  ) then
    raise exception 'Indice de lembretes por paciente ausente';
  end if;

  if not exists (
    select 1
      from pg_policies
     where schemaname = 'public'
       and tablename = 'lembretes'
       and policyname = 'iris_lembretes_patient_all'
  ) then
    raise exception 'Politica RLS de lembretes ausente';
  end if;

  if (
    select count(*)
      from pg_policies
     where schemaname = 'public'
       and tablename = 'lembretes'
  ) <> 1 then
    raise exception 'Lembretes deve ter exatamente uma politica (paciente)';
  end if;

  if to_regprocedure(
    'public.iris_upsert_daily_emotional_record(date,text,text,text,integer,integer,text[],text[],boolean)'
  ) is null then
    raise exception 'RPC com p_limpar_diario ausente';
  end if;

  if to_regprocedure(
    'public.iris_upsert_daily_emotional_record(date,text,text,text,integer,integer,text[],text[])'
  ) is not null then
    raise exception 'Assinatura antiga do RPC ainda existe';
  end if;

  if has_function_privilege(
       'anon',
       'public.iris_upsert_daily_emotional_record(date,text,text,text,integer,integer,text[],text[],boolean)',
       'EXECUTE'
     ) then
    raise exception 'RPC emocional ainda executavel por anon';
  end if;
end;
$$;

-- 2. Tipos de refeicao validos e legado sem tipo continua aceito.

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

do $$
declare
  v_patient_id uuid;
  v_tipo text;
begin
  select id into v_patient_id
    from public.pacientes
   where user_id = auth.uid();

  insert into public.registros_alimentares (
    paciente_id,
    descricao_refeicao,
    nivel_fome,
    tipo_refeicao
  ) values (v_patient_id, 'Macarrao com molho', 5, 'almoco');

  insert into public.registros_alimentares (
    paciente_id,
    descricao_refeicao,
    nivel_fome,
    tipo_refeicao
  ) values (v_patient_id, 'Legado sem tipo', 4, null);

  select tipo_refeicao into v_tipo
    from public.registros_alimentares
   where descricao_refeicao = 'Macarrao com molho';
  if v_tipo is distinct from 'almoco' then
    raise exception 'Tipo de refeicao nao persistido';
  end if;

  select tipo_refeicao into v_tipo
    from public.registros_alimentares
   where descricao_refeicao = 'Legado sem tipo';
  if v_tipo is not null then
    raise exception 'Tipo nulo deve ser preservado';
  end if;

  begin
    insert into public.registros_alimentares (
      paciente_id,
      descricao_refeicao,
      nivel_fome,
      tipo_refeicao
    ) values (v_patient_id, 'Tipo invalido', 5, 'brunch');
    raise exception 'EXPECTED_MEAL_TYPE_REJECTION';
  exception
    when check_violation then null;
  end;
end;
$$;

select id as almoco_id
from public.registros_alimentares
where descricao_refeicao = 'Macarrao com molho'
limit 1 \gset

select id as legado_id
from public.registros_alimentares
where descricao_refeicao = 'Legado sem tipo'
limit 1 \gset

-- 3. Lembretes: CRUD isolado por paciente e validações.

do $$
declare
  v_my_patient uuid;
  v_reminder uuid;
begin
  select id into v_my_patient
    from public.pacientes
   where user_id = auth.uid();

  insert into public.lembretes (
    paciente_id,
    tipo,
    titulo,
    horario
  ) values (v_my_patient, 'medicamento', 'Remedio do almoco', '12:30')
  returning id into v_reminder;

  if not exists (
    select 1
      from public.lembretes
     where id = v_reminder
       and paciente_id = v_my_patient
       and tipo = 'medicamento'
       and ativo
  ) then
    raise exception 'Lembrete criado com dados incorretos';
  end if;

  update public.lembretes
     set ativo = false
   where id = v_reminder;

  if exists (
    select 1
      from public.lembretes
     where id = v_reminder
       and ativo
  ) then
    raise exception 'Desativacao de lembrete falhou';
  end if;

  begin
    insert into public.lembretes (
      paciente_id,
      tipo,
      titulo,
      horario
    ) values (v_my_patient, 'suplemento', 'Invalido', '10:00');
    raise exception 'EXPECTED_REMINDER_TYPE_REJECTION';
  exception
    when check_violation then null;
  end;

  begin
    insert into public.lembretes (
      paciente_id,
      tipo,
      titulo,
      horario
    ) values (v_my_patient, 'refeicao', '   ', '10:00');
    raise exception 'EXPECTED_REMINDER_TITLE_REJECTION';
  exception
    when check_violation then null;
  end;

  delete from public.lembretes where id = v_reminder;
end;
$$;

-- 4. Lembretes de outro paciente são invisíveis.

reset role;

do $$
declare
  v_other_patient uuid;
  v_other_reminder uuid;
  v_count integer;
begin
  insert into auth.users (id, email)
  values (
    '90000000-0000-4000-8000-000000000001',
    'other-patient@example.com'
  );

  insert into public.usuarios (id, email)
  values (
    '90000000-0000-4000-8000-000000000001',
    'other-patient@example.com'
  );

  insert into public.pacientes (user_id)
  values ('90000000-0000-4000-8000-000000000001')
  returning id into v_other_patient;

  insert into public.lembretes (
    paciente_id,
    tipo,
    titulo,
    horario
  ) values (v_other_patient, 'refeicao', 'Almoco de outra pessoa', '11:00')
  returning id into v_other_reminder;

  perform set_config(
    'request.jwt.claim.sub',
    '00000000-0000-0000-0000-000000000002',
    false
  );
  perform set_config(
    'request.jwt.claims',
    '{"email":"patient@example.com"}',
    false
  );
  set role authenticated;

  if exists (
    select 1
      from public.lembretes
     where id = v_other_reminder
  ) then
    raise exception 'Lembrete de outro paciente ficou visivel';
  end if;

  update public.lembretes
     set titulo = 'Invasao'
   where id = v_other_reminder;
  get diagnostics v_count = row_count;
  if v_count <> 0 then
    raise exception 'Lembrete de outro paciente foi alterado';
  end if;

  delete from public.lembretes
   where id = v_other_reminder;
  get diagnostics v_count = row_count;
  if v_count <> 0 then
    raise exception 'Lembrete de outro paciente foi excluido';
  end if;

  reset role;
  delete from public.lembretes where id = v_other_reminder;
  delete from public.pacientes where id = v_other_patient;
  delete from public.usuarios
   where id = '90000000-0000-4000-8000-000000000001';
  delete from auth.users
   where id = '90000000-0000-4000-8000-000000000001';
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

-- 5. p_limpar_diario zera apenas o texto, preservando a avaliacao clinica.

select (public.iris_upsert_daily_emotional_record(
  p_data_local => current_date,
  p_fuso_horario => 'UTC',
  p_humor => 'Mal',
  p_como_sentiu => 2,
  p_avaliacao_alimentacao => 3,
  p_sintomas_emocionais_hoje => array['compulsao'],
  p_sintomas_fisicos_hoje => array['desmaio']
)).id as emocional_id \gset

select pg_sleep(0.02);

select (public.iris_upsert_daily_emotional_record(
  p_data_local => current_date,
  p_fuso_horario => 'UTC',
  p_diario_emocional => 'Diario que sera limpo',
  p_limpar_diario => true
)).id as limpo_id \gset

select (
  :'limpo_id' = :'emocional_id'
  and count(*) = 1
  and max(diario_emocional) is null
  and max(humor) = 'Mal'
  and max(como_sentiu) = 2
  and max(avaliacao_alimentacao) = 3
  and bool_or('compulsao' = any(sintomas_emocionais_hoje))
  and bool_or('desmaio' = any(sintomas_fisicos_hoje))
  and max(data_registro) = min(data_registro)
) as clear_preserves_clinical_data
from public.registros_emocionais
where id = :'emocional_id'::uuid
\gset

\if :clear_preserves_clinical_data
\else
  \echo 'Limpar diario alterou a avaliacao clinica ou renovou data_registro'
  \quit 1
\endif

-- 6. Edicao do diario (sem limpar) preserva a avaliacao clinica e nao renova
--    data_registro; um check-in posterior renova data_registro mas mantem o
--    texto do diario (que e editado em fluxo separado).

select data_registro as baseline_at
from public.registros_emocionais
where id = :'emocional_id'::uuid \gset

select (public.iris_upsert_daily_emotional_record(
  p_data_local => current_date,
  p_fuso_horario => 'UTC',
  p_diario_emocional => 'Novo texto de diario'
)).id as editado_id \gset

select data_registro as edited_at
from public.registros_emocionais
where id = :'editado_id'::uuid \gset

select pg_sleep(0.02);

select (public.iris_upsert_daily_emotional_record(
  p_data_local => current_date,
  p_fuso_horario => 'UTC',
  p_humor => 'Regular',
  p_como_sentiu => 3,
  p_avaliacao_alimentacao => 3
)).id as checkin2_id \gset

select data_registro as checkin2_at
from public.registros_emocionais
where id = :'checkin2_id'::uuid \gset

select (
  :'editado_id' = :'limpo_id'
  and :'checkin2_id' = :'editado_id'
  and count(*) = 1
  and max(diario_emocional) = 'Novo texto de diario'
  and max(humor) = 'Regular'
  and max(como_sentiu) = 3
  and :'edited_at'::timestamptz = :'baseline_at'::timestamptz
  and :'checkin2_at'::timestamptz > :'edited_at'::timestamptz
) as diary_edit_and_checkin_flow
from public.registros_emocionais
where id = :'emocional_id'::uuid
\gset

\if :diary_edit_and_checkin_flow
\else
  \echo 'Fluxo de edicao do diario divergiu do esperado'
  \quit 1
\endif

reset role;

-- 7. Registros alimentares tipados também ficam visíveis para o profissional
--    vinculado e ativo.

set role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000003',
  false
);
select set_config(
  'request.jwt.claims',
  '{"email":"pro2@example.com"}',
  false
);

select count(*) = 2
  and bool_or(tipo_refeicao = 'almoco')
  and bool_or(tipo_refeicao is null)
  as professional_sees_typed_foods
from public.registros_alimentares
where id in (:'almoco_id'::uuid, :'legado_id'::uuid)
\gset

\if :professional_sees_typed_foods
\else
  \echo 'Profissional nao enxerga os registros alimentares tipados'
  \quit 1
\endif

reset role;

select 'Melhorias do diario do paciente validadas.' as resultado;