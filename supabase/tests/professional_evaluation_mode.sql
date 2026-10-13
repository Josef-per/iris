\set ON_ERROR_STOP on
begin;

do $$
begin
  if not (select habilitado from public.configuracao_avaliacao_profissional) then
    raise exception 'Modo de avaliação não foi ativado pela migration';
  end if;
  if has_table_privilege('authenticated', 'public.configuracao_avaliacao_profissional', 'SELECT')
    or has_table_privilege('authenticated', 'public.configuracao_avaliacao_profissional', 'UPDATE')
    or has_table_privilege('anon', 'public.configuracao_avaliacao_profissional', 'UPDATE')
    or has_function_privilege('authenticated', 'public.iris_apply_professional_evaluation_mode()', 'EXECUTE') then
    raise exception 'Configuração administrativa acessível pelo cliente';
  end if;
  if not has_table_privilege('service_role', 'public.configuracao_avaliacao_profissional', 'UPDATE') then
    raise exception 'Administrador não consegue encerrar a avaliação';
  end if;
end;
$$;

insert into auth.users (id, email) values
  ('17000000-0000-0000-0000-000000000001', 'evaluation-pro@example.com'),
  ('17000000-0000-0000-0000-000000000002', 'manual-pro@example.com'),
  ('17000000-0000-0000-0000-000000000003', 'evaluation-patient@example.com');

-- O mesmo bootstrap chamado pelo cadastro Flutter libera o painel e o QR.
set role authenticated;
select set_config('request.jwt.claim.sub', '17000000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claims', '{"email":"evaluation-pro@example.com"}', true);
select public.iris_bootstrap_current_user('Avaliador', 'profissional', 'Psicologia', 'CRP TESTE');
select public.iris_bootstrap_current_user('Avaliador', 'profissional', 'Psicologia', 'CRP TESTE');
select * from public.iris_create_professional_invite(30, 1);

do $$
begin
  if public.iris_current_professional_id() is null then
    raise exception 'Cadastro de avaliação não liberou acesso profissional';
  end if;
  if (select count(*) from public.profissionais where user_id = auth.uid()) <> 1 then
    raise exception 'Bootstrap repetido duplicou o profissional';
  end if;
  if exists (select 1 from public.anotacoes_clinicas) then
    raise exception 'Avaliação liberou anotações de pacientes sem autorização';
  end if;

  begin
    update public.configuracao_avaliacao_profissional set habilitado = false;
    raise exception 'Cliente alterou o modo de avaliação';
  exception when insufficient_privilege then null;
  end;
  begin
    update public.profissionais set credenciamento_status = 'ativo' where user_id = auth.uid();
    raise exception 'Cliente alterou diretamente o credenciamento';
  exception when insufficient_privilege then null;
  end;

  if public.iris_update_professional_settings(
    'Avaliador', null, 'Psiquiatria', 'CRM TESTE', null, null, null, null,
    true, true, false
  ) <> 'ativo' then
    raise exception 'Editar credenciais durante a avaliação bloqueou o painel';
  end if;
end;
$$;
reset role;

-- A avaliação não ignora a suspensão/rejeição administrativa em novos logins.
do $$
declare
  v_status text;
  v_professional_id uuid;
begin
  select id into v_professional_id from public.profissionais
  where user_id = '17000000-0000-0000-0000-000000000001';
  foreach v_status in array array['suspenso', 'rejeitado', 'pendente'] loop
    perform public.iris_set_professional_credential_status(v_professional_id, v_status);
    perform public.iris_bootstrap_current_user('Avaliador', 'profissional', 'Psicologia', 'CRP TESTE');
    if (select credenciamento_status from public.profissionais where id = v_professional_id) <> v_status then
      raise exception 'Bootstrap reativou profissional %', v_status;
    end if;
    if public.iris_current_professional_id() is not null then
      raise exception 'Profissional % ainda tem acesso ao painel', v_status;
    end if;
    if public.iris_update_professional_settings(
      'Avaliador', null, v_status, v_status, null, null, null, null,
      true, true, false
    ) = 'ativo' then
      raise exception 'Editar credenciais reativou profissional %', v_status;
    end if;
  end loop;
  perform public.iris_set_professional_credential_status(v_professional_id, 'ativo');
end;
$$;

-- Encerrar o piloto preserva aprovações e retoma a análise dos novos cadastros.
set role service_role;
update public.configuracao_avaliacao_profissional set habilitado = false where id = true;
reset role;

do $$
begin
  if (select credenciamento_status from public.profissionais
      where user_id = '17000000-0000-0000-0000-000000000001') <> 'ativo' then
    raise exception 'Desativar avaliação removeu uma aprovação existente';
  end if;
end;
$$;

set role authenticated;
select set_config('request.jwt.claim.sub', '17000000-0000-0000-0000-000000000002', true);
select set_config('request.jwt.claims', '{"email":"manual-pro@example.com"}', true);
select public.iris_bootstrap_current_user('Manual', 'profissional', 'Psicologia', 'CRP MANUAL');
do $$
begin
  if (select credenciamento_status from public.profissionais where user_id = auth.uid()) <> 'pendente' then
    raise exception 'Cadastro foi aprovado com avaliação desativada';
  end if;
  begin
    perform public.iris_create_professional_invite(30, 1);
    raise exception 'Cadastro pendente conseguiu gerar convite';
  exception when others then
    if sqlerrm <> 'PROFESSIONAL_NOT_APPROVED' then raise; end if;
  end;
end;
$$;
reset role;

-- Reativar o piloto não aprova pendências existentes ao entrar ou editar perfil.
update public.configuracao_avaliacao_profissional set habilitado = true where id = true;
set role authenticated;
select public.iris_bootstrap_current_user('Manual', 'profissional', 'Psicologia', 'CRP MANUAL');
do $$
begin
  if public.iris_update_professional_settings(
    'Manual', null, 'Psiquiatria', 'CRM MANUAL', null, null, null, null,
    true, true, false
  ) <> 'pendente' then
    raise exception 'Piloto aprovou pendência existente';
  end if;
end;
$$;
reset role;

-- Fora do piloto, alterar as credenciais de um aprovado exige nova análise.
update public.configuracao_avaliacao_profissional set habilitado = false where id = true;
set role authenticated;
select set_config('request.jwt.claim.sub', '17000000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claims', '{"email":"evaluation-pro@example.com"}', true);
do $$
begin
  if public.iris_update_professional_settings(
    'Avaliador', null, 'Nutrição', 'CRN TESTE', null, null, null, null,
    true, true, false
  ) <> 'pendente' then
    raise exception 'Editar credenciais fora do piloto não exigiu revisão';
  end if;
end;
$$;
reset role;

-- Cadastro de paciente continua separado e não ganha vínculo automático.
update public.configuracao_avaliacao_profissional set habilitado = true where id = true;
set role authenticated;
select set_config('request.jwt.claim.sub', '17000000-0000-0000-0000-000000000003', true);
select set_config('request.jwt.claims', '{"email":"evaluation-patient@example.com"}', true);
select public.iris_bootstrap_current_user('Paciente', 'paciente', null, null);
reset role;
do $$
begin
  if exists (select 1 from public.profissionais
      where user_id = '17000000-0000-0000-0000-000000000003')
    or exists (select 1 from public.paciente_profissional
      where paciente_id = (select id from public.pacientes
        where user_id = '17000000-0000-0000-0000-000000000003')) then
    raise exception 'Modo de avaliação alterou o fluxo de autorização do paciente';
  end if;
end;
$$;

rollback;
