# Reflexão diária da Íris

Esta Edge Function cria uma reflexão curta para a Home apenas depois de
validar o usuário, o paciente, a personalização e cada fonte consentida no
servidor. O aplicativo envia um objeto vazio: textos e sinais nunca trafegam
do cliente para a função.

A reflexão acolhe o relato atual em um parágrafo curto, geralmente de duas
frases. Fala diretamente com a pessoa, sem avaliar como ela escreveu, repetir
o sentimento em vários tópicos ou inventar suas causas. Um desabafo sobre
cansaço ou ansiedade pode receber somente acolhimento, sem tarefas. Um dia bom
recebe duas ou três frases curtas: o reconhecimento da alegria e um fechamento
caloroso, ligado ao que fez bem, sem tarefa, cobrança, pergunta ou problema a
resolver. Em um relato feliz com amigos, por exemplo, ela pode desejar que essas
boas amizades continuem rendendo momentos assim. Uma perspectiva prática é
opcional e depende de uma necessidade concreta de escolha ou organização,
além de acrescentar algo ao acolhimento. Ela não recomenda exercícios, técnicas guiadas, rotinas
ou sequências de passos. Também não prescreve afastamento, redução de contato,
confronto ou ruptura de relações, preservando autonomia e acesso a apoio.

O diário de hoje orienta a resposta. O check-in é um sinal separado; os temas
confirmados anteriormente chegam ao modelo como `backgroundTopics` e não
comprovam sentimentos atuais. Solidão ou sobrecarga no histórico não devem
transformar um relato feliz com amigos em cansaço ou mal-estar. Sentimentos
mistos e dificuldades explícitas continuam sendo reconhecidos.

Os exemplos abaixo são critérios editoriais para revisão; não são respostas
fixas inseridas pelo aplicativo nem resultados de uma avaliação com o modelo real.

| Tipo de relato | Exemplo de entrada | Comportamento esperado |
| --- | --- | --- |
| Positivo | “Saí de bicicleta com meus amigos, foi muito bom.” | Reconhecer a alegria e encerrar com uma frase calorosa ligada ao passeio ou às amizades. |
| Desabafo difícil | “Estou me sentindo muito cansada, ansiosa sobre o trabalho...” | Acolher em um parágrafo, sem presumir pressão profissional ou exigir um ajuste prático. |
| Misto | “Foi bom rever meus amigos, mas voltei triste.” | Reconhecer os dois sentimentos, sem impor otimismo nem incentivar automaticamente a repetição. |
| Cotidiano | “Fui ao mercado e arrumei a casa.” | Responder com leveza, sem atribuir felicidade, solidão ou uma conquista. |
| Vago ou irônico | “Sei lá, hoje foi estranho.” / “Que maravilha de dia...” | Respeitar a ambiguidade, sem completar a história ou interrogar. |
| Negação ou passado | “Não fiquei ansiosa hoje, como na semana passada.” | Respeitar a negação e distinguir o sentimento passado do atual. |
| Conflito | “Fiquei com raiva depois da discussão com minha irmã.” | Acolher a emoção sem tomar partido, atribuir intenções ou prescrever afastamento. |
| Perda ou saudade | “Senti muita falta da minha avó hoje.” | Acolher a saudade sem presumir falecimento, buscar um lado positivo ou dar prazo para superar. |
| Culpa ou alimentação | “Fiquei com culpa depois de comer.” | Acolher o desconforto sem julgamento alimentar, restrição, compensação ou conselho de dieta. |

Para o desabafo sobre trabalho, um exemplo de tom é: “Estar tão cansada e
ansiosa com o trabalho parece estar pesando hoje. Você merece acolhimento
também nos dias difíceis, sem precisar resolver tudo de uma vez.”

O campo `message` usa Markdown restrito: um parágrafo, opcionalmente seguido
de um ou dois itens com ênfase em negrito. O modelo retorna `points: []` quando
o parágrafo já basta. O servidor rejeita cabeçalhos, links, imagens, citações,
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
O prompt `daily-companion-v8` renova o cache para aplicar o acolhimento natural
a diferentes relatos, preservando o fechamento caloroso dos positivos.
O servidor revalida cada parágrafo e item do cache antes de reutilizá-lo;
um registro cortado é descartado e passa pela geração normal. O aplicativo
também rejeita trechos sem pontuação final ou com reticências, inclusive quando
recebidos de uma função antiga, sem completar ou cortar frases por conta própria.

## Deploy

Aplicar a migration `0014_daily_companion_complete_text.sql` antes de publicar
a função e distribuir o aplicativo atualizado. Ela amplia o limite do texto e
adiciona a versão do contrato ao cache; reflexões antigas serão regeneradas.
A correção atual não requer outra migration quando a `0014` já está aplicada.

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
o método POST e os cabeçalhos usados pelo cliente Supabase. Depois consulta
`functionVersion` com GET, que retorna `405 METHOD_NOT_ALLOWED` antes de
autenticar ou gerar conteúdo, e compara com a versão do código local. CORS
aprovado com função desatualizada também faz o comando falhar.

Na investigação de 10/09/2026, o ambiente remoto ainda estava em
`daily-companion-v5`, enquanto o aplicativo acompanhava o contrato `v8`.
A tabela remota também continuava com limite de 480 caracteres e sem
`versao_prompt`: a migration `0014` ainda não tinha sido aplicada. O aplicativo
passou a rejeitar trechos incompletos que a função antiga ainda podia devolver.

Nesse caso, aplicar somente a migration `0014_daily_companion_complete_text.sql`
e publicar `ai-daily-companion`, nessa ordem. Conferir no banco a coluna
`versao_prompt` e o limite de 1.200 caracteres; então repetir o diagnóstico
acima. O script não verifica o banco nem comprova geração autenticada.
Não é necessário mudar autenticação, consentimentos, CORS ou outras funções.

A atualização foi concluída nessa investigação: a função publicada passou
a responder `daily-companion-v8`, e as consultas de estrutura confirmaram a
coluna de versão e o limite de 1.200 caracteres. O diagnóstico passou para
localhost:8080 e para o domínio da demo. Essas verificações não acessaram
diários nem executaram geração autenticada.

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

As respostas identificam a versão em `functionVersion` (`daily-companion-v10`).
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
