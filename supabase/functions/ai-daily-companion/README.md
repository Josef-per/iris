# Reflexão diária da Íris

Esta Edge Function cria uma reflexão curta para a Home apenas depois de
validar o usuário, o paciente, a personalização e cada fonte consentida no
servidor. O aplicativo envia um objeto vazio: textos e sinais nunca trafegam
do cliente para a função.

A reflexão é uma orientação personalizada breve, formulada
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
rota de apoio humano. O modelo também pode sinalizar `needsHumanSupport`;
nesse caso, nenhum texto gerado é exibido ou salvo como reflexão. O cartão
mostra apenas “Encontrar apoio agora”, sem “Ler reflexão”. Esse bloqueio não
constitui avaliação clínica de risco.

O texto livre é limitado a 1.800 caracteres, não é registrado em logs e a
chamada à OpenAI usa `store: false`. A resposta é JSON validado e expira em
36 horas. Editar/apagar o diário, revogar `diary_text` ou excluir os dados de
apoio remove as mensagens derivadas.

A introdução comporta até 300 caracteres e cada item até 360, com limite total
de 1.200 caracteres no servidor, banco e aplicativo. Frases sem pontuação final
ou terminadas em reticências são rejeitadas e podem gerar uma nova tentativa;
a função não corta nem completa o texto recebido. Isso detecta finais visivelmente
incompletos, mas não garante a completude semântica de toda frase.
O cache só é reutilizado quando `versao_prompt` corresponde ao contrato atual.

## Deploy

Aplicar a migration `0014_daily_companion_complete_text.sql` antes de publicar
a função e distribuir o aplicativo atualizado. Ela amplia o limite do texto e
adiciona a versão do contrato ao cache; reflexões antigas serão regeneradas.

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

## Atualização após diário e check-in

Na investigação de 08/09/2026, a função publicada ainda usava um schema sem
`minLength`, `maxLength`, `minItems` e `maxItems`, embora o validador local já
exigisse esses limites. A cópia publicada foi comparada com o repositório e
atualizada. Após o deploy, a sequência diário → humor estável → mudança de
humor retornou `ready` nas três etapas com conta fictícia.

Alterar o humor invalida a reflexão anterior (migration `0013`). A função faz
até duas tentativas para recuperar falhas transitórias ou uma resposta fora
do formato; cada chamada ao modelo tem limite de 8 segundos. O cliente aguarda
até 30 segundos, incluindo autenticação, contexto e persistência. Recusas
explícitas, erro de autenticação e limite de uso do modelo não são repetidos.
Uma reflexão invalidada nunca é reapresentada como resultado novo.

As respostas identificam a versão em `functionVersion` (`daily-companion-v6`).
Falhas de geração também retornam `reasonCode`, sem diário, prompt ou resposta
bruta: `model_timeout`, `model_output_invalid`, `model_incomplete`,
`model_refusal`, `model_rate_limited`, `model_http_error`,
`model_request_failed` ou `model_secret_missing`. Isso permite diferenciar
falha técnica e versão desatualizada sem expor conteúdo pessoal.

Teste de regressão do handler e da geração, com fronteiras simuladas:

```sh
node supabase/functions/ai-daily-companion/generation_test.ts
```

Atualizar o Flutter não publica esta função: é necessário executar o deploy
indicado acima. Para validar a atualização, testar diário → check-in → alteração
de humor com conta fictícia e conferir `functionVersion` na resposta.
