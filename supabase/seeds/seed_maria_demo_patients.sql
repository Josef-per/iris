-- Dados de demonstracao para o painel profissional do Iris.
--
-- Cria cinco pacientes autenticaveis e os vincula ao profissional cujo
-- e-mail e maria@email.com. Tambem inclui consultas, anotacoes, plano de
-- cuidado, metas, medicacoes e historicos emocional e alimentar.
--
-- Pre-requisitos:
--   * migrations 0001, 0005, 0006, 0007 e 0008 aplicadas;
--   * maria@email.com cadastrada como profissional com credenciamento ativo;
--   * execucao pelo SQL Editor do Supabase ou por uma conexao administrativa.
--
-- Credenciais dos pacientes de demonstracao:
--   paciente.demo01@iris.local / IrisDemo@2026
--   paciente.demo02@iris.local / IrisDemo@2026
--   paciente.demo03@iris.local / IrisDemo@2026
--   paciente.demo04@iris.local / IrisDemo@2026
--   paciente.demo05@iris.local / IrisDemo@2026
--
-- Os UUIDs sao derivados de chaves fixas com md5. Assim, executar novamente
-- nao duplica as linhas geradas por este arquivo. Inserts de historico usam
-- ON CONFLICT DO NOTHING para preservar eventuais edicoes feitas no app.

begin;

do $$
declare
  v_profissional_id uuid;
  v_user_id uuid;
  v_existing_user_id uuid;
  v_paciente_id uuid;
  v_vinculo_id uuid;
  v_plano_id uuid;
  v_email text;
  v_inicio timestamptz;
  v_status text;
  v_i integer;
  v_j integer;
  v_day_offsets integer[] := array[6, 3, 1];
  v_names text[] := array[
    'Ana Clara Souza',
    'Beatriz Lima Santos',
    'Carolina Mendes Rocha',
    'Daniela Alves Ferreira',
    'Eduarda Ribeiro Costa'
  ];
  v_birth_dates date[] := array[
    date '1998-03-14',
    date '2001-07-22',
    date '1995-11-08',
    date '2003-01-30',
    date '1999-09-17'
  ];
  v_diagnoses text[] := array[
    'Transtorno alimentar em acompanhamento',
    'Compulsao alimentar em avaliacao',
    'Restricao alimentar em acompanhamento',
    'Relacao disfuncional com a alimentacao',
    'Transtorno alimentar em remissao parcial'
  ];
  v_current_moods text[] := array[
    'Ansiosa, mas colaborativa',
    'Estavel',
    'Oscilando durante a semana',
    'Motivada com o tratamento',
    'Estavel, com boa adesao'
  ];
  v_orientations text[] := array[
    'Manter horarios regulares para as refeicoes e registrar os gatilhos percebidos.',
    'Praticar alimentacao consciente e levar os episodios de compulsao para a consulta.',
    'Evitar longos periodos sem se alimentar e acionar a rede de apoio quando necessario.',
    'Registrar pensamentos automaticos antes e depois das refeicoes principais.',
    'Manter a rotina atual e observar sinais precoces de recaida.'
  ];
begin
  select profissional.id
    into v_profissional_id
    from public.profissionais profissional
    join public.usuarios usuario on usuario.id = profissional.user_id
   where lower(btrim(usuario.email)) = lower('maria@email.com')
     and usuario.ativo
     and usuario.tipo_usuario = 'profissional'
     and profissional.credenciamento_status = 'ativo'
   limit 1;

  if v_profissional_id is null then
    raise exception using
      message = 'MARIA_PROFESSIONAL_NOT_FOUND_OR_INACTIVE',
      hint = 'Cadastre/ative maria@email.com como profissional antes de executar este seed.';
  end if;

  for v_i in 1..5 loop
    v_user_id := md5(format('iris-demo:user:%s', v_i))::uuid;
    v_paciente_id := md5(format('iris-demo:patient:%s', v_i))::uuid;
    v_vinculo_id := md5(format('iris-demo:link:%s', v_i))::uuid;
    v_plano_id := md5(format('iris-demo:care-plan:%s', v_i))::uuid;
    v_email := format(
      'paciente.demo%s@iris.local',
      lpad(v_i::text, 2, '0')
    );

    select usuario.id
      into v_existing_user_id
      from auth.users usuario
     where lower(usuario.email) = lower(v_email)
     limit 1;

    if v_existing_user_id is not null and v_existing_user_id <> v_user_id then
      raise exception 'DEMO_EMAIL_ALREADY_USED: %', v_email;
    end if;

    -- A conta de Auth permite abrir o aplicativo como qualquer paciente de
    -- demonstracao. pgcrypto foi instalado no schema extensions pela 0001.
    insert into auth.users (
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at
    )
    values (
      v_user_id,
      'authenticated',
      'authenticated',
      v_email,
      extensions.crypt('IrisDemo@2026', extensions.gen_salt('bf')),
      now(),
      jsonb_build_object('provider', 'email', 'providers', array['email']),
      jsonb_build_object(
        'display_name', v_names[v_i],
        'email_verified', true
      ),
      now(),
      now()
    )
    on conflict (id) do update
      set email = excluded.email,
          encrypted_password = excluded.encrypted_password,
          email_confirmed_at = coalesce(
            auth.users.email_confirmed_at,
            excluded.email_confirmed_at
          ),
          raw_app_meta_data = excluded.raw_app_meta_data,
          raw_user_meta_data = excluded.raw_user_meta_data,
          updated_at = now();

    -- GoTrue atual usa provider_id; a ramificacao alternativa mantem o seed
    -- compativel com projetos Supabase que ainda possuem o schema anterior.
    if exists (
      select 1
        from information_schema.columns
       where table_schema = 'auth'
         and table_name = 'identities'
         and column_name = 'provider_id'
    ) then
      insert into auth.identities (
        provider_id,
        user_id,
        identity_data,
        provider,
        last_sign_in_at,
        created_at,
        updated_at
      )
      values (
        v_user_id::text,
        v_user_id,
        jsonb_build_object(
          'sub', v_user_id::text,
          'email', v_email,
          'email_verified', true
        ),
        'email',
        now(),
        now(),
        now()
      )
      on conflict (provider_id, provider) do update
        set identity_data = excluded.identity_data,
            updated_at = now();
    else
      insert into auth.identities (
        id,
        user_id,
        identity_data,
        provider,
        last_sign_in_at,
        created_at,
        updated_at
      )
      values (
        v_user_id::text,
        v_user_id,
        jsonb_build_object(
          'sub', v_user_id::text,
          'email', v_email,
          'email_verified', true
        ),
        'email',
        now(),
        now(),
        now()
      )
      on conflict (provider, id) do update
        set identity_data = excluded.identity_data,
            updated_at = now();
    end if;

    insert into public.usuarios (
      id,
      email,
      senha_hash,
      tipo_usuario,
      ativo
    )
    values (
      v_user_id,
      v_email,
      'managed_by_supabase_auth',
      'paciente',
      true
    )
    on conflict (id) do update
      set email = excluded.email,
          tipo_usuario = 'paciente',
          ativo = true;

    insert into public.perfis (
      id,
      user_id,
      nome_completo,
      nome_social,
      telefone,
      data_nascimento
    )
    values (
      md5(format('iris-demo:profile:%s', v_i))::uuid,
      v_user_id,
      v_names[v_i],
      split_part(v_names[v_i], ' ', 1),
      format('+55 11 9999-%s', lpad((1000 + v_i)::text, 4, '0')),
      v_birth_dates[v_i]
    )
    on conflict (user_id) do update
      set nome_completo = excluded.nome_completo,
          nome_social = excluded.nome_social,
          telefone = excluded.telefone,
          data_nascimento = excluded.data_nascimento;

    insert into public.pacientes (id, user_id)
    values (v_paciente_id, v_user_id)
    on conflict (user_id) do nothing;

    -- Recupera o id real caso a conta de demonstracao ja existisse antes
    -- deste arquivo com outro id de public.pacientes.
    select paciente.id
      into v_paciente_id
      from public.pacientes paciente
     where paciente.user_id = v_user_id;

    if exists (
      select 1
        from public.paciente_profissional vinculo
       where vinculo.paciente_id = v_paciente_id
         and vinculo.profissional_id <> v_profissional_id
         and vinculo.autorizacao_status = 'ativo'
    ) then
      raise exception 'DEMO_PATIENT_ALREADY_LINKED_TO_ANOTHER_PROFESSIONAL: %',
        v_email;
    end if;

    insert into public.paciente_profissional (
      id,
      paciente_id,
      profissional_id,
      status,
      autorizacao_status,
      diagnostico,
      humor_atual,
      ultimo_registro
    )
    values (
      v_vinculo_id,
      v_paciente_id,
      v_profissional_id,
      'ativo',
      'ativo',
      v_diagnoses[v_i],
      v_current_moods[v_i],
      now() - interval '1 day'
    )
    on conflict (paciente_id, profissional_id) do update
      set status = 'ativo',
          autorizacao_status = 'ativo',
          autorizacao_revogada_em = null,
          diagnostico = coalesce(
            public.paciente_profissional.diagnostico,
            excluded.diagnostico
          ),
          humor_atual = coalesce(
            public.paciente_profissional.humor_atual,
            excluded.humor_atual
          ),
          ultimo_registro = coalesce(
            public.paciente_profissional.ultimo_registro,
            excluded.ultimo_registro
          );

    select vinculo.id
      into v_vinculo_id
      from public.paciente_profissional vinculo
     where vinculo.paciente_id = v_paciente_id
       and vinculo.profissional_id = v_profissional_id;

    -- Tres check-ins emocionais por paciente. O array vazio e proposital em
    -- algumas linhas e representa a resposta clinica "nenhum sintoma".
    for v_j in 1..3 loop
      insert into public.registros_emocionais (
        id,
        paciente_id,
        data_registro,
        data_local,
        fuso_horario,
        diario_emocional,
        humor,
        como_sentiu,
        avaliacao_alimentacao,
        sintomas_emocionais_hoje,
        sintomas_fisicos_hoje,
        criado_em
      )
      values (
        md5(format('iris-demo:emotional:%s:%s', v_i, v_j))::uuid,
        v_paciente_id,
        ((current_date - v_day_offsets[v_j]) + time '20:00')
          at time zone 'America/Sao_Paulo',
        current_date - v_day_offsets[v_j],
        'America/Sao_Paulo',
        case v_j
          when 1 then 'Dia desafiador, mas consegui seguir parte do plano.'
          when 2 then 'Percebi os gatilhos e pedi ajuda antes da refeicao.'
          else 'Hoje me senti mais presente e consegui manter a rotina.'
        end,
        case ((v_i + v_j) % 4)
          when 0 then 'calma'
          when 1 then 'ansiosa'
          when 2 then 'cansada'
          else 'esperancosa'
        end,
        greatest(1, least(5, 2 + ((v_i + v_j) % 4))),
        greatest(1, least(5, 2 + ((v_i + (2 * v_j)) % 4))),
        case
          when v_j = 3 and v_i in (2, 5) then '{}'::text[]
          when v_i % 2 = 0 then array['ansiedade', 'culpa']::text[]
          else array['ansiedade', 'inseguranca']::text[]
        end,
        case
          when v_j = 3 and v_i in (1, 4) then '{}'::text[]
          when v_i % 2 = 0 then array['cansaco_excessivo']::text[]
          else array['dor_cabeca', 'dificuldade_concentracao']::text[]
        end,
        ((current_date - v_day_offsets[v_j]) + time '20:00')
          at time zone 'America/Sao_Paulo'
      )
      on conflict do nothing;
    end loop;

    -- Tres refeicoes historicas por paciente.
    for v_j in 1..3 loop
      insert into public.registros_alimentares (
        id,
        paciente_id,
        horario_refeicao,
        descricao_refeicao,
        nivel_fome,
        sentimento_depois,
        observacoes,
        criado_em
      )
      values (
        md5(format('iris-demo:meal:%s:%s', v_i, v_j))::uuid,
        v_paciente_id,
        case v_j
          when 1 then
            ((current_date - 2) + time '08:00')
              at time zone 'America/Sao_Paulo'
          when 2 then
            ((current_date - 1) + time '12:30')
              at time zone 'America/Sao_Paulo'
          else
            ((current_date - 1) + time '19:30')
              at time zone 'America/Sao_Paulo'
        end,
        case v_j
          when 1 then 'Iogurte, fruta e aveia'
          when 2 then 'Arroz, feijao, legumes e frango'
          else 'Sopa de legumes com torradas'
        end,
        case v_j when 1 then 6 when 2 then 8 else 5 end,
        case v_j
          when 1 then 'Satisfeita'
          when 2 then 'Um pouco ansiosa, mas confortavel'
          else 'Tranquila'
        end,
        case v_j
          when 1 then 'Consegui comer sem usar o celular.'
          when 2 then 'Fiz uma pausa no meio da refeicao para perceber a saciedade.'
          else 'Refeicao realizada junto com a familia.'
        end,
        case v_j
          when 1 then
            ((current_date - 2) + time '08:00')
              at time zone 'America/Sao_Paulo'
          when 2 then
            ((current_date - 1) + time '12:30')
              at time zone 'America/Sao_Paulo'
          else
            ((current_date - 1) + time '19:30')
              at time zone 'America/Sao_Paulo'
        end
      )
      on conflict (id) do nothing;
    end loop;

    -- Duas consultas concluidas e uma futura por paciente.
    for v_j in 1..3 loop
      if v_j = 1 then
        v_inicio := now() - make_interval(days => 28 + v_i);
        v_status := 'concluida';
      elsif v_j = 2 then
        v_inicio := now() - make_interval(days => 10 + v_i);
        v_status := 'concluida';
      else
        v_inicio := now() + make_interval(days => v_i, hours => 2);
        v_status := 'agendada';
      end if;

      insert into public.consultas (
        id,
        vinculo_id,
        inicio_em,
        fim_em,
        modalidade,
        status,
        titulo,
        local_ou_link,
        criado_em
      )
      values (
        md5(format('iris-demo:appointment:%s:%s', v_i, v_j))::uuid,
        v_vinculo_id,
        v_inicio,
        v_inicio + interval '50 minutes',
        case when (v_i + v_j) % 2 = 0 then 'online' else 'presencial' end,
        v_status,
        case when v_j = 3
          then 'Acompanhamento quinzenal'
          else 'Consulta de acompanhamento'
        end,
        case when (v_i + v_j) % 2 = 0
          then 'https://meet.example.com/iris-demo'
          else 'Clinica Iris - Sala 2'
        end,
        least(v_inicio - interval '7 days', now())
      )
      on conflict (id) do nothing;
    end loop;

    insert into public.anotacoes_clinicas (
      id,
      vinculo_id,
      profissional_id,
      conteudo,
      marcador,
      criado_em
    )
    values
      (
        md5(format('iris-demo:note:%s:1', v_i))::uuid,
        v_vinculo_id,
        v_profissional_id,
        'Paciente apresentou boa participacao. Foram revisados gatilhos, rede de apoio e estrategias para as refeicoes.',
        'Evolucao',
        now() - make_interval(days => 28 + v_i)
      ),
      (
        md5(format('iris-demo:note:%s:2', v_i))::uuid,
        v_vinculo_id,
        v_profissional_id,
        'Mantido acompanhamento quinzenal. Reforcada a orientacao de registrar alteracoes importantes entre consultas.',
        'Conduta',
        now() - make_interval(days => 10 + v_i)
      )
    on conflict (id) do nothing;

    insert into public.planos_cuidado (
      id,
      vinculo_id,
      orientacoes,
      passos_crise,
      compartilhar_paciente,
      alertar_checkins_ausentes
    )
    values (
      v_plano_id,
      v_vinculo_id,
      v_orientations[v_i],
      array[
        'Interromper atividades e fazer respiracao lenta por dois minutos',
        'Avisar uma pessoa da rede de apoio',
        'Entrar em contato com a equipe de cuidado se o risco persistir'
      ]::text[],
      true,
      true
    )
    on conflict (vinculo_id) do nothing;

    select plano.id
      into v_plano_id
      from public.planos_cuidado plano
     where plano.vinculo_id = v_vinculo_id;

    insert into public.metas_cuidado (
      id,
      plano_id,
      descricao,
      concluida,
      ordem
    )
    values
      (
        md5(format('iris-demo:goal:%s:1', v_i))::uuid,
        v_plano_id,
        'Realizar ao menos tres refeicoes principais por dia',
        v_i in (3, 5),
        0
      ),
      (
        md5(format('iris-demo:goal:%s:2', v_i))::uuid,
        v_plano_id,
        'Preencher o check-in emocional em cinco dias da semana',
        false,
        1
      ),
      (
        md5(format('iris-demo:goal:%s:3', v_i))::uuid,
        v_plano_id,
        'Praticar uma estrategia de regulacao emocional antes da refeicao',
        v_i = 5,
        2
      )
    on conflict (id) do nothing;

    -- Medicacoes abaixo sao exclusivamente dados ficticios de interface.
    insert into public.medicacoes_plano (
      id,
      plano_id,
      nome,
      dose,
      frequencia,
      adesao,
      ordem
    )
    values (
      md5(format('iris-demo:medication:%s:1', v_i))::uuid,
      v_plano_id,
      case v_i
        when 1 then 'Sertralina'
        when 2 then 'Fluoxetina'
        when 3 then 'Escitalopram'
        when 4 then 'Sertralina'
        else 'Fluoxetina'
      end,
      case when v_i in (2, 5) then '20 mg' else '50 mg' end,
      'Uma vez ao dia, conforme prescricao',
      case v_i
        when 1 then 0.9200
        when 2 then 0.8500
        when 3 then 0.9600
        when 4 then 0.7800
        else 1.0000
      end,
      0
    )
    on conflict (id) do nothing;
  end loop;
end;
$$;

commit;

-- Resumo para conferencia no SQL Editor.
select
  perfil.nome_completo as paciente,
  usuario.email,
  vinculo.status as acompanhamento,
  vinculo.diagnostico,
  count(distinct consulta.id) as consultas,
  count(distinct emocional.id) as checkins_emocionais,
  count(distinct alimentar.id) as registros_alimentares
from public.paciente_profissional vinculo
join public.profissionais profissional
  on profissional.id = vinculo.profissional_id
join public.usuarios usuario_profissional
  on usuario_profissional.id = profissional.user_id
join public.pacientes paciente on paciente.id = vinculo.paciente_id
join public.usuarios usuario on usuario.id = paciente.user_id
join public.perfis perfil on perfil.user_id = usuario.id
left join public.consultas consulta on consulta.vinculo_id = vinculo.id
left join public.registros_emocionais emocional
  on emocional.paciente_id = paciente.id
left join public.registros_alimentares alimentar
  on alimentar.paciente_id = paciente.id
where lower(usuario_profissional.email) = lower('maria@email.com')
  and usuario.email like 'paciente.demo%@iris.local'
group by
  perfil.nome_completo,
  usuario.email,
  vinculo.status,
  vinculo.diagnostico
order by perfil.nome_completo;
