# Anotações de estudo — como o código do Íris funciona

Estas anotações explicam a implementação do repositório para a apresentação à banca. Os trechos destacados são recortes do código; quando houver simplificação, ela estará identificada. Não é necessário decorar cada arquivo: procure conseguir acompanhar uma ação do usuário até sua persistência no banco.

## Arquitetura do sistema

### Como classificar a arquitetura do Íris

O Íris usa uma **arquitetura cliente-servidor**, com um aplicativo Flutter consumindo serviços de backend do Supabase e funções de servidor para os recursos de IA.

O **Supabase funciona como Backend as a Service (BaaS)**: fornece autenticação, APIs de acesso aos dados, PostgreSQL e armazenamento de arquivos. Sobre essa infraestrutura, o projeto implementa suas próprias tabelas, políticas de acesso, funções SQL e Edge Functions.

As **Edge Functions seguem o modelo serverless**: o projeto publica funções no ambiente gerenciado do Supabase, sem precisar manter uma aplicação de servidor dedicada para cada integração com IA. Isso continua sendo backend e envolve configuração, limites, custos e manutenção.

Dentro do aplicativo, há separação entre interface, estado, acesso aos dados e modelos, com organização por funcionalidades em `lib/features`. Essa descrição representa o código atual. Não há necessidade de classificá-lo como uma implementação integral de MVC, MVVM ou Clean Architecture, nem como um conjunto de microsserviços independentes.

### 1. Visão dos componentes

**Aplicativo Flutter — onde o usuário interage.** Contém os fluxos de paciente e profissional, formulários, navegação, estado da interface e repositórios. As áreas de paciente e profissional são partes da mesma aplicação; o papel da conta e as permissões determinam o acesso. As notificações locais de apoio usam recursos do aparelho em Android/iOS.

**Supabase Auth — identidade e sessão.** Autentica a conta e fornece a sessão utilizada nas chamadas ao backend. `AuthService`, `AuthGate` e `SessionGate` conectam essa identidade aos perfis e à navegação da aplicação. A sessão identifica o usuário; as regras de acesso determinam quais dados ele pode usar.

**API de dados e PostgreSQL — persistência e regras.** Os repositórios fazem consultas e gravações pela API do Supabase. O banco armazena dados relacionais, aplica RLS, chaves estrangeiras e constraints e executa funções SQL chamadas por RPC. O aplicativo não recebe uma conexão administrativa direta ao PostgreSQL.

**Supabase Storage — arquivos.** Armazena as fotos dos registros alimentares. O banco mantém o caminho associado ao registro, enquanto os bytes ficam no serviço de armazenamento. Gravação no banco e upload são operações distintas e podem ter falhas parciais.

**Edge Functions — integração e processamento no servidor.** Recebem requisições autenticadas, verificam as condições da funcionalidade, consultam o contexto autorizado e chamam a OpenAI. `ai-support-recommend` seleciona conteúdo de um catálogo; `ai-daily-companion` gera a reflexão diária dentro do contrato previsto.

**OpenAI — fornecedor externo de IA.** Recebe da função o contexto permitido para a tarefa. Sua resposta é validada antes de influenciar a experiência. A chave de acesso ao modelo fica no backend.

Fontes: [entrada do app](../lib/main.dart), [autenticação](../lib/features/auth/auth_service.dart), [banco e regras](../supabase/migrations), [fotos](../lib/features/food/food_record_repository.dart) e [funções de IA](../supabase/functions).

### 2. Camadas lógicas dentro da aplicação

As camadas abaixo descrevem responsabilidades; não significam que cada uma tenha seu próprio servidor ou processo.

1. **Apresentação:** telas e widgets recebem ações e exibem resultados. Exemplos: `HomeScreen` e `CheckInDiarioBottomSheet`.
2. **Estado e coordenação:** estado local e stores acompanham carregamento, dados disponíveis, navegação e operações. Exemplos: `ProfessionalFrontendStore` e `MockAiSupportStore` configurada no modo conectado.
3. **Serviços e acesso aos dados:** repositórios e adaptadores encapsulam chamadas ao Supabase e validam entradas/saídas conforme o fluxo. Exemplos: `EmotionalDiaryRepository`, `PatientCarePlanRepository` e `SupabaseProfessionalWorkspaceBackend`.
4. **Modelos e contratos:** objetos e interfaces descrevem dados e operações esperadas. Exemplos: `FoodRecord`, `PatientTodaySummary`, `EmotionalDiaryDataSource` e `ProfessionalWorkspaceBackend`.

Na área profissional, a tela usa uma store, que delega ao contrato de backend. No check-in, o formulário chama diretamente o contrato do repositório. Portanto, **nem toda ação passa obrigatoriamente por uma store**.

As regras também têm locais diferentes: a tela valida campos para orientar o usuário, o repositório prepara a operação e o banco aplica as condições que precisam valer mesmo fora da interface. As funções de IA acrescentam verificações específicas no servidor.

### 3. Como os componentes se comunicam

**Fluxo de registro clínico:**

1. O usuário preenche o formulário Flutter.
2. O repositório usa o SDK do Supabase para fazer a requisição autenticada à API de dados ou a uma RPC.
3. O backend verifica o acesso e o PostgreSQL executa a operação e suas regras.
4. O resultado retorna ao repositório e à interface, que atualiza seu estado ou apresenta um erro.

**Fluxo de IA:**

1. O aplicativo chama uma Edge Function com a sessão do usuário.
2. A função verifica identidade, paciente, consentimentos e liberação da funcionalidade.
3. O backend consulta o contexto autorizado no Supabase.
4. A função chama a API da OpenAI, recebe e valida o resultado.
5. Conforme o fluxo, persiste o resultado e devolve uma resposta controlada; o aplicativo também verifica o contrato recebido.

**Fluxo de foto:** o repositório coordena o registro no PostgreSQL e o envio do arquivo ao Storage, associando o caminho ao registro.

**Ponto importante para a banca:** as Edge Functions de IA não são uma passagem obrigatória de todos os dados. Registros, consultas e vínculos também usam a API de dados e RPCs do Supabase. O acesso do cliente a essa API faz parte da arquitetura e precisa estar protegido no banco.

### 4. Fronteiras de confiança e segurança

O **aplicativo é distribuído ao usuário**. Por isso, esconder campos, bloquear botões ou colocar um valor no build não cria uma proteção de servidor. As requisições podem ser reproduzidas fora da interface.

Na **API de dados**, a sessão identifica quem está chamando e as políticas RLS restringem as linhas acessíveis. Nas **RPCs**, as validações internas e permissões de execução protegem operações como resgate de convite e atualização do registro diário.

Nas **Edge Functions**, a identidade e as condições de uso precisam ser verificadas antes das consultas privilegiadas. A reflexão diária, por exemplo, valida a sessão e resolve o paciente antes de consultar o contexto com um cliente administrativo. Como esse cliente tem privilégios elevados, as verificações da função são parte essencial da autorização.

Ao chamar a **OpenAI**, o contexto cruza a fronteira para outro fornecedor. O recomendador não envia texto livre do diário; a reflexão pode enviá-lo com consentimento específico. Chave publicável do Supabase, segredo administrativo e chave da OpenAI têm permissões e locais de uso diferentes.

Fontes: [políticas e RPCs](../supabase/migrations/0006_professional_backend.sql), [handler da reflexão](../supabase/functions/ai-daily-companion/index.ts) e [contrato do recomendador](../supabase/functions/ai-support-recommend/README.md).

### 5. Arquitetura de publicação

Na configuração web do repositório, a **Vercel hospeda os arquivos compilados** da landing page e do Flutter Web. O navegador baixa esses arquivos e executa o cliente. A publicação apresenta a landing em `/` e o aplicativo em `/app`.

O **Supabase hospeda os serviços de backend**: autenticação, PostgreSQL, Storage e Edge Functions. A **OpenAI executa o modelo externo** chamado pelas funções. Publicar os arquivos web na Vercel não publica automaticamente as migrations nem as funções do Supabase.

Nos alvos mobile e desktop, o cliente é compilado para a plataforma e continua consumindo os serviços remotos configurados. Ter esses alvos no projeto não comprova distribuição ou homologação em todos eles.

Existem, portanto, entregas separadas: **cliente**, **estrutura/regras do banco** e **funções de servidor**. Elas precisam manter contratos compatíveis. Uma versão nova do aplicativo pode falhar se chamar uma RPC que ainda não foi instalada no ambiente.

Fontes: [configuração Vercel](../vercel.json), [build web](../scripts/build_web.mjs), [orientações de publicação](deploy_vercel.md) e [migrations](../supabase/migrations).

### 6. Decisões arquiteturais e suas consequências

- **Flutter compartilhado entre plataformas:** permite reaproveitar interface e lógica, mas integrações com câmera, notificações e navegação precisam de verificação em cada plataforma.
- **Supabase como BaaS:** reduz a infraestrutura que a equipe precisa construir e operar, mas exige políticas de acesso corretas e cria dependência dos serviços e limites do fornecedor.
- **Regras críticas no banco:** protegem integridade e autorização mesmo quando a interface é contornada, mas tornam migrations e testes SQL parte importante da manutenção.
- **Interfaces e dependências por construtor:** facilitam testar e substituir implementações, sem remover o acoplamento ao Supabase de todos os arquivos; o SDK ainda aparece em partes do código da aplicação.
- **IA em funções de servidor:** mantém segredos fora do cliente e concentra o controle do contexto, mas acrescenta latência, custo e uma dependência externa que pode falhar.
- **Consultas e atualizações explícitas:** permitem recarregar os dados após operações. Isso não representa sincronização offline nem atualização automática de todos os dispositivos por Realtime.

### 7. Resposta pronta para “qual é a arquitetura do sistema?”

> O Íris usa uma arquitetura cliente-servidor. O cliente é feito em Flutter e organizado por funcionalidades, com telas, estado, modelos e repositórios. O backend utiliza o Supabase como serviço, com autenticação, PostgreSQL, Storage e regras de acesso no banco. Operações de negócio também usam funções SQL por RPC. A integração com IA passa por Edge Functions que verificam o contexto autorizado e chamam a OpenAI. Na web, a Vercel entrega os arquivos do cliente, enquanto os serviços de backend permanecem no Supabase.

## 1. Visão geral: quem faz o quê no código

| Parte | Responsabilidade | Exemplo real |
|---|---|---|
| Tela ou widget | Exibir informações, receber ações e mostrar carregamento, sucesso ou erro. | `CheckInDiarioBottomSheet` |
| Modelo | Representar os dados usados pela aplicação. | `PatientTodaySummary`, `FoodRecord` |
| Repositório | Encapsular consultas e gravações, além de validações relacionadas à operação. | `EmotionalDiaryRepository` |
| Serviço | Concentrar operações de uma responsabilidade, como autenticação. | `AuthService` |
| Store | Manter o estado de uma área e avisar à interface quando ele muda. | `ProfessionalFrontendStore` |
| Banco e RPCs | Persistir dados, aplicar integridade e executar operações de negócio no servidor. | `iris_upsert_daily_emotional_record` |
| Edge Function | Executar código no servidor, validar contexto e integrar a IA. | `ai-daily-companion` |

**Para explicar:** a interface recebe a ação; repositórios e serviços conversam com o backend; o banco confirma a operação; a interface atualiza o que mostra.

Isso é uma separação de responsabilidades. O projeto combina organização por funcionalidade e pastas compartilhadas; não precisa ser apresentado como uma implementação integral de MVC ou Clean Architecture.

## 2. Como encontrar as partes do projeto

- `lib/main.dart`: entrada do aplicativo, inicialização e observação da autenticação.
- `lib/screens/`: telas principais e decisões sobre qual área abrir.
- `lib/features/`: código agrupado por funcionalidade, como diário, alimentação, vínculo, plano e apoio com IA.
- `lib/widgets/`: componentes reutilizáveis e formulários apresentados em painéis modais.
- `lib/core/`: configuração, navegação, temas, mensagens de erro, datas e processamento do QR.
- `supabase/migrations/`: estrutura, funções, políticas e alterações versionadas do banco.
- `supabase/functions/`: funções TypeScript executadas no servidor.
- `test/`: testes Dart/Flutter; `supabase/tests/`: testes SQL.
- `scripts/`: ferramentas de execução, build, publicação e verificação.

**Atenção:** as pastas `lib/models` e `lib/controllers` contêm anotações, mas os modelos e a lógica efetivamente usados estão distribuídos nas funcionalidades. Explique a organização que o código usa hoje.

## 3. Inicialização: o que acontece ao abrir o aplicativo

Fonte: [main.dart](../lib/main.dart).

O método `main()`:

1. Chama `WidgetsFlutterBinding.ensureInitialized()` para preparar os serviços do Flutter antes da inicialização assíncrona.
2. Confere `SupabaseConfig.isConfigured`.
3. Inicia o Supabase quando há URL e chave publicável.
4. Ativa `AuthRecoveryReplay` para preservar um possível evento de recuperação de senha recebido durante a abertura.
5. Aguarda a inicialização e chama `runApp(const IrisApp())`.

`IrisApp` monta o `MaterialApp.router`, configura os temas claro/escuro e conecta o controlador de navegação. Um `ValueListenableBuilder` observa a preferência de tema e reconstrói essa parte da interface quando ela muda.

**Por que o Supabase vem antes de `runApp`?** Para que os componentes que dependem do cliente possam usá-lo depois da inicialização.

**Sem configuração:** a abertura direciona para o login, mas os fluxos de autenticação conectada ficam indisponíveis. A ausência do backend não é substituída por um login fictício.

## 4. Autenticação: como o código decide qual tela abrir

Fontes: [AuthService](../lib/features/auth/auth_service.dart), [SessionGate](../lib/screens/session_gate.dart) e [UserRepository](../lib/features/users/user_repository.dart).

Há decisões diferentes ao longo da entrada:

1. **`AuthGate`, em `main.dart`:** observa a sessão e os eventos do Supabase Auth. Sem sessão, mostra login; com recuperação de senha, abre a troca de senha; com sessão autenticada, abre `SessionGate`.
2. **`SessionGate`:** consulta o papel da conta no backend e direciona para paciente ou profissional.
3. **`PatientSessionGate`:** verifica o vínculo e monta a navegação do paciente; também prepara os serviços opcionais de apoio.

### O método `AuthService.signIn()`

- Normaliza o e-mail com `trim().toLowerCase()`.
- Chama `signInWithPassword()` do Supabase Auth.
- Usa `UserRepository.ensureSessionForAuthUser()` para preparar e validar o perfil da aplicação.
- Consulta o papel real com `getCurrentUserType()`.
- Compara esse papel com o perfil escolhido na tela de login.
- Se houver divergência, encerra a sessão e lança `AccountTypeMismatchException`.

**Para explicar:** selecionar “Sou profissional” não transforma uma conta de paciente em profissional. A seleção é comparada com o papel persistido no banco.

`profileValidationInProgress` é um `ValueNotifier<bool>`: informa ao fluxo de autenticação que o perfil ainda está sendo validado, para evitar abrir a área antes dessa verificação.

### O que significa bootstrap do usuário

`UserRepository` chama a RPC `iris_bootstrap_current_user`. Ela prepara/valida os registros da aplicação relacionados à identidade autenticada. O identificador de `auth.users` não deve ser confundido com o `id` da tabela `pacientes`: os repositórios resolvem essa relação por `user_id`.

O uso inicial de metadados no bootstrap não autoriza uma conta existente a trocar livremente seu papel; as regras do servidor continuam necessárias.

## 5. Configuração e acesso ao Supabase

Fontes: [SupabaseConfig](../lib/core/supabase/supabase_config.dart) e [SupabaseClientProvider](../lib/core/supabase/supabase_client_provider.dart).

`SupabaseConfig` lê valores definidos no build com `String.fromEnvironment`, como `SUPABASE_URL` e `SUPABASE_PUBLISHABLE_KEY`. Há compatibilidade com `SUPABASE_ANON_KEY`.

`SupabaseClientProvider.client` centraliza o acesso ao cliente inicializado. Se a configuração estiver ausente, lança `SupabaseConfigException`.

**Por que centralizar?** Os repositórios reutilizam a mesma forma de obter o cliente e o tratamento da ausência de configuração fica consistente.

**Ponto de segurança:** `--dart-define` faz parte do aplicativo compilado. Serve para a URL e a chave publicável, não para esconder chaves administrativas ou da OpenAI.

## 6. Exemplo completo: salvar o check-in

Fontes: [formulário do check-in](../lib/widgets/bottom_sheets/check_in_diario_bottom_sheet.dart), [repositório emocional](../lib/features/emotional_diary/emotional_diary_repository.dart) e [HomeScreen](../lib/screens/home_screen.dart).

### 6.1. A tela mantém o preenchimento em memória

`CheckInDiarioBottomSheet` é um `StatefulWidget`. Seu estado guarda:

- `selectedMood` e `selectedFood`: opções selecionadas;
- `mentalSymptoms` e `physicalSymptoms`: conjuntos de sintomas;
- `_isLoading`: uma gravação está em andamento;
- `_isLoadingTodayRecord`: o registro atual ainda está sendo carregado;
- mensagens de falha de leitura e gravação.

Ao abrir, `_loadTodayRecord()` consulta o registro existente e preenche os campos. Isso permite editar o check-in do mesmo dia.

### 6.2. A tela converte a seleção em valor de negócio

A interface ordena as opções do melhor estado para o mais difícil, usando índices de 0 a 4. O banco usa notas de 5 a 1:

```dart
int _selectorIndexToScore(int index) => 5 - index;
```

Exemplos: índice `0` vira nota `5` (“Muito feliz”); índice `4` vira nota `1` (“Muito difícil”). O índice visual e a nota persistida são coisas diferentes.

### 6.3. `_submit()` valida e chama o repositório

O método impede novo envio durante carregamentos, exige as duas seleções e chama:

```dart
await _repository.createCheckIn(
  humor: _moodLabels[moodIndex],
  comoSentiu: comoSentiu,
  avaliacaoAlimentacao: avaliacaoAlimentacao,
  sintomasEmocionaisHoje: mentalSymptoms.toList(growable: false),
  sintomasFisicosHoje: physicalSymptoms.toList(growable: false),
);
```

`await` aguarda o resultado da operação assíncrona antes de continuar. A tela informa sucesso depois que a chamada termina sem erro.

### 6.4. O repositório prepara a persistência

`EmotionalDiaryRepository.createCheckIn()` verifica se as notas estão entre 1 e 5 e encaminha os campos para `_upsertTodayRecord()`:

```dart
await _client.rpc(
  'iris_upsert_daily_emotional_record',
  params: {
    'p_data_local': LocalDay.key(now),
    'p_fuso_horario': LocalDay.timeZone(now),
    ...values,
  },
);
```

- `.rpc(...)`: chama uma função SQL exposta pelo backend.
- `params`: informa os parâmetros da função.
- `LocalDay.key(now)`: produz a data local no formato `AAAA-MM-DD`.
- `...values`: inclui no mapa os campos específicos da ação.

O paciente é resolvido no servidor pela identidade autenticada. Essa RPC não depende de aceitar um `paciente_id` escolhido pelo formulário.

### 6.5. A tela fecha e o painel consulta os dados novamente

Após salvar, o formulário chama `navigator.pop(true)`. O `true` é o resultado devolvido à tela que abriu o painel.

`HomeScreen` recebe esse resultado, atualiza o resumo diário e, no caso de um check-in salvo, solicita atualização da reflexão e do apoio opcional.

**Para explicar à banca:** “O check-in é persistido primeiro. Depois a interface atualiza o resumo e pode solicitar apoio. Uma resposta da IA não é requisito para confirmar a gravação.”

## 7. Upsert: como o banco evita dois registros emocionais no mesmo dia

Fontes: [migration de integridade](../supabase/migrations/0008_clinical_data_integrity.sql) e [melhorias do diário](../supabase/migrations/0009_patient_journal_improvements.sql).

**Upsert** combina inserção e atualização: insere se o registro não existir; atualiza se já existir para a mesma chave.

A restrição única considera `paciente_id` e `data_local`. A função usa:

```sql
on conflict (paciente_id, data_local) do update
```

Assim, duas tentativas de criação para o mesmo paciente/dia não produzem duas linhas distintas. O banco resolve o conflito dentro da operação.

Outro detalhe importante é preservar os campos de uma ação diferente:

```sql
como_sentiu = coalesce(
  excluded.como_sentiu,
  registros_emocionais.como_sentiu
)
```

`excluded.como_sentiu` é o valor proposto pela inserção que encontrou conflito. `coalesce` usa o primeiro valor não nulo. Ao salvar só o texto do diário, uma nota não enviada não apaga o check-in existente.

A remoção intencional do texto usa `p_limpar_diario`, pois “não enviar um campo” e “apagar um campo” têm significados diferentes.

**Limite:** unicidade e upsert não criam um histórico de versões. Duas edições do mesmo campo ainda podem substituir seu conteúdo conforme a ordem de gravação.

## 8. Como uma consulta do Supabase é lida

Fonte: [UserRepository.getCurrentUserType](../lib/features/users/user_repository.dart).

```dart
final existing = await _client
    .from(DatabaseTables.usuarios)
    .select('tipo_usuario')
    .eq('id', user.id)
    .limit(1)
    .maybeSingle();
```

Leitura de cada parte:

1. `.from(...)`: escolhe a tabela; `DatabaseTables` centraliza seus nomes.
2. `.select(...)`: escolhe as colunas retornadas.
3. `.eq(...)`: aplica um filtro de igualdade.
4. `.limit(1)`: limita o resultado.
5. `.maybeSingle()`: espera um registro ou ausência dele, em vez de uma lista.
6. `await`: aguarda a requisição.

O SDK faz a comunicação com a API do Supabase. Esse código Dart não acessa diretamente a porta do PostgreSQL nem contém a senha do banco. A sessão e as regras RLS participam do controle do acesso.

## 9. Estado da interface: `setState`, `FutureBuilder` e `ChangeNotifier`

| Recurso | O que faz no projeto |
|---|---|
| `setState()` | Marca uma mudança no estado local para reconstruir a interface correspondente. Não grava no banco por conta própria. |
| `FutureBuilder` | Exibe a interface conforme uma operação assíncrona está carregando, terminou ou falhou. |
| `ChangeNotifier` | Permite que uma store ou controlador avise seus ouvintes por `notifyListeners()`. |
| `ValueNotifier` | Expõe um valor observável, como a validação de perfil em andamento. |
| `StreamSubscription` | Acompanha eventos ao longo do tempo, como mudanças de autenticação. |

`HomeScreen` guarda `_todaySummaryFuture` e o renova dentro de `setState()` após alterações. `PatientTodayRepository.loadToday()` usa `Future.wait` para consultar em paralelo a quantidade de refeições e o registro emocional; depois monta um `PatientTodaySummary`.

**Atenção:** `Future.wait` permite aguardar operações juntas; não transforma requisições separadas em uma transação de banco.

## 10. Área profissional: tela, store e backend

Fontes: [ProfessionalHomeScreen](../lib/screens/professional_home_screen.dart), [ProfessionalFrontendStore](../lib/features/professional/presentation/professional_frontend_store.dart) e [SupabaseProfessionalWorkspaceBackend](../lib/features/professional/data/supabase_professional_workspace_backend.dart).

### Tela

`ProfessionalHomeScreen` monta a área profissional, controla navegação e conecta a store à implementação real:

```dart
_store = ProfessionalFrontendStore.connected(
  widget.backend ?? SupabaseProfessionalWorkspaceBackend(),
);
```

`??` significa “use o valor à direita se o da esquerda for nulo”. Um teste pode fornecer `widget.backend`; na execução normal, usa-se o backend Supabase.

### Store

`ProfessionalFrontendStore extends ChangeNotifier` mantém listas de pacientes, agenda, anotações, planos e estados de carregamento/gravação.

`initialize()` pede um `ProfessionalWorkspaceSnapshot` ao backend, atualiza as coleções e chama `notifyListeners()` para os componentes interessados reconstruírem sua interface.

Há um contador `_loadGeneration`: se uma carga antiga terminar depois de uma mais recente ter começado, seu resultado é ignorado. Isso evita que uma resposta atrasada substitua o estado mais novo.

### Backend

`ProfessionalWorkspaceBackend` define o contrato de operações. `SupabaseProfessionalWorkspaceBackend implements ProfessionalWorkspaceBackend` implementa esse contrato usando Supabase.

`loadWorkspace()` resolve o profissional, carrega suas configurações, verifica o credenciamento e consulta vínculos e dados permitidos. Sem credenciamento ativo, retorna um painel sem pacientes/registros e com as próprias configurações. Sem vínculos, retorna coleções vazias.

### Gravação

Ao adicionar uma anotação, por exemplo, a store aguarda `_backend.addNote(note)` e só depois insere o resultado confirmado na lista local. `_mutate()` mantém um contador de operações pendentes e limpa dados locais quando reconhece certos erros de autorização.

**Para explicar:** “A store mantém o que a interface exibe; o backend implementa como consultar e salvar; o banco continua responsável por aplicar as permissões.”

## 11. Injeção de dependência: por que os construtores recebem interfaces

Fonte: [EmotionalDiaryRepository](../lib/features/emotional_diary/emotional_diary_repository.dart).

```dart
EmotionalDiaryRepository({
  SupabaseClient? client,
  UserRepository? users,
  DateTime Function()? clock,
}) : _clientOverride = client,
     _users = users ?? UserRepository(client: client),
     _clock = clock ?? DateTime.now;
```

O objeto recebe dependências em vez de obrigatoriamente criar todas internamente. Isso permite:

- fornecer outro cliente em um contexto controlado;
- controlar a data/hora nos testes por `clock`;
- trocar implementações por meio de contratos como `EmotionalDiaryDataSource` e `ProfessionalWorkspaceBackend`.

Não é necessário um framework específico para fazer injeção de dependência. Aqui ela aparece principalmente pelos parâmetros dos construtores.

## 12. Segurança no banco: o que as regras RLS verificam

Fonte: [políticas do backend profissional](../supabase/migrations/0006_professional_backend.sql).

O banco diferencia a permissão de escrita do paciente e a consulta pelo profissional. Para um profissional consultar registros emocionais, a política verifica um vínculo com:

- o paciente do registro;
- o profissional resolvido a partir da sessão;
- `autorizacao_status = 'ativo'`;
- `status = 'ativo'`.

`iris_current_professional_id()` também exige conta ativa, papel profissional e credenciamento ativo. `auth.uid()` fornece a identidade autenticada usada pelas funções do banco.

**Por que isso importa?** Alterar um ID na requisição ou abrir uma rota pela URL não deve criar uma autorização que o banco não concede.

**Status não são sinônimos:** acompanhamento inativo ainda pode manter autorização para gerenciar a identificação; a consulta aos registros clínicos exige acompanhamento ativo. Autorização revogada remove a permissão do vínculo.

Algumas RPCs usam `security definer`, executando com privilégios do proprietário da função. Por isso precisam de verificações internas de identidade, papel e vínculo, além de permissões de execução restritas. Não basta presumir que toda chamada feita pelo aplicativo é confiável.

## 13. QR: do texto lido até o vínculo no banco

Fontes: [ProfessionalRepository](../lib/features/professional/professional_repository.dart), [parser](../lib/core/qr/professional_qr_parser.dart), [payload](../lib/core/qr/professional_qr_payload.dart) e [PatientProfessionalRepository](../lib/features/patient_professional/patient_professional_repository.dart).

1. `ProfessionalRepository.createLinkInvite()` chama `iris_create_professional_invite`.
2. A função gera um token aleatório no servidor. Os padrões da chamada são 30 minutos e um uso.
3. `ProfessionalQrPayload.build()` monta o texto `iris://vincular/profissional?v=1&token=...`.
4. `ProfessionalQrParser.parseInviteToken()` verifica o formato e extrai o token; também aceita os 64 caracteres hexadecimais sem a URI.
5. `previewInvite()` consulta a identificação do profissional antes da confirmação.
6. `linkCurrentPatientToProfessional()` chama `iris_redeem_professional_invite`.
7. O banco verifica validade e regras, controla concorrência e cria/reativa o vínculo, revogando a autorização anterior quando há troca.

**Duas validações diferentes:** o parser confere a estrutura do texto. O servidor confere se aquele convite existe e ainda pode ser usado. Um token bem formatado pode ser inválido ou estar expirado.

O banco guarda o hash SHA-256, não o token original. Hash não é criptografia reversível: o servidor compara o hash do token apresentado com o persistido.

## 14. Registro alimentar e fotos

Fonte: [FoodRecordRepository](../lib/features/food/food_record_repository.dart).

O repositório organiza criação, edição, remoção e consulta dos registros. `FoodRecord.fromMap()` converte os dados retornados pelo backend em um objeto Dart.

Quando há foto, o arquivo é enviado ao Supabase Storage, no bucket `registro-alimentar`. O registro no banco guarda o caminho; os bytes da imagem ficam no armazenamento de arquivos.

A gravação do registro e o upload são etapas separadas. O repositório devolve resultados como `FoodRecordSaveResult` e `FoodRecordPhotoIssue` para comunicar problemas parciais, como falha de upload ou de limpeza da foto anterior.

**Para explicar:** um problema na foto pode ter um resultado diferente de uma falha na gravação dos dados. O código precisa informar o que foi salvo, em vez de representar toda a operação apenas por um sucesso genérico.

## 15. IA: onde o código termina e o modelo começa

Fontes: [montagem do modo conectado](../lib/screens/patient_session_gate.dart), [recomendador remoto](../lib/features/ai_support/data/remote_ai_recommender.dart), [função de sugestões](../supabase/functions/ai-support-recommend/index.ts) e [função da reflexão](../supabase/functions/ai-daily-companion/index.ts).

### Sugestão de apoio

`SupabaseAiSupportRemoteRecommender` envia somente `requestId` e `trigger`. O contexto do paciente é consultado no backend com base na identidade autenticada e nos consentimentos.

O modelo seleciona um conteúdo do catálogo. O aplicativo recebe IDs, fontes e códigos de motivo, em vez de um conselho livre. A seleção precisa ser válida e permitida pelas preferências. Sem uma seleção aceita, o modo conectado não fabrica uma alternativa por regras locais.

### Reflexão diária

`SupabaseDailyCompanionRepository.loadToday()` faz:

```dart
final response = await _client.functions
    .invoke('ai-daily-companion', body: const <String, Object?>{})
    .timeout(const Duration(seconds: 30));
```

`.functions.invoke()` chama uma Edge Function; é diferente de `.rpc()`, que chama uma função do banco.

A Edge Function valida o usuário, resolve o paciente, verifica preferências e rollout e consulta as fontes permitidas. Se `diary_text` estiver autorizado, pode incluir até 1.800 caracteres do diário no contexto enviado à OpenAI.

A chamada ao modelo exige um JSON com schema definido. O servidor ainda valida o retorno, e o cliente usa `decodeDailyCompanionMessage()` para conferir estado, conteúdo e limites. O código permite apenas uma renderização restrita de Markdown.

**O que a validação garante?** Verifica contratos e rejeita determinadas saídas. Um JSON bem formado, sozinho, não comprova que todo conteúdo é correto ou clinicamente seguro.

### O nome `MockAiSupportStore` exige atenção

Apesar do nome, essa classe orquestra dois modos. Em `PatientSessionGate`, ela é construída com `isDemonstration: false` e recebe repositórios Supabase, recomendador remoto e gateway real de notificações.

Portanto, encontrar `Mock` no nome não basta para concluir que o modo conectado usa dados fictícios. Verifique a configuração e as dependências recebidas pelo objeto.

**Para a banca:** “A IA é uma integração externa. Nós implementamos a seleção das fontes autorizadas, os contratos, as validações, a persistência e a apresentação dos resultados. Não treinamos um modelo próprio neste repositório.”

## 16. Navegação, datas e tratamento de erro

### Navegação

Fonte: [iris_router.dart](../lib/core/navigation/iris_router.dart).

`IrisRouteController` mantém o destino; `IrisRouteInformationParser` interpreta a URI; `IrisRouterDelegate` integra esse estado ao `MaterialApp.router`. Classes como `PatientRouteLocation` e `ProfessionalRouteLocation` representam endereços da aplicação.

Há uma verificação antes de certas mudanças de rota para tratar alterações profissionais ainda não salvas. Isso é proteção de navegação; a autorização de dados continua no backend.

### Datas

Fonte: [LocalDay](../lib/core/time/local_day.dart).

O código distingue um instante de tempo do dia local usado pelo paciente. Isso importa para o check-in diário e para consultas dos registros: a virada do dia do usuário pode não coincidir com a data UTC.

### Erros

Fonte: [AppErrorMessages](../lib/core/errors/app_error_messages.dart).

`AppErrorMessages.from(error)` converte exceções de autenticação, banco, papel e configuração em mensagens para a interface. Não corrige a causa do erro; padroniza como ele é apresentado.

Padrão encontrado nos formulários, em exemplo simplificado:

```dart
try {
  await salvar();
  if (!mounted) return;
  // Atualiza a interface ou fecha o formulário.
} catch (error) {
  if (!mounted) return;
  // Exibe AppErrorMessages.from(error).
} finally {
  if (mounted) {
    // Encerra o estado de carregamento.
  }
}
```

`mounted` informa se o estado do widget ainda está ligado à árvore da interface. Depois de um `await`, o usuário pode já ter fechado a tela. A checagem evita tentar atualizar um componente descartado.

## 17. Sintaxe Dart que vale reconhecer

| Sintaxe | Significado no contexto do projeto |
|---|---|
| `Future<T>` | Resultado assíncrono que futuramente entrega um valor `T` ou falha. |
| `async` / `await` | Permitem escrever a sequência de operações assíncronas sem callbacks encadeados manualmente. Esperar uma requisição não exige bloquear a interface. |
| `String?` | Texto que pode ser nulo. |
| `obj?.campo` | Acessa o campo apenas se o objeto existir. |
| `valor ?? padrao` | Usa o padrão se o valor for nulo. |
| `valor!` | Afirma ao compilador que o valor não é nulo; falha em execução se essa suposição estiver errada. |
| `final` | A variável recebe uma única atribuição; não torna automaticamente uma coleção imutável. |
| `const` | Expressa um valor/construtor constante quando permitido. |
| `late final` | Permite inicialização posterior com uma única atribuição, comum em `initState()`. |
| `_nome` | Identificador privado à biblioteca Dart, não uma autorização de segurança. |
| `extends` | Herança de uma classe, como uma store que herda de `ChangeNotifier`. |
| `implements` | Compromisso de implementar o contrato de uma interface. |
| `@override` | Indica implementação ou substituição de um membro herdado/contratado. |
| `unawaited(futuro)` | Inicia uma operação sem aguardar ali; não cancela a operação e não trata seus erros automaticamente. |
| `dispose()` | Libera listeners, assinaturas e outros recursos do componente. |

## 18. Testes: o que você deve saber localizar

| Assunto | Exemplos no repositório |
|---|---|
| Autenticação e sessão | [auth_role_flow_test.dart](../test/auth_role_flow_test.dart), [auth_session_regression_test.dart](../test/auth_session_regression_test.dart) |
| Registros do paciente | [patient_data_flow_test.dart](../test/patient_data_flow_test.dart), [diario_emocional_bottom_sheet_test.dart](../test/diario_emocional_bottom_sheet_test.dart) |
| Estado profissional | [professional_frontend_store_test.dart](../test/professional_frontend_store_test.dart) |
| Processamento do QR | [professional_qr_parser_test.dart](../test/professional_qr_parser_test.dart) |
| Contratos da IA | [remote_ai_recommender_test.dart](../test/remote_ai_recommender_test.dart), [generation_test.ts](../supabase/functions/ai-daily-companion/generation_test.ts) |
| Integridade e permissões SQL | [clinical_data_integrity.sql](../supabase/tests/clinical_data_integrity.sql), [professional_backend_flow.sql](../supabase/tests/professional_backend_flow.sql) |
| Segredos no cliente | [client_secret_exposure_test.dart](../test/client_secret_exposure_test.dart) |

**Como explicar:** testes de widget exercitam comportamento de interface; testes de regras conferem decisões e transformações; testes SQL verificam o backend isolado. Testes com dependências simuladas não substituem um ensaio integrado com as duas contas no ambiente publicado.

Estas anotações documentam a leitura do código; não afirmam uma execução atual dessas suítes.

## 19. Perguntas técnicas para treinar

- **Por que usar um repositório?** Para concentrar acesso aos dados e suas validações, permitindo que a tela cuide da interação e que implementações sejam substituídas em testes.
- **Qual é a diferença entre store e banco?** A store mantém estado em memória para a interface; o banco persiste dados e aplica regras entre usuários e sessões.
- **O que impede um check-in duplicado?** A restrição única por paciente/dia, combinada ao upsert no banco.
- **Como a tela sabe que precisa atualizar?** Pelo resultado do formulário, por `setState()` e pelos ouvintes das stores/controladores, dependendo do fluxo.
- **A atualização entre dois dispositivos é automática em tempo real?** Os fluxos descritos aqui usam consultas e atualizações explícitas. Usar Supabase não comprova, por si só, uma assinatura de Realtime.
- **Por que validar no aplicativo e no servidor?** A interface oferece retorno rápido; o servidor continua protegendo dados mesmo se alguém contornar o aplicativo.
- **RPC e Edge Function são a mesma coisa?** Não. RPC executa uma função do banco; Edge Function executa código do servidor, usado aqui também para chamadas à IA.
- **Por que a chave da IA fica na função?** Porque o código do aplicativo é distribuído ao usuário e não pode guardar um segredo de servidor com segurança.
- **O que acontece se o backend falhar?** A chamada pode lançar erro; a tela deve encerrar o carregamento e informar a falha. Não se deve confundir ausência de resposta com gravação confirmada.

## 20. Percurso de leitura para revisar antes da apresentação

1. `main.dart`: entenda inicialização e `AuthGate`.
2. `auth_service.dart` e `session_gate.dart`: acompanhe login e papel da conta.
3. `check_in_diario_bottom_sheet.dart`: encontre `_submit()`.
4. `emotional_diary_repository.dart`: siga `createCheckIn()` até a RPC.
5. `0009_patient_journal_improvements.sql`: encontre o `on conflict` do upsert.
6. `professional_frontend_store.dart`: leia `initialize()` e uma gravação, como `addNote()`.
7. `0006_professional_backend.sql`: confira as políticas dos registros e as funções do convite.
8. `remote_ai_recommender.dart` e `ai-daily-companion/index.ts`: compare seleção de catálogo e geração de reflexão.

Ao explicar uma parte, identifique sempre **quem chama, quais dados entram, qual regra é aplicada, onde o dado é salvo e como a tela recebe o resultado**.
