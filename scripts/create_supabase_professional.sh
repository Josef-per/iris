#!/usr/bin/env bash
set -euo pipefail

# Cria um profissional confirmado no Supabase Auth e registros em usuarios,
# perfis e profissionais. Em seguida, autentica o profissional e solicita um
# convite QR temporario pela mesma RPC segura usada pelo aplicativo.
#
# Uso:
#   EMAIL='psiquiatra@exemplo.com' PASSWORD='Senha123!' ./scripts/create_supabase_professional.sh
# Opcional:
#   DISPLAY_NAME='Dra. Ana Silva' SPECIALTY='Psiquiatria' \
#     REGISTRATION='CRM/SP 123456' ./scripts/create_supabase_professional.sh
#
# Requer SUPABASE_URL e SERVICE_ROLE_KEY no .env.server ou no ambiente.

if [ -f .env.server ]; then
  set -o allexport
  # shellcheck disable=SC1091
  source .env.server
  set +o allexport
fi

SUPABASE_URL="${SUPABASE_URL:-}"
SERVICE_ROLE_KEY="${SERVICE_ROLE_KEY:-}"

if [ -z "$SUPABASE_URL" ]; then
  echo "SUPABASE_URL nao definido."
  exit 1
fi

if [ -z "$SERVICE_ROLE_KEY" ]; then
  echo "SERVICE_ROLE_KEY nao definido."
  exit 1
fi

if [ -z "${EMAIL:-}" ] || [ -z "${PASSWORD:-}" ]; then
  cat <<EOF
Uso:
  EMAIL='psiquiatra@exemplo.com' PASSWORD='Senha123!' ./scripts/create_supabase_professional.sh

Opcional:
  DISPLAY_NAME='Dra. Ana Silva'
EOF
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Este script requer jq instalado."
  exit 1
fi

display_name="${DISPLAY_NAME:-}"
specialty="${SPECIALTY:-Psiquiatria}"
registration="${REGISTRATION:-}"

auth_payload=$(jq -n \
  --arg email "$EMAIL" \
  --arg password "$PASSWORD" \
  --arg display_name "$display_name" \
  '{
    email: $email,
    password: $password,
    email_confirm: true,
    user_metadata: (if ($display_name | length) > 0 then {display_name: $display_name, tipo_usuario: "profissional"} else {tipo_usuario: "profissional"} end)
  }')

auth_resp=$(curl -sS -X POST "$SUPABASE_URL/auth/v1/admin/users" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d "$auth_payload")

user_id=$(echo "$auth_resp" | jq -r '.id // empty')
if [ -z "$user_id" ]; then
  echo "Falha ao criar usuario auth:"
  echo "$auth_resp" | jq .
  exit 1
fi

now_iso=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

usuario_payload=$(jq -n \
  --arg id "$user_id" \
  --arg email "$EMAIL" \
  --arg now "$now_iso" \
  '{
    id: $id,
    email: $email,
    senha_hash: "managed_by_supabase_auth",
    tipo_usuario: "profissional",
    ativo: true,
    atualizado_em: $now
  }')

curl -sS -X POST "$SUPABASE_URL/rest/v1/usuarios?on_conflict=id" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "apikey: $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: resolution=merge-duplicates,return=minimal" \
  -d "$usuario_payload" >/dev/null

if [ -n "$display_name" ]; then
  perfil_payload=$(jq -n \
    --arg user_id "$user_id" \
    --arg display_name "$display_name" \
    '{
      user_id: $user_id,
      nome_social: $display_name,
      nome_completo: $display_name
    }')

  existing_perfil=$(curl -sS "$SUPABASE_URL/rest/v1/perfis?select=id&user_id=eq.$user_id&limit=1" \
    -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -H "apikey: $SERVICE_ROLE_KEY")

  perfil_id=$(echo "$existing_perfil" | jq -r '.[0].id // empty')

  if [ -n "$perfil_id" ]; then
    curl -sS -X PATCH "$SUPABASE_URL/rest/v1/perfis?id=eq.$perfil_id" \
      -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
      -H "apikey: $SERVICE_ROLE_KEY" \
      -H "Content-Type: application/json" \
      -H "Prefer: return=minimal" \
      -d "$(jq -n --arg display_name "$display_name" '{nome_social: $display_name, nome_completo: $display_name}')" >/dev/null
  else
    curl -sS -X POST "$SUPABASE_URL/rest/v1/perfis" \
      -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
      -H "apikey: $SERVICE_ROLE_KEY" \
      -H "Content-Type: application/json" \
      -H "Prefer: return=minimal" \
      -d "$perfil_payload" >/dev/null
  fi
fi

profissional_payload=$(jq -n \
  --arg user_id "$user_id" \
  --arg specialty "$specialty" \
  --arg registration "$registration" \
  '{
    user_id: $user_id,
    especialidade: (if ($specialty | length) > 0 then $specialty else null end),
    registro_profissional: (if ($registration | length) > 0 then $registration else null end),
    credenciamento_status: "ativo"
  }')

profissional_resp=$(curl -sS -X POST "$SUPABASE_URL/rest/v1/profissionais?on_conflict=user_id" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "apikey: $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: resolution=merge-duplicates,return=representation" \
  -d "$profissional_payload")

profissional_id=$(echo "$profissional_resp" | jq -r '.[0].id // empty')
if [ -z "$profissional_id" ]; then
  profissional_id=$(curl -sS "$SUPABASE_URL/rest/v1/profissionais?select=id&user_id=eq.$user_id&limit=1" \
    -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -H "apikey: $SERVICE_ROLE_KEY" | jq -r '.[0].id // empty')
fi

if [ -z "$profissional_id" ]; then
  echo "Falha ao criar registro em profissionais:"
  echo "$profissional_resp" | jq .
  exit 1
fi

session_payload=$(jq -n \
  --arg email "$EMAIL" \
  --arg password "$PASSWORD" \
  '{email: $email, password: $password}')

session_resp=$(curl -sS -X POST \
  "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d "$session_payload")

access_token=$(echo "$session_resp" | jq -r '.access_token // empty')
if [ -z "$access_token" ]; then
  echo "Profissional criado, mas nao foi possivel autenticar para gerar o convite:"
  echo "$session_resp" | jq .
  exit 1
fi

invite_resp=$(curl -sS -X POST \
  "$SUPABASE_URL/rest/v1/rpc/iris_create_professional_invite" \
  -H "Authorization: Bearer $access_token" \
  -H "apikey: $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"p_ttl_minutes":30,"p_max_uses":1}')

invite_token=$(echo "$invite_resp" | jq -r \
  'if type == "array" then .[0].token else .token end // empty')
expires_at=$(echo "$invite_resp" | jq -r \
  'if type == "array" then .[0].expires_at else .expires_at end // empty')
if [ -z "$invite_token" ]; then
  echo "Profissional criado, mas a RPC nao gerou o convite:"
  echo "$invite_resp" | jq .
  echo "Aplique todas as migrations em supabase/migrations e tente novamente."
  exit 1
fi

qr_payload="iris://vincular/profissional?v=1&token=$invite_token"
qr_file="qr-profissional-${profissional_id}.png"

echo
echo "Profissional criado com sucesso."
echo "User ID:         $user_id"
echo "Profissional ID: $profissional_id"
echo "QR payload:      $qr_payload"
echo "Expira em:       $expires_at"
echo

if command -v qrencode >/dev/null 2>&1; then
  qrencode -o "$qr_file" "$qr_payload"
  echo "QR Code salvo em: $qr_file"
else
  echo "Instale qrencode para gerar a imagem PNG localmente."
  echo "No app, o profissional tambem ve o QR Code ao fazer login."
fi

echo
echo "Proximo passo:"
echo "1. Mantenha a SERVICE_ROLE_KEY somente no servidor e em .env.server."
echo "2. Faca login com o profissional para renovar ou revogar convites."
echo "3. Crie ou entre com um paciente e escaneie o QR Code antes da expiracao."
