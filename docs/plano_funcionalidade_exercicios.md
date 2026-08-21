# Plano de produto — “Não estou bem” e exercícios de apoio

Status: proposta para validação de produto e clínica  
Escopo desta entrega: somente front-end Flutter, com dados fictícios em memória  
Público inicial recomendado: pessoas adultas em acompanhamento de transtornos alimentares  

## 1. Decisão de produto

A funcionalidade deve ser apresentada como **apoio breve para o momento**, e não
como diagnóstico, tratamento autônomo, substituto do profissional ou recurso de
emergência.

O acesso aos exercícios não deve pressupor crise. A Home oferece duas entradas:

1. **Exercícios**, para abrir diretamente o catálogo e recomendações;
2. **Não estou bem**, para escolher entre uma prática curta, vídeo, contato
   humano ou ajuda urgente.

Nenhuma dessas duas entradas obriga a pessoa a responder uma pergunta sobre
suicídio. A checagem de segurança aparece somente quando a própria pessoa toca
em **“Ajuda urgente”**. Essa ação permanece visível durante todo o fluxo.

O formato “estilo Duolingo” significa uma instrução por tela, passos pequenos,
interações simples e progresso claro. Não significa competição, pontuação ou
pressão para voltar ao app.

### Objetivo do MVP

Permitir que uma pessoa inicie uma prática sem triagem obrigatória e a conclua
em até cinco minutos, mantendo uma rota explícita de ajuda urgente acessível a
qualquer momento.

### Fora do escopo do MVP

- diagnosticar transtornos ou estimar risco clínico;
- recomendar mudanças em alimentação, medicação, peso ou tratamento;
- substituir psicólogo, psiquiatra, nutricionista ou atendimento de urgência;
- chatbot aberto de “terapia por IA”;
- persistência, integração com Supabase ou envio real ao profissional;
- conteúdo gerado livremente por IA;
- exercícios específicos para refeição sem revisão clínica especializada;
- uso por menores sem um fluxo próprio de consentimento e responsáveis.

## 2. Fluxo principal

```text
Home
  ├─ Exercícios
  │    └─ Catálogo / recomendação → exercício → check-out
  └─ Não estou bem
       └─ Como podemos apoiar você agora?
            ├─ Fazer uma prática curta
            │    └─ necessidade + tempo → recomendação → exercício
            ├─ Prefiro assistir
            │    └─ biblioteca de vídeos
            ├─ Falar com alguém seguro
            │    └─ rede de apoio / profissional (simulado)
            └─ Ajuda urgente
                 └─ Checagem de segurança
                      ├─ Sim / Talvez
                      │    └─ 192, 188, pessoa de confiança e profissional
                      └─ Não
                           └─ voltar às opções de apoio

Notificação personalizada
  └─ sugestão detalhada → exercício/reflexão, sem checagem obrigatória
```

“Ajuda urgente” deve permanecer disponível no cabeçalho de todas as telas do
fluxo. “Pior” no check-out não significa automaticamente risco de suicídio.
Sair do exercício nunca deve exigir confirmação culpabilizante.

## 3. Entradas e rota de segurança

### Entrada na Home

Adicionar dois acessos claros logo abaixo do cabeçalho e antes dos cards de
registro:

- **Exercícios** — “Práticas curtas para diferentes momentos.”; abre diretamente
  o catálogo;
- **Não estou bem** — “Encontre uma prática ou procure apoio.”; abre o menu de
  apoio em tela cheia.

O card “Não estou bem” mantém:

- título: **Não estou bem**;
- apoio: “Encontre uma prática ou procure apoio.”;
- ícone: apoio/cuidado, sem sirene;
- cor: roxo profundo da marca, não vermelho por padrão;
- ação: abre uma rota em tela cheia, não um bottom sheet.

### Primeira tela de “Não estou bem”

Texto sugerido:

> Sinto muito que este momento esteja difícil. Como podemos apoiar você agora?

Opções grandes e explícitas:

- **Fazer uma prática curta**;
- **Prefiro assistir**;
- **Falar com alguém seguro**;
- **Ajuda urgente**.

As três primeiras opções seguem sem checagem. A pessoa também pode abrir o
catálogo pela Home sem passar por esta tela.

### Checagem somente após “Ajuda urgente”

Texto sugerido:

> Você corre risco de se machucar, não consegue se manter em segurança ou está
> com um sintoma físico grave agora?

Opções:

- **Sim**;
- **Talvez / não tenho certeza**;
- **Não** — volta às opções de apoio, sem bloquear exercícios.

“Sim” e “Talvez” seguem a mesma rota determinística. Nenhuma IA participa dessa
decisão.

### Tela “Ajuda urgente”

Ordem recomendada:

1. **Ligar para o SAMU — 192** (`tel:192`) para risco ou emergência;
2. **Ligar para o CVV — 188** (`tel:188`) para apoio emocional 24 horas;
3. **Chamar uma pessoa de confiança** (simulado no MVP);
4. **Falar com meu profissional** (simulado e claramente marcado);
5. texto curto: “Se puder, fique com alguém e afaste-se de meios que possam
   ferir você enquanto busca ajuda.”;
6. “Voltar” continua disponível, sem esconder as ações acima.

O app não deve afirmar que notificou ou acionou alguém no protótipo. A interface
deve dizer “Demonstração — nenhuma mensagem será enviada”.

## 4. Seleção da necessidade

Pergunta: **“O que ajudaria mais neste momento?”**

Cards de resposta, sem certo ou errado:

- “Voltar para o presente”;
- “Lidar com um pensamento difícil”;
- “Dar nome ao que sinto”;
- “Ser mais gentil comigo”;
- “Dar um próximo passo seguro”;
- “Não sei — escolha algo simples”.

Depois, no máximo duas perguntas:

- **Tempo/energia:** “1–2 min”, “3 min” ou “5 min”;
- **Formato:** “Interativo”, “Ouvir” ou “Assistir”.

Preferências sensoriais devem existir em “Ajustar”: sem animação, sem som,
evitar exercícios focados na respiração e usar texto maior. O app nunca deve
obrigar a fechar os olhos, controlar a respiração ou tocar o próprio corpo.

## 5. Catálogo fictício do MVP

Todo conteúdo precisa ter autoria, fonte conceitual, revisão clínica, versão,
data da próxima revisão e contraindicações registradas, mesmo que esses campos
não apareçam por inteiro para o paciente.

| Exercício | Necessidade | Duração | Mecânica interativa | Encerramento |
|---|---|---:|---|---|
| Ancorar no presente | Redirecionar a atenção para o ambiente | 2 min | Notar cor, forma, som e um ponto de apoio, sempre com alternativa de pular | Ensinar o atalho “ver, ouvir ou apoiar-se” para repetir apenas uma parte da prática |
| Perceber e nomear | Observar uma experiência sem tentar resolvê-la | 3 min | Selecionar uma palavra aproximada e, opcionalmente, completar “Agora há ___ em mim” | Conectar nomeação a uma continuação concreta: retomar uma tarefa pequena ou pedir companhia |
| Dar espaço ao pensamento | Notar pensamento como pensamento | 3 min | Escrever opcionalmente uma versão curta, usar “Estou notando o pensamento de que…” e escolher uma direção de dois minutos | Repetir o roteiro de distanciamento e escolher um gesto; buscar ajuda humana diante de risco |
| Falar comigo como com alguém querido | Usar um tom menos duro e identificar um cuidado possível | 3 min | Escolher uma frase realista, adaptá-la para si e apontar um cuidado pequeno | Converter gentileza em uma pergunta prática: diminuir, pausar, pedir ou adiar |
| Próximo passo seguro | Transformar uma necessidade em ação clara e voluntária | 2 min | Identificar o tipo de apoio e escolher um passo específico que caiba em poucos minutos | Tornar o passo observável e oferecer uma versão ainda menor se ele não couber |

Os conceitos são inspirados nas técnicas de grounding, perceber/nomear,
desprender-se de pensamentos difíceis, agir segundo valores e gentileza consigo
da OMS. Os roteiros finais não devem ser copiados sem verificar licenciamento;
devem ser escritos e aprovados por especialistas brasileiros.

### Conteúdo que exige fase clínica posterior

- suporte antes, durante ou depois de refeições;
- manejo de impulso de compulsão, purgação ou restrição;
- plano de prevenção de recaída;
- exposição, reestruturação cognitiva específica ou tarefas de CBT-ED;
- qualquer orientação nutricional.

Esses módulos só entram depois de definidos público, contraindicações,
acompanhamento profissional e procedimento para piora.

## 6. Player interativo “leve, não competitivo”

Cada exercício usa de três a seis telas:

- cabeçalho com “Sair”, título e “Ajuda urgente”;
- indicador `Etapa 2 de 5`, legível por leitor de tela;
- uma instrução curta por tela;
- no máximo uma decisão principal;
- botões com rótulo, nunca apenas cor ou ícone;
- feedback neutro: “Etapa concluída” ou “Você percebeu isso agora”;
- “Pular esta etapa” sempre disponível;
- animação suave opcional e respeitando redução de movimento.

### Usar da inspiração do Duolingo

- microlições;
- cards tocáveis;
- ordenar ou relacionar itens simples;
- progresso visível;
- feedback imediato e acolhedor;
- retomada do ponto atual durante a sessão;
- sensação de descoberta de novas ferramentas.

### Não usar neste contexto

- ofensiva diária, sequência perdida ou lembretes com culpa;
- XP, vidas, ranking, liga, competição ou comparação social;
- cronômetro ou punição por pausa/erro;
- sons de erro, vermelho/verde como julgamento emocional;
- confete quando a pessoa relata sofrimento;
- “acertar” uma emoção;
- métricas de calorias, macros, peso ou “comida boa/ruim”;
- avatar cujo corpo muda com desempenho;
- ajuda de emergência bloqueada por progresso.

## 7. Vídeo-aulas como rota alternativa

A biblioteca abre tanto pela recomendação quanto por “Prefiro assistir”. O
foco visual ainda deve favorecer “Começar exercício interativo”.

Dados fictícios iniciais:

- “Como voltar ao presente” — 3 min;
- “Pensamentos não são ordens” — 4 min;
- “Gentileza em momentos difíceis” — 5 min.

Cada card informa duração, tema, autor/revisor fictício claramente identificado
como demonstração e data de revisão. O player deve oferecer legenda, transcrição,
velocidade, pausar e alternativa somente em texto. O vídeo não começa sozinho.

## 8. Check-out sem promessa terapêutica

Pergunta: **“Como este momento está agora?”**

- “Pior”;
- “Igual”;
- “Um pouco melhor”;
- “Melhor”.

Não usar nota, estrelinhas ou “sucesso/falha”.

- **Pior:** priorizar “Falar com alguém” e deixar “Ajuda urgente” em destaque;
  oferecer apenas uma alternativa leve, sem presumir crise nem insistir em
  completar outra atividade.
- **Igual:** permitir escolher outra ferramenta, vídeo ou encerrar.
- **Um pouco melhor / melhor:** reconhecer o tempo dedicado e permitir concluir.

Resumo fictício opcional:

> Você praticou “Ancorar no presente” por cerca de 2 min. Marcou que está “um
> pouco melhor”. Nada foi enviado ao seu profissional.

Compartilhamento futuro deve ser granular e opt-in para cada sessão.

## 9. Espaço preparado para IA

### MVP: recomendador simulado e explicável

Implementar `MockExerciseRecommender`, uma tabela de regras local que usa apenas:

- necessidade escolhida;
- tempo disponível;
- formato;
- preferências de acessibilidade;
- feedback da sessão atual.

Exibir “Sugestão para você” e uma explicação como: “Você pediu algo interativo,
sem foco na respiração, para cerca de 2 minutos.” Não rotular essa regra como IA.

### Evolução segura

Se IA real for avaliada, sua primeira função deve ser **selecionar e ordenar**
itens de uma lista aprovada — nunca escrever um exercício clínico em tempo real.

Contrato proposto:

```text
RecommendationContext estruturado
  → regras de segurança determinísticas
  → IA retorna somente exerciseId + motivo + confiança
  → validação contra catálogo permitido e contraindicações
  → fallback para recomendação por regras
  → explicação e opção “Escolher outra”
```

Guardrails obrigatórios:

- triagem e rota de emergência nunca dependem da IA;
- lista permitida de conteúdos versionados e revisados;
- saída validada por schema; qualquer texto livre é descartado;
- opção de desligar personalização sem perder funcionalidade;
- consentimento específico e revogável antes de usar dados de saúde;
- informar quais sinais influenciaram a sugestão;
- não inferir diagnóstico, risco, intenção suicida, calorias ou peso;
- não treinar modelo com dados do paciente por padrão;
- não enviar diário ou texto livre a modelo no primeiro lançamento;
- registrar versão do modelo, catálogo e motivo da recomendação;
- monitorar diferença de resultados e piora entre grupos;
- revisão humana, canal de contestação e desligamento imediato.

Antes de alegar finalidade terapêutica, deve haver avaliação regulatória: a
Anvisa diferencia software de registro/comunicação de software destinado a
diagnóstico ou tratamento; IA usada para um propósito médico pode exigir
regularização e evidência clínica.

## 10. Arquitetura front-end proposta

```text
lib/features/support_exercises/
  data/
    mock_exercise_catalog.dart
    mock_video_catalog.dart
    mock_exercise_recommender.dart
  domain/
    exercise.dart
    exercise_step.dart
    recommendation_context.dart
    support_session.dart
  presentation/
    support_flow_screen.dart
    safety_check_view.dart
    immediate_help_view.dart
    need_picker_view.dart
    recommendation_view.dart
    exercise_player_view.dart
    video_library_view.dart
    support_checkout_view.dart
    widgets/
      exercise_progress.dart
      option_card.dart
      persistent_help_action.dart
```

Modelos mínimos:

- `Exercise`: id, título, objetivo, duração, modos, etapas, tags de segurança,
  fontes, versão e status de revisão;
- `ExerciseStep`: tipo da interação, prompt, opções, possibilidade de pular e
  semântica de acessibilidade;
- `RecommendationContext`: necessidade, tempo, formato e preferências;
- `SupportSession`: etapa atual e respostas somente em memória;
- `SupportVideo`: metadados, transcrição fictícia e revisão.

Não incluir repository Supabase nesta fase. Ao fechar o fluxo, todos os dados da
sessão são descartados. O código deve deixar isso explícito para evitar que o
mock seja confundido com prontuário.

## 11. Acessibilidade e inclusão

Meta: WCAG 2.2 AA no Flutter web e boas práticas equivalentes no mobile.

- navegação completa por teclado e ordem de foco previsível;
- foco visível e nunca escondido por barra ou modal;
- alvos de toque com pelo menos 48 × 48 dp no app;
- texto funcional com escala de 200% e reflow em 320 px;
- contraste AA e informação nunca transmitida só por cor;
- leitores de tela anunciam título, etapa, seleção e mudança de status;
- botão não habilitado não é a única forma de explicar o próximo passo;
- redução de movimento respeitada e sem flashes;
- legenda, transcrição e alternativa textual para audiovisual;
- linguagem simples, acolhedora, sem gênero e sem infantilização;
- modo escuro testado com o tema já existente.

## 12. Privacidade e dados de saúde

Dados de humor, sintomas e transtorno alimentar são dados pessoais sensíveis. A
evolução deve aplicar finalidade, adequação, necessidade, transparência,
segurança, prevenção e não discriminação da LGPD.

Para o protótipo:

- usar nomes e conteúdos inequivocamente fictícios;
- manter respostas apenas em memória;
- não registrar texto sensível em logs/analytics;
- não pedir microfone, câmera, contatos ou localização;
- mostrar “Nada será salvo ou enviado” no resumo.

Para uma fase conectada:

- mapear base legal com assessoria jurídica, sem depender de um checkbox genérico;
- separar consentimento de personalização, compartilhamento e pesquisa;
- coletar apenas o dado necessário para cada finalidade;
- permitir acesso, correção, exportação e exclusão quando aplicável;
- criptografar trânsito/repouso, controlar acesso e definir retenção;
- fazer RIPD/DPIA antes de IA ou análise de risco sensível.

## 13. Validação de conteúdo e governança

Antes de teste com pacientes, formar um grupo mínimo com:

- psicólogo com experiência em transtornos alimentares;
- nutricionista especializado;
- médico/psiquiatra para sinais de urgência;
- pessoa com experiência vivida, remunerada e com direito de veto sobre linguagem;
- especialista de acessibilidade e responsável de privacidade.

Cada exercício passa por revisão de segurança, linguagem, acessibilidade,
direitos autorais, público indicado e contraindicações. O catálogo mostra
`draft`, `clinicallyReviewed` e `retired`; somente `clinicallyReviewed` poderá
ser usado quando sair do modo demonstração.

Conteúdo de crise e números de contato devem ter responsável e revisão
trimestral. A tela deve informar a data da última verificação.

## 14. Critérios de aceite do protótipo

1. “Exercícios” abre o catálogo sem checagem de segurança.
2. “Não estou bem” abre opções de apoio e não uma pergunta sobre suicídio.
3. Somente “Ajuda urgente” abre a checagem de segurança.
4. “Sim” ou “Talvez” na checagem leva diretamente à ajuda, sem recomendador.
5. 192 e 188 ficam visíveis e acionáveis na tela de ajuda.
6. A pessoa pode acessar “Ajuda urgente” de qualquer etapa em um toque.
7. Uma sugestão por notificação abre seu detalhe sem checagem obrigatória.
8. Há pelo menos cinco exercícios fictícios, três deles completamente
   navegáveis, com três ou mais tipos de interação.
9. Vídeo é alternativa, com legenda/transcrição fictícia e sem autoplay.
10. A recomendação mock respeita tempo, formato e exclusão de respiração.
11. O check-out aceita qualquer resposta sem julgamento ou bloqueio; “Pior” não
    é tratado automaticamente como ideação suicida.
12. Nenhum fluxo usa sequência, XP, ranking, calorias, peso ou punição.
13. Nenhuma resposta é persistida e nenhuma mensagem é realmente enviada.
14. O fluxo funciona em 320 px, tablet, tema claro/escuro e texto a 200%.
15. Testes comprovam que a rota de urgência não pode ser sobrescrita pela
    recomendação simulada.

## 15. Testes propostos

### Widget e navegação

- Home abre o catálogo diretamente por “Exercícios”;
- “Não estou bem” abre o menu de apoio sem checagem obrigatória;
- notificação abre a sugestão sem checagem obrigatória;
- somente “Ajuda urgente” abre a pergunta de segurança;
- cada resposta de segurança chega à rota correta;
- ajuda permanece acessível em todas as etapas;
- pular, voltar e sair preservam controle da pessoa;
- cada tipo de `ExerciseStep` renderiza e avança corretamente;
- resultado “Pior” prioriza ajuda humana sem presumir intenção suicida;
- modo vídeo expõe legenda/transcrição;
- nenhum CTA fictício afirma ter enviado mensagem.

### Recomendador

- mesma entrada produz mesma recomendação no mock;
- preferência “sem respiração” filtra conteúdos incompatíveis;
- formato e duração são respeitados;
- catálogo vazio ou erro usa fallback estático seguro;
- rota de urgência nunca chega ao recomendador.

### Acessibilidade e visual

- `Semantics` para progresso e estado selecionado;
- percurso de teclado e foco visível no web;
- golden tests em 320, 768 e 1280 px, claro/escuro;
- teste com `textScaler` em 2.0 sem overflow;
- contraste verificado para estados normal, foco e desabilitado;
- animação desativada quando redução de movimento estiver ativa.

## 16. Fases de entrega

### Fase 1 — segurança e estrutura

- CTAs “Exercícios” e “Não estou bem” na Home;
- shell do fluxo em tela cheia;
- menu de apoio, checagem opcional e tela “Ajuda urgente”;
- modelos, catálogo/recomendador mock;
- testes das rotas críticas.

### Fase 2 — experiência principal

- seletor de necessidade, tempo e formato;
- player genérico por schema;
- três exercícios completos e dois em prévia;
- check-out e resumo em memória;
- responsividade, tema e Semantics.

### Fase 3 — mídia e acabamento

- biblioteca e player fictício de vídeo;
- transcrições e preferências sensoriais;
- todos os cinco exercícios completos;
- revisão de linguagem e testes de usabilidade.

### Fase 4 — somente após governança clínica

- piloto controlado com pacientes e profissionais;
- critérios clínicos para módulos ligados à alimentação;
- decisão regulatória e de privacidade;
- experimento do recomendador real contra regras, com kill switch e auditoria.

## 17. Métricas úteis (sem transformar sofrimento em pontuação)

No protótipo, coletar apenas durante testes consentidos:

- tempo até iniciar uma ferramenta;
- conclusão ou saída voluntária por etapa;
- escolha entre interativo, áudio e vídeo;
- avaliação pós-atividade agregada;
- facilidade de encontrar ajuda e de abandonar o fluxo;
- falhas de acessibilidade e compreensão.

Não usar “dias seguidos”, tempo total no app ou número de exercícios como meta
de saúde. O objetivo é a pessoa encontrar ajuda adequada com menos esforço, não
maximizar retenção.

## 18. Base de evidências e normas consultadas

- [OMS — Doing What Matters in Times of Stress](https://www.who.int/publications/i/item/9789240003927): práticas breves de grounding, nomeação, distanciamento, valores e autocompaixão.
- [NICE NG69 — Eating disorders: recognition and treatment](https://www.nice.org.uk/guidance/ng69/chapter/recommendations): self-help deve ser focado no transtorno, baseado em CBT e, em cenários indicados, acompanhado por suporte breve; o app não substitui cuidado especializado.
- [Thomas et al., 2024 — técnicas de mudança em intervenções digitais para transtornos alimentares](https://pubmed.ncbi.nlm.nih.gov/39088817/): intervenções mais fundamentadas em teoria tiveram melhores resultados; não foi demonstrado que uma técnica isolada determine eficácia.
- [Linardon et al., 2021 — conteúdo baseado em evidência de apps para transtornos alimentares](https://pubmed.ncbi.nlm.nih.gov/33534176/): apps disponíveis variam na incorporação de técnicas com base em evidência.
- [Cheng et al., 2021 — gamificação em apps de saúde mental](https://pmc.ncbi.nlm.nih.gov/articles/PMC8669581/): gamificação pode favorecer engajamento em alguns contextos, mas a evidência não autoriza transportar pontuação/competição sem avaliação para transtornos alimentares.
- [Ministério da Saúde — Prevenção do suicídio](https://www.gov.br/saude/pt-br/assuntos/saude-de-a-a-z/s/suicidio-prevencao/suicidio-prevencao): CVV 188 e serviços de emergência, incluindo SAMU 192, UPA e pronto-socorro.
- [Ministério da Saúde — SAMU 192](https://www.gov.br/saude/pt-br/composicao/saes/samu-192): serviço gratuito 24 horas para urgências e emergências.
- [Stanley et al., 2018 — Safety Planning Intervention](https://pubmed.ncbi.nlm.nih.gov/29998307/): planejamento de segurança com acompanhamento foi associado a menos comportamento suicida e maior engajamento em cuidado; um app não deve reduzir isso a uma tela automática sem suporte.
- [WCAG 2.2](https://www.w3.org/TR/WCAG22/): contraste, foco, teclado, status, tamanho de alvo, movimento e outras exigências de acessibilidade.
- [LGPD — Lei nº 13.709/2018](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709compilado.htm): princípios de tratamento e proteção reforçada de dados pessoais sensíveis de saúde.
- [OMS — ética e governança de IA para saúde](https://www.who.int/news/item/28-06-2021-who-issues-first-global-report-on-artificial-intelligence-ai-in-health-and-six-guiding-principles-for-its-design-and-use): autonomia, segurança, transparência, responsabilidade, inclusão e sustentabilidade.
- [Anvisa — perguntas e respostas da RDC 657/2022](https://www.gov.br/anvisa/pt-br/centraisdeconteudo/publicacoes/produtos-para-a-saude/manuais/software-como-dispositivo-medico-perguntas-e-respostas): distinção entre software administrativo/comunicacional e software com finalidade clínica diagnóstica ou terapêutica.

## 19. Riscos a resolver antes de produção

- definir faixa etária e fluxo próprio para menores;
- validar termos de crise e sinais físicos com equipe brasileira;
- definir disponibilidade real de profissional e expectativa de resposta;
- não adaptar diretamente material protegido sem licença adequada;
- avaliar Anvisa, LGPD, ética profissional e responsabilidade clínica conforme
  a finalidade final declarada;
- testar linguagem com pessoas em recuperação para eliminar gatilhos;
- provar segurança e benefício antes de liberar IA com dados reais.
