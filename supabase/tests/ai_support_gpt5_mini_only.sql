do $$
declare
  development public.rollout_ia_apoio%rowtype;
  production public.rollout_ia_apoio%rowtype;
begin
  if not exists (
    select 1
      from pg_constraint
     where conrelid = 'public.sugestoes_ia_apoio'::regclass
       and conname = 'iris_sugestoes_ia_modelo_unico'
  ) then
    raise exception 'constraint de origem exclusiva OpenAI ausente';
  end if;

  select * into strict development
    from public.rollout_ia_apoio
   where ambiente = 'development';

  if development.modo <> 'limited'
     or not development.openai_ativa
     or development.kill_switch
     or development.percentual_entrega <> 100
     or development.modelo <> 'gpt-5-mini' then
    raise exception 'desenvolvimento nao esta configurado para GPT-5 mini exclusivo';
  end if;

  select * into strict production
    from public.rollout_ia_apoio
   where ambiente = 'production';

  if production.modo <> 'limited'
     or production.openai_ativa
     or not production.kill_switch
     or production.percentual_entrega <> 0
     or production.modelo <> 'gpt-5-mini' then
    raise exception 'producao deve permanecer fechada ate ativacao explicita';
  end if;
end;
$$;
