# `ai-support-recommend`

Edge Function autenticada que transforma sinais estruturados em, no máximo,
um ID de conteúdo previamente aprovado. Ela não devolve conselho livre, não
escolhe horário de notificação e não lê o conteúdo textual do diário.

O cliente envia somente `requestId` e `trigger`. O backend resolve o paciente,
o check-in do dia, a tendência recente, os tópicos explicitamente confirmados
e as interações com notificações. As consultas não selecionam diário bruto,
alimentação nem sintomas, e esses campos não entram na chamada à OpenAI.

## Antes de implantar

1. Aplique `supabase/migrations/0010_ai_support_backend.sql`.
2. Defina um projeto e uma chave OpenAI exclusivos para cada ambiente, com
   limites de gasto e rotação próprios.
3. Configure os secrets da função; não coloque a chave no `.env` usado pelo
   Flutter e nunca use `--dart-define` para ela.
4. Mantenha produção em `modo = 'local'`, `openai_ativa = false` e
   `kill_switch = true` até as aprovações clínica, jurídica, privacidade,
   segurança e regulatória.

Secrets necessários para habilitar chamadas ao modelo:

```text
OPENAI_API_KEY=<secret somente do backend>
OPENAI_MODEL=<snapshot avaliado e aprovado>
AI_SUPPORT_SAFETY_SALT=<valor aleatório exclusivo do ambiente>
AI_SUPPORT_ENVIRONMENT=staging
AI_SUPPORT_ALLOWED_ORIGINS=https://app-staging.exemplo
OPENAI_TIMEOUT_MS=6000
```

Para desenvolvimento local, copie `supabase/functions/.env.example` para
`supabase/functions/.env`, preencha os valores (o arquivo final é ignorado pelo
Git) e execute:

```bash
supabase functions serve ai-support-recommend \
  --env-file supabase/functions/.env
```

No projeto remoto, use o gerenciador de secrets do Supabase:

```bash
supabase secrets set --env-file supabase/functions/.env
supabase functions deploy ai-support-recommend
```

O `.env` da raiz é lido apenas pelo script de execução do Flutter para valores
publicáveis do Supabase. Ele não configura secrets de Edge Functions.

## Contrato do cliente

O cliente envia apenas idempotência e origem do disparo:

```json
{
  "requestId": "0d3f9ef2-29b6-4fa1-983a-e9418bc4dd46",
  "trigger": "after_checkin"
}
```

Valores aceitos para `trigger`: `manual`, `after_checkin`, `after_diary` e
`notification_open`. O paciente e seus registros são resolvidos no backend a
partir do JWT. Dados clínicos enviados pelo cliente são rejeitados como campos
extras.

Resposta com sugestão:

```json
{
  "requestId": "0d3f9ef2-29b6-4fa1-983a-e9418bc4dd46",
  "mode": "pilot",
  "status": "suggested",
  "suggestionId": "identificador-opaco",
  "templateId": "exercise_difficult_checkins_v1",
  "category": "exercise",
  "exerciseId": "anchor-present",
  "reasonCodes": [
    "RECENT_DIFFICULT_CHECKINS",
    "PREFERS_SHORT_PRACTICE"
  ],
  "confidenceBand": "medium",
  "usedSources": ["mood_history"],
  "origin": "openai",
  "proposal": {
    "suggestionTemplateId": "exercise_difficult_checkins_v1",
    "exerciseId": "anchor-present",
    "reasonCodes": [
      "RECENT_DIFFICULT_CHECKINS",
      "PREFERS_SHORT_PRACTICE"
    ],
    "confidenceBand": "medium"
  },
  "expiresAt": "2026-08-25T12:00:00Z"
}
```

Sem evidência suficiente, consentimento ou disponibilidade segura, retorna
`{"requestId":"...","mode":"local","status":"silent","proposal":null}`.
Uma indisponibilidade do modelo nunca impede o salvamento do check-in ou
diário; a função usa regra local ou silêncio.

O `proposal` repete apenas o contrato fechado necessário para uma segunda
validação no aplicativo. Ele nunca contém texto gerado. Os templates atualmente
aceitos cobrem check-in difícil/estável/mais leve, sobrecarga, solidão,
autogentileza e uma alternativa após feedback negativo de exercício. O motivo
`PREFERRED_FROM_PAST_INTERACTIONS` só é válido junto de uma evidência atual e
quando a categoria ou o template coincide com uma notificação aberta antes.

## Modos de rollout

- `local`: não chama a OpenAI; usa regras fechadas.
- `shadow`: chama somente para a coorte configurada, grava IDs e métricas em
  uma linha invisível ao paciente e mantém a decisão local na interface.
- `pilot`: usa uma saída validada apenas para pacientes inscritos em
  `participantes_piloto_ia_apoio`.
- `limited`: usa distribuição determinística pelo percentual configurado; o
  restante continua nas regras locais.

`kill_switch = true` força regra local imediatamente. `apoio_ativo = false`
produz silêncio. A migration bloqueia `texto_generativo_ativo`; liberar texto
gerado exige uma avaliação e uma migration separadas.

O campo `mode` da resposta sempre reflete o rollout configurado. Somente
`pilot` e `limited` podem permitir que uma seleção da OpenAI, já validada no
backend e novamente no app, influencie a experiência. Em `local` e `shadow`, o
aplicativo mantém a recomendação local.

Exemplo de ativação **somente em staging**, depois de cadastrar no secret
`OPENAI_MODEL` o mesmo snapshot:

```sql
update public.rollout_ia_apoio
   set modo = 'shadow',
       openai_ativa = true,
       kill_switch = false,
       percentual_shadow = 100,
       modelo = '<snapshot-avaliado>',
       atualizado_em = now()
 where ambiente = 'staging';
```

Não altere produção antes dos gates externos. Fases de piloto e produção são
processos clínicos e regulatórios; a presença do código não equivale à sua
aprovação.

## Privacidade e retenção

A chamada usa Responses API com `store: false`, Structured Outputs estritos,
limite curto de tokens, nenhum tool e um `safety_identifier` derivado por HMAC.
O banco guarda apenas IDs aceitos, códigos de motivo, fontes, hashes e métricas.
Payload, prompt, resposta bruta e identificador do paciente não entram em logs.

`store: false` não elimina sozinho a retenção de logs de monitoramento de abuso
do fornecedor. Antes de qualquer dado de saúde real, valide contrato, região,
suboperadores e controles como Zero Data Retention/Modified Abuse Monitoring.
Texto livre do diário permanece fora desta função.

## Testes

O contrato fechado pode ser testado sem rede:

```bash
node supabase/functions/_shared/ai_support_contract_test.ts
```

As tabelas, constraints, RPCs, RLS e a idempotência das migrations são
validadas em PostgreSQL isolado por:

```bash
./scripts/test_supabase_migrations.sh
```

Referências:

- [Structured Outputs](https://developers.openai.com/api/docs/guides/structured-outputs)
- [Controles de dados](https://developers.openai.com/api/docs/guides/your-data)
- [Práticas de segurança](https://developers.openai.com/api/docs/guides/safety-best-practices)
- [Autorização de Edge Functions](https://supabase.com/docs/guides/functions/auth-headers)
- [Secrets de Edge Functions](https://supabase.com/docs/guides/functions/secrets)
