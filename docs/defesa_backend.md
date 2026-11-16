# Defesa do backend do Íris — preparação técnica e recrutamento

Este material complementa as [anotações do código](anotacoes_codigo.md) e o [guia da banca](guia_banca.md). O objetivo é conseguir explicar decisões e acompanhar uma operação do início ao fim. As observações abaixo vêm do repositório, sem auditoria do ambiente publicado nem execução atual das suítes.

## 1. Como apresentar sua responsabilidade

Uma descrição possível, ajustada ao que você realmente fez e revisou:

> Fiquei responsável pelo backend do Íris, utilizando Supabase e PostgreSQL. O trabalho inclui a modelagem dos dados, as permissões por usuário e vínculo, as funções SQL para operações críticas e a integração com IA por funções de servidor. Usei IA como apoio ao desenvolvimento; consigo explicar as regras implementadas, os testes existentes e os limites atuais.

Não é preciso afirmar que implementou banco, autenticação e infraestrutura do zero. O trabalho da aplicação está nas regras e integrações construídas sobre esses serviços. Ao contar uma dificuldade, use um caso que você realmente acompanhou; um comentário ou teste no repositório não comprova sua experiência pessoal com o incidente.

## 2. Onde o backend realmente está

O sistema usa arquitetura **cliente-servidor com backend gerenciado (BaaS)** e **funções serverless** para a integração com IA.

- O **Flutter** executa no dispositivo/navegador e apresenta a aplicação.
- O **Supabase Auth** fornece autenticação e sessão.
- A **API de dados do Supabase** expõe operações permitidas sobre tabelas e funções PostgreSQL.
- O **PostgreSQL** guarda dados, valida integridade e executa políticas e regras SQL.
- O **Storage** guarda arquivos de fotos.
- As **Edge Functions**, escritas em TypeScript, executam no servidor e chamam a OpenAI.
- A **Vercel**, na configuração web, entrega os arquivos da interface; não hospeda o PostgreSQL deste projeto.

**Cuidado com o nome:** `SupabaseProfessionalWorkspaceBackend` está em um arquivo Dart de `lib/` e executa no cliente. É um adaptador de acesso ao backend, não um servidor. A autorização não pode depender exclusivamente das verificações dessa classe.

**Por que Supabase?** A escolha concentra serviços úteis ao escopo acadêmico e permite dedicar esforço às regras da aplicação. A contrapartida é depender do fornecedor e manter corretamente suas configurações, permissões e limites. Criar um servidor próprio não eliminaria essas responsabilidades.

## 3. Os três caminhos principais das requisições

### Tabelas pela API

Chamadas como `.from(...).select(...)` ou `.insert(...)` usam o SDK para conversar com a API de dados. A sessão identifica o usuário e o banco aplica privilégios, políticas e restrições. Não se trata de entregar a senha do PostgreSQL ao aplicativo.

Exemplo: criação de registro alimentar e consulta de anotações permitidas.

### RPCs

`.rpc('nome_da_funcao', params: ...)` chama uma função SQL. É útil quando uma operação envolve regras e várias alterações que precisam acontecer juntas.

Exemplos: `iris_upsert_daily_emotional_record`, `iris_redeem_professional_invite` e `iris_save_care_plan`.

### Edge Functions

`.functions.invoke(...)` chama código TypeScript no servidor. No projeto, essa camada integra a API externa de IA, mantém segredos e controla o contexto autorizado.

**Não existe uma passagem obrigatória de todo CRUD por uma Edge Function.** O uso da API gerenciada com proteção no banco é uma decisão central da arquitetura.

## 4. Modelagem: por que os dados estão separados

- `auth.users`: identidade mantida pelo serviço de autenticação.
- `usuarios`: identidade da aplicação, papel e estado ativo, referenciada à identidade autenticada.
- `perfis`: informações pessoais.
- `pacientes` e `profissionais`: entidades específicas de cada papel, com IDs próprios ligados por `user_id`.
- `paciente_profissional`: relação autorizada de acompanhamento.
- `registros_emocionais` e `registros_alimentares`: informações registradas pelo paciente.
- `consultas`, `anotacoes_clinicas` e `planos_cuidado`: informações do acompanhamento associadas ao vínculo.
- `metas_cuidado` e `medicacoes_plano`: itens associados ao plano.
- Tabelas de apoio: preferências, temas confirmados, sugestões, eventos e reflexões.

**Por que um banco relacional?** Há relações explícitas e regras entre entidades. Chaves estrangeiras preservam referências, e constraints expressam limites e unicidade. Não basta dizer que PostgreSQL é “mais seguro” ou “mais rápido” sem explicar a necessidade concreta.

Um profissional pode ter vários pacientes; a implementação aceita **um único vínculo autorizado por paciente por vez**, protegido por índice único parcial. Acompanhamento multiprofissional simultâneo exigiria rever regras, consultas e interface, não apenas adicionar mais um botão.

**Detalhe que pode chamar atenção:** `usuarios.senha_hash` existe no esquema, mas recebe o marcador `managed_by_supabase_auth`. Não é o hash real de senha calculado pela aplicação. A autenticação foi delegada ao Supabase Auth; o nome dessa coluna é uma oportunidade de limpeza do esquema legado.

Fontes: [esquema](../supabase/migrations/0001_core_schema.sql) e [backend profissional](../supabase/migrations/0006_professional_backend.sql).

## 5. Cadastro, login e bootstrap

No cadastro, o Supabase Auth cria a identidade. A disponibilidade imediata de sessão depende também das configurações de confirmação de e-mail. Quando há sessão, `UserRepository` prepara os registros da aplicação pela RPC `iris_bootstrap_current_user`.

No login, `AuthService.signIn()` autentica, garante o bootstrap, consulta o papel persistido e confere se corresponde ao perfil escolhido. Se o usuário escolheu profissional e a conta é de paciente, o aplicativo encerra a sessão e informa a divergência.

O bootstrap usa a identidade da sessão, não um ID arbitrário informado pelo formulário. Ao reencontrar um usuário, a operação preserva seu papel existente e verifica se a conta está ativa. As permissões não devem permitir que o próprio usuário se promova ou aprove seu credenciamento.

**JWT, sem decorar sua estrutura:** é o token de acesso usado para representar a sessão nas requisições. O servidor precisa validar o token; receber um texto com aparência de JWT ou apenas decodificar seu conteúdo não comprova autenticidade. No SQL, `auth.uid()` fornece o identificador do usuário autenticado para as regras.

Fonte: [AuthService](../lib/features/auth/auth_service.dart) e [UserRepository](../lib/features/users/user_repository.dart).

## 6. Autenticação, autorização, privilégios e RLS

São verificações diferentes:

1. **Autenticação:** quem está fazendo a requisição?
2. **Privilégio da operação:** esse papel pode executar `SELECT`, `INSERT`, uma função etc.?
3. **RLS:** quais linhas esse usuário pode consultar ou alterar?
4. **Integridade e regras:** os valores e a operação respeitam o contrato do sistema?

RLS significa segurança por linha. Por exemplo, a consulta profissional a um registro emocional depende de o usuário ser um profissional ativo e credenciado, ter vínculo autorizado com aquele paciente e estar com acompanhamento ativo.

**A sutileza do diário:** a migration `0008` revoga `INSERT`, `UPDATE` e `DELETE` diretos de `registros_emocionais` para `authenticated`. A leitura continua com RLS; a escrita precisa passar pela RPC de upsert. Uma política de escrita ainda presente na tabela não basta para autorizar uma operação sem o privilégio correspondente.

**Se alterarem o ID pela requisição?** O ID localiza o recurso, mas não concede permissão. O backend deve verificar a relação daquele recurso com a identidade autenticada. UUID não substitui autorização.

**Se não tiver acesso, sempre volta 403?** Não. Uma consulta com RLS pode retornar nenhuma linha visível. Erros e respostas dependem do tipo de operação; não assuma que todo bloqueio vira o mesmo código HTTP.

Fontes: [RLS e papéis](../supabase/migrations/0006_professional_backend.sql) e [privilégios da escrita emocional](../supabase/migrations/0008_clinical_data_integrity.sql).

## 7. `security definer`: poder e responsabilidade

Uma função com `security definer` executa com os privilégios do proprietário da função. Isso permite operações controladas que o cliente não pode executar diretamente, mas exige verificar a identidade, o papel e a propriedade dos dados dentro da função.

No projeto, há funções que resolvem o paciente/profissional autenticado, verificam o vínculo e restringem quem pode executar uma RPC. Funções de credenciamento administrativo são restritas ao papel de serviço. O `search_path` controlado e a restrição de criação de objetos nos schemas ajudam a evitar resolução indevida de objetos usados pelas funções.

**Resposta-base:** “Não confio no parâmetro só porque veio do nosso aplicativo. A função precisa validar quem chama e se pode realizar aquela operação.”

## 8. Registro diário: integridade, data e concorrência

O formulário envia notas de 1 a 5, sintomas e o dia local. O repositório chama `iris_upsert_daily_emotional_record`; o servidor resolve o paciente e valida os parâmetros.

O índice único de `(paciente_id, data_local)` estabelece que existe uma linha por paciente/dia. `INSERT ... ON CONFLICT ... DO UPDATE` insere ou atualiza essa linha de forma atômica. Isso evita o problema de fazer “consultar se existe” e “inserir” em chamadas separadas, quando duas requisições podem observar ausência simultaneamente.

Campos não enviados são preservados conforme a função. Assim, salvar o texto do diário não limpa o humor já registrado. `p_limpar_diario` representa a intenção explícita de apagar o texto.

**Data local não é igual a timestamp UTC.** Uma representa o dia do registro para o usuário; o outro representa um instante. A função também valida uma janela aceitável para a data recebida, em vez de aceitar qualquer dia arbitrário.

**Limite:** upsert não é histórico de versões nem resolução de conflito de duas edições do mesmo campo. Para evitar sobrescrita de uma edição antiga, seria necessário adotar uma estratégia como controle de versão e rejeição de gravações desatualizadas.

Fonte: [RPC atual do diário](../supabase/migrations/0009_patient_journal_improvements.sql).

## 9. QR: segurança, transação, locks e idempotência

O token é gerado no servidor com 32 bytes aleatórios: 256 bits representados em 64 caracteres hexadecimais. O QR contém esse token; no banco fica seu hash SHA-256.

O resgate:

1. Confere se quem chama é paciente autenticado e se o token tem formato válido.
2. Bloqueia a linha do paciente com `FOR UPDATE`, serializando trocas concorrentes para o mesmo paciente.
3. Localiza e bloqueia o convite válido, verificando credenciamento, prazo, revogação e limite de usos.
4. Registra o resgate com unicidade por convite/paciente.
5. Revoga o vínculo anterior quando necessário e cria/reativa o atual.
6. Incrementa o uso apenas quando é um novo resgate.

**Transação:** as alterações da função fazem parte da mesma operação transacional. Se ela falha com erro não tratado, não se confirma só metade da troca.

**Lock:** controla acessos concorrentes às linhas durante a transação. É importante para dois pacientes não consumirem indevidamente o último uso do mesmo convite ou duas trocas do mesmo paciente competirem sem controle.

**Idempotência:** repetir um resgate já concluído, enquanto continuam válidas as condições previstas pela função, pode retornar o mesmo vínculo sem consumir outro uso. Não significa que o convite se torna reutilizável para sempre.

**Hash não é criptografia reversível.** Ele permite comparar o token recebido sem persistir o original. Isso não impede o compartilhamento do próprio QR enquanto válido, nem revoga automaticamente um vínculo já criado quando o convite é revogado.

Fontes: [criação e regras](../supabase/migrations/0006_professional_backend.sql), [versão compatível do resgate](../supabase/migrations/0007_professional_invite_legacy_text_compat.sql) e [teste do fluxo](../supabase/tests/professional_backend_flow.sql).

## 10. Plano de cuidado: por que usar uma RPC

`iris_save_care_plan` verifica se o profissional possui o vínculo ativo, grava/atualiza o plano e substitui suas metas e medicações na mesma função SQL.

Isso evita dividir o salvamento em várias requisições independentes pelo cliente e terminar com o plano novo e apenas parte de seus itens. Se houver falha SQL não tratada, a transação não confirma as alterações parciais.

**Contrapartida atual:** os itens são removidos e reinseridos, e não há um histórico completo de versões do plano nessa operação. Atomicidade não garante preservar todas as edições concorrentes nem torna o banco e uma API externa parte da mesma transação.

O paciente consulta somente o plano permitido pelo vínculo e marcado como compartilhado. As anotações profissionais não são liberadas ao paciente simplesmente porque o plano foi compartilhado.

Fonte: [iris_save_care_plan](../supabase/migrations/0006_professional_backend.sql) e [adaptador que chama a RPC](../lib/features/professional/data/supabase_professional_workspace_backend.dart).

## 11. Inativo, revogado e credenciamento

- **Acompanhamento inativo:** o vínculo pode continuar autorizado para gerenciamento da identificação, mas o profissional não deve consultar os registros clínicos por esse acompanhamento.
- **Autorização revogada:** remove a permissão daquele vínculo; trocar de profissional revoga a autorização anterior.
- **Credenciamento:** controla a habilitação da conta profissional.

A migration `0017` habilita um modo de avaliação que pode aprovar novos profissionais automaticamente. Isso é uma configuração de demonstração/avaliação, não uma consulta ao conselho profissional. Desativá-la não desfaz aprovações já concedidas.

**Revogação não apaga o que alguém já viu.** Ela restringe novas operações no servidor; não promete retirar retroativamente uma captura de tela ou dados já carregados. O cliente também precisa limpar/revalidar estado quando recebe a mudança ou um erro de autorização.

Fonte: [modo de avaliação](../supabase/migrations/0017_professional_evaluation_mode.sql).

## 12. Fotos: operação distribuída e pendência de infraestrutura

O registro alimentar é salvo no banco; a foto é enviada ao bucket `registro-alimentar`; depois o caminho é associado ao registro. O caminho inclui o ID autenticado, o registro e um identificador temporal.

Se o upload funciona e a associação falha, o código tenta remover o arquivo enviado. Se a limpeza também falha, pode sobrar arquivo órfão. Há resultados específicos para falhas parciais. Um comentário sobre manutenção futura não comprova que exista um job automático de limpeza.

**Não há transação única entre PostgreSQL e Storage nesse fluxo.** O tratamento usa tentativas de compensação e comunicação de resultado parcial.

**Limite constatado no repositório:** não foram encontradas migrations criando esse bucket e suas políticas de acesso. Isso não prova que estejam ausentes no ambiente remoto; significa que sua configuração e reprodutibilidade precisam ser verificadas separadamente. O prefixo de uma pasta não é uma política de segurança.

Fonte: [FoodRecordRepository](../lib/features/food/food_record_repository.dart).

## 13. Edge Functions: CORS, autenticação e segredo administrativo

As funções tratam o preflight `OPTIONS`, restringem métodos e verificam origens web configuradas. CORS orienta o acesso feito pelo navegador; não autentica uma pessoa nem impede, por si só, clientes fora do navegador.

Em `supabase/config.toml`, `verify_jwt = false` desliga a verificação automática do gateway para permitir que esse fluxo chegue ao handler. Os handlers ainda exigem `Bearer` e chamam `auth.getUser()` para validar o usuário antes do acesso administrativo. Portanto, essa configuração não significa que os POSTs foram projetados para ser públicos.

O cliente com privilégios administrativos é poderoso e pode contornar RLS. Por isso a função precisa resolver o paciente pela identidade validada e aplicar os consentimentos e restrições, sem confiar em um `patientId` arbitrário do corpo.

Fontes: [configuração das funções](../supabase/config.toml), [CORS compartilhado](../supabase/functions/_shared/cors.ts) e [handler de apoio](../supabase/functions/ai-support-recommend/index.ts).

## 14. Os dois contratos de IA

**Recomendador:** recebe `requestId` e `trigger`; consulta sinais estruturados autorizados; restringe candidatos e pede ao `gpt-5-mini` uma seleção do catálogo. Não envia diário bruto, alimentação ou sintomas como contexto desse recomendador. A saída não é um conselho livre. A seleção passa por validações no backend e no aplicativo.

**Reflexão diária:** recebe um objeto vazio com a sessão; resolve o contexto no servidor; pode usar até 1.800 caracteres do diário quando a fonte `diary_text` estiver autorizada; solicita uma reflexão estruturada e valida seu retorno. O app aceita apenas um subconjunto restrito de Markdown.

**Dados não vêm no corpo do cliente, mas podem sair do backend para a OpenAI.** Não confunda essas duas afirmações. O consentimento para uma fonte é uma condição técnica importante, não uma comprovação automática de todos os requisitos jurídicos e clínicos.

As chamadas usam `store: false`; isso, isoladamente, não permite prometer retenção zero em todo o fornecedor. O código não demonstra treinamento próprio ou fine-tuning.

**Segurança do modelo:** catálogo fechado, schema e filtros reduzem saídas inadequadas. Schema garante estrutura, não verdade clínica. O bloqueio de determinados sinais de risco e a rota de apoio humano não equivalem a uma avaliação clínica ou monitoramento de emergência.

Fontes: [contrato de sugestões](../supabase/functions/ai-support-recommend/README.md) e [contrato da reflexão](../supabase/functions/ai-daily-companion/README.md).

## 15. Cache, invalidação, timeouts e falhas

A reflexão gerada é persistida e reutilizada quando atende às condições, como dia, expiração, versão do prompt e validação do conteúdo. Alterar diário/humor invalida a mensagem anterior por trigger. Retirar fontes consentidas e excluir dados de apoio também afeta os conteúdos derivados.

Isso mostra uma preocupação de consistência: uma reflexão antiga não deve reaparecer como se correspondesse ao contexto novo. Ainda assim, não se deve apresentar cache como uma solução completa para todas as corridas entre geração e edição concorrente.

A reflexão tem até duas tentativas para falhas previstas, com limite de oito segundos por chamada ao modelo; o cliente aguarda até trinta segundos para a operação completa. Recusa, autenticação inválida e limitação de uso não são simplesmente repetidas como qualquer erro transitório.

No recomendador conectado, ausência de resultado válido, consentimento, rollout ou disponibilidade produz ausência de nova sugestão, sem fallback por regras. O salvamento dos registros não depende da IA.

Fontes: [invalidação](../supabase/migrations/0013_daily_companion_refresh.sql), [versão do cache](../supabase/migrations/0014_daily_companion_complete_text.sql) e [geração](../supabase/functions/ai-daily-companion/index.ts).

## 16. Idempotência de IA não é execução exatamente uma vez

O recomendador procura uma execução anterior com o mesmo paciente e `requestId`. A tabela também tem unicidade por paciente, requisição e papel da execução.

Isso permite reaproveitar uma execução concluída e evitar linhas duplicadas para a chave. Porém, a leitura anterior e a chamada à OpenAI não estão protegidas por uma reserva exclusiva antes da geração. Duas chamadas simultâneas podem ambas chegar ao modelo antes de uma delas persistir.

**Se perguntarem sobre custo duplicado:** explique esse limite. Uma evolução seria reservar a execução de forma atômica antes da chamada externa e controlar estados, prazo e retomada. A restrição única na gravação não garante sozinha uma única cobrança do fornecedor.

Fonte: [findEffectiveRun e persistRun](../supabase/functions/ai-support-recommend/index.ts).

## 17. Rollout, notificações e alertas

Rollout controla a liberação por ambiente, participante de piloto ou percentual. Shadow executa a seleção sem exibir o resultado; piloto/limitado podem permitir entrega validada. Kill switch interrompe a entrega conforme as verificações implementadas; não é o mesmo que um circuit breaker automático por taxa de falha.

As notificações de apoio são locais em Android/iOS, dependem da permissão do aparelho e usam textos genéricos. Não há, nesse gateway, um serviço completo de push web/remoto ou aviso garantido ao profissional.

O adaptador Dart da área profissional calcula alertas do painel a partir dos registros carregados e das preferências, usando janela recente e critérios do código. Isso acontece no cliente ao carregar os dados. Não deve ser apresentado como um serviço de servidor monitorando pacientes continuamente e acionando alguém com o aplicativo fechado.

Fontes: [gateway local](../lib/features/ai_support/notifications/flutter_local_support_notification_gateway.dart) e [carga do painel profissional](../lib/features/professional/data/supabase_professional_workspace_backend.dart).

## 18. Desempenho e crescimento

O projeto possui índices para relações e consultas frequentes. O carregamento profissional usa páginas de até 500 linhas e divide filtros de IDs em grupos de 100, avançando pelo tamanho efetivamente retornado pelo servidor.

**Limite importante:** essas páginas são acumuladas para montar o workspace no cliente. Isso é paginação de transporte, não necessariamente uma tela que mantém apenas uma pequena página na memória. Com muitos pacientes e registros, volume transferido, memória, agrupamentos e contagens podem se tornar caros.

Para evoluir, faria sentido medir consultas e latência, limitar janelas de histórico, carregar detalhes sob demanda, paginar a experiência de navegação e avaliar agregações no servidor. A decisão deve vir de medição; adicionar cache ou um servidor novo não comprova ganho por si só.

Não há teste de carga apresentado neste material que autorize prometer um número de usuários simultâneos. Também não confunda intervalo entre sugestões/notificações com proteção completa de rate limiting da API.

Fonte: [paginação do workspace](../lib/features/professional/data/supabase_professional_workspace_backend.dart).

## 19. Testes: qual evidência cada camada fornece

- **Dart/Flutter:** regras e comportamento dos componentes com dependências controladas.
- **SQL em PostgreSQL isolado:** migrations, constraints, permissões, RLS e fluxos como convite, troca de profissional e gravações.
- **TypeScript com fronteiras simuladas:** contratos e comportamento de handlers/geração sem depender de uma chamada real ao modelo.
- **Ensaio integrado publicado:** comprova a compatibilidade concreta entre app, Auth, banco e funções na versão usada na demonstração.

O script SQL usa Docker com PostgreSQL e cria uma simulação mínima do schema Auth e dos papéis. Ele não sobe toda a infraestrutura real do Supabase. O repositório inclui repetição de migrations específicas para testar convergência/idempotência, mas isso não autoriza reaplicar indiscriminadamente qualquer migration em produção.

**Teste de segurança que vale saber explicar:** o profissional A não vinculado deve ficar sem acesso; o profissional anteriormente autorizado deve perder acesso após a troca; o próprio usuário não pode aprovar seu credenciamento. Testar apenas o caminho permitido não demonstra isolamento.

O workflow presente em `.github/workflows` compila Windows; não demonstra, sozinho, um pipeline que execute todas as suítes antes de cada publicação. Só declare resultados de testes quando tiver a execução correspondente.

Fontes: [runner SQL](../scripts/test_supabase_migrations.sh), [bootstrap simulado](../supabase/tests/local_auth_bootstrap.sql), [fluxo de permissões](../supabase/tests/professional_backend_flow.sql) e [workflow](../.github/workflows/build-windows.yml).

## 20. Publicação, configuração e operação

Há três entregas compatíveis entre si: arquivos do cliente, migrations do banco e Edge Functions. Cada uma precisa ser publicada no ambiente correto. Secrets remotos também não são atualizados simplesmente porque um `.env` local mudou.

Uma RPC ausente pode indicar migration pendente, projeto errado, assinatura diferente ou cache de schema desatualizado. Um erro CORS pode impedir o navegador de enviar a requisição antes da autenticação. Uma função antiga pode responder um formato que o aplicativo novo rejeita.

As funções de IA registram códigos de erro e algumas métricas, como versão, latência e tokens, evitando colocar o diário bruto nesses logs. Isso é diferente de afirmar que toda a aplicação possui observabilidade e auditoria completas. Outros pontos imprimem exceções e precisam ser considerados em uma revisão de logs.

Antes de uso amplo, é necessário verificar configuração real de backups, recuperação testada, monitoração, limites, acesso administrativo e procedimento de incidentes. A presença de um serviço gerenciado não comprova que todos esses processos estejam definidos para este projeto.

Fontes: [publicação](deploy_vercel.md), [configuração](../README.md) e [diagnóstico da reflexão](../supabase/functions/ai-daily-companion/README.md).

## 21. Como raciocinar ao depurar

Use uma sequência curta:

1. **Reproduzir:** qual conta, ação, ambiente e versão falham?
2. **Localizar a fronteira:** formulário, requisição web, Auth, RPC/RLS, Storage ou modelo?
3. **Observar:** erro HTTP, código de banco, etapa da consulta e versão da função, sem divulgar tokens ou dados clínicos.
4. **Formar uma hipótese:** por exemplo, falta de vínculo, assinatura antiga da RPC ou origem web não autorizada.
5. **Verificar com o menor teste possível:** provar/refutar a hipótese antes de alterar várias configurações.
6. **Corrigir e verificar regressão:** confirmar tanto o caso permitido quanto a preservação dos bloqueios de acesso.

Exemplo de raciocínio: se o preflight CORS falha, mudar o prompt não resolve. Se uma consulta retorna vazia, confira se deveria haver dados e se a RLS permite vê-los, antes de concluir que o banco perdeu os registros.

## 22. Perguntas de recrutadores para ensaiar em voz alta

1. **O que você implementou além de configurar o Supabase?** Explique modelagem, políticas, RPCs, integração e testes que conhece, distinguindo código da aplicação e infraestrutura fornecida.
2. **Por que essa arquitetura?** Relacione escopo e reaproveitamento de serviços às contrapartidas de dependência e configuração.
3. **Onde está a regra de quem acessa o paciente?** Mostre as políticas e funções no banco, não apenas o gate da tela.
4. **Como duas requisições simultâneas afetam o sistema?** Compare a unicidade/upsert do diário, os locks do convite e o limite de concorrência das chamadas à IA.
5. **Qual operação precisa ser atômica?** Use a troca de vínculo ou a gravação do plano e seus itens; explique o erro evitado.
6. **O que acontece quando um serviço externo falha?** Compare silêncio da IA e resultado parcial de foto; não prometa transação distribuída.
7. **O que você melhoraria primeiro?** Escolha algo concreto: infraestrutura reproduzível do Storage, testes integrados na publicação, operação/recuperação ou redução da carga do workspace. Explique o motivo e como verificaria o resultado.
8. **Como provaria que um usuário não acessa outro?** Descreva testes negativos com identidades diferentes e chamadas feitas fora da interface normal.
9. **Que bug você resolveu?** Conte um caso real seu, com problema, hipótese, alteração e evidência. O repositório tem exemplos estudáveis de compatibilidade SQL, integridade diária e versionamento de funções, mas não invente que viveu todos eles.
10. **Como usou IA?** Explique seu processo real. Distinga sugestão de código, revisão, teste e decisão humana; não alegue ter validado o que não conferiu.

Uma boa estrutura de resposta é: **necessidade → decisão → funcionamento → evidência → limite**. Você não precisa conhecer toda tecnologia de memória; precisa saber localizar e explicar o contrato da parte pela qual responde.

## 23. Cinco operações que você deve conseguir acompanhar sem ajuda

1. Login até a decisão de papel, explicando identidade Auth e perfil da aplicação.
2. Check-in até o upsert, explicando paciente da sessão, data local, notas e unicidade.
3. Convite até a troca de vínculo, explicando token, hash, prazo, lock e idempotência.
4. Plano até a consulta do paciente, explicando transação, itens e compartilhamento.
5. Pedido de IA até resultado/silêncio, explicando consentimento, contexto, segredo, validação e falha.

Para cada uma, responda: **quem pode chamar, qual entrada é aceita, onde a regra é executada, o que muda no banco, o que pode falhar e qual teste comprova o comportamento**.
