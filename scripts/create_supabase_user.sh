#!/usr/bin/env bash
set -euo pipefail

# Script para criar usuário confirmado via Admin API do Supabase (server-side).
# Uso:
#   EMAIL='novo@exemplo.com' PASSWORD='Senha123!' ./scripts/create_supabase_user.sh
# Opcional:
#   DISPLAY_NAME='Nome Completo' ./scripts/create_supabase_user.sh
# Alternativamente, defina SUPABASE_URL e SERVICE_ROLE_KEY no arquivo
# .env.server ou como variáveis de ambiente.
# Atenção: NÃO COMMITAR sua SERVICE_ROLE_KEY em repositórios públicos.

# Carrega .env.server se existir
if [ -f .env.server ]; then
  set -o allexport
  # shellcheck disable=SC1091
  source .env.server
  set +o allexport
fi

SUPABASE_URL="${SUPABASE_URL:-}"
SERVICE_ROLE_KEY="${SERVICE_ROLE_KEY:-}"

if [ -z "$SUPABASE_URL" ]; then
  echo "SUPABASE_URL não definido (exporte a variável ou use .env.server)"
  exit 1
fi

if [ -z "$SERVICE_ROLE_KEY" ]; then
  echo "SERVICE_ROLE_KEY não definido (exporte a variável ou use .env.server)"
  exit 1
fi

if [ -z "${EMAIL:-}" ] || [ -z "${PASSWORD:-}" ]; then
  cat <<EOF
Uso:
  EMAIL='novo@exemplo.com' PASSWORD='Senha123!' ./scripts/create_supabase_user.sh
ou defina as variáveis de ambiente antes de rodar:
  export EMAIL='novo@exemplo.com'
  export PASSWORD='Senha123!'
  ./scripts/create_supabase_user.sh

Opcional:
  export DISPLAY_NAME='Nome Completo'
EOF
  exit 1
fi

# Monta payload JSON (usa jq se disponível, senão monta manualmente)
if command -v jq >/dev/null 2>&1; then
  if [ -n "${DISPLAY_NAME:-}" ]; then
    payload=$(jq -n --arg email "$EMAIL" --arg password "$PASSWORD" --arg display_name "$DISPLAY_NAME" '{email:$email,password:$password,"email_confirm":true, user_metadata:{display_name:$display_name}}')
  else
    payload=$(jq -n --arg email "$EMAIL" --arg password "$PASSWORD" '{email:$email,password:$password,"email_confirm":true}')
  fi
else
  payload='{"email":"'"$EMAIL"'","password":"'"$PASSWORD"'","email_confirm":true'
  if [ -n "${DISPLAY_NAME:-}" ]; then
    # Escapa aspas case haja no nome
    esc_display=$(printf '%s' "$DISPLAY_NAME" | sed 's/"/\\"/g')
    payload="$payload, \"user_metadata\":{\"display_name\":\"$esc_display\"}"
  fi
  payload="$payload}"
fi

# Faz requisição para Admin API
resp=$(curl -sS -X POST "$SUPABASE_URL/auth/v1/admin/users" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d "$payload")

# Exibe resposta (formatada com jq se disponível)
if command -v jq >/dev/null 2>&1; then
  echo "$resp" | jq .
else
  echo "$resp"
fi

echo "Usuário criado (ou resposta retornada acima)."
