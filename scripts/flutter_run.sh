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

iris_run_args=()
iris_device_was_selected=false
iris_build_mode_was_selected=false
iris_web_port_was_selected=false
iris_uses_web_device=false
iris_expects_device_id=false
for iris_argument in "$@"; do
  if [[ "$iris_expects_device_id" == true ]]; then
    if [[ "$iris_argument" == "chrome" || "$iris_argument" == "edge" || "$iris_argument" == "web-server" ]]; then
      iris_uses_web_device=true
    fi
    iris_expects_device_id=false
    continue
  fi

  case "$iris_argument" in
    -d|--device-id)
      iris_device_was_selected=true
      iris_expects_device_id=true
      ;;
    --device-id=*|-d=*)
      iris_device_was_selected=true
      iris_device_id="${iris_argument#*=}"
      if [[ "$iris_device_id" == "chrome" || "$iris_device_id" == "edge" || "$iris_device_id" == "web-server" ]]; then
        iris_uses_web_device=true
      fi
      ;;
    --debug|--profile|--release)
      iris_build_mode_was_selected=true
      ;;
    --web-port|--web-port=*)
      iris_web_port_was_selected=true
      ;;
  esac
done

if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" && \
      "$iris_device_was_selected" == false ]]; then
  iris_run_args+=(
    -d web-server
    --web-hostname=0.0.0.0
  )
  if [[ "$iris_build_mode_was_selected" == false ]]; then
    iris_run_args+=(--release)
  fi
  echo "Ambiente sem interface gráfica; iniciando a versão web otimizada na porta ${IRIS_WEB_PORT:-8080}." >&2
fi

iris_web_port="${IRIS_WEB_PORT:-8080}"
if { { [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]] &&
       [[ "$iris_device_was_selected" == false ]]; } ||
     [[ "$iris_uses_web_device" == true ]]; } &&
   [[ "$iris_web_port_was_selected" == false ]]; then
  iris_run_args+=("--web-port=$iris_web_port")
  echo "Versão web usando a porta fixa $iris_web_port." >&2
fi

exec "$iris_flutter_bin" run \
  "--dart-define=SUPABASE_URL=$iris_supabase_url" \
  "--dart-define=SUPABASE_PUBLISHABLE_KEY=$iris_supabase_key" \
  "${iris_run_args[@]}" \
  "$@"
