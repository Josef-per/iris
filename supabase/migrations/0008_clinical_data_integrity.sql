-- Integridade e contratos dos dados clinicos do Iris.
--
-- Esta migration:
--   * cria uma identidade diaria explicita para registros emocionais;
--   * consolida eventuais duplicatas antes de criar a chave unica;
--   * substitui indices posicionais de sintomas por codigos estaveis;
--   * disponibiliza um upsert diario atomico para o aplicativo;
--   * valida escalas, estados e horarios de consultas no servidor.

alter table public.registros_emocionais
  add column if not exists data_local date,
  add column if not exists fuso_horario text;

-- Registros legados nao guardavam o fuso informado pelo paciente. UTC e a
-- unica interpretacao deterministica possivel durante o backfill.
update public.registros_emocionais
   set data_local = (data_registro at time zone 'UTC')::date
 where data_local is null;

update public.registros_emocionais
   set fuso_horario = 'UTC'
 where fuso_horario is null or btrim(fuso_horario) = '';

-- Mantem, por paciente/dia, a linha mais recente e mescla nela os campos
-- preenchidos mais recentemente antes de remover duplicatas legadas.
with grupos as (
  select
    paciente_id,
    data_local,
    (array_agg(id order by data_registro desc, criado_em desc, id desc))[1]
      as manter_id
  from public.registros_emocionais
  group by paciente_id, data_local
  having count(*) > 1
),
consolidados as (
  update public.registros_emocionais destino
   set data_registro = coalesce(
         (
           select origem.data_registro
             from public.registros_emocionais origem
            where origem.paciente_id = destino.paciente_id
              and origem.data_local = destino.data_local
              and (
                nullif(btrim(origem.humor), '') is not null
                or origem.como_sentiu is not null
                or origem.avaliacao_alimentacao is not null
              )
            order by origem.data_registro desc, origem.criado_em desc,
                     origem.id desc
            limit 1
         ),
         destino.data_registro
       ),
       diario_emocional = coalesce(
         (
           select origem.diario_emocional
             from public.registros_emocionais origem
            where origem.paciente_id = destino.paciente_id
              and origem.data_local = destino.data_local
              and nullif(btrim(origem.diario_emocional), '') is not null
            order by origem.data_registro desc, origem.criado_em desc,
                     origem.id desc
            limit 1
         ),
         destino.diario_emocional
       ),
       humor = coalesce(
         (
           select origem.humor
             from public.registros_emocionais origem
            where origem.paciente_id = destino.paciente_id
              and origem.data_local = destino.data_local
              and nullif(btrim(origem.humor), '') is not null
            order by origem.data_registro desc, origem.criado_em desc,
                     origem.id desc
            limit 1
         ),
         destino.humor
       ),
       como_sentiu = coalesce(
         (
           select origem.como_sentiu
             from public.registros_emocionais origem
            where origem.paciente_id = destino.paciente_id
              and origem.data_local = destino.data_local
              and origem.como_sentiu is not null
            order by origem.data_registro desc, origem.criado_em desc,
                     origem.id desc
            limit 1
         ),
         destino.como_sentiu
       ),
       avaliacao_alimentacao = coalesce(
         (
           select origem.avaliacao_alimentacao
             from public.registros_emocionais origem
            where origem.paciente_id = destino.paciente_id
              and origem.data_local = destino.data_local
              and origem.avaliacao_alimentacao is not null
            order by origem.data_registro desc, origem.criado_em desc,
                     origem.id desc
            limit 1
         ),
         destino.avaliacao_alimentacao
       ),
       sintomas_emocionais_hoje = coalesce(
         (
           -- Array vazio e uma resposta clinica explicita. Busca o valor do
           -- check-in mais recente, em vez do ultimo array nao vazio.
           select origem.sintomas_emocionais_hoje
             from public.registros_emocionais origem
            where origem.paciente_id = destino.paciente_id
              and origem.data_local = destino.data_local
              and origem.sintomas_emocionais_hoje is not null
              and (
                nullif(btrim(origem.humor), '') is not null
                or origem.como_sentiu is not null
                or origem.avaliacao_alimentacao is not null
              )
            order by origem.data_registro desc, origem.criado_em desc,
                     origem.id desc
            limit 1
         ),
         destino.sintomas_emocionais_hoje
       ),
       sintomas_fisicos_hoje = coalesce(
         (
           -- O mesmo contrato vale para "nenhum sintoma fisico".
           select origem.sintomas_fisicos_hoje
             from public.registros_emocionais origem
            where origem.paciente_id = destino.paciente_id
              and origem.data_local = destino.data_local
              and origem.sintomas_fisicos_hoje is not null
              and (
                nullif(btrim(origem.humor), '') is not null
                or origem.como_sentiu is not null
                or origem.avaliacao_alimentacao is not null
              )
            order by origem.data_registro desc, origem.criado_em desc,
                     origem.id desc
            limit 1
         ),
         destino.sintomas_fisicos_hoje
       )
    from grupos
   where destino.id = grupos.manter_id
  returning destino.id as manter_id
)
delete from public.registros_emocionais registro
 using grupos
 join consolidados on consolidados.manter_id = grupos.manter_id
 where registro.paciente_id = grupos.paciente_id
   and registro.data_local = grupos.data_local
   and registro.id <> grupos.manter_id;

alter table public.registros_emocionais
  alter column data_local set not null,
  alter column fuso_horario set not null;

create unique index if not exists iris_emocionais_paciente_dia_unique
  on public.registros_emocionais(paciente_id, data_local);

-- Falha de forma explicita se um cliente antigo tiver gravado indices fora
-- dos catalogos conhecidos. Assim a migration nunca apaga um sintoma sem
-- que o dado legado seja revisado.
do $$
begin
  if exists (
    select 1
      from information_schema.columns
     where table_schema = 'public'
       and table_name = 'registros_emocionais'
       and column_name = 'sintomas_emocionais_hoje'
       and udt_name = '_int4'
  ) then
    if exists (
      select 1
        from public.registros_emocionais registro,
             unnest(registro.sintomas_emocionais_hoje) sintoma
       where sintoma not between 0 and 5
    ) then
      raise exception 'UNKNOWN_LEGACY_EMOTIONAL_SYMPTOM';
    end if;

    if exists (
      select 1
        from public.registros_emocionais registro,
             unnest(registro.sintomas_fisicos_hoje) sintoma
       where sintoma not between 0 and 9
    ) then
      raise exception 'UNKNOWN_LEGACY_PHYSICAL_SYMPTOM';
    end if;
  end if;
end;
$$;

create or replace function public.iris_emotional_symptom_codes(
  p_indexes integer[]
)
returns text[]
language sql
immutable
set search_path = pg_catalog
as $$
  select coalesce(
    array_agg(
      case item.value
        when 0 then 'inseguranca'
        when 1 then 'culpa'
        when 2 then 'vomito_autoinduzido'
        when 3 then 'medo'
        when 4 then 'compulsao'
        when 5 then 'ansiedade'
      end
      order by item.ordinality
    ),
    '{}'::text[]
  )
  from unnest(coalesce(p_indexes, '{}'::integer[]))
    with ordinality as item(value, ordinality);
$$;

create or replace function public.iris_physical_symptom_codes(
  p_indexes integer[]
)
returns text[]
language sql
immutable
set search_path = pg_catalog
as $$
  select coalesce(
    array_agg(
      case item.value
        when 0 then 'cansaco_excessivo'
        when 1 then 'alteracao_pressao'
        when 2 then 'problemas_digestivos'
        when 3 then 'queda_cabelo'
        when 4 then 'dificuldade_concentracao'
        when 5 then 'desmaio'
        when 6 then 'fraqueza'
        when 7 then 'tontura'
        when 8 then 'nausea'
        when 9 then 'dor_cabeca'
      end
      order by item.ordinality
    ),
    '{}'::text[]
  )
  from unnest(coalesce(p_indexes, '{}'::integer[]))
    with ordinality as item(value, ordinality);
$$;

do $$
begin
  if exists (
    select 1
      from information_schema.columns
     where table_schema = 'public'
       and table_name = 'registros_emocionais'
       and column_name = 'sintomas_emocionais_hoje'
       and udt_name = '_int4'
  ) then
    alter table public.registros_emocionais
      alter column sintomas_emocionais_hoje drop default,
      alter column sintomas_fisicos_hoje drop default;

    alter table public.registros_emocionais
      alter column sintomas_emocionais_hoje type text[]
        using public.iris_emotional_symptom_codes(
          sintomas_emocionais_hoje
        ),
      alter column sintomas_fisicos_hoje type text[]
        using public.iris_physical_symptom_codes(sintomas_fisicos_hoje);
  end if;
end;
$$;

alter table public.registros_emocionais
  alter column sintomas_emocionais_hoje set default '{}'::text[],
  alter column sintomas_fisicos_hoje set default '{}'::text[],
  alter column sintomas_emocionais_hoje set not null,
  alter column sintomas_fisicos_hoje set not null;

drop function if exists public.iris_emotional_symptom_codes(integer[]);
drop function if exists public.iris_physical_symptom_codes(integer[]);

do $$
begin
  if not exists (
    select 1 from pg_constraint
     where conrelid = 'public.registros_alimentares'::regclass
       and conname = 'iris_alimentares_fome_valida'
  ) then
    alter table public.registros_alimentares
      add constraint iris_alimentares_fome_valida
      check (nivel_fome is null or nivel_fome between 1 and 10);
  end if;

  if not exists (
    select 1 from pg_constraint
     where conrelid = 'public.registros_alimentares'::regclass
       and conname = 'iris_alimentares_descricao_valida'
  ) then
    alter table public.registros_alimentares
      add constraint iris_alimentares_descricao_valida
      check (btrim(descricao_refeicao) <> '');
  end if;

  if not exists (
    select 1 from pg_constraint
     where conrelid = 'public.registros_emocionais'::regclass
       and conname = 'iris_emocionais_como_sentiu_valido'
  ) then
    alter table public.registros_emocionais
      add constraint iris_emocionais_como_sentiu_valido
      check (como_sentiu is null or como_sentiu between 1 and 5);
  end if;

  if not exists (
    select 1 from pg_constraint
     where conrelid = 'public.registros_emocionais'::regclass
       and conname = 'iris_emocionais_alimentacao_valida'
  ) then
    alter table public.registros_emocionais
      add constraint iris_emocionais_alimentacao_valida
      check (
        avaliacao_alimentacao is null
        or avaliacao_alimentacao between 1 and 5
      );
  end if;

  if not exists (
    select 1 from pg_constraint
     where conrelid = 'public.registros_emocionais'::regclass
       and conname = 'iris_emocionais_sintomas_emocionais_validos'
  ) then
    alter table public.registros_emocionais
      add constraint iris_emocionais_sintomas_emocionais_validos
      check (
        sintomas_emocionais_hoje <@ array[
          'inseguranca', 'culpa', 'vomito_autoinduzido', 'medo',
          'compulsao', 'ansiedade'
        ]::text[]
      );
  end if;

  if not exists (
    select 1 from pg_constraint
     where conrelid = 'public.registros_emocionais'::regclass
       and conname = 'iris_emocionais_sintomas_fisicos_validos'
  ) then
    alter table public.registros_emocionais
      add constraint iris_emocionais_sintomas_fisicos_validos
      check (
        sintomas_fisicos_hoje <@ array[
          'cansaco_excessivo', 'alteracao_pressao', 'problemas_digestivos',
          'queda_cabelo', 'dificuldade_concentracao', 'desmaio',
          'fraqueza', 'tontura', 'nausea', 'dor_cabeca'
        ]::text[]
      );
  end if;

  if not exists (
    select 1 from pg_constraint
     where conrelid = 'public.consultas'::regclass
       and conname = 'iris_consultas_modalidade_valida'
  ) then
    alter table public.consultas
      add constraint iris_consultas_modalidade_valida
      check (modalidade in ('online', 'presencial'));
  end if;

  if not exists (
    select 1 from pg_constraint
     where conrelid = 'public.consultas'::regclass
       and conname = 'iris_consultas_status_valido'
  ) then
    alter table public.consultas
      add constraint iris_consultas_status_valido
      check (status in ('agendada', 'concluida', 'cancelada'));
  end if;
end;
$$;

create or replace function public.iris_upsert_daily_emotional_record(
  p_data_local date,
  p_fuso_horario text,
  p_diario_emocional text default null,
  p_humor text default null,
  p_como_sentiu integer default null,
  p_avaliacao_alimentacao integer default null,
  p_sintomas_emocionais_hoje text[] default null,
  p_sintomas_fisicos_hoje text[] default null
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
    nullif(btrim(p_diario_emocional), ''),
    nullif(btrim(p_humor), ''),
    p_como_sentiu,
    p_avaliacao_alimentacao,
    coalesce(p_sintomas_emocionais_hoje, '{}'::text[]),
    coalesce(p_sintomas_fisicos_hoje, '{}'::text[])
  )
  on conflict (paciente_id, data_local) do update
    set data_registro = case
          -- data_registro representa o instante da avaliacao clinica. Editar
          -- apenas o diario nao deve renovar scores/sintomas nem seus alertas.
          when nullif(btrim(p_humor), '') is not null
            or p_como_sentiu is not null
            or p_avaliacao_alimentacao is not null
            or p_sintomas_emocionais_hoje is not null
            or p_sintomas_fisicos_hoje is not null
            then now()
          else registros_emocionais.data_registro
        end,
        fuso_horario = excluded.fuso_horario,
        diario_emocional = coalesce(
          excluded.diario_emocional,
          registros_emocionais.diario_emocional
        ),
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

revoke all on function public.iris_upsert_daily_emotional_record(
  date,
  text,
  text,
  text,
  integer,
  integer,
  text[],
  text[]
) from public, anon;
grant execute on function public.iris_upsert_daily_emotional_record(
  date,
  text,
  text,
  text,
  integer,
  integer,
  text[],
  text[]
) to authenticated;

-- Toda escrita emocional passa pelo upsert atomico. A leitura continua
-- protegida pelas policies RLS existentes.
revoke insert, update, delete on public.registros_emocionais
  from authenticated;
grant select on public.registros_emocionais to authenticated;

-- Uma expressao CHECK nao pode depender de now(). O trigger aplica a regra
-- temporal no servidor para qualquer cliente ou chamada REST.
create or replace function public.iris_validate_appointment_schedule()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.status = 'agendada' and new.inicio_em <= now() then
    raise exception 'APPOINTMENT_MUST_BE_FUTURE';
  end if;

  return new;
end;
$$;

revoke all on function public.iris_validate_appointment_schedule()
  from public;

drop trigger if exists iris_validate_appointment_schedule
  on public.consultas;
create trigger iris_validate_appointment_schedule
  before insert or update of inicio_em, status
  on public.consultas
  for each row execute function public.iris_validate_appointment_schedule();

notify pgrst, 'reload schema';
