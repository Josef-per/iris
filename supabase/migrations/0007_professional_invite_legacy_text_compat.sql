-- Corrige as RPCs de convite em bancos criados pelo schema legado do Iris.
-- Nesse schema, perfis.nome_social e perfis.nome_completo sao varchar(255).
-- PL/pgSQL exige que RETURN QUERY corresponda exatamente ao RETURNS TABLE;
-- por isso os valores sao convertidos explicitamente para text.

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
    coalesce(
      perfil.nome_social,
      perfil.nome_completo,
      'Profissional'
    )::text,
    profissional.especialidade::text,
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
    coalesce(
      perfil.nome_social,
      perfil.nome_completo,
      'Profissional'
    )::text,
    profissional.especialidade::text
  from public.profissionais profissional
  left join public.perfis perfil
    on perfil.user_id = profissional.user_id
  where profissional.id = v_invite.profissional_id;
end;
$$;

revoke all on function public.iris_preview_professional_invite(text)
  from public;
revoke all on function public.iris_redeem_professional_invite(text)
  from public;
grant execute on function public.iris_preview_professional_invite(text)
  to authenticated;
grant execute on function public.iris_redeem_professional_invite(text)
  to authenticated;

notify pgrst, 'reload schema';
