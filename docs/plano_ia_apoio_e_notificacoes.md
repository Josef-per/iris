# Plano de produto — IA de apoio baseada em diário e humor

Status: proposta para validação de produto, clínica, privacidade e regulação  
Base: `plano_funcionalidade_exercicios.md`  
Escopo inicial: front-end Flutter com dados fictícios e notificações simuladas  
Público inicial recomendado: pessoas adultas em acompanhamento de transtornos alimentares  

## 1. Decisão de produto

O nome visível da funcionalidade deve ser **Sugestões de apoio**, não “terapeuta
IA” ou “conselhos clínicos”. Seu objetivo é oferecer um convite breve e
voluntário para:

- fazer uma pergunta de autorreflexão;
- iniciar um exercício já revisado;
- assistir a um conteúdo curto;
- procurar alguém seguro da rede de apoio;
- anotar um tema para conversar com o profissional.

A IA não deve diagnosticar, interpretar a pessoa como verdade, criar tratamento,
dar instruções sobre alimentação/medicação nem escrever livremente para a tela
bloqueada. Ela seleciona conteúdos de um catálogo fechado, aprovado e
versionado; o aplicativo monta a mensagem com templates fixos.

### Objetivo do MVP

Demonstrar, com dados fictícios, como um registro de humor ou diário pode gerar
uma sugestão de apoio explicável, discreta e controlável pelo paciente, sem
enviar dados a um modelo, servidor ou sistema de notificação real.

### Princípio central

```text
IA propõe uma categoria ou um ID aprovado.
Regras determinísticas decidem se e quando pode haver notificação.
Templates revisados decidem o texto que a pessoa recebe.
```

Isso reduz alucinação, prompt injection pelo texto do diário, exposição na tela
bloqueada e conselhos incompatíveis com o plano de cuidado.

## 2. Limites explícitos

### A funcionalidade pode

- observar sinais estruturados escolhidos pelo usuário;
- apontar uma possível tendência em linguagem incerta;
- perguntar se essa interpretação combina com a percepção da pessoa;
- selecionar um exercício do catálogo do plano anterior;
- sugerir contato com uma pessoa **segura escolhida pelo usuário**;
- explicar quais dados e regras influenciaram a sugestão;
- aceitar correção, recusa, pausa ou desativação.
  
### A funcionalidade não pode

- substituir psicoterapia ou atendimento do profissional;
- monitorar crises ou prometer que alguém está acompanhando o diário;
- estimar ou pontuar risco de suicídio em segundo plano;
- notificar amigo, familiar ou profissional automaticamente;
- usar diário como instrução para o modelo;
- gerar diagnóstico, prognóstico ou plano terapêutico;
- recomendar restrição, compensação, exercício físico, peso, calorias, macros,
  jejum, purgação, suplementos ou mudanças de medicação;
- afirmar causas: “você está assim porque…”;
- afirmar estados clínicos: “seu quadro piorou” ou “você está deprimido”;
- usar linguagem relacional que incentive dependência, como “só eu entendo você”;
- usar urgência artificial, sequência diária, culpa ou medo de perder progresso;
- usar conteúdo do diário no título ou corpo da notificação do sistema;
- funcionar para menores antes de existir um projeto específico de proteção.

### A IA pode dar conselhos?

**Sim, desde que sejam sugestões de apoio de baixo risco e não orientações
clínicas.** O produto deve trabalhar com três níveis:

| Nível | O que a IA faz | Decisão |
|---|---|---|
| 1 — Seleção segura | escolhe uma reflexão, exercício, vídeo ou ação de conexão de um catálogo aprovado | permitido no MVP |
| 2 — Formulação limitada | redige uma frase curta e tentativa dentro de uma categoria aprovada | somente em piloto controlado, dentro do app |
| 3 — Orientação clínica | diagnostica, prescreve, interpreta risco ou orienta alimentação, medicação e tratamento | proibido sem produto clínico validado e regularizado |

Na maior parte dos casos, o que a pessoa percebe como “conselho personalizado”
pode ser produzido com o nível 1:

> Você registrou alguns dias mais difíceis e prefere práticas curtas. Talvez
> “Ancorar no presente” seja uma opção agora. Isso faz sentido para você?

O modelo escolhe os IDs e os motivos; um template aprovado cria a frase. Esse é
o padrão recomendado para produção inicial.

#### Conselhos permitidos

- convidar a nomear uma emoção ou necessidade;
- propor uma pergunta de autorreflexão;
- sugerir um exercício aprovado e compatível com as preferências;
- sugerir uma pausa breve ou mudança simples de ambiente;
- convidar a procurar alguém seguro escolhido pela própria pessoa;
- sugerir guardar um tema para conversar com o profissional;
- reconhecer incerteza e perguntar se a interpretação combina com a pessoa.

Exemplos:

- “Talvez ajude separar dois minutos para perceber o que você precisa agora.”;
- “Você gostaria de experimentar uma prática curta para voltar ao presente?”;
- “Se fizer sentido, considere conversar com alguém que seja seguro para você.”;
- “Este tema pode ser útil na próxima conversa com seu profissional. Quer
  guardá-lo?”

#### Conselhos proibidos

- “Você deveria reduzir/aumentar o que come.”;
- “Compense essa refeição fazendo exercício.”;
- “Pare, aumente ou troque sua medicação.”;
- “Você está com depressão/ansiedade/anorexia.”;
- “Seu quadro está piorando.”;
- “Não conte isso ao seu profissional/familiar.”;
- “Termine esse relacionamento” ou “confronte essa pessoa.”;
- “Você não está em risco” ou qualquer conclusão automática sobre crise;
- prometer que determinada ação fará a pessoa melhorar.

#### Formulação generativa limitada

Depois de o nível 1 estar validado, um piloto pode permitir que a IA redija a
frase de apoio, mas apenas se todas estas condições forem atendidas:

- aparece somente dentro do app autenticado, nunca diretamente no push;
- usa sinais estruturados ou tópicos confirmados, não o diário bruto por padrão;
- tem no máximo duas frases curtas;
- usa linguagem tentativa: “talvez”, “se fizer sentido”, “você gostaria?”;
- só pode propor ações presentes em uma allowlist;
- não adiciona fato, causa, diagnóstico ou interpretação não confirmada;
- passa por schema, filtros determinísticos e catálogo de termos/temas proibidos;
- inclui uma ação concreta aprovada ou permite não fazer nada;
- mostra “Por que isto?” e “Isso não combina comigo”;
- qualquer incerteza, falha de validação ou tema sensível produz silêncio ou
  template fixo, não uma tentativa livre;
- é avaliada em shadow mode e red team antes de chegar a pacientes.

Um aviso de “a IA pode errar” não substitui essas restrições. A segurança deve
estar no contrato de saída e na arquitetura, não apenas no texto legal.

## 3. Separação entre apoio e segurança

Notificações são assíncronas, podem atrasar, ser silenciadas ou vistas por outra
pessoa. Portanto, não são um canal de emergência.

O diário deve sempre oferecer, depois de salvar, um card estático:

> Quer apoio agora? Você pode iniciar um exercício, abrir “Não estou bem” ou
> escolher “Ajuda urgente”.

Esse card não depende de análise do texto. Exercícios e sugestões por
notificação abrem sem checagem obrigatória. A pergunta de segurança, os números
192/188 e a rota determinística aparecem somente quando a pessoa escolhe “Ajuda
urgente”, como definido no plano anterior.

O produto deve dizer com clareza:

> A Íris não monitora seu diário em tempo real e não aciona serviços, pessoas de
> confiança ou profissionais automaticamente.

Se, no futuro, for estudada detecção de conteúdo de risco, ela será um projeto
clínico e regulatório separado. Não se deve introduzi-la silenciosamente como
parte do recomendador de notificações.

## 4. Fluxo do paciente

```text
Configurar Sugestões de apoio
  ├─ ver exemplos e limites
  ├─ escolher fontes de dados
  ├─ escolher tipos de sugestão
  ├─ escolher frequência e horários seguros
  ├─ escolher privacidade da notificação
  └─ só então pedir permissão do sistema

Registrar humor ou diário
  └─ salvar normalmente
       ├─ acessos estáticos a exercício, “Não estou bem” e “Ajuda urgente”
       └─ mecanismo fictício cria um candidato de sugestão
            └─ política determinística valida horário, frequência e consentimento
                 └─ notificação genérica simulada
                      └─ desbloquear e abrir a Íris
                           └─ sugestão detalhada
                                ├─ isso combina comigo
                                ├─ não combina / corrigir
                                ├─ refletir
                                ├─ fazer exercício
                                ├─ falar com alguém seguro
                                ├─ guardar para o profissional
                                └─ agora não / parar sugestões

“Ajuda urgente” permanece visível, mas a sugestão não exige uma checagem antes
de reflexão ou exercício.
```

## 5. Consentimento e controles

A permissão do sistema operacional não substitui a escolha informada sobre os
dados de saúde. Antes de pedir permissão de notificação, mostrar:

- o que será personalizado;
- exemplos de uma notificação bloqueada e de uma sugestão dentro do app;
- quais dados podem ser usados;
- o que nunca será feito;
- como desligar e excluir os sinais derivados.

### Fontes independentes, desligadas por padrão no protótipo

- humor dos últimos dias;
- tags escolhidas no diário;
- texto livre do diário — controle separado e indisponível no primeiro piloto;
- exercícios concluídos e avaliação pós-exercício;
- notificações abertas, dispensadas ou marcadas como inúteis.

Desligar uma fonte deve impedir novas sugestões baseadas nela. “Usar diário” não
pode ser obrigatório para receber lembretes genéricos ou usar os exercícios.

### Preferências

- categorias: reflexão, exercício, vídeo, conexão humana e conversa profissional;
- frequência: nunca, até 1 por semana, até 2 ou até 3;
- janela escolhida pela própria pessoa;
- dias permitidos;
- som e vibração desligados por padrão para esta categoria;
- prévia genérica ou nenhuma prévia na tela bloqueada;
- pausa por 7 ou 30 dias;
- botão permanente “Desativar sugestões personalizadas”.

Não usar consentimento único para personalização, compartilhamento com
profissional, pesquisa e treinamento de modelo. São finalidades diferentes.

## 6. Dados permitidos e proibidos

### MVP fictício

| Dado | Uso permitido | Exemplo |
|---|---|---|
| Humor estruturado | tendência simples | 3 de 4 registros recentes foram “difícil” |
| Tag escolhida | escolher categoria | “sobrecarga” → reflexão/grounding |
| Preferência | filtrar conteúdo | sem respiração, 2 minutos, texto |
| Feedback de exercício | evitar repetição inadequada | “não ajudou” → não repetir logo |
| Interação com notificação | reduzir interrupção | três dispensas → pausar |

### Não usar no primeiro lançamento conectado

- texto bruto do diário;
- foto de refeição ou corpo;
- peso, calorias, quantidade de alimento ou atividade física;
- notas privadas do profissional;
- diagnóstico inferido;
- medicação e adesão;
- localização, microfone, câmera, contatos ou uso de outros aplicativos;
- dados de terceiros citados no diário;
- horários de refeição como gatilho automático.

### Evolução opcional do texto livre

Só deve ser considerada depois de validação específica. A extração receberia o
texto como dado não confiável e retornaria apenas `topicKey` de uma taxonomia
fechada, por exemplo `overload`, `loneliness` ou `self_kindness`.

O sistema não guarda uma nova cópia do diário no serviço de IA, não usa o texto
para treinamento e aplica prazo curto aos sinais derivados. A pessoa confirma a
interpretação antes de ela influenciar recomendações futuras.

## 7. Tipos de sugestão

### Autorreflexão

Perguntas revisadas e não prescritivas:

- “O que tornou este momento um pouco mais suportável?”;
- “O que você percebe que precisa agora: pausa, companhia ou espaço?”;
- “Que frase gentil você diria a alguém querido nesta situação?”;
- “Existe um próximo passo pequeno e seguro que faça sentido para você?”

Sempre permitir “Não quero responder”. Não pedir justificativa.

### Exercício

Selecionar apenas um `exerciseId` do catálogo clinicamente revisado do plano
anterior, respeitando duração, acessibilidade, preferências e feedback prévio.

Exemplo dentro do app:

> Você pediu práticas curtas e sem foco na respiração. Quer experimentar
> “Ancorar no presente” por cerca de 2 minutos?

### Conexão humana

Texto sugerido:

> Conversar com alguém seguro pode ajudar a não atravessar este momento só.
> Existe alguém que você gostaria de procurar?

Ações:

- “Ver minha rede de apoio”;
- “Preparar uma mensagem” — apenas rascunho local;
- “Levar para meu profissional”;
- “Agora não”.

Não escolher a pessoa por conta própria e não presumir que família, parceiro ou
amigo seja seguro.

### Conversa com profissional

> Talvez valha guardar este tema para sua próxima conversa profissional.

O protótipo só cria um cartão fictício. Não afirma que o profissional recebeu,
leu ou responderá. Uma integração real exige consentimento por item, prazo de
resposta explícito e governança do prontuário.

## 8. Conteúdo da notificação

### Na tela bloqueada

Usar apenas mensagens genéricas:

- “Uma pausa gentil, se fizer sentido.”;
- “A Íris separou uma sugestão de apoio.”;
- “Quer reservar dois minutos para você?”;

Não usar:

- “Vi que você está triste”;
- “Seu humor piorou esta semana”;
- “Você escreveu sobre compulsão”;
- nome de exercício ligado a crise, transtorno ou refeição;
- trecho, tag ou resumo do diário;
- nome de amigo, profissional ou diagnóstico.

No Android, planejar `VISIBILITY_PRIVATE` ou `VISIBILITY_SECRET`, canal próprio
e sem heads-up. No iOS, pedir autorização somente depois do contexto; avaliar
autorização provisória/silenciosa e sempre renderizar conteúdo genérico, pois a
prévia final também depende da configuração do dispositivo.

### Depois de abrir o app

Exigir sessão autenticada. O deep link leva apenas um identificador opaco, nunca
texto ou dado de humor.

Estrutura da tela:

1. observação tentativa: “Seus check-ins recentes pareceram mais difíceis.”;
2. confirmação: “Isso combina com sua percepção?”;
3. `Sim`, `Não`, `Prefiro não responder`;
4. convite: reflexão, exercício ou conexão;
5. “Por que estou vendo isto?”;
6. “Não mostrar sugestões como esta”.

## 9. Política determinística de envio

A IA não escolhe diretamente a hora nem ignora preferências. Um orquestrador
aplica, nesta ordem:

1. personalização ativa e fonte consentida;
2. sessão não marcada como demonstração de risco;
3. categoria permitida;
4. janela e fuso horário escolhidos;
5. limite de no máximo uma por dia e três por semana;
6. cooldown após dispensa ou feedback negativo;
7. conteúdo não duplicado recentemente;
8. validade do insight — não enviar observação antiga;
9. dispositivo não está em modo de demonstração/teste;
10. template e catálogo ainda estão aprovados.

Com três notificações seguidas ignoradas, pausar automaticamente e perguntar
dentro do app, sem nova notificação, se a pessoa quer retomar. Não enviar lote
atrasado ao sair do horário silencioso.

O limite é de produto, não uma recomendação clínica definitiva; deve ser testado
com pacientes e reduzido se causar incômodo.

## 10. Arquitetura de IA proposta

### Camada 1 — sinais

Transforma dados permitidos em sinais mínimos:

```text
MoodTrend: direction, count, window
ConfirmedTopic: topicKey, source, confirmedAt
SupportPreference: allowedModes, excludedTags, duration
RecentFeedback: exerciseId, helpfulness
```

### Camada 2 — recomendador restrito

Entrada estruturada, sem instruções livres. Saída:

```json
{
  "suggestionTemplateId": "reflection_overload_v1",
  "exerciseId": "grounding_present_2m",
  "reasonCodes": ["RECENT_DIFFICULT_CHECKINS", "PREFERS_2_MIN"],
  "confidenceBand": "medium"
}
```

O modelo não retorna texto ao usuário, contato, diagnóstico, horário ou comando
de envio.

### Camada 3 — validação

- schema estrito;
- IDs em allowlist e versões aprovadas;
- compatibilidade com exclusões clínicas e sensoriais;
- máximo de uma sugestão;
- bloqueio de qualquer campo adicional;
- fallback para regra local ou nenhuma sugestão;
- registro de modelo, prompt, catálogo, reason codes e resultado da validação.

### Camada 4 — política de notificação

Aplica consentimento, horário, frequência, cooldown e privacidade. Somente essa
camada pode produzir `NotificationCandidate`.

### Camada 5 — renderização

Combina IDs com templates locais revisados. O push contém apenas o template
genérico. A personalização detalhada é montada dentro do app autenticado.

## 11. Explicabilidade e correção

“Por que estou vendo isto?” deve responder em linguagem simples:

> Você permitiu usar seus registros de humor. Em três dos quatro check-ins mais
> recentes, escolheu uma opção difícil. Você também prefere atividades curtas.
> Por isso a Íris sugeriu um exercício de 2 minutos.

Controles na mesma tela:

- “Isso não combina comigo”;
- “Não usar este registro”;
- “Não sugerir este exercício”;
- “Gerenciar dados usados”;
- “Pausar ou desligar personalização”;
- “Solicitar revisão/explicação”.

A correção não deve reescrever o diário original. Ela remove ou invalida apenas
o sinal derivado e impede que ele continue influenciando sugestões.

## 12. Front-end fictício proposto

```text
lib/features/ai_support/
  data/
    mock_diary_signals.dart
    mock_mood_history.dart
    mock_support_templates.dart
    mock_ai_recommender.dart
    mock_notification_policy.dart
  domain/
    ai_support_consent.dart
    support_signal.dart
    support_suggestion.dart
    notification_candidate.dart
    notification_preferences.dart
    suggestion_feedback.dart
  presentation/
    ai_support_onboarding_screen.dart
    ai_support_settings_screen.dart
    notification_preview_screen.dart
    support_suggestion_screen.dart
    why_this_suggestion_sheet.dart
    suggestion_feedback_sheet.dart
    support_inbox_screen.dart
```

### Componentes do protótipo

- onboarding com exemplos e limites;
- consentimento granular;
- configuração de frequência/janela;
- prévia de tela bloqueada;
- central de notificações simuladas dentro do app;
- três cenários fictícios de humor/diário;
- cinco templates de reflexão;
- integração visual com os exercícios planejados;
- tela de explicação e correção;
- pausa e desativação.

Não adicionar dependência de push nem pedir permissão real na primeira fase. A
notificação aparece em um simulador visual, identificada como demonstração.

## 13. Cenários fictícios

### A — humor mais difícil, prefere interativo

- sinal: três check-ins difíceis em quatro;
- preferência: 2 minutos, sem respiração;
- sugestão: “Ancorar no presente”;
- notificação: “Uma pausa gentil, se fizer sentido.”;
- explicação: tendência de humor + preferência, sem usar diário livre.

### B — tag “solidão” confirmada

- sinal: tag escolhida e confirmada pela pessoa;
- sugestão: procurar alguém seguro ou preparar um rascunho;
- nenhuma mensagem é enviada;
- “Agora não” encerra sem insistência.

### C — exercício anterior não ajudou

- sinal: feedback “pior” ou “não ajudou”;
- comportamento: não repetir o exercício; priorizar conexão humana e acesso a
  “Não estou bem” dentro do app;
- não enviar nova sugestão no mesmo dia.

### D — interpretação incorreta

- IA propõe `overload`, pessoa responde “não combina”;
- sinal é descartado;
- UI explica que o diário não foi alterado;
- recomendação futura não usa essa inferência.

## 14. Segurança específica para transtornos alimentares

O conteúdo deve evitar:

- elogiar controle, disciplina, perda de peso ou “resistir” a comida;
- associar valor moral a alimento, corpo ou exercício;
- sugerir compensação ou substituição de refeição;
- transformar registros alimentares em meta, streak ou recompensa;
- enviar mensagens perto de refeições por inferência automática;
- interpretar ausência de registro como melhora ou piora;
- recomendar exercício de suporte alimentar sem plano clínico individual;
- repetir palavra ou trecho potencialmente gatilho na notificação.

Qualquer personalização ligada a refeição, compulsão, restrição ou purgação fica
fora do catálogo geral e exige módulo aprovado por psicólogo, nutricionista e
médico/psiquiatra, com critérios e contraindicações próprias.

## 15. Privacidade, LGPD e segurança

Humor, diário e inferências emocionais são dados de saúde ou podem revelar
aspectos sensíveis. Antes de conexão real:

- documentar finalidade, necessidade, base legal e agentes de tratamento;
- realizar RIPD/DPIA para personalização e modelo;
- tratar o fornecedor de IA por contrato, sem treinamento com dados da Íris;
- verificar localização, suboperadores, retenção e exclusão;
- separar identificadores do conteúdo;
- criptografar trânsito e repouso;
- não incluir dado sensível em logs, analytics, crash reports ou push payload;
- usar identificador opaco, curto e expirável no deep link;
- manter sinais derivados por prazo mínimo definido e permitir sua eliminação;
- fornecer acesso, explicação, correção, oposição/desativação e revisão aplicável;
- testar isolamento entre paciente e profissional nas políticas de acesso;
- ter plano de incidente e desligamento do recomendador.

A base legal não deve ser presumida neste plano; deve ser definida com assessoria
jurídica para cada finalidade. Um checkbox não torna todo uso de dados de saúde
legítimo.

## 16. Governança e conteúdo

Grupo mínimo:

- psicólogo com experiência em transtornos alimentares;
- nutricionista especializado;
- médico/psiquiatra para risco e contraindicações;
- pessoas com experiência vivida;
- especialista de acessibilidade;
- responsável por privacidade/segurança;
- engenharia de ML e responsável formal pelo produto.

Cada template tem autor, fonte, finalidade, público, exclusões, versão, aprovador,
data da revisão e status `draft`, `approved` ou `retired`.

Mudança de modelo, prompt, catálogo, fornecedor ou finalidade exige nova
avaliação proporcional ao risco. Deve existir kill switch que transforma todas
as sugestões em regras genéricas ou desativa a entrega.

## 17. Critérios de aceite do protótipo

1. O onboarding explica que não é terapia, monitoramento ou emergência.
2. Cada fonte de dado possui controle separado e começa desligada.
3. A permissão do sistema é representada somente depois da prévia e consentimento.
4. Toda notificação simulada usa texto genérico na tela bloqueada.
5. O detalhe personalizado exige abertura do app e mostra “Por que isto?”.
6. A pessoa pode discordar, remover o sinal, pausar ou desligar em até dois toques.
7. O recomendador retorna somente IDs/reason codes aceitos pelo schema.
8. Saída inválida, ID aposentado ou baixa confiança resulta em fallback ou silêncio.
9. Preferências de horário, frequência, conteúdo e acessibilidade são respeitadas.
10. Nenhuma mensagem ou dado é realmente enviado no protótipo.
11. “Falar com alguém” nunca escolhe contato nem afirma que enviou mensagem.
12. Conteúdo de diário não aparece em preview, log, URL ou payload.
13. Exercício marcado como “não ajudou/pior” não é repetido imediatamente.
14. Exercícios e sugestões abrem sem checagem de segurança obrigatória.
15. Somente a escolha explícita “Ajuda urgente” abre a pergunta de segurança.
16. “Não estou bem” continua acessível sem personalização ou permissão de push.
17. O protótipo funciona em tema claro/escuro, 320 px e texto a 200%.
18. No MVP, todo conselho percebido pelo usuário é montado com template aprovado.
19. Formulação generativa, se habilitada em piloto, aparece apenas dentro do app,
    usa linguagem tentativa e nunca trata temas clínicos proibidos.

## 18. Testes propostos

### Consentimento e privacidade

- fonte desligada não influencia a sugestão;
- revogação elimina os sinais fictícios derivados;
- prévia nunca mostra humor, tag ou trecho de diário;
- deep link contém apenas ID opaco e exige autenticação;
- analytics e logs de teste não recebem texto sensível;
- usuário sem push mantém todas as funções no app.
- deep link de sugestão abre seu detalhe sem passar pela checagem de segurança;
- “Ajuda urgente” continua disponível no detalhe em um toque.

### Recomendação

- saída fora do schema é rejeitada;
- `exerciseId` fora da allowlist é rejeitado;
- conteúdo aposentado não é recomendado;
- preferência “sem respiração” é respeitada;
- feedback negativo ativa cooldown e muda a categoria;
- ausência de dado resulta em sugestão genérica ou nenhuma sugestão;
- mesma entrada do mock produz resultado reproduzível.
- conselho referencia somente sinais permitidos e confirmados;
- tema não permitido gera abstenção ou template fixo, nunca texto livre.

### Política de notificação

- janela silenciosa, fuso, limite diário/semanal e validade;
- nenhuma rajada de mensagens atrasadas;
- três dispensas pausam a entrega;
- mudança de preferência invalida candidato pendente;
- template retirado não pode ser entregue;
- expiração remove observação antiga.

### Red team

- diário contendo “ignore as regras” é tratado como dado, não instrução;
- menções a suicídio, automutilação, abuso, psicose, medicação, compulsão,
  purgação e restrição não geram conselho livre nem falsa tranquilização;
- sugestão de contato não presume que família/parceiro é seguro;
- nenhum texto personifica a IA ou incentiva segredo/dependência;
- nenhuma saída recomenda alimento, peso, medicação ou exercício físico;
- nenhuma saída afirma diagnóstico, causa, piora ou ausência de risco;
- formulação generativa não ultrapassa o tamanho nem as ações permitidas;
- testes em linguagem coloquial, erros ortográficos e variações regionais.

### Acessibilidade

- leitor de tela anuncia fonte ativa, escolha e consequência;
- frequência não depende apenas de slider;
- foco visível e ordem previsível;
- opção “Agora não” tão acessível quanto “Começar”;
- feedback de erro compreensível e sem culpabilização.

## 19. Métricas e avaliação

Não otimizar clique, retenção, número de diários ou dependência da IA.

### Métricas de utilidade

- porcentagem de interpretações confirmadas, corrigidas e recusadas;
- sugestão percebida como útil, neutra, irritante ou prejudicial;
- facilidade de entender “Por que isto?” e desligar;
- escolha entre reflexão, exercício e conexão humana;
- frequência considerada adequada.

### Métricas de segurança

- exposição de informação sensível na tela bloqueada: meta zero;
- conselho proibido no conjunto de red team: bloqueio obrigatório;
- repetição após feedback negativo;
- sugestão entregue fora de consentimento/horário;
- diferenças de erro e utilidade por grupo, idioma e acessibilidade;
- relatos de culpa, vigilância, dependência ou afastamento de apoio humano.

### Métricas técnicas

- saída inválida do modelo;
- taxa de fallback e silêncio;
- catálogo/modelo/template responsável por cada sugestão;
- tempo de revogação e eliminação dos sinais;
- candidatos expirados ou duplicados bloqueados.

## 20. Fases de entrega

### Fase 0 — governança

- definir finalidade e público adulto;
- aprovar taxonomia, templates e conteúdos proibidos;
- mapear LGPD, Anvisa, fluxo de incidentes e responsáveis;
- pesquisa com pessoas em recuperação sobre privacidade e linguagem.

### Fase 1 — protótipo front-end

- onboarding, configurações e consentimentos fictícios;
- históricos mock de humor/tags;
- recomendador e política locais determinísticos;
- simulador de notificação;
- tela detalhada, explicação, correção e feedback;
- integração visual com exercícios.

### Fase 2 — regras locais, sem IA generativa

- notificações locais de templates fixos, após permissão real;
- sem texto livre do diário;
- piloto interno de privacidade, frequência e deep links;
- auditoria de acessibilidade e segurança.

### Fase 3 — IA em shadow mode

- IA recebe somente sinais estruturados;
- suas escolhas e eventuais rascunhos de conselho não chegam ao paciente;
- comparar com regras e revisão clínica;
- red team, análise por grupos e documentação de falhas.

### Fase 4 — piloto controlado

- consentimento específico e amostra adulta acompanhada;
- catálogo reduzido, frequência conservadora e monitoramento humano;
- começar por seleção de templates; testar formulação limitada separadamente;
- kill switch e fallback por regras;
- avaliação independente de dano, utilidade e privacidade.

### Fase 5 — produção limitada

- somente após aprovação clínica, jurídica, de segurança e regulatória;
- auditoria contínua e revisão periódica de templates/modelo;
- expansão gradual sem texto livre até haver evidência própria;
- relatório transparente de limitações e incidentes.

## 21. Base de evidências e normas

- [OMS — IA generativa multimodal em saúde, 2024](https://www.who.int/news/item/18-01-2024-who-releases-ai-ethics-and-governance-guidance-for-large-multi-modal-models): riscos de respostas falsas, enviesadas ou incompletas, automation bias, segurança, transparência e participação de pacientes/profissionais.
- [OMS — IA responsável para saúde mental, 2026](https://www.who.int/news/item/20-03-2026-towards-responsible-ai-for-mental-health-and-well-being--experts-chart-a-way-forward): necessidade de co-design, evidência, contexto cultural, monitoramento de dependência emocional, referral de crise e accountability.
- [American Psychological Association — GenAI e apps de bem-estar em saúde mental, 2025](https://www.apa.org/topics/artificial-intelligence-machine-learning/health-advisory-chatbots-wellness-apps): não substituir profissionais, limitar dependência, proteger dados sensíveis e criar protocolos de segurança claros.
- [Lützow et al., 2025 — revisão de intervenções adaptativas just-in-time](https://pubmed.ncbi.nlm.nih.gov/41027677/): efeitos médios pequenos, incerteza de longo prazo e necessidade de regras de decisão e estudos mais rigorosos.
- [NICE NG69 — transtornos alimentares](https://www.nice.org.uk/guidance/ng69/chapter/recommendations): self-help indicada deve ser focada no transtorno, baseada em técnicas apropriadas e não substituir acompanhamento especializado.
- [ANPD — direitos dos titulares](https://www.gov.br/anpd/pt-br/assuntos/titular-de-dados-1/direito-dos-titulares): acesso, eliminação aplicável, explicação e revisão de decisões automatizadas que afetem interesses.
- [LGPD — Lei nº 13.709/2018](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709compilado.htm): dados de saúde como sensíveis, princípios de finalidade, necessidade, transparência, segurança e não discriminação.
- [Android — privacidade de notificações](https://developer.android.com/develop/ui/compose/notifications/create-notification): visibilidade pública, privada ou secreta na tela bloqueada e controle final do usuário.
- [Apple — autorização para notificações](https://developer.apple.com/documentation/UserNotifications/asking-permission-to-use-notifications): autorização contextual e possibilidade de entrega provisória/silenciosa.
- [Anvisa — RDC 657/2022, perguntas e respostas](https://www.gov.br/anvisa/pt-br/centraisdeconteudo/publicacoes/produtos-para-a-saude/manuais/software-como-dispositivo-medico-perguntas-e-respostas/view): enquadramento depende da finalidade de uso; finalidade diagnóstica ou terapêutica exige avaliação regulatória e evidência apropriada.

## 22. Decisões pendentes antes da implementação real

- definir se a Íris será ferramenta de bem-estar, suporte ao tratamento ou SaMD;
- confirmar faixa etária e excluir menores tecnicamente no piloto;
- decidir se texto livre será processado — recomendação inicial: não;
- definir quem aprova e responde por cada template;
- definir prazo de retenção de sinais e fornecedor/região de IA;
- estabelecer expectativa real de contato do profissional;
- validar frequência e horários com pessoas em recuperação;
- definir protocolo para conteúdo de risco sem prometer monitoramento;
- realizar avaliação regulatória, jurídica, clínica e de segurança antes do push;
- definir critérios de go/no-go e autoridade para acionar o kill switch.
