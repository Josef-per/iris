\set ON_ERROR_STOP on
begin;

insert into auth.users (id, email, raw_user_meta_data) values
  ('16000000-0000-0000-0000-000000000001', 'lucas@gmail.com', '{"tipo_usuario":"profissional"}'),
  ('16000000-0000-0000-0000-000000000002', 'demo@example.com', '{"tipo_usuario":"paciente","demo_professional_link":true}'),
  ('16000000-0000-0000-0000-000000000003', 'legacy@example.com', '{"tipo_usuario":"paciente"}'),
  ('16000000-0000-0000-0000-000000000004', 'other-demo@example.com', '{"tipo_usuario":"paciente","demo_professional_link":true}');

set role authenticated;
select set_config('request.jwt.claim.sub', '16000000-0000-0000-0000-000000000001', false);
select set_config('request.jwt.claims', '{"email":"lucas@gmail.com"}', false);
select public.iris_bootstrap_current_user('Lucas', 'profissional', 'Psiquiatria', 'CRM TESTE');
select set_config('request.jwt.claim.sub', '16000000-0000-0000-0000-000000000002', false);
select set_config('request.jwt.claims', '{"email":"demo@example.com"}', false);
select public.iris_bootstrap_current_user('Demo', 'paciente', null, null);
select set_config('request.jwt.claim.sub', '16000000-0000-0000-0000-000000000003', false);
select set_config('request.jwt.claims', '{"email":"legacy@example.com"}', false);
select public.iris_bootstrap_current_user('Legado', 'paciente', null, null);
select set_config('request.jwt.claim.sub', '16000000-0000-0000-0000-000000000004', false);
select set_config('request.jwt.claims', '{"email":"other-demo@example.com"}', false);
select public.iris_bootstrap_current_user('Outro Demo', 'paciente', null, null);
reset role;

do $$
begin
  if (select count(*) from public.cadastros_paciente_demo) <> 2 then
    raise exception 'Cadastro profissional ou legado entrou na demonstração';
  end if;
  if exists (
    select 1 from public.paciente_profissional v join public.pacientes p on p.id = v.paciente_id
    where p.user_id in ('16000000-0000-0000-0000-000000000002', '16000000-0000-0000-0000-000000000004')
  ) then
    raise exception 'Vínculo criado sem aprovação';
  end if;
end;
$$;

create function pg_temp.expect_demo_denied(expected text) returns void language plpgsql as $$
begin
  begin
    perform public.iris_approve_demo_professional_link();
  exception when others then
    if sqlerrm = expected then return; end if;
    raise;
  end;
  raise exception 'Acesso indevido: esperava %', expected;
end;
$$;
grant execute on function pg_temp.expect_demo_denied(text) to authenticated;

-- Não libera vínculo enquanto o profissional não estiver credenciado.
set role authenticated;
select set_config('request.jwt.claim.sub', '16000000-0000-0000-0000-000000000002', false);
select pg_temp.expect_demo_denied('DEMO_PROFESSIONAL_UNAVAILABLE');
reset role;
update public.profissionais set credenciamento_status = 'ativo'
where user_id = '16000000-0000-0000-0000-000000000001';

-- Alterar metadados de uma conta existente não cria elegibilidade.
update auth.users set raw_user_meta_data = raw_user_meta_data || '{"demo_professional_link":true}'::jsonb
where id = '16000000-0000-0000-0000-000000000003';
set role authenticated;
select set_config('request.jwt.claim.sub', '16000000-0000-0000-0000-000000000003', false);
select pg_temp.expect_demo_denied('DEMO_REGISTRATION_REQUIRED');
select set_config('request.jwt.claim.sub', '16000000-0000-0000-0000-000000000001', false);
select pg_temp.expect_demo_denied('PATIENT_REQUIRED');

-- A aprovação é idempotente e aponta exclusivamente para o Lucas.
select set_config('request.jwt.claim.sub', '16000000-0000-0000-0000-000000000002', false);
do $$
declare first_link uuid;
begin
  first_link := public.iris_approve_demo_professional_link();
  if first_link <> public.iris_approve_demo_professional_link() then
    raise exception 'Aprovação duplicou o vínculo';
  end if;
  if not exists (
    select 1 from public.paciente_profissional v join public.profissionais p on p.id = v.profissional_id
    where v.id = first_link and p.user_id = '16000000-0000-0000-0000-000000000001'
      and v.autorizacao_status = 'ativo' and v.status = 'ativo'
  ) then
    raise exception 'Vínculo não aponta para Lucas ativo';
  end if;
end;
$$;
reset role;

-- Não reativa autorização revogada.
update public.paciente_profissional set autorizacao_status = 'revogado', status = 'inativo'
where paciente_id = (select id from public.pacientes where user_id = '16000000-0000-0000-0000-000000000002');
set role authenticated;
select pg_temp.expect_demo_denied('DEMO_LINK_ALREADY_EXISTS');
reset role;

-- Não troca o profissional de um paciente já vinculado pelo fluxo normal.
insert into public.paciente_profissional (paciente_id, profissional_id, status, autorizacao_status)
select p.id, pr.id, 'ativo', 'ativo' from public.pacientes p cross join public.profissionais pr
where p.user_id = '16000000-0000-0000-0000-000000000004'
  and pr.user_id = '00000000-0000-0000-0000-000000000001';
set role authenticated;
select set_config('request.jwt.claim.sub', '16000000-0000-0000-0000-000000000004', false);
select pg_temp.expect_demo_denied('DEMO_LINK_ALREADY_EXISTS');
reset role;

do $$
begin
  if has_function_privilege('anon', 'public.iris_approve_demo_professional_link()', 'execute')
    or has_table_privilege('authenticated', 'public.cadastros_paciente_demo', 'insert') then
    raise exception 'Permissões excessivas no fluxo de demonstração';
  end if;
end;
$$;
rollback;
