-- Temporário: novos cadastros de paciente aprovam o Lucas sem convite QR.
-- Não altera cadastros existentes, convites ou vínculos já estabelecidos.
begin;

create table if not exists public.cadastros_paciente_demo (
  paciente_id uuid primary key references public.pacientes(id) on delete cascade,
  criado_em timestamptz not null default now()
);
alter table public.cadastros_paciente_demo enable row level security;
revoke all on public.cadastros_paciente_demo from public, anon, authenticated;

create or replace function public.iris_mark_demo_patient_registration()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if exists (
    select 1 from auth.users usuario
    where usuario.id = new.user_id
      and usuario.raw_user_meta_data -> 'demo_professional_link' = 'true'::jsonb
      and usuario.raw_user_meta_data ->> 'tipo_usuario' = 'paciente'
  ) then
    insert into public.cadastros_paciente_demo (paciente_id)
    values (new.id) on conflict do nothing;
  end if;
  return new;
end;
$$;
revoke all on function public.iris_mark_demo_patient_registration()
  from public, anon, authenticated;

drop trigger if exists iris_demo_patient_registration on public.pacientes;
create trigger iris_demo_patient_registration
after insert on public.pacientes
for each row execute function public.iris_mark_demo_patient_registration();

create or replace function public.iris_approve_demo_professional_link()
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_patient_id uuid := public.iris_current_patient_id();
  v_professional_id uuid;
  v_link public.paciente_profissional%rowtype;
begin
  if v_patient_id is null then
    raise exception 'PATIENT_REQUIRED';
  end if;
  if not exists (
    select 1 from public.cadastros_paciente_demo
    where paciente_id = v_patient_id
  ) then
    raise exception 'DEMO_REGISTRATION_REQUIRED';
  end if;

  -- Mesmo bloqueio usado pelo resgate de QR: serializa vínculos por paciente.
  perform 1 from public.pacientes where id = v_patient_id for update;

  -- O cliente não pode escolher o profissional nem precisa conhecer seu ID.
  select profissional.id into v_professional_id
  from public.profissionais profissional
  join public.usuarios usuario on usuario.id = profissional.user_id
  where lower(btrim(usuario.email)) = 'lucas@gmail.com'
    and usuario.tipo_usuario = 'profissional'
    and usuario.ativo
    and profissional.credenciamento_status = 'ativo';
  if v_professional_id is null then
    raise exception 'DEMO_PROFESSIONAL_UNAVAILABLE';
  end if;

  if exists (
    select 1 from public.paciente_profissional
    where paciente_id = v_patient_id
      and profissional_id <> v_professional_id
      and autorizacao_status = 'ativo'
  ) then
    raise exception 'DEMO_LINK_ALREADY_EXISTS';
  end if;

  select * into v_link from public.paciente_profissional
  where paciente_id = v_patient_id and profissional_id = v_professional_id;
  if found then
    if v_link.autorizacao_status = 'ativo' then
      return v_link.id;
    end if;
    -- Não reativa autorização revogada ou vínculo inativo.
    raise exception 'DEMO_LINK_ALREADY_EXISTS';
  end if;

  insert into public.paciente_profissional (
    paciente_id, profissional_id, status, autorizacao_status
  ) values (v_patient_id, v_professional_id, 'ativo', 'ativo')
  returning * into v_link;
  return v_link.id;
end;
$$;
revoke all on function public.iris_approve_demo_professional_link()
  from public, anon, authenticated;
grant execute on function public.iris_approve_demo_professional_link()
  to authenticated;

notify pgrst, 'reload schema';

commit;
