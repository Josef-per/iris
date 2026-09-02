# Reflexão diária da Íris

Esta Edge Function cria uma reflexão curta para a Home apenas depois de
validar o usuário, o paciente, a personalização e cada fonte consentida no
servidor. O aplicativo envia um objeto vazio: textos e sinais nunca trafegam
do cliente para a função.

O texto livre é limitado a 1.800 caracteres, não é registrado em logs e a
chamada à OpenAI usa `store: false`. A resposta é JSON validado e expira em
36 horas. Editar/apagar o diário, revogar `diary_text` ou excluir os dados de
apoio remove as mensagens derivadas.

## Deploy

```sh
supabase functions deploy ai-daily-companion
```

O `config.toml` deixa a validação de JWT no handler porque ele valida o Bearer
token usando `auth.getUser`. A função requer as mesmas variáveis da função de
sugestões: `OPENAI_API_KEY`, `SUPABASE_URL`, uma chave publishable, uma chave
de serviço, `AI_SUPPORT_ENVIRONMENT` e `AI_SUPPORT_SAFETY_SALT`.
