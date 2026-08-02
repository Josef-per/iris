#!/usr/bin/env bash

set -euo pipefail

iris_project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
iris_env_file="${IRIS_ENV_FILE:-$iris_project_dir/.env}"

if [[ ! -f "$iris_env_file" ]]; then
  echo "Arquivo de configuração não encontrado: $iris_env_file" >&2
  exit 1
fi

read_public_value() {
  local key="$1"
  local value

  value="$(
    awk -v key="$key" '
      $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
        line = $0
        sub("^[[:space:]]*" key "[[:space:]]*=[[:space:]]*", "", line)
        value = line
      }
      END { print value }
    ' "$iris_env_file"
  )"
  value="${value%$'\r'}"

  if [[ "$value" == \"*\" && "$value" == *\" ]]; then
    value="${value:1:${#value}-2}"
  elif [[ "$value" == \'*\' && "$value" == *\' ]]; then
    value="${value:1:${#value}-2}"
  fi

  printf '%s' "$value"
}

iris_supabase_url="$(read_public_value SUPABASE_URL)"
iris_supabase_key="$(read_public_value SUPABASE_PUBLISHABLE_KEY)"

if [[ -z "$iris_supabase_key" ]]; then
  iris_supabase_key="$(read_public_value SUPABASE_ANON_KEY)"
fi

if [[ -z "$iris_supabase_url" || -z "$iris_supabase_key" ]]; then
  echo "Defina SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY no arquivo .env." >&2
  exit 1
fi

iris_flutter_bin="${IRIS_FLUTTER_BIN:-}"
if [[ -z "$iris_flutter_bin" ]]; then
  if [[ -x "$iris_project_dir/.flutter-sdk/bin/flutter" ]]; then
    iris_flutter_bin="$iris_project_dir/.flutter-sdk/bin/flutter"
  else
    iris_flutter_bin="flutter"
  fi
fi

exec "$iris_flutter_bin" run \
  "--dart-define=SUPABASE_URL=$iris_supabase_url" \
  "--dart-define=SUPABASE_PUBLISHABLE_KEY=$iris_supabase_key" \
  "$@"
