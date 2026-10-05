# Vínculo temporário da demonstração

Antes de publicar o aplicativo atualizado no Vercel, aplique
`supabase/migrations/0016_demo_patient_link.sql` no Supabase conectado.
A conta `lucas@gmail.com` precisa existir como profissional ativo e ter
`credenciamento_status = 'ativo'`.

Novos cadastros de paciente recebem o metadado `demo_professional_link: true`.
Quando seu perfil de paciente é criado, o backend registra sua elegibilidade
para a demonstração, inclusive após confirmação de e-mail. O vínculo só é
criado ao clicar em **Aprovar vínculo e testar**. A confirmação mostra
**Psiquiatra Lucas (para teste)**, seu e-mail e a autorização para acompanhar
os registros adicionados.

Pacientes existentes, vínculos ativos, cadastro profissional, login,
recuperação de senha e convites QR continuam nos fluxos atuais. O backend não
substitui vínculos nem reativa autorizações revogadas.

Para encerrar a entrada de novos pacientes na demonstração, remova a inclusão
de `demo_professional_link` no método `AuthService.signUp` e publique novamente.
Mantenha a tela e a RPC enquanto houver cadastros de demonstração aguardando
aprovação. Os vínculos já aprovados continuam válidos.
