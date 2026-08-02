# Íris

Aplicação Flutter para acompanhamento entre pacientes com transtornos
alimentares e seus profissionais de saúde. O mesmo projeto atende web,
desktop e mobile.

O projeto foi desenvolvido como TCC do curso de Desenvolvimento de Sistemas
da ETEC Dr. Julio Cardoso.

## Estado dos dados

A área profissional possui dois modos:

- a prévia de design usa dados fictícios, sem persistência;
- uma sessão autenticada com Supabase configurado usa somente dados reais do
  banco e apresenta estados de carregamento, erro e lista vazia.

Dados exibidos na prévia não representam pacientes reais. No modo conectado,
pacientes são adicionados por um convite QR; o profissional não cria uma
identidade de paciente manualmente.

## Funcionalidades

### Paciente

- autenticação e cadastro;
- diário emocional e registros alimentares;
- leitura ou digitação de convite QR;
- confirmação e vínculo com o profissional.

### Profissional

- dashboard e agenda;
- gerenciamento de pacientes ativos e inativos;
- anotações clínicas;
- plano de cuidado, metas e medicações;
- perfil, clínica e preferências de notificação;
- convite QR temporário para vínculo.

## Tecnologias

- Flutter e Dart;
- Supabase Auth;
- PostgreSQL, Row Level Security e RPCs do Supabase;
- `qr_flutter` e `mobile_scanner`.

## Configuração do Supabase

As migrations estão em `supabase/migrations` e devem ser aplicadas na ordem:

1. `0001_core_schema.sql`;
2. `0005_patient_professional_link_rls.sql`;
3. `0006_professional_backend.sql`.

Com o projeto Supabase vinculado pelo CLI:

```bash
supabase db push
```

Também é possível aplicar os arquivos nessa ordem pelo SQL Editor. A migration
`0006` cria consultas, anotações, planos de cuidado, convites e as RPCs usadas
pelo aplicativo.

Novos profissionais começam com `credenciamento_status = 'pendente'`. Depois
de validar especialidade e registro, um administrador pode aprovar pelo SQL
Editor:

```sql
select public.iris_set_professional_credential_status(
  (
    select profissional.id
    from public.profissionais profissional
    join public.usuarios usuario on usuario.id = profissional.user_id
    where lower(usuario.email) = lower('profissional@exemplo.com')
  ),
  'ativo'
);
```

Essa RPC é restrita ao papel `service_role`; usuários autenticados não podem
aprovar a própria conta nem alterar seu papel em `usuarios`.

## Executar o aplicativo

Instale as dependências:

```bash
flutter pub get
```

O arquivo `.env` não é carregado como asset, pois ele pode conter credenciais
administrativas. Para desenvolvimento, use o inicializador seguro do projeto:

```bash
./scripts/flutter_run.sh
```

Ele lê somente `SUPABASE_URL` e `SUPABASE_PUBLISHABLE_KEY` (ou a chave
`SUPABASE_ANON_KEY` legada) do `.env`. Qualquer chave secreta presente no
arquivo é ignorada e nunca é encaminhada ao aplicativo. Argumentos adicionais
do Flutter podem ser informados normalmente, por exemplo:

```bash
./scripts/flutter_run.sh -d chrome
```

Em ambientes sem interface gráfica, como GitHub Codespaces, o inicializador
seleciona automaticamente o dispositivo `web-server`, publica em `0.0.0.0` e
usa a porta `8080`. Nesse caso, o modo `release` é usado por padrão para evitar
o carregamento lento dos centenas de módulos separados do modo debug pelo
proxy. Abra essa porta pelo encaminhamento do ambiente. Para usar outra porta:

```bash
IRIS_WEB_PORT=3000 ./scripts/flutter_run.sh
```

Uma escolha explícita de dispositivo continua sendo respeitada com `-d`.
Para diagnosticar especificamente a versão web, ainda é possível solicitar
`--debug` de forma explícita.

Em builds automatizados, passe apenas a URL e a chave publicável do Supabase
diretamente ao Flutter:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://seu-projeto.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sua-chave-publicavel
```

Instalações antigas também podem usar `SUPABASE_ANON_KEY` no lugar de
`SUPABASE_PUBLISHABLE_KEY`.

`--dart-define` faz parte do aplicativo compilado e não é um cofre de segredos.
Por isso, nunca passe `SERVICE_ROLE_KEY`, `SUPABASE_SECRET_KEY`, senha de banco
ou outra chave privada dessa forma.

## Segredos usados por scripts

Scripts administrativos podem ler um arquivo local `.env.server`:

```dotenv
SUPABASE_URL=https://seu-projeto.supabase.co
SERVICE_ROLE_KEY=sua-chave-de-servidor
```

O arquivo `.env.server` é ignorado pelo Git e deve existir apenas no ambiente
administrativo. Ele não pode ser incluído em assets, código Flutter, build web
ou aplicativo distribuído.

Se uma chave `service_role` ou secret já tiver sido incluída em um asset ou
build, removê-la do repositório não basta: revogue/rotacione a chave no painel
do Supabase e gere novos builds.

## Segurança do convite QR

O QR não contém o UUID permanente do profissional. O fluxo é:

1. um profissional aprovado solicita um convite;
2. o servidor gera um token aleatório de 256 bits, com prazo e limite de usos;
3. somente o hash SHA-256 é persistido;
4. o paciente autenticado visualiza o nome do profissional e confirma;
5. o resgate ocorre de forma atômica e cria ou reativa o vínculo;
6. ao trocar de profissional, a autorização anterior é revogada.

Enquanto o convite estiver aberto, o profissional também pode revogá-lo
manualmente antes da expiração.

O payload aceito pelo aplicativo segue o formato:

```text
iris://vincular/profissional?v=1&token=<64-caracteres-hexadecimais>
```

O status de acompanhamento (`ativo` ou `inativo`) é separado da autorização
(`ativo` ou `revogado`). Assim, o profissional ainda gerencia a identificação
de um paciente inativo autorizado, mas os registros clínicos só ficam
disponíveis durante acompanhamento ativo.

## Validação

Execute análise e testes antes de publicar:

```bash
flutter analyze
flutter test
flutter build web \
  --dart-define=SUPABASE_URL=https://seu-projeto.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sua-chave-publicavel
./scripts/check_client_bundle.sh build/web
./scripts/test_supabase_migrations.sh
```

O teste de exposição de segredos verifica que `.env` não é asset nem arquivo
do build e que identificadores de chave administrativa não aparecem no código
do cliente.

## Licença

Projeto desenvolvido para fins acadêmicos.
