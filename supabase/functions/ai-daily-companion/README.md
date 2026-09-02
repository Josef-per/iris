# Reflexão diária da Íris

Esta Edge Function cria uma reflexão curta para a Home apenas depois de
validar o usuário, o paciente, a personalização e cada fonte consentida no
servidor. O aplicativo envia um objeto vazio: textos e sinais nunca trafegam
do cliente para a função.

A reflexão é uma orientação personalizada de uma ou duas frases, formulada
como possibilidade. Ela não recomenda exercícios, técnicas guiadas, rotinas ou
sequências de passos. Também não prescreve afastamento, redução de contato,
confronto ou ruptura de relações; situações relacionais recebem apenas uma
forma de organizar a decisão, preservando autonomia e acesso a apoio.

O campo `message` usa Markdown restrito: um parágrafo e um ou dois itens com
ênfase em negrito. O servidor rejeita cabeçalhos, links, imagens, citações,
código, HTML e listas numeradas. O aplicativo renderiza apenas parágrafos,
negrito e listas, sem abrir links nem interpretar conteúdo arbitrário.

Quando o diário autorizado contém linguagem explícita de
suicídio ou autoagressão, a geração é interrompida e o aplicativo apresenta a
rota de apoio humano. Esse bloqueio não constitui avaliação clínica de risco.

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
