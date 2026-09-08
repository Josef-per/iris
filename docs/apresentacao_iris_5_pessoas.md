# Demo do Íris — 5 pessoas, até 15 minutos

A apresentação acontece com o **aplicativo rodando e projetado**, desde a abertura. Cada integrante fala enquanto opera sua parte. O percurso planejado dura **14 minutos**, deixando **1 minuto de margem** para carregamentos e trocas. Não há bloco separado de slides ou explicação de código.

Objetivo da demo: mostrar um paciente registrando informações, sendo vinculado a um profissional e consultando um plano de cuidado, além dos recursos opcionais de apoio.

## Divisão e cronômetro

| Pessoa | Intervalo | O que mostrar ao vivo | Dificuldade |
|---|---|---|---|
| 1 | 0:00–1:30 | Apresentação breve, login e início do paciente | Baixa |
| 2 | 1:30–4:30 | Check-in, diário, registro alimentar e histórico | Média |
| 3 | 4:30–7:00 | Painel profissional, agenda e acompanhamento de um paciente preparado | Média |
| **4** | **7:00–10:30** | **Convite, confirmação do vínculo e plano compartilhado entre duas sessões** | **Alta** |
| **5** | **10:30–14:00** | **Apoio com IA, reflexão diária, preferências e encerramento** | **Alta** |
| Equipe | 14:00–15:00 | Margem para imprevistos; terminar antes se não for necessária | — |

As pessoas 4 e 5 assumem as partes mais difíceis. A pessoa 4 coordena duas sessões e demonstra a integração entre perfis. A pessoa 5 precisa dominar as condições de disponibilidade da IA e explicar corretamente seus resultados. Todos operam o aplicativo na própria vez.

## Preparação antes de começar — fora dos 15 minutos

- Deixar o aplicativo iniciado, conectado ao Supabase e testado no equipamento da apresentação.
- Preparar dois perfis separados de navegador ou dois dispositivos: **paciente de demonstração** e **profissional de demonstração**. Evitar abas que compartilhem a mesma sessão de autenticação.
- Manter o profissional autenticado e com credenciamento aprovado. Deixar o login do paciente pronto para executar sem digitação demorada ou exposição da senha.
- Usar apenas contas e conteúdo fictícios identificados como demonstração. Preparar no profissional um segundo paciente já vinculado, com registros, agenda, anotação e plano. Ele será usado pela pessoa 3.
- Deixar o paciente apresentado pelas pessoas 1 e 2 sem vínculo, no estado exato já ensaiado, para a pessoa 4 demonstrar a vinculação. Se repetirem a demo, restaurar esse cenário previamente no ambiente de teste.
- Preparar textos curtos para os registros e para uma meta de demonstração. Não preencher formulários longos em público.
- Conferir previamente a disponibilidade da IA, os consentimentos e as fontes autorizadas dessa conta. Deixar um resultado de teste existente para consulta caso uma nova geração demore, identificando-o como anterior.
- Ensaiar as rotas e conferir os nomes dos botões na versão instalada. A presença de código no repositório não garante que a função remota esteja publicada.
- Deixar o cronômetro visível para a equipe. Fazer um ensaio completo que termine em 14 minutos.

## Pessoa 1 — Abrir e entrar no aplicativo

**Tempo: 0:00–1:30. Tela inicial: login do paciente.**

1. Apresentar a proposta em até 20 segundos com o aplicativo já projetado.
2. Entrar na conta de paciente preparada.
3. Mostrar brevemente o início e onde ficam os registros e o histórico.

**Fala sugerida:** “Este é o Íris, um aplicativo de apoio ao acompanhamento entre pacientes e profissionais de saúde. Vamos demonstrar uma jornada completa: registrar informações, conectar os dois perfis e consultar o cuidado compartilhado. Aqui estamos entrando como paciente.”

Ao mostrar o início: “Esta é a área que reúne as ações do paciente no dia a dia.”

**Passagem:** “Agora vamos registrar informações e conferir como ficam salvas.”

Não realizar cadastro completo nem recuperação de senha durante a demo.

## Pessoa 2 — Registrar e consultar

**Tempo: 1:30–4:30. Usar a mesma conta do paciente.**

| Tempo do bloco | Ação no aplicativo | O que explicar |
|---|---|---|
| 0:00–0:40 | Abrir e salvar um check-in | O paciente registra como está naquele momento. |
| 0:40–1:30 | Abrir o diário emocional e salvar uma anotação breve | O registro organiza informações para consulta posterior. |
| 1:30–2:15 | Abrir o registro alimentar, preencher o necessário e salvar | O aplicativo também reúne registros alimentares. |
| 2:15–3:00 | Abrir o histórico e localizar os registros recém-salvos | Mostrar a persistência e a consulta, destacando o que acabou de mudar. |

**Fala sugerida:** “Vou fazer registros curtos com dados fictícios. Depois de salvar, podemos consultar essas informações no histórico. Isso permite que o paciente retome o que registrou ao longo do acompanhamento.”

Evitar narrar cada clique. Explicar a finalidade enquanto preenche. Não usar câmera ou upload de foto nesse bloco, a menos que o ensaio comprove que cabe no tempo.

**Passagem:** “Agora vamos abrir o outro lado desse acompanhamento: a área profissional.”

## Pessoa 3 — Mostrar a rotina profissional

**Tempo: 4:30–7:00. Trocar para a sessão do profissional já autenticada.**

1. **40 segundos:** mostrar dashboard e agenda, abrindo um compromisso de teste já preparado.
2. **50 segundos:** abrir a lista de pacientes e os detalhes do segundo paciente, previamente vinculado. Mostrar um registro disponível e uma anotação clínica de teste.
3. **60 segundos:** abrir o plano desse paciente e apontar metas e campos de medicações. Mostrar a organização sem preencher outro formulário completo.

**Fala sugerida:** “Na área profissional, temos a agenda e os pacientes acompanhados. Este paciente de exemplo já estava vinculado antes da apresentação. Aqui o profissional consulta registros e organiza anotações e o plano de cuidado.”

Ao abrir o plano: “Estas informações são gerenciadas pelo profissional. Vamos mostrar agora como o paciente que acabou de registrar seus dados passa a fazer parte desse acompanhamento.”

Não dizer que esse segundo paciente é a mesma conta apresentada no começo.

## Pessoa 4 — Demonstrar vínculo e compartilhamento — parte difícil

**Tempo: 7:00–10:30. Alternar entre profissional e paciente, identificando cada troca.**

| Tempo do bloco | Ação ao vivo |
|---|---|
| 0:00–0:45 | No profissional, gerar um convite temporário de vínculo. |
| 0:45–1:30 | No paciente do início, ler ou inserir o convite, conferir o profissional e confirmar. |
| 1:30–2:10 | Voltar ao profissional, atualizar a lista e abrir o paciente recém-vinculado; mostrar um registro salvo pela pessoa 2. |
| 2:10–2:55 | Criar e salvar um plano breve com uma meta de demonstração, seguindo o fluxo ensaiado. |
| 2:55–3:30 | Voltar ao paciente, atualizar a tela necessária e abrir o plano compartilhado. |

**Fala sugerida:** “Este convite conecta os dois perfis. O paciente confere o profissional e confirma o vínculo. Agora o profissional consegue acessar os registros permitidos desse acompanhamento. Vou salvar uma meta e mostrar o mesmo plano na sessão do paciente.”

Explicação técnica curta, durante a operação: “O convite é temporário. O acesso depende da autenticação e das regras do vínculo no banco, além do que aparece na interface.”

**Por que esta parte é difícil:** exige que o estado das duas contas esteja correto, que o convite seja válido e que os dados sejam atualizados nas duas sessões. A pessoa deve ensaiar também a entrada manual do convite para evitar depender da câmera.

Não abrir SQL, arquivos de configuração ou diagramas durante esse percurso. Revogação e troca de profissional podem ser explicadas se perguntarem; não desfazer o vínculo que a demo acabou de criar.

**Passagem:** “Com os dois perfis conectados, vamos mostrar os recursos opcionais de apoio ao paciente.”

## Pessoa 5 — Demonstrar IA e concluir — parte difícil

**Tempo: 10:30–14:00. Permanecer na sessão do paciente.**

| Tempo do bloco | Ação ao vivo | Explicação |
|---|---|---|
| 0:00–0:45 | Abrir preferências de personalização e mostrar as fontes autorizadas | O processamento depende das configurações e autorizações do paciente. |
| 0:45–1:40 | Abrir a área de apoio e uma sugestão disponível; mostrar motivo e opção de feedback, quando presentes | O recomendador seleciona conteúdo predefinido a partir de sinais estruturados. |
| 1:40–2:30 | Voltar ao início e mostrar a reflexão diária disponível | É outro fluxo, que pode usar texto do diário quando essa fonte está autorizada. |
| 2:30–3:00 | Mostrar as preferências de notificações de apoio | No celular, a entrega local também depende das permissões do aparelho. |
| 3:00–3:30 | Encerrar com o aplicativo ainda projetado | Retomar o percurso demonstrado e o propósito do software. |

**Fala sugerida:** “O apoio personalizado é opcional. Existem dois recursos diferentes: as sugestões selecionam conteúdos existentes usando sinais estruturados; a reflexão diária pode considerar o texto do diário quando autorizado. Esses recursos complementam a experiência, e as decisões de cuidado continuam com o profissional.”

Se houver um resultado anterior: “Este resultado foi gerado anteriormente nesta conta de teste e está sendo consultado agora.” Não afirmar que foi produzido ao vivo.

Se não aparecer uma sugestão: “Neste momento não há uma sugestão disponível. O recomendador pode ficar sem resultado quando as condições de entrega não são atendidas. Os registros do paciente continuam funcionando.” Não atribuir uma causa específica sem verificá-la.

**Por que esta parte é difícil:** precisa distinguir seleção de conteúdo e geração de reflexão, explicar consentimento e lidar com disponibilidade remota sem travar a apresentação. Não afirmar que nenhum texto do diário é usado por qualquer IA: essa restrição é do recomendador, e não de todos os fluxos.

**Encerramento:** “Mostramos o paciente registrando informações, o profissional acompanhando os dados, o vínculo entre as contas e o plano compartilhado, além do apoio opcional. Essa é a proposta do Íris: reunir essas etapas para apoiar a continuidade do acompanhamento. Obrigado.”

O aplicativo não deve ser apresentado como ferramenta de diagnóstico, prescrição automática ou monitoramento de emergência.

## Controle de tempo e imprevistos

- Aos **7 minutos**, iniciar o bloco de vínculo. Aos **10 minutos e 30 segundos**, passar para a IA. Aos **13 minutos e 30 segundos**, encaminhar o encerramento.
- Se uma ação demorar mais de 15 segundos, explicar brevemente e avançar para uma tela disponível. Não gastar o restante do bloco repetindo a mesma tentativa.
- Se o vínculo falhar, usar o segundo paciente já vinculado para mostrar o plano, deixando explícito que o novo vínculo não foi concluído. Isso exige uma sessão desse paciente preparada antes da demo.
- Se uma função de IA estiver indisponível, mostrar preferências e um resultado anterior identificado, se existir. Não improvisar resultados nem alterar configurações do servidor durante a apresentação.
- Se houver atraso, reduzir primeiro os detalhes da agenda, anotações e notificações. Preservar registro → consulta → vínculo → plano compartilhado e o encerramento.
- Manter uma gravação curta apenas como contingência para falha geral de conexão, avisando que é uma gravação. O roteiro principal é executado ao vivo.
- O total de **15 minutos inclui a margem**. Não acrescentar perguntas além desse limite se elas fizerem parte do tempo concedido; nesse caso, ensaiar um percurso de 12 minutos e reservar os 3 finais para a banca.

## Preparação para perguntas, sem bloco extra de apresentação

| Assunto | Responsável |
|---|---|
| Objetivo e público | Pessoa 1 |
| Registros e histórico do paciente | Pessoa 2 |
| Agenda e rotina do profissional | Pessoa 3 |
| Flutter, Supabase, autenticação, banco e permissões | Pessoa 4 |
| IA, fontes autorizadas, notificações e limitações | Pessoa 5 |

Para estudar os detalhes técnicos, consultar o [README](../README.md), as [migrations](../supabase/migrations), a documentação do [recomendador](../supabase/functions/ai-support-recommend/README.md) e da [reflexão diária](../supabase/functions/ai-daily-companion/README.md). Não apresentar funcionalidades futuras do plano de desenvolvimento como recursos disponíveis na demo.
