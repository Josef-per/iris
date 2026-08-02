\set ON_ERROR_STOP on

do $$
declare
  missing_table text;
begin
  foreach missing_table in array array[
    'consultas',
    'anotacoes_clinicas',
    'planos_cuidado',
    'metas_cuidado',
    'medicacoes_plano',
    'convites_vinculo_profissional',
    'convites_vinculo_resgates'
  ]
  loop
    if to_regclass('public.' || missing_table) is null then
      raise exception 'Tabela ausente: %', missing_table;
    end if;
  end loop;

  if to_regprocedure(
    'public.iris_create_professional_invite(integer,integer)'
  ) is null then
    raise exception 'RPC de criação de convite ausente';
  end if;

  if to_regprocedure(
    'public.iris_redeem_professional_invite(text)'
  ) is null then
    raise exception 'RPC de resgate de convite ausente';
  end if;

  if not exists (
    select 1
    from pg_indexes
    where schemaname = 'public'
      and indexname = 'iris_vinculo_autorizado_por_paciente_unique'
  ) then
    raise exception 'Índice de vínculo único ausente';
  end if;

  if exists (
    select 1
    from information_schema.role_table_grants
    where grantee = 'authenticated'
      and table_schema = 'public'
      and table_name in (
        'usuarios',
        'profissionais',
        'paciente_profissional',
        'convites_vinculo_profissional',
        'convites_vinculo_resgates'
      )
      and privilege_type in ('INSERT', 'UPDATE', 'DELETE')
  ) then
    raise exception 'DML sensível concedido diretamente ao cliente';
  end if;

  if not exists (
    select 1
      from public.paciente_profissional
     where paciente_id = '20000000-0000-4000-8000-000000000001'
     group by paciente_id
    having count(*) filter (where autorizacao_status = 'ativo') = 1
       and count(*) filter (where autorizacao_status = 'revogado') = 1
       and count(*) filter (
             where autorizacao_status = 'ativo'
               and profissional_id =
                 '20000000-0000-4000-8000-000000000003'
           ) = 1
  ) then
    raise exception 'Vínculos autorizados legados não foram reconciliados';
  end if;
end;
$$;
