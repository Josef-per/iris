# Íris — guia de estudo para a banca

Material baseado no código e na documentação deste repositório. A existência de uma implementação não comprova que ela esteja publicada, habilitada ou validada em produção. Confira o ambiente da apresentação antes de demonstrar.

## 1. O que você precisa conseguir explicar em 30 segundos

“O Íris é um aplicativo de apoio ao acompanhamento entre pessoas com transtornos alimentares e profissionais de saúde. O paciente faz check-ins e registros emocionais e alimentares; o profissional autorizado consulta esses registros e organiza agenda, anotações e plano de cuidado. O paciente também pode acessar recursos opcionais de apoio com IA. O objetivo é reunir informações para dar continuidade ao acompanhamento, mantendo as decisões de cuidado com o profissional.”

Saiba responder: **qual problema o sistema procura resolver, para quem e como**. A proposta é reduzir a dispersão das informações entre consultas. Isso é um objetivo do projeto; benefício clínico comprovado exigiria avaliação própria.

## 2. As funcionalidades de cada perfil

| Perfil | Principais recursos |
|---|---|
| Paciente | Cadastro e login, check-in, diário emocional, registro alimentar com foto opcional, histórico, lembretes, consulta ao plano compartilhado, contato de emergência e preferências de apoio. |
| Profissional | Dashboard, agenda, pacientes ativos e inativos, consulta aos registros permitidos, anotações clínicas, plano de cuidado, metas, medicações e convite de vínculo. |

**Exemplo que vale dominar:** o paciente salva um registro → confirma o vínculo com o profissional → o profissional consulta o registro → salva um plano e habilita o compartilhamento → o paciente consulta o plano.

O campo de medicações organiza informações inseridas pelo profissional. A IA não determina medicamentos ou doses.

## 3. Arquitetura e tecnologias

O percurso principal dos dados é:

1. A interface em **Flutter/Dart** recebe a ação do usuário.
2. Repositórios e serviços fazem chamadas ao **Supabase** com a sessão autenticada.
3. O **PostgreSQL** persiste os dados e aplica permissões e regras de integridade.
4. Nos recursos de IA, uma **Edge Function em TypeScript** valida a requisição, consulta o contexto autorizado e chama a API da OpenAI.

| Termo | Como explicar na banca |
|---|---|
| Flutter | Framework da interface, usado para compartilhar código entre web, desktop e mobile. Cada plataforma ainda precisa de testes próprios. |
| Dart | Linguagem principal do aplicativo. |
| Supabase | Serviço de backend que fornece autenticação, acesso ao PostgreSQL, armazenamento de arquivos e funções no servidor. |
| PostgreSQL | Banco relacional que representa usuários, vínculos, registros e planos com relações e restrições. |
| RLS | Regras no banco que determinam quais linhas cada usuário pode consultar ou alterar. |
| RPC | Chamada a uma função do banco, usada em operações como vinculação e atualização do registro emocional diário. |
| Edge Function | Código executado no servidor; no Íris, mantém a chave da IA fora do aplicativo e controla o contexto enviado ao modelo. |

**Por que essas escolhas fazem sentido?** Flutter favorece o reaproveitamento da interface; Supabase reúne serviços de backend úteis para o escopo acadêmico; PostgreSQL permite expressar relações, integridade e controle de acesso. As contrapartidas incluem dependência dos fornecedores, configuração cuidadosa e custos de operação.

**Como o código está organizado?** Há recursos em `lib/features`, telas em `lib/screens`, componentes em `lib/widgets` e infraestrutura compartilhada em `lib/core`. Repositórios separam o acesso aos dados da interface. O painel profissional usa uma store baseada em `ChangeNotifier`; também há estado local em widgets. Evite classificar o projeto inteiro como MVC, Clean Architecture, BLoC ou Riverpod sem demonstrar isso no código.

## 4. Banco de dados e regras de negócio

Domine estas relações:

- `usuarios` guarda a identidade da aplicação ligada ao Supabase Auth; `perfis` reúne dados de perfil.
- `pacientes` e `profissionais` representam os dois papéis.
- `paciente_profissional` registra o vínculo e seus estados de acompanhamento e autorização.
- `registros_emocionais` e `registros_alimentares` pertencem ao paciente.
- Consultas, anotações e planos de cuidado são associados ao vínculo; metas e medicações pertencem ao plano.
- A personalização tem tabelas próprias para preferências, temas, eventos, sugestões e reflexões.

**Regras que podem virar perguntas:**

- Existe **um único vínculo autorizado por paciente por vez**. Um profissional pode acompanhar vários pacientes. Atendimento simultâneo por uma equipe multiprofissional exigiria evolução dessa regra.
- O registro emocional é único por paciente e dia local. Check-in e texto do diário atualizam o registro do dia por uma RPC de upsert, preservando os campos que não estão sendo alterados.
- As escalas do check-in têm limites de 1 a 5, validados no aplicativo e no banco.
- Chaves estrangeiras, índices únicos e constraints protegem relações e valores; a validação não fica só nos formulários.
- Migrations são alterações versionadas da estrutura e das regras do banco. Precisam ser aplicadas no ambiente que recebe o aplicativo.

## 5. Login, permissões e privacidade

**Autenticação responde “quem é você?”; autorização responde “o que você pode acessar?”.**

O Supabase Auth cuida da sessão. O aplicativo verifica o papel cadastrado no banco, e as políticas RLS restringem o acesso aos dados. Esconder um botão ou trocar a URL não substitui essa proteção.

Um profissional não recebe acesso aos registros de qualquer paciente por estar autenticado. O acesso clínico depende do credenciamento ativo e de vínculo autorizado com acompanhamento ativo. Paciente inativo e autorização revogada são situações diferentes: um vínculo inativo ainda autorizado permite gerenciamento da identificação, mas bloqueia o acesso profissional aos registros clínicos.

A chave publicável do Supabase pode estar no cliente: ela não deve conceder privilégios administrativos. A proteção depende das políticas de acesso. Chaves administrativas e a chave da OpenAI ficam no servidor, fora dos assets e do build Flutter.

**Se perguntarem sobre LGPD:** descreva os controles implementados — acesso por vínculo, consentimentos por fonte na personalização, possibilidade de desligar o apoio e excluir os dados dessa funcionalidade. Não afirme conformidade integral só porque esses controles existem. Bases legais, contratos, retenção, atendimento aos titulares e operação precisam de avaliação específica. Excluir dados de personalização não equivale a excluir toda a conta ou todo o histórico clínico.

## 6. Como funciona o vínculo por QR

1. O profissional habilitado solicita um convite temporário.
2. O servidor gera um token aleatório de 256 bits e guarda seu hash SHA-256.
3. O QR contém o token, em vez do identificador permanente do profissional.
4. O paciente autenticado lê ou insere o convite, confere o profissional e confirma.
5. O servidor verifica validade, revogação e limite de usos; o resgate e a atualização do vínculo são atômicos.
6. Ao trocar de profissional, a autorização anterior é revogada.

**Por que não basta usar um UUID no QR?** O convite precisa expirar, ser revogável e ter uso controlado. O QR facilita a entrada; a autorização efetiva é verificada no servidor. O hash protege o token persistido, mas não impede que alguém compartilhe o próprio QR enquanto ele estiver válido.

## 7. IA: a diferença mais importante da apresentação

Os dois fluxos usam `gpt-5-mini`, mas têm contratos diferentes:

| Ponto | Sugestões de apoio | Reflexão diária |
|---|---|---|
| Função | `ai-support-recommend` | `ai-daily-companion` |
| Entrada autorizada | Check-in, tendência de humor, temas confirmados e interações/feedback previstos no contrato. | Contexto do dia conforme as fontes consentidas; pode incluir texto do diário com autorização `diary_text`. |
| Texto livre do diário | Não entra no contrato do recomendador. | Pode ser enviado ao modelo pelo backend, limitado a 1.800 caracteres. |
| Saída | Seleção de um conteúdo predefinido, com IDs e códigos de motivo; sem conselho livre gerado. | Reflexão curta gerada, sujeita a limites e validações de formato e conteúdo. |
| Controle | Consentimento, fontes permitidas, validação da seleção e configuração de rollout. | Consentimento, fontes permitidas, validação da geração e configuração de rollout. |

**Resposta curta para “vocês enviam o diário à IA?”:** “Depende do recurso. O recomendador não recebe o texto livre. A reflexão diária pode usar esse texto quando o paciente autoriza especificamente essa fonte. O servidor verifica a autorização antes de consultar e enviar o contexto.”

O cliente não monta um prompt com todos os dados do paciente: o recomendador envia `requestId` e `trigger`; a reflexão envia um objeto vazio. As funções autenticadas resolvem o contexto no backend. Isso **não significa ausência de envio à OpenAI**: o backend envia o contexto permitido para realizar a geração ou seleção.

**Se o modelo falhar:** no modo conectado, o recomendador não usa regras locais como alternativa; fica sem nova sugestão. A indisponibilidade de IA não deve impedir o salvamento do diário ou check-in. A reflexão também pode ficar indisponível.

**Como reduzir respostas inadequadas?** O recomendador usa um catálogo fechado e valida a seleção no servidor e no app. A reflexão tem instruções, saída estruturada e filtros adicionais. Esses controles reduzem riscos; não garantem que o modelo nunca erre.

**Rollout** significa liberação controlada por ambiente, coorte ou percentual. **Kill switch** permite interromper a entrega. O código deixa staging e produção inicialmente bloqueados para a seleção conectada, até ativação explícita; confirme a configuração real da demo.

## 8. Limites do apoio e das notificações

- O sistema oferece apoio e organização do acompanhamento. Não deve ser apresentado como diagnóstico, prescrição automática ou substituto do profissional.
- Existem bloqueios de geração e rota de apoio humano para determinados sinais explícitos de risco. Isso não comprova detecção de todos os casos nem constitui avaliação clínica de risco.
- O contato de emergência permite abrir a discagem. Isso não equivale a chamar automaticamente, avisar o profissional ou garantir atendimento.
- As notificações de apoio são **locais, para Android e iOS**, dependem da permissão do aparelho e usam mensagens genéricas. O conteúdo detalhado fica no aplicativo autenticado.
- Esse gateway não oferece notificações no navegador ou desktop. Adicionar o site à tela inicial não cria essa capacidade.
- Um campo de preferência, como alerta de crise ou relatório automático, não comprova que exista um serviço completo de entrega. Demonstre somente os fluxos verificados.

## 9. O que é demonstração e o que ainda precisa evoluir

| Situação no projeto | Como explicar com precisão |
|---|---|
| Áreas conectadas | Usam dados persistidos no Supabase; conteúdo fictício precisa estar identificado como conta de demonstração. |
| Exercícios e biblioteca de vídeos | Há catálogos de protótipo com autoria/revisão explicitamente fictícias. Não representam revisão clínica comprovada. |
| Credenciamento | A migration `0017` habilita um modo de avaliação que libera novos profissionais automaticamente. Isso não valida o registro em um conselho profissional. A opção é administrativa e seu estado real deve ser conferido. |
| Vínculo de demonstração | Além do QR, há um fluxo temporário para novos pacientes elegíveis aprovarem explicitamente o vínculo com um profissional de teste. Não é um vínculo automático no cadastro. |
| Plataformas | O projeto tem alvos web, desktop e mobile. A documentação descreve publicação web e informa que não há APK publicado. Suporte no código não comprova homologação em todos os aparelhos. |
| Internet | Os fluxos conectados dependem de internet; não prometa operação offline completa ou sincronização posterior. |
| Resultados clínicos | A implementação demonstra comportamento do software. Eficácia e segurança clínica precisam de avaliação própria. |

## 10. Testes, publicação e falhas

O repositório contém testes de autenticação e papéis, registros do paciente, formulários, QR, permissões e fluxos do banco, contratos da IA, consentimentos, notificações e exposição de segredos. Também há testes de contraste e componentes da interface. Isso não equivale a uma auditoria completa de acessibilidade, segurança ou validação clínica.

Saiba explicar os tipos de verificação:

- `flutter analyze`: análise estática do código.
- `flutter test`: testes Dart/Flutter, incluindo regras e widgets.
- `scripts/test_supabase_migrations.sh`: migrations, permissões e fluxos SQL em PostgreSQL isolado via Docker.
- Testes TypeScript das funções: contratos e comportamento do backend com fronteiras simuladas.
- `scripts/check_client_bundle.sh`: verificação de exposição indevida de segredos no cliente.
- Ensaio com duas sessões: valida o percurso real entre paciente e profissional no ambiente da apresentação.

**Não diga que todos passaram hoje sem ter a execução correspondente.** Este guia foi elaborado pela leitura do projeto; não é um relatório de execução dessas suítes.

A publicação web separa a landing page em `/` e o aplicativo em `/app`, com configuração para Vercel. O frontend, as migrations e as Edge Functions têm etapas de publicação próprias. Atualizar o Flutter não atualiza automaticamente o banco nem as funções remotas.

**Se perguntarem sobre escala:** há índices e restrições no banco, mas capacidade de atender milhares de usuários exige teste de carga e medição. Seria necessário avaliar consultas, paginação, conexões, armazenamento, concorrência e limites dos fornecedores.

**Se perguntarem sobre custos:** os componentes a estimar são hospedagem, banco, armazenamento/tráfego de fotos e chamadas à IA. Não apresente um valor mensal ou capacidade por plano sem levantamento real.

## 11. Perguntas prováveis e respostas curtas

Use estas respostas como base para explicar com suas palavras.

| Pergunta | Resposta-base |
|---|---|
| Qual é o diferencial? | Reunir a jornada entre registros do paciente, vínculo autorizado e plano compartilhado. A IA é um recurso opcional dentro dessa jornada. Não fizemos aqui uma comparação de mercado que comprove exclusividade. |
| Por que não usar apenas um diário comum? | O Íris acrescenta o acompanhamento por um profissional autorizado e a consulta ao plano compartilhado. |
| Vocês desenvolveram o backend? | Desenvolvemos o esquema, migrations, políticas RLS, RPCs e funções da aplicação sobre a infraestrutura do Supabase. |
| O profissional pode ver todos os pacientes? | Não. A autorização é verificada no banco; os registros clínicos exigem vínculo autorizado e acompanhamento ativo. |
| O profissional altera o diário do paciente? | As políticas dos registros permitem escrita pelo próprio paciente e consulta pelo profissional autorizado. O profissional registra suas informações em anotações e planos próprios. |
| E se alguém alterar o ID na requisição? | O ID enviado não concede acesso. As políticas devem conferir a identidade da sessão e sua relação com o dado solicitado. |
| Posso ter nutricionista e psicólogo ao mesmo tempo? | A regra atual aceita um profissional autorizado por paciente por vez. Apoio multiprofissional simultâneo é uma evolução possível. |
| Quem valida o profissional? | Há status de credenciamento e controle administrativo. No modo de avaliação, novos cadastros podem ser liberados automaticamente; não há comprovação de validação automática junto a conselhos. |
| A IA cria o plano de cuidado? | Não. O profissional gerencia o plano. A IA atua nos recursos opcionais de apoio. |
| A IA foi treinada pela equipe? | O código integra um modelo externo por API. Não há neste repositório um processo de treinamento próprio ou fine-tuning. |
| A IA aprende com cada paciente? | Há personalização por contexto autorizado e feedback; isso não significa treinar um modelo individual com o diário. |
| O diário fica só no celular? | Não. Os registros conectados são persistidos no Supabase; a reflexão pode enviar texto autorizado à OpenAI. |
| E se a IA estiver fora do ar? | Os registros continuam independentes da geração. O apoio pode ficar indisponível, sem fabricar uma nova sugestão. |
| O sistema avisa alguém em uma crise? | Não prometemos monitoramento nem acionamento automático. Há caminhos de apoio humano e abertura de discagem para o contato cadastrado. |
| Está pronto para uso clínico amplo? | É um projeto acadêmico com fluxos implementados. Uso amplo exige validação clínica, de privacidade, segurança e operação. |
| Como provar que funciona? | Demonstrando o fluxo persistido entre duas contas e apresentando resultados reais dos testes executados, sem confundir funcionamento técnico com eficácia clínica. |
| Como o projeto pode evoluir? | Priorizar avaliação com usuários e profissionais, revisão real do conteúdo de apoio, segurança operacional e medição de desempenho; depois ampliar os fluxos conforme evidências e necessidades. |

## 12. Revisão final antes de entrar

Se tiver pouco tempo, estude nesta ordem:

1. Objetivo, público e jornada completa entre os dois perfis.
2. Diferença entre sugestão de apoio e reflexão diária, incluindo o envio autorizado do diário.
3. Autenticação, RLS e regras do vínculo.
4. Flutter, Supabase, PostgreSQL, RPC e Edge Functions.
5. Limitações reais: demonstração, credenciamento em avaliação, internet, notificações e ausência de validação clínica comprovada.
6. Testes, publicação, custos e próximos passos.

Antes da apresentação, confira login, vínculo, compartilhamento do plano e IA no equipamento que será usado. Utilize contas fictícias em perfis separados de navegador para não misturar sessões. Tenha um resultado anterior identificado e uma gravação como contingência; explique quando estiver mostrando algo previamente preparado.

Para responder sem se perder, use a sequência: **resposta direta → como funciona no Íris → limite atual**. Se não souber, diga o que foi implementado e qual verificação falta, sem inventar uma garantia ou um número.

## Onde conferir no projeto

- [Visão geral, configuração e publicação](../README.md)
- [Roteiro da apresentação com cinco pessoas](apresentacao_iris_5_pessoas.md)
- [Esquema e migrations do banco](../supabase/migrations)
- [Autenticação e validação de papel](../lib/features/auth/auth_service.dart)
- [Repositório de vínculo entre paciente e profissional](../lib/features/patient_professional/patient_professional_repository.dart)
- [Plano compartilhado com o paciente](../lib/features/care_plan/patient_care_plan_repository.dart)
- [Contrato do recomendador de apoio](../supabase/functions/ai-support-recommend/README.md)
- [Contrato da reflexão diária](../supabase/functions/ai-daily-companion/README.md)
- [Vínculo temporário da demonstração](demo_patient_link.md)
- [Modo de avaliação dos profissionais](../supabase/migrations/0017_professional_evaluation_mode.sql)
- [Catálogo demonstrativo de exercícios](../lib/features/support_exercises/data/mock_exercise_catalog.dart)
- [Testes do aplicativo](../test) e [testes do banco](../supabase/tests)
