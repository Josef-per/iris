-- Vinculo paciente-profissional: policies RLS necessarias para o fluxo do app Iris.
-- Aplique no SQL Editor do Supabase apos as migrations base (0001-0004).

alter table public.usuarios enable row level security;
alter table public.perfis enable row level security;
alter table public.pacientes enable row level security;
alter table public.profissionais enable row level security;
alter table public.paciente_profissional enable row level security;

drop policy if exists iris_usuarios_select_own on public.usuarios;
create policy iris_usuarios_select_own
  on public.usuarios
  for select
  to authenticated
  using (id = auth.uid());

drop policy if exists iris_usuarios_insert_own on public.usuarios;
create policy iris_usuarios_insert_own
  on public.usuarios
  for insert
  to authenticated
  with check (id = auth.uid());

drop policy if exists iris_usuarios_update_own on public.usuarios;
create policy iris_usuarios_update_own
  on public.usuarios
  for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

drop policy if exists iris_perfis_select_own on public.perfis;
create policy iris_perfis_select_own
  on public.perfis
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists iris_perfis_insert_own on public.perfis;
create policy iris_perfis_insert_own
  on public.perfis
  for insert
  to authenticated
  with check (user_id = auth.uid());

drop policy if exists iris_perfis_update_own on public.perfis;
create policy iris_perfis_update_own
  on public.perfis
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists iris_pacientes_select_own on public.pacientes;
create policy iris_pacientes_select_own
  on public.pacientes
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists iris_pacientes_insert_own on public.pacientes;
create policy iris_pacientes_insert_own
  on public.pacientes
  for insert
  to authenticated
  with check (user_id = auth.uid());

drop policy if exists iris_profissionais_select_authenticated on public.profissionais;
create policy iris_profissionais_select_authenticated
  on public.profissionais
  for select
  to authenticated
  using (true);

drop policy if exists iris_profissionais_insert_own on public.profissionais;
create policy iris_profissionais_insert_own
  on public.profissionais
  for insert
  to authenticated
  with check (user_id = auth.uid());

drop policy if exists iris_profissionais_update_own on public.profissionais;
create policy iris_profissionais_update_own
  on public.profissionais
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists iris_paciente_profissional_select_involved on public.paciente_profissional;
create policy iris_paciente_profissional_select_involved
  on public.paciente_profissional
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.pacientes p
      where p.id = paciente_profissional.paciente_id
        and p.user_id = auth.uid()
    )
    or exists (
      select 1
      from public.profissionais pr
      where pr.id = paciente_profissional.profissional_id
        and pr.user_id = auth.uid()
    )
  );

drop policy if exists iris_paciente_profissional_insert_by_patient on public.paciente_profissional;
create policy iris_paciente_profissional_insert_by_patient
  on public.paciente_profissional
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.pacientes p
      where p.id = paciente_profissional.paciente_id
        and p.user_id = auth.uid()
    )
    and exists (
      select 1
      from public.profissionais pr
      where pr.id = paciente_profissional.profissional_id
    )
  );

drop policy if exists iris_paciente_profissional_update_by_patient on public.paciente_profissional;
create policy iris_paciente_profissional_update_by_patient
  on public.paciente_profissional
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.pacientes p
      where p.id = paciente_profissional.paciente_id
        and p.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from public.pacientes p
      where p.id = paciente_profissional.paciente_id
        and p.user_id = auth.uid()
    )
  );
