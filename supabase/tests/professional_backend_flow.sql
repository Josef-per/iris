\set ON_ERROR_STOP on

insert into auth.users (id, email)
values
  ('00000000-0000-0000-0000-000000000001', 'pro1@example.com'),
  ('00000000-0000-0000-0000-000000000002', 'patient@example.com'),
  ('00000000-0000-0000-0000-000000000003', 'pro2@example.com');

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
select public.iris_bootstrap_current_user(
  'Profissional Um',
  'profissional',
  'Psiquiatria',
  'CRM 1001'
);
reset role;

select id as pro1_id
from public.profissionais
where user_id = '00000000-0000-0000-0000-000000000001'
\gset

select public.iris_set_professional_credential_status(
  :'pro1_id',
  'ativo'
);

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
select invite_id as pro1_invite_id, token as pro1_token
from public.iris_create_professional_invite(30, 1)
\gset
reset role;

select (token_hash <> :'pro1_token') as token_is_hashed
from public.convites_vinculo_profissional
where id = :'pro1_invite_id'
\gset
\if :token_is_hashed
\else
  \echo 'Token do convite foi persistido sem hash'
  \quit 1
\endif

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
select public.iris_bootstrap_current_user(
  'Paciente',
  'paciente',
  null,
  null
);
select *
from public.iris_preview_professional_invite(:'pro1_token');
select link_id as first_link_id
from public.iris_redeem_professional_invite(:'pro1_token')
\gset

-- Repetir a mesma chamada é idempotente e não consome outro uso.
select link_id
from public.iris_redeem_professional_invite(:'pro1_token');
reset role;

select (usos = 1) as first_invite_used_once
from public.convites_vinculo_profissional
where id = :'pro1_invite_id'
\gset
\if :first_invite_used_once
\else
  \echo 'Resgate idempotente contabilizou mais de um uso'
  \quit 1
\endif

-- Exercita o backend operacional com as mesmas permissões do cliente.
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
select public.iris_update_linked_patient(
  :'first_link_id',
  'Diagnóstico de teste',
  'ativo',
  'Bem'
);
insert into public.consultas (
  vinculo_id,
  inicio_em,
  modalidade,
  status
)
values (
  :'first_link_id',
  now() + interval '1 day',
  'online',
  'agendada'
);
insert into public.anotacoes_clinicas (
  vinculo_id,
  profissional_id,
  conteudo,
  marcador
)
values (
  :'first_link_id',
  :'pro1_id',
  'Anotação de teste',
  'Evolução'
);
select public.iris_save_care_plan(
  :'first_link_id',
  'Orientação de teste',
  true,
  true,
  array['Passo de crise'],
  '[{"text":"Meta de teste","completed":false}]'::jsonb,
  '[{"name":"Medicação","dose":"10 mg","frequency":"Diária","adherence":1}]'::jsonb
);
select public.iris_update_professional_settings(
  'Profissional Um',
  null,
  'Psiquiatria',
  'CRM 1001',
  'Biografia de teste',
  'Clínica Teste',
  'Endereço Teste',
  'PU',
  true,
  true,
  false
);
reset role;

select (
  (select count(*) from public.consultas
    where vinculo_id = :'first_link_id') = 1
  and (select count(*) from public.anotacoes_clinicas
    where vinculo_id = :'first_link_id') = 1
  and (select count(*) from public.planos_cuidado
    where vinculo_id = :'first_link_id') = 1
  and (select count(*)
    from public.metas_cuidado meta
    join public.planos_cuidado plano on plano.id = meta.plano_id
    where plano.vinculo_id = :'first_link_id') = 1
  and (select count(*)
    from public.medicacoes_plano medicacao
    join public.planos_cuidado plano on plano.id = medicacao.plano_id
    where plano.vinculo_id = :'first_link_id') = 1
) as professional_crud_persisted
\gset
\if :professional_crud_persisted
\else
  \echo 'CRUD operacional do profissional não foi persistido'
  \quit 1
\endif

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
select public.iris_bootstrap_current_user(
  'Profissional Dois',
  'profissional',
  'Psiquiatria',
  'CRM 1002'
);
reset role;

select id as pro2_id
from public.profissionais
where user_id = '00000000-0000-0000-0000-000000000003'
\gset

select public.iris_set_professional_credential_status(
  :'pro2_id',
  'ativo'
);

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
select token as pro2_token
from public.iris_create_professional_invite(30, 1)
\gset
reset role;

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
select link_id as second_link_id
from public.iris_redeem_professional_invite(:'pro2_token')
\gset
reset role;

select (
  count(*) filter (where autorizacao_status = 'ativo') = 1
  and count(*) filter (where autorizacao_status = 'revogado') = 1
) as single_authorized_professional
from public.paciente_profissional
where paciente_id = (
  select id
  from public.pacientes
  where user_id = '00000000-0000-0000-0000-000000000002'
)
\gset
\if :single_authorized_professional
\else
  \echo 'Troca de profissional não preservou autorização única'
  \quit 1
\endif

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
select (count(*) = 0) as old_professional_cannot_read_link
from public.paciente_profissional
where id = :'first_link_id'
\gset
reset role;

\if :old_professional_cannot_read_link
\else
  \echo 'Profissional revogado ainda lê o vínculo'
  \quit 1
\endif
