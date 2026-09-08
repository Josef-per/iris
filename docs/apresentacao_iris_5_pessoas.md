# Apresentação do Íris — roteiro para 5 pessoas

Proposta para uma apresentação acadêmica de **25 minutos, mais 5 minutos de perguntas**, com 15 slides. Os tempos incluem as demonstrações. Substituam “Pessoa” pelos nomes do grupo.

O roteiro se baseia no código e na documentação do repositório. A existência de um recurso no código não comprova que esteja publicado ou funcionando no ambiente da apresentação: confirmem isso no ensaio.

## 1. Divisão da equipe

| Responsável | Tempo | Slides | Conteúdo | Dificuldade |
|---|---|---|---|---|
| Pessoa 1 | 3 min | 1–3 | Problema, público e proposta | Baixa |
| Pessoa 2 | 5 min | 4–6 | Jornada e demonstração do paciente | Média |
| Pessoa 3 | 5 min | 7–9 | Jornada e demonstração do profissional | Média |
| **Pessoa 4** | **6 min** | **10–12** | **Arquitetura, banco, autenticação e segurança** | **Alta** |
| **Pessoa 5** | **6 min** | **13–15** | **IA, notificações, validação e encerramento** | **Alta** |

As pessoas 4 e 5 ficam com as partes mais difíceis: precisam explicar o funcionamento interno, as condições de falha e as limitações técnicas. As pessoas 2 e 3 apresentam as operações na interface; a pessoa 4 explica como elas são implementadas.

## 2. Slides e falas sugeridas

### Pessoa 1 — Contexto e proposta

**Slide 1 — Íris: apoio ao acompanhamento entre consultas (40 s)**

Na tela: nome, logo, integrantes e identificação do TCC de Desenvolvimento de Sistemas da ETEC Dr. Julio Cardoso.

Fala sugerida: “O Íris é um aplicativo que reúne registros do paciente e ferramentas para o profissional acompanhar essas informações. Nosso projeto busca apoiar a continuidade do acompanhamento entre consultas.”

**Slide 2 — Problema e público-alvo (1 min)**

Na tela: registros dispersos, dificuldade de organizar o cotidiano e dois públicos — pacientes com transtornos alimentares e profissionais de saúde.

Fala sugerida: “O problema que orienta o projeto é como organizar informações do cotidiano para que possam ser consultadas pelo paciente e acompanhadas pelo profissional. O aplicativo reúne registros emocionais, alimentares e informações do plano de cuidado.”

Não apresentar estatísticas, entrevistas ou resultados de pesquisa que o grupo não tenha documentado.

**Slide 3 — Solução e escopo (1 min 20 s)**

Na tela: registrar → consultar → compartilhar pelo vínculo → acompanhar.

Fala sugerida: “Existem duas áreas, com funções e permissões diferentes. O paciente registra sua rotina e consulta seu histórico. O profissional acompanha pacientes vinculados e organiza o cuidado. O Íris é uma ferramenta complementar: não realiza diagnóstico nem substitui o atendimento profissional.”

Transição: “Agora vamos mostrar como essa proposta aparece na experiência do paciente.”

### Pessoa 2 — Área do paciente

**Slide 4 — Entrada e organização da área do paciente (1 min)**

Na tela: cadastro, login, início e perfil. Usar uma captura de tela do ambiente de demonstração.

Fala sugerida: “Depois da autenticação, o paciente encontra sua área de acompanhamento. A navegação reúne as ações do dia e o acesso às informações pessoais. O cadastro e o login dependem da configuração do Supabase.”

**Slide 5 — Registros do cotidiano (2 min 30 s, incluindo demonstração)**

Na tela: check-in, diário emocional e registro alimentar.

Demonstração: abrir a conta de teste, realizar um check-in, mostrar os campos do diário e do registro alimentar e salvar um registro breve. Usar conteúdo fictício, identificado como dado de demonstração.

Fala sugerida: “Esses registros organizam informações de diferentes momentos do dia. Após salvar, o painel diário é atualizado. Vamos mostrar o registro persistido para evidenciar o percurso completo, da entrada dos dados à consulta.”

**Slide 6 — Histórico, plano de cuidado e preferências (1 min 30 s)**

Na tela: histórico dos registros, consulta ao plano compartilhado e lembretes.

Demonstração: localizar o registro salvo e abrir um plano de cuidado previamente preparado na conta de teste.

Fala sugerida: “O paciente pode consultar o que registrou e acessar o plano compartilhado pelo profissional. Os recursos de apoio e suas preferências complementam essa jornada. A parte técnica da personalização será explicada ao final.”

Transição: “Com a experiência do paciente apresentada, vamos mostrar como o profissional utiliza essas informações.”

### Pessoa 3 — Área do profissional

**Slide 7 — Painel, agenda e pacientes (1 min 30 s)**

Na tela: dashboard, agenda e lista de pacientes ativos e inativos.

Demonstração: abrir a sessão de um profissional de teste previamente aprovado e mostrar a organização da área.

Fala sugerida: “O profissional possui um espaço próprio para organizar a agenda e os pacientes vinculados. O painel conectado consulta os dados do Supabase; os exemplos desta apresentação foram preparados em contas de teste.”

**Slide 8 — Acompanhamento e plano de cuidado (2 min)**

Na tela: detalhes do paciente, registros disponíveis, anotações clínicas, metas e medicações.

Demonstração: abrir um paciente de teste e mostrar o plano que apareceu na apresentação da pessoa 2. Se o fluxo estiver ensaiado, alterar uma meta demonstrativa e recarregar a área do paciente para mostrar a integração.

Fala sugerida: “O profissional pode consultar os registros permitidos pelo vínculo e organizar anotações e o plano de cuidado. As informações de metas e medicações são cadastradas pelo profissional; não são prescrições produzidas pela inteligência artificial.”

**Slide 9 — Vínculo por convite QR (1 min 30 s)**

Na tela: gerar convite → paciente lê ou digita → confere profissional → confirma vínculo.

Demonstração: gerar um convite temporário e mostrar a confirmação no paciente. Para não depender da câmera, ensaiar também a opção de digitação.

Fala sugerida: “O vínculo começa com um convite gerado pelo profissional aprovado. O paciente confere a identidade apresentada e confirma. O convite tem validade e pode ser revogado.”

Transição: “Agora vamos explicar a estrutura que sustenta esses fluxos e controla o acesso aos dados.”

### Pessoa 4 — Arquitetura, banco e segurança — parte difícil

**Slide 10 — Arquitetura do sistema (2 min)**

Na tela, transformar este fluxo em um diagrama:

```text
Interface Flutter / Dart
          ↓
Repositórios e serviços do aplicativo
          ↓
Supabase Auth + consultas e funções do banco (RPCs)
          ↓
PostgreSQL com regras de acesso por registro (RLS)

Recursos de IA: aplicativo → Edge Function → modelo → validação → aplicativo
```

Fala sugerida: “O Flutter constrói a interface. Os repositórios concentram operações de dados, enquanto os serviços cuidam de fluxos como autenticação. O Supabase oferece autenticação e acesso ao PostgreSQL. Operações que precisam de regras centralizadas são executadas por funções no servidor.”

Explicar a organização real: `lib/screens` reúne telas; `lib/features` organiza funcionalidades e repositórios; `lib/core` reúne infraestrutura; `supabase/migrations` versiona mudanças do banco. Evitar classificar todo o projeto como MVC apenas pela existência de pastas com esses nomes.

**Slide 11 — Dados e persistência (2 min)**

Na tela: modelo conceitual simplificado, sem apresentá-lo como diagrama físico completo:

```text
Usuário → perfil de paciente ou profissional
Paciente ↔ vínculo ↔ profissional
Paciente → registros emocionais e alimentares
Acompanhamento → agenda, anotações e plano de cuidado
Personalização → consentimentos, preferências e resultados de apoio
```

Fala sugerida: “Os dados são relacionados por identificadores. O vínculo determina quais pacientes podem ser acompanhados pelo profissional. As migrations registram a evolução do banco. Restrições e operações atômicas ajudam a manter os dados consistentes, inclusive quando duas solicitações acontecem próximas.”

Exemplo para explicar atomicidade: no resgate do convite, verificar sua disponibilidade e efetivar o vínculo precisam fazer parte da mesma operação protegida contra concorrência.

**Slide 12 — Autenticação e autorização (2 min)**

Na tela: identidade, papel, vínculo, RLS e segredos no servidor.

Fala sugerida: “Autenticação identifica quem entrou. Autorização define o que essa pessoa pode acessar. As políticas RLS aplicam restrições no banco, além das verificações da interface. O profissional começa com credenciamento pendente e não pode aprovar a própria conta.”

Pontos para dominar:

- O QR contém um token temporário, não o identificador permanente do profissional; o servidor persiste seu hash.
- Acompanhamento ativo/inativo e autorização ativa/revogada são estados distintos. Registros clínicos exigem acompanhamento ativo e acesso autorizado.
- A troca de profissional revoga a autorização anterior.
- Chaves administrativas e de IA ficam no servidor; a chave publicável no cliente não substitui políticas de acesso.
- Controles implementados não equivalem, por si só, a certificação de segurança ou comprovação de conformidade legal.

Transição: “Sobre essa base, o projeto adiciona recursos opcionais de IA, com contratos e controles próprios.”

### Pessoa 5 — IA, notificações e validação — parte difícil

**Slide 13 — Dois fluxos de inteligência artificial (2 min 30 s)**

Na tela:

| Fluxo | Entrada autorizada | Resultado |
|---|---|---|
| Sugestões de apoio | Sinais estruturados, como check-in, temas confirmados e interações | Seleção validada de conteúdo predefinido |
| Reflexão diária | Fontes consentidas; pode incluir texto do diário quando autorizado | Mensagem curta, com formato restrito e validação |

Fala sugerida: “O projeto possui dois fluxos diferentes. O recomendador usa sinais estruturados para selecionar conteúdo existente e não envia o texto livre do diário. Já a reflexão diária pode utilizar esse texto quando a fonte está autorizada. Em ambos os casos, o servidor valida a sessão e as condições do processamento.”

Detalhes para dominar:

- `ai-support-recommend` usa exclusivamente `gpt-5-mini` no contrato documentado e valida os identificadores retornados. Se não houver resultado válido ou condições de entrega, permanece sem sugestão, sem substituição por regras no modo conectado.
- `ai-daily-companion` gera uma reflexão curta; limita o texto livre de entrada, valida o JSON e restringe a formatação. Não deve ser descrita como simples seleção de uma frase pronta.
- A reflexão tem controles documentados de expiração e remoção quando fontes são alteradas, apagadas ou revogadas.
- O bloqueio de determinadas expressões sensíveis não constitui avaliação clínica de risco nem monitoramento de emergência.
- Disponibilidade depende da implantação, dos consentimentos e da configuração de cada fluxo. Não prometer sugestão nova durante a apresentação.

**Slide 14 — Notificações e comportamento em falhas (1 min 30 s)**

Na tela: preferências, notificações locais no celular, conteúdo discreto e funções essenciais independentes da IA.

Fala sugerida: “As notificações de apoio consideram preferências e regras de agendamento. A entrega local depende da plataforma e das permissões do aparelho. Se o modelo não produzir uma sugestão válida, isso não impede o salvamento do check-in ou do diário.”

Demonstrar preferências na interface. Mostrar entrega local apenas se tiver sido ensaiada em Android ou iOS. Uma demonstração web não comprova a entrega de notificações no celular.

**Slide 15 — Qualidade, limitações e encerramento (2 min)**

Na tela: testes existentes, dependências de execução e próximos passos.

Fala sugerida: “O repositório possui testes de autenticação, vínculo QR, registros, área profissional, contratos da IA e notificações. Para a apresentação, precisamos registrar quais verificações foram executadas e seus resultados. Ter testes no projeto não significa que todos passaram nesta versão.”

Separar claramente:

- **Implementado no repositório:** jornadas de paciente e profissional, vínculo, persistência e recursos de apoio descritos neste roteiro, sujeitos à configuração do ambiente.
- **A comprovar na demonstração:** execução integrada, disponibilidade das funções remotas e comportamento no dispositivo escolhido.
- **Evoluções previstas no plano:** resumos semanais para revisão profissional e infraestrutura ampliada de push, sem anunciá-los como entregues com base apenas no documento de planejamento.

Encerramento sugerido: “O Íris reúne registros do cotidiano e ferramentas de acompanhamento em duas experiências conectadas. A proposta é facilitar a organização dessas informações, mantendo o profissional responsável pelas decisões de cuidado. Obrigado; estamos disponíveis para as perguntas.”

## 3. Preparação da demonstração

1. Preparar contas exclusivas de teste para paciente e profissional, com dados fictícios identificados. Confirmar o credenciamento do profissional e o plano compartilhado antes do ensaio.
2. Usar sessões separadas, em dois perfis de navegador ou dispositivos. Deixar claro qual papel está em exibição.
3. Verificar conexão, configuração do Supabase, migrations aplicadas e acesso às telas escolhidas. Não projetar arquivos de ambiente ou painéis de secrets.
4. Ensaiar o percurso: paciente registra → histórico exibe → profissional consulta → plano é apresentado → convite é confirmado. Reservar uma conta sem vínculo ou um cenário ensaiado de reativação para o convite.
5. Testar os fluxos opcionais de IA antes da apresentação. Se indisponíveis, explicar o fluxo com o diagrama e identificar qualquer captura como registro de ensaio anterior.
6. Preparar capturas ou um vídeo curto do mesmo percurso como alternativa à falha de conexão. Não apresentar gravação como execução ao vivo.
7. Cronometrar cada bloco e ensaiar as transições. Se houver atraso, reduzir cliques repetidos e manter as explicações centrais.

## 4. Perguntas prováveis da banca

| Pergunta | Quem responde | Resposta-base |
|---|---|---|
| Qual problema o Íris pretende resolver? | Pessoa 1 | Organizar registros entre consultas e apoiar o acompanhamento pelo profissional. |
| Qual é a contribuição do projeto? | Pessoa 1 | Integrar jornada do paciente, área profissional e apoio opcional; não afirmar exclusividade de mercado sem pesquisa. |
| O que o paciente consegue fazer? | Pessoa 2 | Registrar, consultar histórico, acessar o plano compartilhado e configurar recursos disponíveis. |
| Como o profissional recebe acesso? | Pessoa 3 | Por vínculo confirmado pelo paciente a partir de convite temporário. |
| Por que Flutter e Supabase? | Pessoa 4 | A estrutura adotada combina interface multiplataforma, autenticação e banco relacional com regras no servidor. Justificar decisões históricas apenas se o grupo as conhece. |
| Basta esconder uma tela para proteger dados? | Pessoa 4 | Não. A autorização precisa ser aplicada também no servidor e no banco, com políticas e validação do vínculo. |
| O que evita dois resgates indevidos do convite? | Pessoa 4 | Validação de prazo e limite de usos junto de resgate atômico no servidor. |
| O diário é enviado à IA? | Pessoa 5 | O recomendador não usa texto livre; a reflexão diária pode usar texto autorizado. São contratos diferentes. |
| A IA prescreve ou diagnostica? | Pessoa 5 | Esse não é o escopo dos fluxos implementados; o plano de cuidado é gerenciado pelo profissional. |
| O que acontece se a IA falhar? | Pessoa 5 | O recomendador conectado fica sem sugestão; os registros principais continuam independentes dele. |
| O aplicativo já teve eficácia clínica comprovada? | Pessoa 5 | Não apresentar essa conclusão sem estudo documentado; implementação e testes técnicos não comprovam eficácia clínica. |
| Todos os testes passaram? | Pessoa 5 | Informar somente os resultados realmente executados para a versão apresentada. |

## 5. Material de estudo por integrante

- **Pessoa 1:** [README](../README.md), para objetivo e contexto; [plano de desenvolvimento](../PLANO_FINAL.md), reconhecendo seu caráter de planejamento.
- **Pessoa 2:** [telas do aplicativo](../lib/screens), [diário emocional](../lib/features/emotional_diary) e [histórico](../lib/features/patient_history).
- **Pessoa 3:** [área profissional](../lib/features/professional) e [repositório de convites](../lib/features/professional/professional_repository.dart).
- **Pessoa 4:** [inicialização](../lib/main.dart), [autenticação](../lib/features/auth), [infraestrutura Supabase](../lib/core/supabase) e [migrations](../supabase/migrations).
- **Pessoa 5:** [recomendador](../supabase/functions/ai-support-recommend/README.md), [reflexão diária](../supabase/functions/ai-daily-companion/README.md), [notificações](../lib/features/ai_support/notifications) e [testes](../test).

Priorizar telas reais e diagramas simples nos slides. As falas deste documento ficam nas notas do apresentador; não precisam ser projetadas integralmente.
