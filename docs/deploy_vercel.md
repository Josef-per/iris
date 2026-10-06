# Publicacao da demo na Vercel

Endereco atual do aplicativo: https://iris-landingpage.vercel.app
Endereco anterior da demo: https://iris-demo-drab.vercel.app

Projeto Vercel: `iris-demo`, no escopo `nicolas-projects-2450ca53`.
A autorização de cada domínio deve ser conferida no Supabase: a lista de
redirects da autenticação e `AI_SUPPORT_ALLOWED_ORIGINS` são configurações
independentes. Uma origem autorizada no login pode continuar bloqueada na IA.

## Build local e publicacao

Requer Node.js 24 e Flutter 3.44.8. O inicializador usa o SDK local quando
disponivel ou baixa essa versao. O arquivo `.env` deve conter `SUPABASE_URL`
e `SUPABASE_PUBLISHABLE_KEY` (ou `SUPABASE_ANON_KEY`). Somente os valores
publicos sao encaminhados ao Flutter; chaves administrativas sao rejeitadas.

Antes de compilar, adicione ao `.env` da raiz os valores reais disponíveis no
painel do seu projeto Supabase:

```dotenv
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_SUBSTITUA_PELA_CHAVE_REAL
```

Se o `.env` já contiver configurações de IA, preserve essas linhas e acrescente
as duas variáveis. Os valores de `.env.example` são apenas exemplos. Também é
possível usar outro arquivo com `IRIS_ENV_FILE=/caminho/config.env` ou exportar
as variáveis no terminal; as variáveis de ambiente têm prioridade sobre o arquivo.
O login no CLI da Vercel não fornece essas configurações ao build local.

Para conferir a configuração sem compilar:

```sh
node scripts/build_web.mjs --check-config
```

Execute a publicação somente se o build terminar com sucesso:

```sh
IRIS_WEB_ORIGIN=https://iris-landingpage.vercel.app bash scripts/build_vercel.sh &&
npx vercel@59.15.1 login &&
npx vercel@59.15.1 deploy build/web --prod
```

No primeiro deploy, selecione sua conta e crie o projeto da demo. A pasta
`build/web` contem a configuracao estatica, inclusive as regras para atualizar
paginas internas. Publique somente essa pasta no fluxo local.

Para integrar o repositorio pela Vercel, use Node.js 24, preset `Other` e as
variaveis publicas acima no ambiente de build. O `vercel.json` configura o
comando de build e a saida. `.vercelignore` limita os arquivos enviados pelo
CLI a fontes e recursos necessarios para compilar.

Com `IRIS_WEB_ORIGIN`, o build verifica o preflight de `ai-daily-companion` e
`ai-support-recommend` antes de executar o Flutter. Um bloqueio em qualquer
função interrompe o build. Na integração da Vercel em produção, a origem é
obtida automaticamente de `VERCEL_PROJECT_PRODUCTION_URL`; domínios próprios
podem ser definidos explicitamente em `IRIS_WEB_ORIGIN`. Previews precisam de
uma origem explícita para essa verificação. `--check-config` continua sendo
uma validação local das variáveis, sem requisições à rede.

O callback web usa a propria origem da pagina. Um override opcional pode ser
definido em `SUPABASE_AUTH_REDIRECT_URL` antes de compilar, mas deve ser uma
URL HTTPS autorizada no Supabase.

## Login e IA

A raiz `/` apresenta a landing page do TCC e `/app` abre o Flutter. O build
executa `scripts/prepare_landing.mjs` para preservar o shell Flutter em
`app.html`; as rotas internas continuam apontando para esse shell. A landing
encaminha callbacks de autenticação recebidos na raiz, preservando query e
fragmento. O manifesto abre `/app` quando instalado na tela inicial.

A instalação é oferecida pelo navegador quando disponível; nos demais casos,
a página mostra instruções para criar o atalho. Publique com HTTPS. Não há
cache offline de dados clínicos nem link para APK sem um artefato publicado.

Com o dominio definitivo, um token de gerenciamento do Supabase no ambiente
`SUPABASE_ACCESS_TOKEN` ou no arquivo do CLI `~/.supabase/access-token`:

```sh
node scripts/configure_supabase_web.mjs https://seu-projeto.vercel.app
```

O comando atualiza `Site URL`, preserva os callbacks existentes, adiciona o
callback web, localhost:8080 e o callback nativo. Tambem inclui o dominio em
`AI_SUPPORT_ALLOWED_ORIGINS` e verifica o preflight das duas funcoes de IA.

A API retorna apenas o hash dos secrets. Quando isso ocorrer, informe a lista
atual exata em `IRIS_EXISTING_ALLOWED_ORIGINS`; o comando compara o hash antes
de alterar. Uma substituicao deliberada da lista exige `--replace-origins` e
a lista desejada nessa variavel. Nao use essa opcao sem conferir quais outros
enderecos devem continuar funcionando.

A configuracao anterior de autenticacao fica em
`supabase-web-config.local.json`, ignorado pelo Git. Se a lista anterior de
origens estiver indisponivel, somente seu hash sera registrado, e nao sera
possivel restaura-la a partir desse arquivo.

O comando nao altera migrations, chaves OpenAI ou rollout de IA.

### Troca de domínio e falha CORS

O erro `Response to preflight request doesn't pass access control check`
significa que o navegador não consegue enviar o POST para a função. Em
06/10/2026, o domínio `iris-landingpage.vercel.app` retornava HTTP 403 sem
`Access-Control-Allow-Origin`, enquanto `iris-demo-drab.vercel.app` retornava
204 e a função publicada identificava `daily-companion-v11`.

No painel Supabase, abra **Edge Functions → Secrets** e inclua a origem exata
`https://iris-landingpage.vercel.app` em `AI_SUPPORT_ALLOWED_ORIGINS`, separada
por vírgula das origens existentes. Não inclua `/app`, fragmentos ou caminhos.
O Supabase exibe apenas o hash dos secrets salvos: preserve a lista em uma
configuração local protegida antes de substituí-la. O arquivo `.env` local
não atualiza o secret remoto e não deve ser enviado ao frontend.

Para conferir CORS e versão da reflexão sem sessão ou geração:

```sh
node scripts/check_daily_companion_web.mjs https://iris-landingpage.vercel.app
```

Essas verificações não comprovam consentimento, banco nem geração autenticada.
Referência: [CORS nas Edge Functions](https://supabase.com/docs/guides/functions/cors).

## Contas ficticias

```sh
node scripts/prepare_demo.mjs
```

Requer a chave administrativa `SUPABASE_SECRET_KEY` ou `SERVICE_ROLE_KEY`
no `.env` ou no ambiente. Cria paciente e profissional confirmados, aprova
somente o profissional ficticio e resgata um convite usando as sessoes reais.
Inclui diario ficticio, preferencias de IA e plano compartilhado sem
prescricao. Verifica que ambas as contas enxergam o vinculo ativo.

As senhas aleatorias ficam somente em `demo-access.local.json`, com permissao
de leitura/escrita do proprietario e ignorado pelo Git. Preserve esse arquivo
para repetir a verificacao sem criar outras contas. Os emails `.invalid` nao
recebem mensagens; essas contas entram diretamente com email e senha.

Antes da apresentacao, entre com ambas as contas no endereco publicado e
confira o diario, o vinculo e a reflexao. Os dados diarios usam a data local:
no dia seguinte, preencha um novo check-in e diario durante o ensaio.
