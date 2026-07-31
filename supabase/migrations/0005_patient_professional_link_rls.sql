-- Vinculo paciente-profissional: policies RLS necessarias para o fluxo do app Iris.
-- Aplique depois de 0001_core_schema.sql e antes de
-- 0006_professional_backend.sql.

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

drop policy if exists iris_usuarios_update_own on public.usuarios;

drop policy if exists iris_perfis_select_own on public.perfis;
create policy iris_perfis_select_own
  on public.perfis
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists iris_perfis_insert_own on public.perfis;

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

drop policy if exists iris_profissionais_select_authenticated on public.profissionais;
drop policy if exists iris_profissionais_select_own on public.profissionais;
create policy iris_profissionais_select_own
  on public.profissionais
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists iris_profissionais_insert_own on public.profissionais;

drop policy if exists iris_profissionais_update_own on public.profissionais;

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

drop policy if exists iris_paciente_profissional_update_by_patient on public.paciente_profissional;

-- Criação de perfis/papéis e vínculos ocorre somente nas funções
-- SECURITY DEFINER da migration 0006. Nenhuma tabela sensível aceita
-- INSERT/UPDATE direto do cliente durante a aplicação das migrations.
revoke insert, update, delete on public.usuarios from authenticated;
revoke insert, update, delete on public.perfis from authenticated;
revoke insert, update, delete on public.pacientes from authenticated;
revoke insert, update, delete on public.profissionais from authenticated;
revoke insert, update, delete on public.paciente_profissional
  from authenticated;
