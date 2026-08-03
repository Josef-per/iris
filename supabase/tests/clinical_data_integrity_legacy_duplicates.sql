\set ON_ERROR_STOP on

-- Antes da 0008, corridas entre clientes podiam criar mais de um registro no
-- mesmo dia. O check-in mais novo declara explicitamente que nao ha sintomas,
-- e uma entrada de diario ainda mais nova nao pode ressuscitar os sintomas nem
-- substituir o instante clinico pelo horario do diario.
insert into public.registros_emocionais (
  id,
  paciente_id,
  data_registro,
  diario_emocional,
  humor,
  como_sentiu,
  avaliacao_alimentacao,
  sintomas_emocionais_hoje,
  sintomas_fisicos_hoje,
  criado_em,
  atualizado_em
)
values
  (
    '40000000-0000-4000-8000-000000000081',
    '20000000-0000-4000-8000-000000000001',
    '2025-03-14 08:00:00+00',
    null,
    'Muito mal',
    1,
    2,
    array[4],
    array[5],
    '2025-03-14 08:00:00+00',
    '2025-03-14 08:00:00+00'
  ),
  (
    '40000000-0000-4000-8000-000000000082',
    '20000000-0000-4000-8000-000000000001',
    '2025-03-14 09:00:00+00',
    'Check-in mais recente sem sintomas',
    'Bem',
    4,
    4,
    '{}'::integer[],
    '{}'::integer[],
    '2025-03-14 09:00:00+00',
    '2025-03-14 09:00:00+00'
  ),
  (
    '40000000-0000-4000-8000-000000000083',
    '20000000-0000-4000-8000-000000000001',
    '2025-03-14 10:00:00+00',
    'Diario posterior ao check-in',
    null,
    null,
    null,
    '{}'::integer[],
    '{}'::integer[],
    '2025-03-14 10:00:00+00',
    '2025-03-14 10:00:00+00'
  );
