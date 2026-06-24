#!/usr/bin/env bash
set -euo pipefail

# Cria um profissional confirmado no Supabase Auth e registros em usuarios,
# perfis e profissionais. Imprime o payload do QR Code para vinculo de pacientes.
#
# Uso:
#   EMAIL='psiquiatra@exemplo.com' PASSWORD='Senha123!' ./scripts/create_supabase_professional.sh
# Opcional:
#   DISPLAY_NAME='Dra. Ana Silva' ./scripts/create_supabase_professional.sh
#
# Requer SUPABASE_URL e SERVICE_ROLE_KEY no .env ou no ambiente.

if [ -f .env ]; then
  set -o allexport
  # shellcheck disable=SC1091
  source .env
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

profissional_payload=$(jq -n --arg user_id "$user_id" '{user_id: $user_id}')

profissional_resp=$(curl -sS -X POST "$SUPABASE_URL/rest/v1/profissionais" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "apikey: $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
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

qr_payload="iris://vincular/profissional/${profissional_id,,}"
qr_file="qr-profissional-${profissional_id}.png"

echo
echo "Profissional criado com sucesso."
echo "User ID:         $user_id"
echo "Profissional ID: $profissional_id"
echo "QR payload:      $qr_payload"
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
echo "1. Aplique supabase/migrations/0005_patient_professional_link_rls.sql no Supabase."
echo "2. Faca login com o profissional para exibir o QR Code no app."
echo "3. Crie ou entre com um paciente e escaneie o QR Code."
