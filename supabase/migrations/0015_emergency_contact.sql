-- Um contato escolhido pelo paciente, acessível somente à própria conta.
create table if not exists public.contatos_emergencia (
  paciente_id uuid primary key references public.pacientes(id) on delete cascade,
  nome text not null check (char_length(btrim(nome)) between 1 and 100),
  telefone text not null check (telefone ~ '^\+?[0-9]{8,15}$'),
  atualizado_em timestamptz not null default now()
);

alter table public.contatos_emergencia enable row level security;

drop policy if exists iris_contatos_emergencia_paciente
  on public.contatos_emergencia;
create policy iris_contatos_emergencia_paciente
  on public.contatos_emergencia
  for all to authenticated
  using (paciente_id = public.iris_current_patient_id())
  with check (paciente_id = public.iris_current_patient_id());

grant select, insert, update, delete on public.contatos_emergencia to authenticated;
