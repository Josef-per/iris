-- Backend profissional do Iris.
-- Inclui credenciamento, consultas, anotações, plano de cuidado, RLS e
-- convites QR temporários. Depende de 0001_core_schema.sql.

alter table public.perfis
  add column if not exists telefone text,
  add column if not exists data_nascimento date,
  add column if not exists atualizado_em timestamptz default now();

-- Preserva como aprovados apenas os profissionais que já existiam antes
-- desta migration. Novos registros ficam pendentes até revisão administrativa.
do $$
begin
  if not exists (
    select 1
      from information_schema.columns
     where table_schema = 'public'
       and table_name = 'profissionais'
       and column_name = 'credenciamento_status'
  ) then
    alter table public.profissionais
      add column credenciamento_status text;

    update public.profissionais
       set credenciamento_status = 'ativo';
  end if;
end;
$$;

alter table public.profissionais
  add column if not exists especialidade text,
  add column if not exists registro_profissional text,
  add column if not exists biografia text,
  add column if not exists telefone text,
  add column if not exists clinica text,
  add column if not exists endereco_clinica text,
  add column if not exists iniciais_avatar text,
  add column if not exists notificacoes_consultas boolean not null default true,
  add column if not exists alertas_crise boolean not null default true,
  add column if not exists relatorios_automaticos boolean not null default false,
  add column if not exists atualizado_em timestamptz default now();

update public.profissionais
   set credenciamento_status = 'pendente'
 where credenciamento_status is null;

alter table public.profissionais
  alter column credenciamento_status set default 'pendente',
  alter column credenciamento_status set not null;

alter table public.paciente_profissional
  add column if not exists diagnostico text,
  add column if not exists humor_atual text,
  add column if not exists ultimo_registro timestamptz,
  add column if not exists atualizado_em timestamptz default now();

do $$
begin
  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'paciente_profissional'
      and column_name = 'autorizacao_status'
  ) then
    alter table public.paciente_profissional
      add column autorizacao_status text not null default 'ativo';

    update public.paciente_profissional
       set autorizacao_status = 'revogado'
     where status = 'inativo';
  end if;
end;
$$;

alter table public.paciente_profissional
  add column if not exists autorizacao_revogada_em timestamptz;

update public.paciente_profissional
   set autorizacao_status = 'revogado',
       autorizacao_revogada_em = coalesce(autorizacao_revogada_em, now())
 where autorizacao_status is null;

update public.paciente_profissional
   set autorizacao_revogada_em = coalesce(atualizado_em, now())
 where autorizacao_status = 'revogado'
   and autorizacao_revogada_em is null;

alter table public.paciente_profissional
  alter column autorizacao_status set default 'ativo',
  alter column autorizacao_status set not null;

do $$
begin
  if not exists (
    select 1
      from pg_constraint
     where conrelid = 'public.profissionais'::regclass
       and conname = 'iris_profissionais_credenciamento_valido'
  ) then
    alter table public.profissionais
      add constraint iris_profissionais_credenciamento_valido
      check (
        credenciamento_status in (
          'pendente',
          'ativo',
          'rejeitado',
          'suspenso'
        )
      );
  end if;

  if not exists (
    select 1
      from pg_constraint
     where conrelid = 'public.paciente_profissional'::regclass
       and conname = 'iris_vinculos_autorizacao_valida'
  ) then
    alter table public.paciente_profissional
      add constraint iris_vinculos_autorizacao_valida
      check (autorizacao_status in ('ativo', 'revogado'));
  end if;
end;
$$;

create table if not exists public.consultas (
  id uuid primary key default gen_random_uuid(),
  vinculo_id uuid not null references public.paciente_profissional(id) on delete cascade,
  inicio_em timestamptz not null,
  fim_em timestamptz,
  modalidade text not null default 'online',
  status text not null default 'agendada',
  titulo text,
  local_ou_link text,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now(),
  constraint iris_consultas_periodo_valido
    check (fim_em is null or fim_em > inicio_em)
);

create table if not exists public.anotacoes_clinicas (
  id uuid primary key default gen_random_uuid(),
  vinculo_id uuid not null references public.paciente_profissional(id) on delete cascade,
  profissional_id uuid not null references public.profissionais(id) on delete cascade,
  conteudo text not null,
  marcador text not null default 'Evolução',
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);

create table if not exists public.planos_cuidado (
  id uuid primary key default gen_random_uuid(),
  vinculo_id uuid not null unique references public.paciente_profissional(id) on delete cascade,
  orientacoes text,
  passos_crise text[] not null default '{}',
  compartilhar_paciente boolean not null default true,
  alertar_checkins_ausentes boolean not null default true,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);

create table if not exists public.metas_cuidado (
  id uuid primary key default gen_random_uuid(),
  plano_id uuid not null references public.planos_cuidado(id) on delete cascade,
  descricao text not null,
  concluida boolean not null default false,
  ordem integer not null default 0,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);

create table if not exists public.medicacoes_plano (
  id uuid primary key default gen_random_uuid(),
  plano_id uuid not null references public.planos_cuidado(id) on delete cascade,
  nome text not null,
  dose text not null,
  frequencia text not null,
  adesao numeric(5,4) not null default 1,
  ordem integer not null default 0,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now(),
  constraint iris_medicacoes_adesao_valida check (adesao between 0 and 1)
);

create table if not exists public.convites_vinculo_profissional (
  id uuid primary key default gen_random_uuid(),
  profissional_id uuid not null references public.profissionais(id) on delete cascade,
  token_hash text not null unique,
  expira_em timestamptz not null,
  max_usos integer not null default 1,
  usos integer not null default 0,
  revogado_em timestamptz,
  ultimo_uso_em timestamptz,
  criado_em timestamptz not null default now(),
  constraint iris_convites_max_usos_valido check (max_usos between 1 and 100),
  constraint iris_convites_usos_valido check (usos between 0 and max_usos)
);

create table if not exists public.convites_vinculo_resgates (
  id uuid primary key default gen_random_uuid(),
  convite_id uuid not null
    references public.convites_vinculo_profissional(id) on delete cascade,
  paciente_id uuid not null references public.pacientes(id) on delete cascade,
  criado_em timestamptz not null default now(),
  unique (convite_id, paciente_id)
);

create index if not exists iris_consultas_vinculo_inicio_idx
  on public.consultas(vinculo_id, inicio_em);
create index if not exists iris_anotacoes_vinculo_data_idx
  on public.anotacoes_clinicas(vinculo_id, criado_em desc);
create index if not exists iris_metas_plano_ordem_idx
  on public.metas_cuidado(plano_id, ordem);
create index if not exists iris_medicacoes_plano_ordem_idx
  on public.medicacoes_plano(plano_id, ordem);
create index if not exists iris_convites_profissional_ativos_idx
  on public.convites_vinculo_profissional(profissional_id, expira_em)
  where revogado_em is null;

-- Bancos legados podiam manter mais de um profissional autorizado para o
-- mesmo paciente. Preserva o vínculo ativo mais recente e revoga os demais
-- sem apagar o histórico clínico associado a eles.
with vinculos_autorizados_ordenados as (
  select
    vinculo.id,
    row_number() over (
      partition by vinculo.paciente_id
      order by
        case when vinculo.status = 'ativo' then 0 else 1 end,
        coalesce(
          vinculo.atualizado_em,
          vinculo.criado_em,
          '-infinity'::timestamptz
        ) desc,
        vinculo.id desc
    ) as ordem
  from public.paciente_profissional vinculo
  where vinculo.autorizacao_status = 'ativo'
)
update public.paciente_profissional vinculo
   set autorizacao_status = 'revogado',
       autorizacao_revogada_em = coalesce(
         vinculo.autorizacao_revogada_em,
         now()
       ),
       atualizado_em = now()
  from vinculos_autorizados_ordenados ordenado
 where vinculo.id = ordenado.id
   and ordenado.ordem > 1;

create unique index if not exists iris_vinculo_autorizado_por_paciente_unique
  on public.paciente_profissional(paciente_id)
  where autorizacao_status = 'ativo';
create index if not exists iris_resgates_convite_paciente_idx
  on public.convites_vinculo_resgates(convite_id, paciente_id);

create or replace function public.iris_set_atualizado_em()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.atualizado_em = now();
  return new;
end;
$$;

revoke all on function public.iris_set_atualizado_em() from public;

do $$
declare
  tabela text;
begin
  foreach tabela in array array[
    'usuarios',
    'perfis',
    'pacientes',
    'profissionais',
    'paciente_profissional',
    'registros_alimentares',
    'registros_emocionais',
    'consultas',
    'anotacoes_clinicas',
    'planos_cuidado',
    'metas_cuidado',
    'medicacoes_plano'
  ]
  loop
    execute format(
      'drop trigger if exists iris_set_atualizado_em on public.%I',
      tabela
    );
    execute format(
      'create trigger iris_set_atualizado_em before update on public.%I '
      'for each row execute function public.iris_set_atualizado_em()',
      tabela
    );
  end loop;
end;
$$;

create or replace function public.iris_current_account_active()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.usuarios usuario
    where usuario.id = auth.uid()
      and usuario.ativo
  );
$$;

create or replace function public.iris_current_patient_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select paciente.id
  from public.pacientes paciente
  join public.usuarios usuario on usuario.id = paciente.user_id
  where paciente.user_id = auth.uid()
    and usuario.ativo
    and usuario.tipo_usuario = 'paciente'
  limit 1;
$$;

create or replace function public.iris_current_professional_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select profissional.id
  from public.profissionais profissional
  join public.usuarios usuario on usuario.id = profissional.user_id
  where profissional.user_id = auth.uid()
    and profissional.credenciamento_status = 'ativo'
    and usuario.ativo
    and usuario.tipo_usuario = 'profissional'
  limit 1;
$$;

create or replace function public.iris_professional_owns_link(p_vinculo_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.paciente_profissional vinculo
    where vinculo.id = p_vinculo_id
      and vinculo.profissional_id = public.iris_current_professional_id()
      and vinculo.autorizacao_status = 'ativo'
      and vinculo.status = 'ativo'
  );
$$;

-- Acesso administrativo ao vínculo (inclui acompanhamento inativo), sem
-- liberar prontuário ou registros clínicos enquanto ele estiver inativo.
create or replace function public.iris_professional_manages_link(
  p_vinculo_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.paciente_profissional vinculo
    where vinculo.id = p_vinculo_id
      and vinculo.profissional_id = public.iris_current_professional_id()
      and vinculo.autorizacao_status = 'ativo'
  );
$$;

create or replace function public.iris_patient_owns_link(p_vinculo_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.paciente_profissional vinculo
    where vinculo.id = p_vinculo_id
      and vinculo.paciente_id = public.iris_current_patient_id()
      and vinculo.autorizacao_status = 'ativo'
  );
$$;

revoke all on function public.iris_current_patient_id() from public;
revoke all on function public.iris_current_professional_id() from public;
revoke all on function public.iris_professional_owns_link(uuid) from public;
revoke all on function public.iris_professional_manages_link(uuid)
  from public;
revoke all on function public.iris_patient_owns_link(uuid) from public;
revoke all on function public.iris_current_account_active() from public;
grant execute on function public.iris_current_patient_id() to authenticated;
grant execute on function public.iris_current_professional_id() to authenticated;
grant execute on function public.iris_professional_owns_link(uuid) to authenticated;
grant execute on function public.iris_professional_manages_link(uuid)
  to authenticated;
grant execute on function public.iris_patient_owns_link(uuid) to authenticated;
grant execute on function public.iris_current_account_active()
  to authenticated;

create or replace function public.iris_bootstrap_current_user(
  p_display_name text default null,
  p_requested_type text default 'paciente',
  p_specialty text default null,
  p_registration text default null
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_email text := auth.jwt() ->> 'email';
  v_existing_type text;
  v_existing_active boolean;
  v_requested_type text;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  if v_email is null or btrim(v_email) = '' then
    raise exception 'EMAIL_REQUIRED';
  end if;

  v_requested_type := lower(btrim(coalesce(p_requested_type, '')));

  if v_requested_type not in ('paciente', 'profissional') then
    raise exception 'INVALID_ACCOUNT_TYPE';
  end if;

  insert into public.usuarios (
    id,
    email,
    senha_hash,
    tipo_usuario,
    ativo,
    atualizado_em
  )
  values (
    v_user_id,
    lower(btrim(v_email)),
    'managed_by_supabase_auth',
    v_requested_type,
    true,
    now()
  )
  on conflict (id) do update
    set email = excluded.email,
        atualizado_em = now()
  returning tipo_usuario, ativo
    into v_existing_type, v_existing_active;

  if not v_existing_active then
    raise exception 'ACCOUNT_INACTIVE';
  end if;

  insert into public.perfis (user_id, nome_social, nome_completo)
  values (
    v_user_id,
    nullif(btrim(p_display_name), ''),
    nullif(btrim(p_display_name), '')
  )
  on conflict (user_id) do update
    set nome_social = coalesce(
          nullif(btrim(excluded.nome_social), ''),
          public.perfis.nome_social
        ),
        nome_completo = coalesce(
          nullif(btrim(excluded.nome_completo), ''),
          public.perfis.nome_completo
        );

  if v_existing_type = 'profissional' then
    insert into public.profissionais (
      user_id,
      especialidade,
      registro_profissional,
      credenciamento_status
    )
    values (
      v_user_id,
      nullif(btrim(p_specialty), ''),
      nullif(btrim(p_registration), ''),
      'pendente'
    )
    on conflict (user_id) do nothing;
  else
    insert into public.pacientes (user_id)
    values (v_user_id)
    on conflict (user_id) do nothing;
  end if;

  return v_existing_type;
end;
$$;

revoke all on function public.iris_bootstrap_current_user(text, text, text, text)
  from public;
grant execute on function public.iris_bootstrap_current_user(text, text, text, text)
  to authenticated;

create or replace function public.iris_create_professional_invite(
  p_ttl_minutes integer default 30,
  p_max_uses integer default 1
)
returns table (
  invite_id uuid,
  token text,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, extensions, public
as $$
declare
  v_professional_id uuid := public.iris_current_professional_id();
  v_token text := encode(gen_random_bytes(32), 'hex');
  v_expires_at timestamptz;
  v_invite_id uuid;
begin
  if v_professional_id is null then
    raise exception 'PROFESSIONAL_NOT_APPROVED';
  end if;

  p_ttl_minutes := greatest(5, least(coalesce(p_ttl_minutes, 30), 1440));
  p_max_uses := greatest(1, least(coalesce(p_max_uses, 1), 100));
  v_expires_at := now() + make_interval(mins => p_ttl_minutes);

  insert into public.convites_vinculo_profissional (
    profissional_id,
    token_hash,
    expira_em,
    max_usos
  )
  values (
    v_professional_id,
    encode(digest(v_token, 'sha256'), 'hex'),
    v_expires_at,
    p_max_uses
  )
  returning id into v_invite_id;

  return query select v_invite_id, v_token, v_expires_at;
end;
$$;

create or replace function public.iris_preview_professional_invite(p_token text)
returns table (
  professional_id uuid,
  professional_name text,
  specialty text,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, extensions, public
as $$
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  if not public.iris_current_account_active() then
    raise exception 'ACCOUNT_INACTIVE';
  end if;

  if p_token is null or p_token !~ '^[0-9a-fA-F]{64}$' then
    raise exception 'INVALID_INVITE';
  end if;

  return query
  select
    profissional.id,
    coalesce(perfil.nome_social, perfil.nome_completo, 'Profissional'),
    profissional.especialidade,
    convite.expira_em
  from public.convites_vinculo_profissional convite
  join public.profissionais profissional
    on profissional.id = convite.profissional_id
  left join public.perfis perfil
    on perfil.user_id = profissional.user_id
  where convite.token_hash = encode(
          digest(lower(btrim(p_token)), 'sha256'),
          'hex'
        )
    and convite.revogado_em is null
    and convite.expira_em > now()
    and convite.usos < convite.max_usos
    and profissional.credenciamento_status = 'ativo'
  limit 1;

  if not found then
    raise exception 'INVALID_OR_EXPIRED_INVITE';
  end if;
end;
$$;

create or replace function public.iris_redeem_professional_invite(p_token text)
returns table (
  link_id uuid,
  professional_id uuid,
  professional_name text,
  specialty text
)
language plpgsql
security definer
set search_path = pg_catalog, extensions, public
as $$
declare
  v_patient_id uuid := public.iris_current_patient_id();
  v_invite public.convites_vinculo_profissional%rowtype;
  v_link_id uuid;
  v_new_redemption integer := 0;
begin
  if v_patient_id is null then
    raise exception 'PATIENT_REQUIRED';
  end if;

  if p_token is null or p_token !~ '^[0-9a-fA-F]{64}$' then
    raise exception 'INVALID_INVITE';
  end if;

  -- Serializa trocas de profissional para o mesmo paciente.
  perform 1
    from public.pacientes
   where id = v_patient_id
   for update;

  select convite.*
    into v_invite
    from public.convites_vinculo_profissional convite
    join public.profissionais profissional
      on profissional.id = convite.profissional_id
     and profissional.credenciamento_status = 'ativo'
   where convite.token_hash = encode(
           digest(lower(btrim(p_token)), 'sha256'),
           'hex'
         )
     and convite.revogado_em is null
     and convite.expira_em > now()
     and (
       convite.usos < convite.max_usos
       or exists (
         select 1
           from public.convites_vinculo_resgates resgate
          where resgate.convite_id = convite.id
            and resgate.paciente_id = v_patient_id
       )
     )
   for update of convite;

  if not found then
    raise exception 'INVALID_OR_EXPIRED_INVITE';
  end if;

  insert into public.convites_vinculo_resgates (convite_id, paciente_id)
  values (v_invite.id, v_patient_id)
  on conflict (convite_id, paciente_id) do nothing;
  get diagnostics v_new_redemption = row_count;

  if v_new_redemption = 1 then
    update public.paciente_profissional
       set status = 'inativo',
           autorizacao_status = 'revogado',
           autorizacao_revogada_em = now(),
           atualizado_em = now()
     where paciente_id = v_patient_id
       and profissional_id <> v_invite.profissional_id
       and autorizacao_status = 'ativo';

    insert into public.paciente_profissional (
      paciente_id,
      profissional_id,
      status,
      autorizacao_status,
      autorizacao_revogada_em
    )
    values (
      v_patient_id,
      v_invite.profissional_id,
      'ativo',
      'ativo',
      null
    )
    on conflict (paciente_id, profissional_id) do update
      set status = 'ativo',
          autorizacao_status = 'ativo',
          autorizacao_revogada_em = null,
          atualizado_em = now()
    returning id into v_link_id;

    update public.convites_vinculo_profissional
       set usos = usos + 1,
           ultimo_uso_em = now()
     where id = v_invite.id;
  else
    select id
      into v_link_id
      from public.paciente_profissional
     where paciente_id = v_patient_id
       and profissional_id = v_invite.profissional_id
       and autorizacao_status = 'ativo';

    if v_link_id is null then
      raise exception 'INVITE_ALREADY_USED';
    end if;
  end if;

  return query
  select
    v_link_id,
    profissional.id,
    coalesce(perfil.nome_social, perfil.nome_completo, 'Profissional'),
    profissional.especialidade
  from public.profissionais profissional
  left join public.perfis perfil
    on perfil.user_id = profissional.user_id
  where profissional.id = v_invite.profissional_id;
end;
$$;

create or replace function public.iris_revoke_professional_invite(
  p_invite_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_professional_id uuid := public.iris_current_professional_id();
begin
  if v_professional_id is null then
    raise exception 'PROFESSIONAL_NOT_APPROVED';
  end if;

  update public.convites_vinculo_profissional
     set revogado_em = now()
   where id = p_invite_id
     and profissional_id = v_professional_id
     and revogado_em is null;
end;
$$;

revoke all on function public.iris_create_professional_invite(integer, integer)
  from public;
revoke all on function public.iris_preview_professional_invite(text)
  from public;
revoke all on function public.iris_redeem_professional_invite(text)
  from public;
revoke all on function public.iris_revoke_professional_invite(uuid)
  from public;
grant execute on function public.iris_create_professional_invite(integer, integer)
  to authenticated;
grant execute on function public.iris_preview_professional_invite(text)
  to authenticated;
grant execute on function public.iris_redeem_professional_invite(text)
  to authenticated;
grant execute on function public.iris_revoke_professional_invite(uuid)
  to authenticated;

create or replace function public.iris_update_linked_patient(
  p_link_id uuid,
  p_diagnosis text,
  p_follow_up_status text,
  p_current_mood text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.iris_professional_manages_link(p_link_id) then
    raise exception 'LINK_ACCESS_DENIED';
  end if;

  if lower(btrim(coalesce(p_follow_up_status, '')))
      not in ('ativo', 'inativo') then
    raise exception 'INVALID_FOLLOW_UP_STATUS';
  end if;

  update public.paciente_profissional
     set diagnostico = nullif(btrim(p_diagnosis), ''),
         humor_atual = coalesce(
           nullif(btrim(p_current_mood), ''),
           humor_atual
         ),
         status = lower(btrim(p_follow_up_status)),
         atualizado_em = now()
   where id = p_link_id;
end;
$$;

revoke all on function public.iris_update_linked_patient(
  uuid,
  text,
  text,
  text
) from public;
grant execute on function public.iris_update_linked_patient(
  uuid,
  text,
  text,
  text
) to authenticated;

create or replace function public.iris_update_professional_settings(
  p_name text,
  p_phone text,
  p_specialty text,
  p_registration text,
  p_biography text,
  p_clinic text,
  p_clinic_address text,
  p_avatar_initials text,
  p_appointment_notifications boolean,
  p_crisis_alerts boolean,
  p_automatic_reports boolean
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_professional public.profissionais%rowtype;
  v_credentials_changed boolean;
begin
  select profissional.*
    into v_professional
    from public.profissionais profissional
    join public.usuarios usuario on usuario.id = profissional.user_id
   where profissional.user_id = v_user_id
     and usuario.ativo
     and usuario.tipo_usuario = 'profissional'
   for update of profissional;

  if not found then
    raise exception 'PROFESSIONAL_REQUIRED';
  end if;

  if btrim(coalesce(p_name, '')) = '' then
    raise exception 'NAME_REQUIRED';
  end if;

  v_credentials_changed :=
    nullif(btrim(p_specialty), '') is distinct from
      v_professional.especialidade
    or nullif(btrim(p_registration), '') is distinct from
      v_professional.registro_profissional;

  insert into public.perfis (
    user_id,
    nome_completo,
    nome_social,
    telefone,
    atualizado_em
  )
  values (
    v_user_id,
    btrim(p_name),
    btrim(p_name),
    nullif(btrim(p_phone), ''),
    now()
  )
  on conflict (user_id) do update
    set nome_completo = excluded.nome_completo,
        nome_social = excluded.nome_social,
        telefone = excluded.telefone,
        atualizado_em = now();

  update public.profissionais
     set especialidade = nullif(btrim(p_specialty), ''),
         registro_profissional = nullif(btrim(p_registration), ''),
         biografia = nullif(btrim(p_biography), ''),
         telefone = nullif(btrim(p_phone), ''),
         clinica = nullif(btrim(p_clinic), ''),
         endereco_clinica = nullif(btrim(p_clinic_address), ''),
         iniciais_avatar = upper(left(btrim(coalesce(p_avatar_initials, '')), 3)),
         notificacoes_consultas = coalesce(
           p_appointment_notifications,
           true
         ),
         alertas_crise = coalesce(p_crisis_alerts, true),
         relatorios_automaticos = coalesce(p_automatic_reports, false),
         credenciamento_status = case
           when v_credentials_changed then 'pendente'
           else v_professional.credenciamento_status
         end,
         atualizado_em = now()
   where id = v_professional.id
   returning credenciamento_status
     into v_professional.credenciamento_status;

  return v_professional.credenciamento_status;
end;
$$;

revoke all on function public.iris_update_professional_settings(
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  boolean,
  boolean,
  boolean
) from public;
grant execute on function public.iris_update_professional_settings(
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  boolean,
  boolean,
  boolean
) to authenticated;

create or replace function public.iris_set_professional_credential_status(
  p_professional_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if lower(btrim(coalesce(p_status, '')))
      not in ('pendente', 'ativo', 'rejeitado', 'suspenso') then
    raise exception 'INVALID_CREDENTIAL_STATUS';
  end if;

  update public.profissionais
     set credenciamento_status = lower(btrim(p_status)),
         atualizado_em = now()
   where id = p_professional_id;

  if not found then
    raise exception 'PROFESSIONAL_NOT_FOUND';
  end if;
end;
$$;

revoke all on function public.iris_set_professional_credential_status(
  uuid,
  text
) from public, anon, authenticated;
grant execute on function public.iris_set_professional_credential_status(
  uuid,
  text
) to service_role;

create or replace function public.iris_save_care_plan(
  p_vinculo_id uuid,
  p_orientation text,
  p_share_with_patient boolean,
  p_notify_missed_checkins boolean,
  p_crisis_steps text[],
  p_goals jsonb,
  p_medications jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_plan_id uuid;
begin
  if not public.iris_professional_owns_link(p_vinculo_id) then
    raise exception 'LINK_ACCESS_DENIED';
  end if;

  insert into public.planos_cuidado (
    vinculo_id,
    orientacoes,
    passos_crise,
    compartilhar_paciente,
    alertar_checkins_ausentes
  )
  values (
    p_vinculo_id,
    nullif(btrim(p_orientation), ''),
    coalesce(p_crisis_steps, '{}'),
    coalesce(p_share_with_patient, true),
    coalesce(p_notify_missed_checkins, true)
  )
  on conflict (vinculo_id) do update
    set orientacoes = excluded.orientacoes,
        passos_crise = excluded.passos_crise,
        compartilhar_paciente = excluded.compartilhar_paciente,
        alertar_checkins_ausentes = excluded.alertar_checkins_ausentes
  returning id into v_plan_id;

  delete from public.metas_cuidado where plano_id = v_plan_id;
  insert into public.metas_cuidado (plano_id, descricao, concluida, ordem)
  select
    v_plan_id,
    btrim(item.value ->> 'text'),
    coalesce((item.value ->> 'completed')::boolean, false),
    item.ordinality - 1
  from jsonb_array_elements(coalesce(p_goals, '[]'::jsonb))
    with ordinality as item(value, ordinality)
  where btrim(coalesce(item.value ->> 'text', '')) <> '';

  delete from public.medicacoes_plano where plano_id = v_plan_id;
  insert into public.medicacoes_plano (
    plano_id,
    nome,
    dose,
    frequencia,
    adesao,
    ordem
  )
  select
    v_plan_id,
    btrim(item.value ->> 'name'),
    btrim(item.value ->> 'dose'),
    btrim(item.value ->> 'frequency'),
    greatest(
      0,
      least(1, coalesce((item.value ->> 'adherence')::numeric, 1))
    ),
    item.ordinality - 1
  from jsonb_array_elements(coalesce(p_medications, '[]'::jsonb))
    with ordinality as item(value, ordinality)
  where btrim(coalesce(item.value ->> 'name', '')) <> ''
    and btrim(coalesce(item.value ->> 'dose', '')) <> ''
    and btrim(coalesce(item.value ->> 'frequency', '')) <> '';

  return v_plan_id;
end;
$$;

revoke all on function public.iris_save_care_plan(
  uuid,
  text,
  boolean,
  boolean,
  text[],
  jsonb,
  jsonb
) from public;
grant execute on function public.iris_save_care_plan(
  uuid,
  text,
  boolean,
  boolean,
  text[],
  jsonb,
  jsonb
) to authenticated;

alter table public.usuarios enable row level security;
alter table public.perfis enable row level security;
alter table public.pacientes enable row level security;
alter table public.profissionais enable row level security;
alter table public.paciente_profissional enable row level security;
alter table public.registros_alimentares enable row level security;
alter table public.registros_emocionais enable row level security;
alter table public.consultas enable row level security;
alter table public.anotacoes_clinicas enable row level security;
alter table public.planos_cuidado enable row level security;
alter table public.metas_cuidado enable row level security;
alter table public.medicacoes_plano enable row level security;
alter table public.convites_vinculo_profissional enable row level security;
alter table public.convites_vinculo_resgates enable row level security;

drop policy if exists iris_usuarios_insert_own on public.usuarios;
drop policy if exists iris_usuarios_update_own on public.usuarios;
drop policy if exists iris_profissionais_select_authenticated on public.profissionais;
drop policy if exists iris_profissionais_insert_own on public.profissionais;
drop policy if exists iris_paciente_profissional_insert_by_patient
  on public.paciente_profissional;
drop policy if exists iris_paciente_profissional_update_by_patient
  on public.paciente_profissional;
drop policy if exists iris_perfis_insert_own on public.perfis;
drop policy if exists iris_pacientes_insert_own on public.pacientes;

drop policy if exists iris_usuarios_select_own on public.usuarios;
create policy iris_usuarios_select_own
  on public.usuarios
  for select
  to authenticated
  using (id = auth.uid() and ativo);

drop policy if exists iris_perfis_select_own on public.perfis;
create policy iris_perfis_select_own
  on public.perfis
  for select
  to authenticated
  using (
    user_id = auth.uid()
    and public.iris_current_account_active()
  );

drop policy if exists iris_perfis_update_own on public.perfis;
create policy iris_perfis_update_own
  on public.perfis
  for update
  to authenticated
  using (
    user_id = auth.uid()
    and public.iris_current_account_active()
  )
  with check (
    user_id = auth.uid()
    and public.iris_current_account_active()
  );

drop policy if exists iris_pacientes_select_own on public.pacientes;
create policy iris_pacientes_select_own
  on public.pacientes
  for select
  to authenticated
  using (
    user_id = auth.uid()
    and public.iris_current_account_active()
  );

drop policy if exists iris_paciente_profissional_select_involved
  on public.paciente_profissional;
create policy iris_paciente_profissional_select_involved
  on public.paciente_profissional
  for select
  to authenticated
  using (
    public.iris_current_account_active()
    and (
      paciente_id = public.iris_current_patient_id()
      or (
        profissional_id = public.iris_current_professional_id()
        and autorizacao_status = 'ativo'
      )
    )
  );

drop policy if exists iris_usuarios_select_linked_professional
  on public.usuarios;
create policy iris_usuarios_select_linked_professional
  on public.usuarios
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.pacientes paciente
      join public.paciente_profissional vinculo
        on vinculo.paciente_id = paciente.id
      where paciente.user_id = usuarios.id
        and vinculo.profissional_id = public.iris_current_professional_id()
        and vinculo.autorizacao_status = 'ativo'
    )
  );

drop policy if exists iris_perfis_select_linked_professional on public.perfis;
create policy iris_perfis_select_linked_professional
  on public.perfis
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.pacientes paciente
      join public.paciente_profissional vinculo
        on vinculo.paciente_id = paciente.id
      where paciente.user_id = perfis.user_id
        and vinculo.profissional_id = public.iris_current_professional_id()
        and vinculo.autorizacao_status = 'ativo'
    )
  );

drop policy if exists iris_perfis_select_linked_patient on public.perfis;
create policy iris_perfis_select_linked_patient
  on public.perfis
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.profissionais profissional
      join public.paciente_profissional vinculo
        on vinculo.profissional_id = profissional.id
      where profissional.user_id = perfis.user_id
        and vinculo.paciente_id = public.iris_current_patient_id()
        and vinculo.autorizacao_status = 'ativo'
    )
  );

drop policy if exists iris_pacientes_select_linked_professional
  on public.pacientes;
create policy iris_pacientes_select_linked_professional
  on public.pacientes
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.paciente_profissional vinculo
      where vinculo.paciente_id = pacientes.id
        and vinculo.profissional_id = public.iris_current_professional_id()
        and vinculo.autorizacao_status = 'ativo'
    )
  );

drop policy if exists iris_profissionais_select_own on public.profissionais;
create policy iris_profissionais_select_own
  on public.profissionais
  for select
  to authenticated
  using (
    user_id = auth.uid()
    and public.iris_current_account_active()
  );

drop policy if exists iris_profissionais_select_linked_patient
  on public.profissionais;
create policy iris_profissionais_select_linked_patient
  on public.profissionais
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.paciente_profissional vinculo
      where vinculo.profissional_id = profissionais.id
        and vinculo.paciente_id = public.iris_current_patient_id()
        and vinculo.autorizacao_status = 'ativo'
    )
  );

drop policy if exists iris_registros_alimentares_patient_all
  on public.registros_alimentares;
create policy iris_registros_alimentares_patient_all
  on public.registros_alimentares
  for all
  to authenticated
  using (paciente_id = public.iris_current_patient_id())
  with check (paciente_id = public.iris_current_patient_id());

drop policy if exists iris_registros_alimentares_professional_select
  on public.registros_alimentares;
create policy iris_registros_alimentares_professional_select
  on public.registros_alimentares
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.paciente_profissional vinculo
      where vinculo.paciente_id = registros_alimentares.paciente_id
        and vinculo.profissional_id = public.iris_current_professional_id()
        and vinculo.autorizacao_status = 'ativo'
        and vinculo.status = 'ativo'
    )
  );

drop policy if exists iris_registros_emocionais_patient_all
  on public.registros_emocionais;
create policy iris_registros_emocionais_patient_all
  on public.registros_emocionais
  for all
  to authenticated
  using (paciente_id = public.iris_current_patient_id())
  with check (paciente_id = public.iris_current_patient_id());

drop policy if exists iris_registros_emocionais_professional_select
  on public.registros_emocionais;
create policy iris_registros_emocionais_professional_select
  on public.registros_emocionais
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.paciente_profissional vinculo
      where vinculo.paciente_id = registros_emocionais.paciente_id
        and vinculo.profissional_id = public.iris_current_professional_id()
        and vinculo.autorizacao_status = 'ativo'
        and vinculo.status = 'ativo'
    )
  );

drop policy if exists iris_consultas_involved_select on public.consultas;
create policy iris_consultas_involved_select
  on public.consultas
  for select
  to authenticated
  using (
    public.iris_professional_owns_link(vinculo_id)
    or public.iris_patient_owns_link(vinculo_id)
  );

drop policy if exists iris_consultas_professional_insert on public.consultas;
create policy iris_consultas_professional_insert
  on public.consultas
  for insert
  to authenticated
  with check (public.iris_professional_owns_link(vinculo_id));

drop policy if exists iris_consultas_professional_update on public.consultas;
create policy iris_consultas_professional_update
  on public.consultas
  for update
  to authenticated
  using (public.iris_professional_owns_link(vinculo_id))
  with check (public.iris_professional_owns_link(vinculo_id));

drop policy if exists iris_consultas_professional_delete on public.consultas;
create policy iris_consultas_professional_delete
  on public.consultas
  for delete
  to authenticated
  using (public.iris_professional_owns_link(vinculo_id));

drop policy if exists iris_anotacoes_professional_all on public.anotacoes_clinicas;
create policy iris_anotacoes_professional_all
  on public.anotacoes_clinicas
  for all
  to authenticated
  using (
    profissional_id = public.iris_current_professional_id()
    and public.iris_professional_owns_link(vinculo_id)
  )
  with check (
    profissional_id = public.iris_current_professional_id()
    and public.iris_professional_owns_link(vinculo_id)
  );

drop policy if exists iris_planos_professional_all on public.planos_cuidado;
create policy iris_planos_professional_all
  on public.planos_cuidado
  for all
  to authenticated
  using (public.iris_professional_owns_link(vinculo_id))
  with check (public.iris_professional_owns_link(vinculo_id));

drop policy if exists iris_planos_patient_select on public.planos_cuidado;
create policy iris_planos_patient_select
  on public.planos_cuidado
  for select
  to authenticated
  using (
    compartilhar_paciente
    and public.iris_patient_owns_link(vinculo_id)
  );

drop policy if exists iris_metas_involved_select on public.metas_cuidado;
create policy iris_metas_involved_select
  on public.metas_cuidado
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.planos_cuidado plano
      where plano.id = metas_cuidado.plano_id
        and (
          public.iris_professional_owns_link(plano.vinculo_id)
          or (
            plano.compartilhar_paciente
            and public.iris_patient_owns_link(plano.vinculo_id)
          )
        )
    )
  );

drop policy if exists iris_metas_professional_all on public.metas_cuidado;
create policy iris_metas_professional_all
  on public.metas_cuidado
  for all
  to authenticated
  using (
    exists (
      select 1
      from public.planos_cuidado plano
      where plano.id = metas_cuidado.plano_id
        and public.iris_professional_owns_link(plano.vinculo_id)
    )
  )
  with check (
    exists (
      select 1
      from public.planos_cuidado plano
      where plano.id = metas_cuidado.plano_id
        and public.iris_professional_owns_link(plano.vinculo_id)
    )
  );

drop policy if exists iris_medicacoes_involved_select on public.medicacoes_plano;
create policy iris_medicacoes_involved_select
  on public.medicacoes_plano
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.planos_cuidado plano
      where plano.id = medicacoes_plano.plano_id
        and (
          public.iris_professional_owns_link(plano.vinculo_id)
          or (
            plano.compartilhar_paciente
            and public.iris_patient_owns_link(plano.vinculo_id)
          )
        )
    )
  );

drop policy if exists iris_medicacoes_professional_all
  on public.medicacoes_plano;
create policy iris_medicacoes_professional_all
  on public.medicacoes_plano
  for all
  to authenticated
  using (
    exists (
      select 1
      from public.planos_cuidado plano
      where plano.id = medicacoes_plano.plano_id
        and public.iris_professional_owns_link(plano.vinculo_id)
    )
  )
  with check (
    exists (
      select 1
      from public.planos_cuidado plano
      where plano.id = medicacoes_plano.plano_id
        and public.iris_professional_owns_link(plano.vinculo_id)
    )
  );

revoke insert, update, delete on public.usuarios from authenticated;
revoke insert, delete on public.perfis from authenticated;
revoke update on public.perfis from authenticated;
grant update (nome_completo, nome_social, telefone, data_nascimento)
  on public.perfis to authenticated;
revoke insert, update, delete on public.pacientes from authenticated;
revoke insert, delete on public.profissionais from authenticated;
revoke update on public.profissionais from authenticated;
revoke insert, update, delete on public.paciente_profissional from authenticated;
revoke all on public.convites_vinculo_profissional from anon, authenticated;
revoke all on public.convites_vinculo_resgates from anon, authenticated;

grant select on public.usuarios to authenticated;
grant select on public.perfis to authenticated;
grant select on public.pacientes to authenticated;
grant select on public.profissionais to authenticated;
grant select on public.paciente_profissional to authenticated;
grant select, insert, update, delete on public.registros_alimentares
  to authenticated;
grant select, insert, update, delete on public.registros_emocionais
  to authenticated;
grant select on public.consultas to authenticated;
grant insert, update, delete on public.consultas to authenticated;
grant select, insert, update, delete on public.anotacoes_clinicas to authenticated;
grant select on public.planos_cuidado to authenticated;
grant select on public.metas_cuidado to authenticated;
grant select on public.medicacoes_plano to authenticated;

-- Garante que as novas tabelas e RPCs fiquem disponíveis imediatamente na
-- API REST depois da execução pelo SQL Editor ou pela CLI.
notify pgrst, 'reload schema';
