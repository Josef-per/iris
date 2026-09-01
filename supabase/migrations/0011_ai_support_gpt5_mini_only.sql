-- O modo conectado de Sugestoes de apoio usa exclusivamente o GPT-5 mini.
-- Regras deterministicas permanecem apenas no demonstrador Flutter e nunca
-- geram uma sugestao persistida ou visivel para um paciente conectado.

alter table public.rollout_ia_apoio
  alter column modo set default 'limited',
  alter column modelo set default 'gpt-5-mini';

-- Registros historicos produzidos pelo prototipo podem continuar no banco,
-- mas toda nova decisao conectada precisa declarar origem OpenAI.
alter table public.sugestoes_ia_apoio
  drop constraint if exists iris_sugestoes_ia_modelo_unico;
alter table public.sugestoes_ia_apoio
  add constraint iris_sugestoes_ia_modelo_unico
  check (origem = 'openai') not valid;

-- Desenvolvimento local fica pronto para usar a OPENAI_API_KEY fornecida ao
-- processo da Edge Function. Staging e producao continuam fechados ate que
-- seus secrets e gates externos sejam configurados explicitamente.
update public.rollout_ia_apoio
   set modo = 'limited',
       openai_ativa = ambiente = 'development',
       kill_switch = ambiente <> 'development',
       percentual_shadow = 0,
       percentual_entrega = case
         when ambiente = 'development' then 100
         else 0
       end,
       modelo = 'gpt-5-mini',
       atualizado_em = now();

notify pgrst, 'reload schema';
