\set ON_ERROR_STOP on

-- Reproduz o estado permitido pelo schema anterior: um mesmo paciente com
-- dois profissionais ativos. A migration 0006 deve reconciliar esse legado.
-- O banco original tambem usava varchar nos campos exibidos pelas RPCs de QR;
-- as funcoes RETURNS TABLE precisam normaliza-los explicitamente para text.
alter table public.perfis
  alter column nome_completo type varchar(255),
  alter column nome_social type varchar(255);

alter table public.profissionais
  add column especialidade varchar(255);

insert into auth.users (id, email)
values
  ('10000000-0000-4000-8000-000000000001', 'legacy-patient@example.com'),
  ('10000000-0000-4000-8000-000000000002', 'legacy-pro-old@example.com'),
  ('10000000-0000-4000-8000-000000000003', 'legacy-pro-new@example.com');

insert into public.usuarios (id, email, tipo_usuario)
values
  (
    '10000000-0000-4000-8000-000000000001',
    'legacy-patient@example.com',
    'paciente'
  ),
  (
    '10000000-0000-4000-8000-000000000002',
    'legacy-pro-old@example.com',
    'profissional'
  ),
  (
    '10000000-0000-4000-8000-000000000003',
    'legacy-pro-new@example.com',
    'profissional'
  );

insert into public.pacientes (id, user_id)
values (
  '20000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000001'
);

insert into public.profissionais (id, user_id)
values
  (
    '20000000-0000-4000-8000-000000000002',
    '10000000-0000-4000-8000-000000000002'
  ),
  (
    '20000000-0000-4000-8000-000000000003',
    '10000000-0000-4000-8000-000000000003'
  );

insert into public.paciente_profissional (
  id,
  paciente_id,
  profissional_id,
  status,
  criado_em,
  atualizado_em
)
values
  (
    '30000000-0000-4000-8000-000000000002',
    '20000000-0000-4000-8000-000000000001',
    '20000000-0000-4000-8000-000000000002',
    'ativo',
    '2025-01-01 12:00:00+00',
    '2025-01-01 12:00:00+00'
  ),
  (
    '30000000-0000-4000-8000-000000000003',
    '20000000-0000-4000-8000-000000000001',
    '20000000-0000-4000-8000-000000000003',
    'ativo',
    '2025-02-01 12:00:00+00',
    '2025-02-01 12:00:00+00'
  );
