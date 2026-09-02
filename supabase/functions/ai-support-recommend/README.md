# `ai-support-recommend`

Edge Function autenticada que pede exclusivamente ao `gpt-5-mini` para
transformar sinais estruturados em, no máximo, um ID de conteúdo previamente
aprovado. Ela não devolve conselho livre, não
escolhe horário de notificação e não lê o conteúdo textual do diário.

O cliente envia somente `requestId` e `trigger`. O backend resolve o paciente,
o check-in do dia, a tendência recente, os tópicos explicitamente confirmados
e as interações com notificações. As consultas não selecionam diário bruto,
alimentação nem sintomas, e esses campos não entram na chamada à OpenAI.

## Antes de implantar

1. Aplique `supabase/migrations/0010_ai_support_backend.sql` e
   `supabase/migrations/0011_ai_support_gpt5_mini_only.sql`.
2. Defina um projeto e uma chave OpenAI exclusivos para cada ambiente, com
   limites de gasto e rotação próprios.
3. Configure os secrets da função; não coloque a chave no `.env` usado pelo
   Flutter e nunca use `--dart-define` para ela.
4. Mantenha staging e produção com `openai_ativa = false` e
   `kill_switch = true` até as aprovações clínica, jurídica, privacidade,
   segurança e regulatória. Nesses estados a função fica em silêncio; ela não
   substitui o modelo por regras.

Secrets necessários para habilitar chamadas ao modelo:

```text
OPENAI_API_KEY=<secret somente do backend>
OPENAI_MODEL=gpt-5-mini
AI_SUPPORT_SAFETY_SALT=<opcional em 100%; recomendado para rollout parcial>
AI_SUPPORT_ENVIRONMENT=staging
AI_SUPPORT_ALLOWED_ORIGINS=https://app-staging.exemplo
OPENAI_TIMEOUT_MS=6000
```

Para desenvolvimento local, copie somente a `OPENAI_API_KEY` do `.env` da raiz
para `supabase/functions/.env` e complete as variáveis mostradas acima. O
arquivo final é ignorado pelo Git. Não passe o `.env` inteiro porque ele pode
conter a URL do projeto remoto e sobrescrever a configuração do Supabase local:

```bash
supabase functions serve ai-support-recommend \
  --env-file supabase/functions/.env
```

Com `AI_SUPPORT_ENVIRONMENT=development`, a função aceita Flutter Web em
`http://localhost` e `http://127.0.0.1` com qualquer porta. Isso evita que a
porta aleatória escolhida por `flutter run -d chrome` quebre o preflight CORS.
Em staging e produção, cada origem continua precisando constar exatamente em
`AI_SUPPORT_ALLOWED_ORIGINS`.

No projeto remoto, use o gerenciador de secrets do Supabase:

```bash
supabase secrets set --env-file supabase/functions/.env
supabase functions deploy ai-support-recommend
```

O inicializador do Flutter continua lendo somente valores publicáveis do
Supabase. A chave OpenAI nunca é encaminhada ao aplicativo.

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
`{"requestId":"...","mode":"limited","status":"silent","proposal":null}`.
Uma indisponibilidade do modelo nunca impede o salvamento do check-in ou
diário; a função fica em silêncio e não usa fallback por regras.

O `proposal` repete apenas o contrato fechado necessário para uma segunda
validação no aplicativo. Ele nunca contém texto gerado. Os templates atualmente
aceitos cobrem check-in difícil/estável/mais leve, sobrecarga, solidão,
autogentileza e uma alternativa após feedback negativo de exercício. O motivo
`PREFERRED_FROM_PAST_INTERACTIONS` só é válido junto de uma evidência atual e
quando a categoria ou o template coincide com uma notificação aberta antes.

## Modos de rollout

- `local`: modo legado; não entrega sugestão no cliente conectado.
- `shadow`: chama somente para a coorte configurada, grava IDs e métricas em
  uma linha invisível ao paciente; a interface permanece sem sugestão.
- `pilot`: usa uma saída validada apenas para pacientes inscritos em
  `participantes_piloto_ia_apoio`.
- `limited`: usa distribuição determinística pelo percentual configurado; o
  restante fica em silêncio.

`kill_switch = true` e `apoio_ativo = false` produzem silêncio. A migration
bloqueia `texto_generativo_ativo`; liberar texto
gerado exige uma avaliação e uma migration separadas.

O campo `mode` da resposta sempre reflete o rollout configurado. Somente
`pilot` e `limited` podem permitir que uma seleção da OpenAI, já validada no
backend e novamente no app, influencie a experiência. Em `local` e `shadow`, o
aplicativo não cria recomendação alternativa.

Exemplo de ativação **somente em staging**, depois de cadastrar
`OPENAI_MODEL=gpt-5-mini` nos secrets:

```sql
update public.rollout_ia_apoio
   set modo = 'shadow',
       openai_ativa = true,
       kill_switch = false,
       percentual_shadow = 100,
       modelo = 'gpt-5-mini',
       atualizado_em = now()
 where ambiente = 'staging';
```

Não altere produção antes dos gates externos. Fases de piloto e produção são
processos clínicos e regulatórios; a presença do código não equivale à sua
aprovação.

## Privacidade e retenção

A chamada usa Responses API com `store: false`, Structured Outputs estritos,
`reasoning.effort = minimal`, limite curto de tokens e nenhum tool. Quando
`AI_SUPPORT_SAFETY_SALT` está
configurado, também envia um `safety_identifier` derivado por HMAC.
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
