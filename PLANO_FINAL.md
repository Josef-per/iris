# Plano Final de Desenvolvimento — Íris

## 1. Visão geral

O Íris é um aplicativo em Flutter para apoiar, entre consultas, o acompanhamento de pessoas com transtornos alimentares. O sistema reúne registros emocionais e alimentares, aproxima paciente e profissional e oferece atividades curtas de cuidado. Ele é uma ferramenta complementar e não substitui avaliação, diagnóstico, tratamento ou atendimento de emergência.

## 2. Objetivos do MVP

- Permitir cadastro, login e vínculo entre paciente e profissional por QR Code.
- Registrar check-in diário, diário emocional e registro alimentar.
- Disponibilizar ao paciente o histórico dos próprios registros.
- Oferecer ao profissional um painel dos pacientes vinculados.
- Usar um mascote como guia visual para microatividades aprovadas, sem interface de chatbot.
- Produzir descobertas e resumos semanais com IA de forma opcional, rastreável e revisável.
- Entregar lembretes e avisos por um mecanismo próprio de notificações.

## 3. Experiência do mascote

O mascote apresentará uma ação curta por vez, como fazer um check-in, realizar uma pausa guiada ou separar um tema para a próxima consulta. Todas as falas e atividades virão de um catálogo versionado e aprovado por profissionais.

A experiência não terá conversa livre, ofensiva diária, ranking, vidas, perda de progresso, recompensas ligadas a peso, alimentação ou sintomas, nem mensagens de culpa por ausência. O paciente poderá recusar uma atividade, reduzir animações ou desativar o mascote sem perder funções clínicas.

## 4. Implementação da IA

A IA será uma camada de apoio ao acompanhamento, sem autonomia clínica. Suas funções no MVP serão:

- Gerar um resumo semanal dos registros para revisão do profissional.
- Identificar temas e mudanças observáveis, sempre ligados aos registros de origem.
- Criar cards de descoberta que o paciente possa confirmar, corrigir ou marcar como incertos.
- Selecionar para o mascote uma microatividade existente no catálogo aprovado.

O processamento ocorrerá no backend, nunca diretamente no aplicativo Flutter:

```text
registros autorizados
  → seleção dos dados mínimos e pseudonimização
  → modelo de IA
  → resposta JSON com estrutura limitada
  → validação de segurança
  → armazenamento com evidências
  → revisão/apresentação
```

O resultado deverá conter campos como tema, nível de confiança, IDs dos registros de origem e ID da atividade sugerida. A IA não produzirá diretamente as falas do mascote e não poderá diagnosticar, prever recaídas, prescrever condutas ou recomendar mudanças de medicamento, dieta, peso ou tratamento. Os cards mostrados diretamente ao paciente serão observações descritivas, sem causalidade ou interpretação clínica; conteúdo sensível dependerá de revisão profissional.

O recurso dependerá de consentimento específico e revogável. A revogação cancelará jobs e notificações personalizadas pendentes e impedirá novos processamentos; os resultados anteriores seguirão a política definida de retenção e exclusão. O resultado ficará nas tabelas protegidas de resumos e insights. A auditoria guardará apenas IDs, hashes, finalidade, modelo, versão do prompt, estado e correções, sem copiar texto clínico.

Resumos para o profissional serão identificados como rascunhos até a revisão humana. A validação não confiará somente na confiança declarada pelo modelo: também verificará o schema do JSON, a cobertura das fontes, a ligação entre afirmações e evidências e as regras de conteúdo. Em caso de falha, saída inválida, evidência insuficiente ou reprovação por essas regras, o sistema usará um resumo determinístico simples ou uma atividade genérica segura, sem bloquear as funções principais.

## 5. Mecanismo próprio de notificações

O Íris terá uma central de notificações dentro do aplicativo, integrada a lembretes locais e notificações push. O fluxo será:

```text
evento do sistema ou lembrete agendado
  → verificação de preferências, consentimento e horário de silêncio
  → criação da notificação e deduplicação
  → fila de entrega
  → central do app, lembrete local ou push
  → registro de envio, abertura ou expiração
```

Lembretes definidos pelo próprio paciente serão agendados localmente no dispositivo. Eventos gerados no backend, como um resumo concluído ou uma mudança de vínculo, serão persistidos no Supabase e enviados por push. A notificação externa carregará somente um identificador e texto neutro; detalhes sensíveis serão buscados apenas depois da autenticação.

### Tipos de notificações

| Tipo | Destinatário | Exemplos |
|---|---|---|
| Lembretes de registro | Paciente | Check-in diário, diário emocional ou registro alimentar no horário escolhido |
| Atividade do mascote | Paciente | Nova microatividade aprovada disponível |
| Resumo semanal | Paciente e profissional | Resumo disponível para consulta ou revisão |
| Revisão profissional | Profissional | Novo rascunho ou feedback aguardando análise |
| Vínculo | Paciente e profissional | Vínculo criado, reativado ou encerrado |
| Sistema e segurança | Ambos | Alteração relevante de conta, privacidade ou acesso |

### Preferências e regras

- Cada categoria poderá ser ativada ou desativada separadamente.
- O usuário definirá dias, horários, fuso e período de silêncio.
- Notificações personalizadas por IA exigirão consentimento ativo para IA.
- A tela bloqueada nunca exibirá diagnóstico, sintomas, peso, alimento, medicamento, diário ou inferência da IA.
- Haverá limite de frequência, deduplicação, expiração e tentativas controladas de reenvio.
- O texto será neutro e não usará pressão, culpa, punição ou mecânicas de sequência.
- A notificação não será tratada como canal de emergência nem como prova de leitura.
- Qualquer alerta sensível ficará em área autenticada e só poderá ser adotado com protocolo e responsabilidade de monitoramento definidos.
- Uma rota fixa de orientação para situações urgentes ficará sempre acessível no aplicativo, sem depender da IA ou prometer monitoramento.

### Dados mínimos

- `preferencias_notificacao`: usuário, categoria, estado, dias, horários, fuso, silêncio e limite diário.
- `dispositivos_push`: usuário, token, plataforma, estado e último acesso.
- `notificacoes`: destinatário, categoria, template e versão, origem, agendamento, status, datas de envio/abertura e chave de deduplicação.

Textos clínicos não serão copiados para essas tabelas. Tokens de push terão RLS restritiva, escrita controlada e leitura exclusiva pelo backend; serão rotacionados ou invalidados em logout, revogação, troca de aparelho e falha permanente de entrega.

## 6. Dados e segurança

Antes da IA, o schema real do Supabase deverá ser exportado e todas as migrations-base deverão ser versionadas. As políticas de Row Level Security devem garantir que o paciente acesse somente os próprios dados e que o profissional acesse somente pacientes com vínculo ativo.

Os registros deverão usar datas, fuso horário, códigos estáveis para sintomas, timestamps do servidor, constraints de faixa e versionamento do formulário. O MVP também precisará das seguintes estruturas:

- Consentimentos de IA.
- Resumos semanais e insights.
- Evidências que ligam cada insight ao registro de origem.
- Catálogo e histórico de atividades do mascote.
- Eventos de auditoria de IA.
- Preferências, dispositivos e entregas de notificações.

Dados de saúde são dados pessoais sensíveis; por isso, finalidade, acesso, retenção, segurança, exportação, exclusão e hipótese legal de tratamento deverão ser definidos antes do piloto. O fornecedor de IA deverá ser avaliado quanto a contrato, uso dos dados para treinamento, retenção e eventual transferência internacional.

## 7. Roadmap

Os marcos devem ser concluídos na ordem abaixo. Um marco só avança quando seu critério de conclusão for atendido.

| Marco | Foco | Resultado esperado |
|---|---|---|
| 1 | Conteúdo, dados e segurança | Base técnica e clínica pronta |
| 2 | Experiência essencial | Jornada principal funcionando sem IA |
| 3 | Notificações | Sistema próprio de avisos funcionando |
| 4 | IA controlada | Resumos e sugestões rastreáveis |
| 5 | Integração clínica | Revisão profissional funcionando |
| 6 | Validação e piloto | MVP aprovado para uso supervisionado |

### Marco 1 — Conteúdo, dados e segurança

**Objetivo:** preparar uma base reproduzível, segura e clinicamente revisada.

**Entregas:**

- Definição do escopo da IA, do mascote e das notificações.
- Guia de linguagem permitida e proibida.
- Catálogo inicial de 6 a 9 microatividades aprovadas.
- Protocolo fixo para situações sensíveis e urgentes.
- Schema completo do Supabase exportado e versionado.
- Políticas de acesso, papéis e privilégios corrigidos.
- Registros, datas, sintomas e restrições do banco normalizados.
- Consentimento de IA, retenção, exclusão, exportação e auditoria especificados.

**Marco concluído quando:**

- Um banco novo pode ser criado somente com as migrations do projeto.
- Pacientes e profissionais acessam apenas os dados permitidos pelo vínculo.
- O conteúdo clínico foi aprovado e a auditoria não copia textos sensíveis.

### Marco 2 — Experiência essencial

**Objetivo:** concluir a jornada principal do paciente e do profissional sem depender de IA.

**Entregas:**

- Apresentação, home, trilha, microatividade e tela de conclusão.
- Histórico dos registros do paciente.
- Painel básico do profissional e vínculo por QR Code.
- Preferências do mascote e opção de desativá-lo.
- Animações leves e modo de movimento reduzido.
- Progressão sem ofensivas, ranking, punições ou perda de progresso.

**Marco concluído quando:**

- O paciente consegue registrar, consultar o histórico e realizar uma atividade.
- O profissional consegue visualizar pacientes com vínculo ativo.
- Desativar o mascote não remove nenhuma função essencial.

**Dependência:** Marco 1.

### Marco 3 — Notificações próprias do sistema

**Objetivo:** entregar lembretes e avisos privados, configuráveis e rastreáveis.

**Entregas:**

- Central de notificações com estados de lida e não lida.
- Preferências por categoria, dias, horários, fuso e período de silêncio.
- Lembretes locais configurados pelo paciente.
- Notificações de check-in, diário, atividades, resumos, vínculos e segurança da conta.
- Serviço de eventos, fila de entrega e templates versionados.
- Links internos que exigem autenticação antes de mostrar detalhes.
- Limite de frequência, deduplicação, expiração e cancelamento.
- Proteção e invalidação de tokens em logout, revogação ou troca de aparelho.

**Marco concluído quando:**

- Cada categoria pode ser ativada e testada separadamente.
- Horário de silêncio, fuso, cancelamento e deduplicação funcionam.
- A tela bloqueada mostra somente texto neutro e nunca revela dados clínicos.
- Falha de entrega não duplica mensagens nem bloqueia o aplicativo.

**Dependências:** Marcos 1 e 2.

### Marco 4 — Personalização controlada por IA

**Objetivo:** adicionar apoio inteligente sem chatbot, diagnóstico ou geração clínica livre.

**Entregas:**

- Seleção inicial de atividades por regras determinísticas.
- Classificação de temas e ordenação de atividades aprovadas pela IA.
- Resumo semanal com resposta em JSON validado.
- Evidências, versão, finalidade e motivo registrados para cada resultado.
- Cards objetivos de descoberta para confirmação do paciente.
- Fallback seguro para falha, evidência insuficiente ou saída inválida.
- Notificação neutra quando um novo resultado estiver disponível.

**Marco concluído quando:**

- Nenhum processamento ocorre sem consentimento ativo.
- Todo insight pode ser ligado aos registros que o originaram.
- Saídas sem schema válido ou evidências suficientes são rejeitadas.
- A IA só consegue selecionar atividades cadastradas e aprovadas.
- Falhas do modelo acionam o fallback sem afetar as funções principais.

**Dependências:** Marcos 1, 2 e 3.

### Marco 5 — Integração clínica

**Objetivo:** criar o ciclo de revisão entre IA, paciente e profissional.

**Entregas:**

- Resumos apresentados como rascunhos para revisão profissional.
- Opções para aceitar, rejeitar e justificar a revisão de insights.
- Confirmação, correção ou incerteza registrada pelo paciente.
- Descobertas confirmadas exibidas no painel do profissional.
- Controle profissional sobre os módulos disponíveis do mascote.
- Orientação fixa para situações urgentes, independente da IA e das notificações.

**Marco concluído quando:**

- Nenhum conteúdo sensível é apresentado como conclusão clínica automática.
- Paciente e profissional conseguem revisar o resultado mantendo sua origem.
- A rota de orientação urgente permanece sempre acessível e não promete monitoramento.

**Dependência:** Marco 4.

### Marco 6 — Validação e piloto supervisionado

**Objetivo:** verificar se o MVP está seguro e estável antes do uso com dados reais.

**Entregas:**

- Testes completos com dados sintéticos e cenários de falha.
- Revisão clínica das mensagens, atividades e notificações.
- Testes de acessibilidade, contraste e movimento reduzido.
- Testes de falha do modelo, cobertura de evidências e fallback.
- Testes de permissão, entrega, fuso, silêncio e duplicidade das notificações.
- Testes de privacidade na tela bloqueada e isolamento entre usuários.
- Avaliação final com profissionais responsáveis pelo projeto.

**Marco concluído quando:**

- Os fluxos críticos e seus fallbacks passam nos testes.
- Não existem falhas críticas de acesso, privacidade ou exposição de dados.
- Todo conteúdo visível ao paciente está aprovado e versionado.
- O piloto supervisionado recebe aprovação técnica, clínica e ética.

**Dependências:** Marcos 1 a 5.

## 8. Critérios de aceite

- As funções principais continuam disponíveis sem IA, mascote ou notificações opcionais.
- O paciente pode conceder e revogar consentimento de IA.
- Todo insight apresenta origem, versão e estado de revisão.
- A IA não gera diagnóstico, prescrição ou aconselhamento clínico livre.
- Saídas da IA são rejeitadas quando o schema, as evidências ou as regras determinísticas falham.
- O mascote só exibe conteúdo aprovado e versionado.
- Toda categoria de notificação possui preferência própria.
- Nenhuma notificação externa revela dado clínico sensível.
- Horário de silêncio, limite de frequência e cancelamento são respeitados.
- Envios duplicados são impedidos por chave de idempotência.
- Abertura de notificação exige sessão válida antes de mostrar detalhes.
- Revogar a IA cancela jobs e notificações personalizadas pendentes.
- Logout e troca de aparelho invalidam ou rotacionam o token push correspondente.
- Falhas de IA ou de entrega não impedem registros nem acesso ao aplicativo.
- Todos os fluxos críticos possuem logs sem duplicação de conteúdo clínico.

## 9. Fora do escopo do MVP

- Chatbot terapêutico ou conversa livre com o mascote.
- Diagnóstico, prescrição ou mudança automatizada de tratamento.
- Monitoramento de emergência em tempo real.
- Mensagens livres entre paciente e profissional.
- Ranking, ofensiva, moedas, compras ou recompensas clínicas.
- Memória emocional permanente do mascote.

## 10. Referências de orientação

- [OMS — Ética e governança da inteligência artificial para a saúde](https://www.who.int/publications/i/item/9789240037403)
- [Lei Geral de Proteção de Dados Pessoais — Lei nº 13.709/2018](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709compilado.htm)
- [ANPD — Guia de Segurança da Informação para Agentes de Tratamento de Pequeno Porte](https://www.gov.br/anpd/pt-br/assuntos/noticias/anpd-publica-guia-de-seguranca-para-agentes-de-tratamento-de-pequeno-porte)
