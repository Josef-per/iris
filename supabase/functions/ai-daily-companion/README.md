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

## Falha imediata no navegador

Antes de alterar o prompt ou o formato da resposta, reproduza o preflight da
função **publicada**, com a origem que aparece na barra do navegador:

```sh
node scripts/check_daily_companion_web.mjs https://seu-app.exemplo
```

O script lê apenas `SUPABASE_URL` do ambiente ou do `.env` da raiz e não envia
chave, sessão nem conteúdo do diário. Ele verifica o status HTTP, a origem,
o método POST e os cabeçalhos usados pelo cliente Supabase.

`403 ORIGIN_NOT_ALLOWED`, ou a ausência de `Access-Control-Allow-Origin`, impede
o navegador de enviar o POST. Nesse caso, preencher o diário ou alterar o prompt
não resolve: a chamada não chega à autenticação nem ao modelo.

Inclua a origem exata (protocolo, domínio e porta, sem caminho) em
`AI_SUPPORT_ALLOWED_ORIGINS` nos secrets do projeto Supabase, preservando as
outras origens da lista. URLs encaminhadas do Codespaces também precisam dessa
configuração explícita, mesmo em development. Somente origens HTTP de loopback
(`localhost`, `127.0.0.1` e `[::1]`) são liberadas automaticamente nesse ambiente.
Não libere todos os domínios `*.app.github.dev`.

Cada variável do arquivo de configuração deve ocupar sua própria linha:

```dotenv
AI_SUPPORT_ALLOWED_ORIGINS=https://seu-app.exemplo
OPENAI_TIMEOUT_MS=6000
```

`OPENAI_TIMEOUT_MS` pertence ao recomendador de apoio; não configura o timeout
da reflexão diária. Um valor como `AI_SUPPORT_ALLOWED_ORIGINS=OPENAI_TIMEOUT_MS=6000`
é inválido. Editar o `.env` local ou compilar novamente o Flutter não atualiza os
secrets da função remota. Após atualizar o secret, repita o teste acima e
recarregue o aplicativo autenticado. CORS aprovado, por si só, não comprova
que a sessão e a geração funcionam.
