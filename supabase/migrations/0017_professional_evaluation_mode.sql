-- Liberação automática durante a avaliação da plataforma.
-- A opção é administrativa e não altera autorizações de pacientes.
begin;

create table if not exists public.configuracao_avaliacao_profissional (
  id boolean primary key default true check (id),
  habilitado boolean not null default false
);

alter table public.configuracao_avaliacao_profissional enable row level security;
revoke all on public.configuracao_avaliacao_profissional
  from public, anon, authenticated;
grant select, update on public.configuracao_avaliacao_profissional
  to service_role;

-- Ativa o piloto na primeira aplicação, sem reativá-lo ao reaplicar a migration.
insert into public.configuracao_avaliacao_profissional (id, habilitado)
values (true, true)
on conflict (id) do nothing;

create or replace function public.iris_apply_professional_evaluation_mode()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if new.credenciamento_status <> 'pendente' or not coalesce((
    select habilitado
    from public.configuracao_avaliacao_profissional
    where id = true
  ), false) then
    return new;
  end if;

  if tg_op = 'INSERT' then
    new.credenciamento_status := 'ativo';
  elsif old.credenciamento_status = 'ativo' and (
    new.especialidade is distinct from old.especialidade
    or new.registro_profissional is distinct from old.registro_profissional
  ) then
    -- Editar as credenciais no piloto não deve bloquear novamente o painel.
    -- Alterações administrativas somente do status continuam sendo respeitadas.
    new.credenciamento_status := 'ativo';
  end if;

  return new;
end;
$$;

revoke all on function public.iris_apply_professional_evaluation_mode()
  from public, anon, authenticated;

drop trigger if exists iris_professional_evaluation_mode on public.profissionais;
create trigger iris_professional_evaluation_mode
before insert or update of especialidade, registro_profissional
on public.profissionais
for each row execute function public.iris_apply_professional_evaluation_mode();

notify pgrst, 'reload schema';
commit;
