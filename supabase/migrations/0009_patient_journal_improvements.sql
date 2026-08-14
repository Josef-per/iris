-- Melhorias no diario do paciente.
--
-- Esta migration:
--   * classifica refeicoes por tipo estavel (cafe da manha, almoco, jantar,
--     lanche) mantendo compatibilidade com registros legados sem tipo;
--   * persiste lembretes de refeicoes e medicamentos por paciente, com RLS;
--   * permite limpar explicitamente o diario emocional do dia no upsert
--     diario, sem renovar scores, sintomas nem alertas do check-in.

alter table public.registros_alimentares
  add column if not exists tipo_refeicao text;

update public.registros_alimentares
   set tipo_refeicao = null
 where tipo_refeicao = '';

do $$
begin
  if not exists (
    select 1
      from pg_constraint
     where conrelid = 'public.registros_alimentares'::regclass
       and conname = 'iris_alimentares_tipo_valido'
  ) then
    alter table public.registros_alimentares
      add constraint iris_alimentares_tipo_valido
      check (
        tipo_refeicao is null
        or tipo_refeicao in ('cafe_da_manha', 'almoco', 'jantar', 'lanche')
      );
  end if;
end;
$$;

create table if not exists public.lembretes (
  id uuid primary key default gen_random_uuid(),
  paciente_id uuid not null references public.pacientes(id) on delete cascade,
  tipo text not null default 'refeicao',
  titulo text not null,
  horario time not null,
  ativo boolean not null default true,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);

alter table public.lembretes
  add column if not exists paciente_id uuid,
  add column if not exists tipo text default 'refeicao',
  add column if not exists titulo text,
  add column if not exists horario time,
  add column if not exists ativo boolean default true,
  add column if not exists criado_em timestamptz default now(),
  add column if not exists atualizado_em timestamptz default now();

update public.lembretes
   set ativo = true
 where ativo is null;

create index if not exists iris_lembretes_paciente_idx
  on public.lembretes(paciente_id);

do $$
begin
  if not exists (
    select 1
      from pg_constraint
     where conrelid = 'public.lembretes'::regclass
       and conname = 'iris_lembretes_tipo_valido'
  ) then
    alter table public.lembretes
      add constraint iris_lembretes_tipo_valido
      check (tipo in ('refeicao', 'medicamento'));
  end if;

  if not exists (
    select 1
      from pg_constraint
     where conrelid = 'public.lembretes'::regclass
       and conname = 'iris_lembretes_titulo_valido'
  ) then
    alter table public.lembretes
      add constraint iris_lembretes_titulo_valido
      check (btrim(titulo) <> '');
  end if;
end;
$$;

alter table public.lembretes enable row level security;

drop policy if exists iris_lembretes_patient_all
  on public.lembretes;
create policy iris_lembretes_patient_all
  on public.lembretes
  for all
  to authenticated
  using (paciente_id = public.iris_current_patient_id())
  with check (paciente_id = public.iris_current_patient_id());

grant select, insert, update, delete on public.lembretes
  to authenticated;

-- Limpar o diario e uma alteracao somente do texto: nao deve renovar o
-- instante da avaliacao clinica nem os alertas derivados dele.
create or replace function public.iris_upsert_daily_emotional_record(
  p_data_local date,
  p_fuso_horario text,
  p_diario_emocional text default null,
  p_humor text default null,
  p_como_sentiu integer default null,
  p_avaliacao_alimentacao integer default null,
  p_sintomas_emocionais_hoje text[] default null,
  p_sintomas_fisicos_hoje text[] default null,
  p_limpar_diario boolean default false
)
returns public.registros_emocionais
language plpgsql
security definer
set search_path = public
as $$
declare
  v_patient_id uuid := public.iris_current_patient_id();
  v_result public.registros_emocionais%rowtype;
begin
  if v_patient_id is null then
    raise exception 'PATIENT_REQUIRED';
  end if;

  if p_data_local is null
      or p_data_local < current_date - 1
      or p_data_local > current_date + 1 then
    raise exception 'INVALID_LOCAL_DATE';
  end if;

  if btrim(coalesce(p_fuso_horario, '')) = ''
      or length(p_fuso_horario) > 64 then
    raise exception 'INVALID_TIME_ZONE';
  end if;

  if p_como_sentiu is not null and p_como_sentiu not between 1 and 5 then
    raise exception 'INVALID_MOOD_SCORE';
  end if;

  if p_avaliacao_alimentacao is not null
      and p_avaliacao_alimentacao not between 1 and 5 then
    raise exception 'INVALID_FOOD_SCORE';
  end if;

  insert into public.registros_emocionais (
    paciente_id,
    data_registro,
    data_local,
    fuso_horario,
    diario_emocional,
    humor,
    como_sentiu,
    avaliacao_alimentacao,
    sintomas_emocionais_hoje,
    sintomas_fisicos_hoje
  )
  values (
    v_patient_id,
    now(),
    p_data_local,
    btrim(p_fuso_horario),
    case
      when p_limpar_diario then null
      else nullif(btrim(p_diario_emocional), '')
    end,
    nullif(btrim(p_humor), ''),
    p_como_sentiu,
    p_avaliacao_alimentacao,
    coalesce(p_sintomas_emocionais_hoje, '{}'::text[]),
    coalesce(p_sintomas_fisicos_hoje, '{}'::text[])
  )
  on conflict (paciente_id, data_local) do update
    set data_registro = case
          -- data_registro representa o instante da avaliacao clinica. Editar
          -- ou limpar apenas o diario nao deve renovar scores/sintomas nem
          -- seus alertas.
          when nullif(btrim(p_humor), '') is not null
            or p_como_sentiu is not null
            or p_avaliacao_alimentacao is not null
            or p_sintomas_emocionais_hoje is not null
            or p_sintomas_fisicos_hoje is not null
            then now()
          else registros_emocionais.data_registro
        end,
        fuso_horario = excluded.fuso_horario,
        diario_emocional = case
          when p_limpar_diario
            then null
          else coalesce(
            excluded.diario_emocional,
            registros_emocionais.diario_emocional
          )
        end,
        humor = coalesce(excluded.humor, registros_emocionais.humor),
        como_sentiu = coalesce(
          excluded.como_sentiu,
          registros_emocionais.como_sentiu
        ),
        avaliacao_alimentacao = coalesce(
          excluded.avaliacao_alimentacao,
          registros_emocionais.avaliacao_alimentacao
        ),
        sintomas_emocionais_hoje = case
          when p_sintomas_emocionais_hoje is null
            then registros_emocionais.sintomas_emocionais_hoje
          else excluded.sintomas_emocionais_hoje
        end,
        sintomas_fisicos_hoje = case
          when p_sintomas_fisicos_hoje is null
            then registros_emocionais.sintomas_fisicos_hoje
          else excluded.sintomas_fisicos_hoje
        end
  returning * into v_result;

  return v_result;
end;
$$;

-- A assinatura antiga (sem p_limpar_diario) e substituida pela nova. Clientes
-- antigos que ainda a chamem passam a receber PGRST202 ate serem atualizados,
-- evitando uma sobrecarga com semantica divergente.
drop function if exists public.iris_upsert_daily_emotional_record(
  date,
  text,
  text,
  text,
  integer,
  integer,
  text[],
  text[]
);

revoke all on function public.iris_upsert_daily_emotional_record(
  date,
  text,
  text,
  text,
  integer,
  integer,
  text[],
  text[],
  boolean
) from public, anon;
grant execute on function public.iris_upsert_daily_emotional_record(
  date,
  text,
  text,
  text,
  integer,
  integer,
  text[],
  text[],
  boolean
) to authenticated;

notify pgrst, 'reload schema';
