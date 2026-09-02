\set ON_ERROR_STOP on

do $$
begin
  if to_regclass('public.mensagens_diarias_ia') is null then
    raise exception 'Tabela de reflexao diaria ausente';
  end if;
  if not exists (
    select 1
      from information_schema.columns
     where table_schema = 'public'
       and table_name = 'rollout_ia_apoio'
       and column_name = 'mensagem_diaria_ativa'
  ) then
    raise exception 'Gate da reflexao diaria ausente';
  end if;
  if not exists (
    select 1
      from pg_trigger
     where tgrelid = 'public.registros_emocionais'::regclass
       and tgname = 'iris_invalidar_mensagem_diaria_ao_mudar_diario'
       and not tgisinternal
  ) then
    raise exception 'Trigger de invalidacao da reflexao diaria ausente';
  end if;
end;
$$;

select paciente.id as companion_patient_id,
       registro.id as companion_record_id,
       registro.como_sentiu as companion_original_mood
  from public.pacientes paciente
  join public.registros_emocionais registro
    on registro.paciente_id = paciente.id
 where paciente.user_id = '00000000-0000-0000-0000-000000000002'::uuid
   and registro.data_local = current_date
   and registro.como_sentiu is not null
 limit 1
\gset

insert into public.mensagens_diarias_ia (
  paciente_id,
  registro_emocional_id,
  data_local,
  titulo,
  mensagem,
  pergunta_reflexao,
  origem,
  modelo,
  fontes_usadas,
  expira_em
) values (
  :'companion_patient_id'::uuid,
  :'companion_record_id'::uuid,
  current_date,
  'Uma prioridade possível',
  'Talvez uma única prioridade seja suficiente para orientar o restante deste dia.',
  null,
  'openai',
  'gpt-5-mini',
  array['mood_history'],
  now() + interval '36 hours'
);

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

select public.iris_upsert_daily_emotional_record(
  current_date,
  'UTC',
  p_como_sentiu => case
    when :'companion_original_mood'::integer = 5 then 4
    else :'companion_original_mood'::integer + 1
  end
);

reset role;

select 1 / case when not exists (
  select 1
    from public.mensagens_diarias_ia
   where paciente_id = :'companion_patient_id'::uuid
     and data_local = current_date
) then 1 else 0 end as reflexao_antiga_removida;

select 'Reflexao diaria e atualizacao de contexto validadas.' as resultado;
