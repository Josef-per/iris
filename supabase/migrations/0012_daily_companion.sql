-- Reflexao diaria opcional baseada apenas nas fontes que a pessoa autorizou.
-- O texto do diario nunca e copiado para esta tabela, para logs ou para o
-- cliente: ele e lido pela Edge Function autenticada somente quando o
-- consentimento `diary_text` estiver ativo.

alter table public.preferencias_ia_apoio
  drop constraint if exists iris_ia_fontes_validas;
alter table public.preferencias_ia_apoio
  add constraint iris_ia_fontes_validas check (
    fontes_consentidas <@ array[
      'mood_history',
      'diary_topics',
      'diary_text',
      'exercise_feedback',
      'notification_interactions'
    ]::text[]
  );

-- O texto generativo tem um gate proprio. Desenvolvimento acompanha o
-- ambiente de teste ja habilitado para o GPT-5 mini; staging e producao
-- permanecem desligados ate uma liberacao consciente.
alter table public.rollout_ia_apoio
  add column if not exists mensagem_diaria_ativa boolean not null default false;
update public.rollout_ia_apoio
   set mensagem_diaria_ativa = ambiente = 'development',
       atualizado_em = now();

create table if not exists public.mensagens_diarias_ia (
  id uuid primary key default extensions.gen_random_uuid(),
  paciente_id uuid not null
    references public.pacientes(id) on delete cascade,
  registro_emocional_id uuid
    references public.registros_emocionais(id) on delete set null,
  data_local date not null,
  titulo text not null,
  mensagem text not null,
  pergunta_reflexao text,
  origem text not null default 'openai',
  modelo text,
  fontes_usadas text[] not null default '{}'::text[],
  gerada_em timestamptz not null default now(),
  expira_em timestamptz not null,
  constraint iris_mensagem_diaria_origem_valida check (
    origem in ('openai')
  ),
  constraint iris_mensagem_diaria_titulo_valido check (
    char_length(btrim(titulo)) between 3 and 80
  ),
  constraint iris_mensagem_diaria_texto_valido check (
    char_length(btrim(mensagem)) between 20 and 480
  ),
  constraint iris_mensagem_diaria_pergunta_valida check (
    pergunta_reflexao is null
    or char_length(btrim(pergunta_reflexao)) between 8 and 240
  ),
  constraint iris_mensagem_diaria_fontes_validas check (
    fontes_usadas <@ array[
      'mood_history',
      'diary_topics',
      'diary_text'
    ]::text[]
  ),
  constraint iris_mensagem_diaria_expiracao_valida check (
    expira_em > gerada_em
  ),
  unique (paciente_id, data_local)
);

create index if not exists iris_mensagens_diarias_ia_paciente_dia_idx
  on public.mensagens_diarias_ia(paciente_id, data_local desc);

alter table public.mensagens_diarias_ia enable row level security;

drop policy if exists iris_mensagem_diaria_patient_select
  on public.mensagens_diarias_ia;
create policy iris_mensagem_diaria_patient_select
  on public.mensagens_diarias_ia
  for select
  to authenticated
  using (
    paciente_id = public.iris_current_patient_id()
    and expira_em > now()
  );

-- Se a pessoa editar ou apagar o texto do diario, a mensagem dele derivada
-- desaparece antes de uma nova leitura. Isso evita mostrar uma reflexao sobre
-- algo que ela escolheu remover.
create or replace function public.iris_invalidar_mensagem_diaria_ao_mudar_diario()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if old.diario_emocional is distinct from new.diario_emocional then
    delete from public.mensagens_diarias_ia
     where paciente_id = new.paciente_id
       and data_local = new.data_local;
  end if;
  return new;
end;
$$;

drop trigger if exists iris_invalidar_mensagem_diaria_ao_mudar_diario
  on public.registros_emocionais;
create trigger iris_invalidar_mensagem_diaria_ao_mudar_diario
  after update of diario_emocional on public.registros_emocionais
  for each row execute function public.iris_invalidar_mensagem_diaria_ao_mudar_diario();

-- Retirar qualquer fonte usada pela reflexao tambem elimina os textos ja
-- derivados dela. A pessoa pode voltar a ativar uma fonte quando quiser.
create or replace function public.iris_apagar_mensagens_ao_revogar_fonte_diaria()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if (
       old.fontes_consentidas @> array['mood_history']::text[]
       and not (new.fontes_consentidas @> array['mood_history']::text[])
     )
     or (
       old.fontes_consentidas @> array['diary_topics']::text[]
       and not (new.fontes_consentidas @> array['diary_topics']::text[])
     )
     or (
       old.fontes_consentidas @> array['diary_text']::text[]
       and not (new.fontes_consentidas @> array['diary_text']::text[])
     ) then
    delete from public.mensagens_diarias_ia
     where paciente_id = new.paciente_id;
  end if;
  return new;
end;
$$;

drop trigger if exists iris_apagar_mensagens_ao_revogar_fonte_diaria
  on public.preferencias_ia_apoio;
create trigger iris_apagar_mensagens_ao_revogar_fonte_diaria
  after update of fontes_consentidas on public.preferencias_ia_apoio
  for each row execute function public.iris_apagar_mensagens_ao_revogar_fonte_diaria();

-- Inclui as reflexoes diarias no mesmo direito de retirada das sugestoes.
create or replace function public.iris_apagar_dados_ia_apoio()
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_patient_id uuid := public.iris_current_patient_id();
begin
  if v_patient_id is null then
    raise exception 'PATIENT_REQUIRED';
  end if;

  delete from public.mensagens_diarias_ia
   where paciente_id = v_patient_id;
  delete from public.eventos_ia_apoio
   where paciente_id = v_patient_id;
  delete from public.sugestoes_ia_apoio
   where paciente_id = v_patient_id;
  delete from public.topicos_apoio
   where paciente_id = v_patient_id;
  delete from public.preferencias_ia_apoio
   where paciente_id = v_patient_id;
  delete from public.participantes_piloto_ia_apoio
   where paciente_id = v_patient_id;
end;
$$;

revoke all on table public.mensagens_diarias_ia
  from public, anon, authenticated;
grant select on public.mensagens_diarias_ia to authenticated;
grant all on table public.mensagens_diarias_ia to service_role;

notify pgrst, 'reload schema';
