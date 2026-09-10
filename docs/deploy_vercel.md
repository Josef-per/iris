# Publicacao da demo na Vercel

## Build local e publicacao

Requer Node.js 24 e Flutter 3.44.8. O inicializador usa o SDK local quando
disponivel ou baixa essa versao. O arquivo `.env` deve conter `SUPABASE_URL`
e `SUPABASE_PUBLISHABLE_KEY` (ou `SUPABASE_ANON_KEY`). Somente os valores
publicos sao encaminhados ao Flutter; chaves administrativas sao rejeitadas.

```sh
bash scripts/build_vercel.sh
npx vercel@59.15.1 login
npx vercel@59.15.1 deploy build/web --prod
```

No primeiro deploy, selecione sua conta e crie o projeto da demo. A pasta
`build/web` contem a configuracao estatica, inclusive as regras para atualizar
paginas internas. Publique somente essa pasta no fluxo local.

Para integrar o repositorio pela Vercel, use Node.js 24, preset `Other` e as
variaveis publicas acima no ambiente de build. O `vercel.json` configura o
comando de build e a saida. `.vercelignore` limita os arquivos enviados pelo
CLI a fontes e recursos necessarios para compilar.

O callback web usa a propria origem da pagina. Um override opcional pode ser
definido em `SUPABASE_AUTH_REDIRECT_URL` antes de compilar, mas deve ser uma
URL HTTPS autorizada no Supabase.

## Login e IA

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
