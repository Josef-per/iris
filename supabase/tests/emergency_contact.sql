do $$
begin
  if not exists (
    select 1
    from pg_class
    where oid = 'public.contatos_emergencia'::regclass
      and relrowsecurity
  ) then
    raise exception 'RLS ausente em contatos_emergencia';
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'contatos_emergencia'
      and policyname = 'iris_contatos_emergencia_paciente'
      and cmd = 'ALL'
      and 'authenticated' = any(roles)
  ) then
    raise exception 'Policy do paciente ausente em contatos_emergencia';
  end if;

  if has_table_privilege('anon', 'public.contatos_emergencia', 'SELECT') then
    raise exception 'Contatos de emergencia expostos ao papel anon';
  end if;
end;
$$;
