-- Schema base reproduzivel do Iris.
-- Esta migration usa CREATE/ALTER idempotentes para também funcionar em
-- projetos Supabase que já possuam parte das tabelas criadas manualmente.

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

-- Impede que papéis da API criem objetos que possam sombrear funções usadas
-- por rotinas SECURITY DEFINER. O proprietário continua aplicando migrations.
revoke create on schema public from public;
revoke create on schema extensions from public;
grant usage on schema public to anon, authenticated;

create table if not exists public.usuarios (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  senha_hash text not null default 'managed_by_supabase_auth',
  tipo_usuario text not null default 'paciente',
  ativo boolean not null default true,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);

alter table public.usuarios
  add column if not exists email text,
  add column if not exists senha_hash text default 'managed_by_supabase_auth',
  add column if not exists tipo_usuario text default 'paciente',
  add column if not exists ativo boolean default true,
  add column if not exists criado_em timestamptz default now(),
  add column if not exists atualizado_em timestamptz default now();

create table if not exists public.perfis (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.usuarios(id) on delete cascade,
  nome_completo text,
  nome_social text,
  telefone text,
  data_nascimento date,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);

alter table public.perfis
  add column if not exists user_id uuid,
  add column if not exists nome_completo text,
  add column if not exists nome_social text,
  add column if not exists telefone text,
  add column if not exists data_nascimento date,
  add column if not exists criado_em timestamptz default now(),
  add column if not exists atualizado_em timestamptz default now();

create table if not exists public.pacientes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.usuarios(id) on delete cascade,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);

alter table public.pacientes
  add column if not exists user_id uuid,
  add column if not exists criado_em timestamptz default now(),
  add column if not exists atualizado_em timestamptz default now();

create table if not exists public.profissionais (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.usuarios(id) on delete cascade,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);

alter table public.profissionais
  add column if not exists user_id uuid,
  add column if not exists criado_em timestamptz default now(),
  add column if not exists atualizado_em timestamptz default now();

create table if not exists public.paciente_profissional (
  id uuid primary key default gen_random_uuid(),
  paciente_id uuid not null references public.pacientes(id) on delete cascade,
  profissional_id uuid not null references public.profissionais(id) on delete cascade,
  status text not null default 'ativo',
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);

alter table public.paciente_profissional
  add column if not exists paciente_id uuid,
  add column if not exists profissional_id uuid,
  add column if not exists status text default 'ativo',
  add column if not exists criado_em timestamptz default now(),
  add column if not exists atualizado_em timestamptz default now();

create table if not exists public.registros_alimentares (
  id uuid primary key default gen_random_uuid(),
  paciente_id uuid not null references public.pacientes(id) on delete cascade,
  horario_refeicao timestamptz not null default now(),
  descricao_refeicao text not null,
  nivel_fome integer,
  sentimento_depois text,
  observacoes text,
  foto_url text,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);

alter table public.registros_alimentares
  add column if not exists paciente_id uuid,
  add column if not exists horario_refeicao timestamptz default now(),
  add column if not exists descricao_refeicao text,
  add column if not exists nivel_fome integer,
  add column if not exists sentimento_depois text,
  add column if not exists observacoes text,
  add column if not exists foto_url text,
  add column if not exists criado_em timestamptz default now(),
  add column if not exists atualizado_em timestamptz default now();

create table if not exists public.registros_emocionais (
  id uuid primary key default gen_random_uuid(),
  paciente_id uuid not null references public.pacientes(id) on delete cascade,
  data_registro timestamptz not null default now(),
  diario_emocional text,
  humor text,
  como_sentiu integer,
  avaliacao_alimentacao integer,
  sintomas_emocionais_hoje integer[] not null default '{}',
  sintomas_fisicos_hoje integer[] not null default '{}',
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);

alter table public.registros_emocionais
  add column if not exists paciente_id uuid,
  add column if not exists data_registro timestamptz default now(),
  add column if not exists diario_emocional text,
  add column if not exists humor text,
  add column if not exists como_sentiu integer,
  add column if not exists avaliacao_alimentacao integer,
  add column if not exists sintomas_emocionais_hoje integer[] default '{}',
  add column if not exists sintomas_fisicos_hoje integer[] default '{}',
  add column if not exists criado_em timestamptz default now(),
  add column if not exists atualizado_em timestamptz default now();

create unique index if not exists iris_perfis_user_unique
  on public.perfis(user_id);
create unique index if not exists iris_pacientes_user_unique
  on public.pacientes(user_id);
create unique index if not exists iris_profissionais_user_unique
  on public.profissionais(user_id);
create unique index if not exists iris_paciente_profissional_unique
  on public.paciente_profissional(paciente_id, profissional_id);

create index if not exists iris_vinculos_profissional_status_idx
  on public.paciente_profissional(profissional_id, status);
create index if not exists iris_vinculos_paciente_status_idx
  on public.paciente_profissional(paciente_id, status);
create index if not exists iris_alimentares_paciente_data_idx
  on public.registros_alimentares(paciente_id, horario_refeicao desc);
create index if not exists iris_emocionais_paciente_data_idx
  on public.registros_emocionais(paciente_id, data_registro desc);

-- As policies e funções SECURITY DEFINER dependem destes valores canônicos.
-- Um papel desconhecido faz a migration falhar, em vez de ser convertido
-- silenciosamente para um papel com privilégios diferentes.
update public.usuarios
   set tipo_usuario = lower(btrim(tipo_usuario))
 where lower(btrim(tipo_usuario)) in ('paciente', 'profissional');

update public.usuarios
   set tipo_usuario = 'paciente'
 where tipo_usuario is null;

update public.usuarios
   set ativo = false
 where ativo is null;

update public.paciente_profissional
   set status = 'inativo'
 where status is null;

alter table public.usuarios
  alter column tipo_usuario set default 'paciente',
  alter column tipo_usuario set not null,
  alter column ativo set default true,
  alter column ativo set not null;

alter table public.paciente_profissional
  alter column status set default 'ativo',
  alter column status set not null;

do $$
begin
  if not exists (
    select 1
      from pg_constraint
     where conrelid = 'public.usuarios'::regclass
       and conname = 'iris_usuarios_tipo_valido'
  ) then
    alter table public.usuarios
      add constraint iris_usuarios_tipo_valido
      check (tipo_usuario in ('paciente', 'profissional'));
  end if;

  if not exists (
    select 1
      from pg_constraint
     where conrelid = 'public.paciente_profissional'::regclass
       and conname = 'iris_vinculos_status_valido'
  ) then
    alter table public.paciente_profissional
      add constraint iris_vinculos_status_valido
      check (status in ('ativo', 'inativo'));
  end if;
end;
$$;
