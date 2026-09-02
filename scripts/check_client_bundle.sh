#!/usr/bin/env bash
set -euo pipefail

bundle_dir="${1:-build/web}"

if [[ ! -d "$bundle_dir" ]]; then
  echo "Bundle não encontrado: $bundle_dir" >&2
  exit 1
fi

if find "$bundle_dir" -type f -name '.env' -print -quit | grep -q .; then
  echo "Falha: arquivo .env encontrado no bundle." >&2
  exit 1
fi

if grep -RIlE \
  'SUPABASE_SECRET_KEY|SUPABASE_SERVICE_ROLE_KEY|SERVICE_ROLE_KEY|sb_secret_|OPENAI_API_KEY|OPENAI_ORG_ID|sk-proj-' \
  "$bundle_dir" >/dev/null; then
  echo "Falha: marcador de segredo encontrado no bundle." >&2
  exit 1
fi

echo "Bundle sem marcadores conhecidos de segredo."
