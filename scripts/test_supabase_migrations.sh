#!/usr/bin/env bash
set -euo pipefail

workspace_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
container_name="iris-pg-smoke-$$"

cleanup() {
  docker stop "$container_name" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker run \
  --rm \
  --name "$container_name" \
  -e POSTGRES_PASSWORD=iris_test_password \
  -e POSTGRES_DB=iris_test \
  -v "$workspace_dir:/workspace:ro" \
  -d \
  postgres:15-alpine >/dev/null

database_ready=false
for _ in $(seq 1 30); do
  if docker exec "$container_name" \
    psql -U postgres -d iris_test -c 'select 1' >/dev/null 2>&1; then
    database_ready=true
    break
  fi
  sleep 1
done

if [[ "$database_ready" != true ]]; then
  echo "PostgreSQL de teste não ficou pronto a tempo." >&2
  exit 1
fi

run_sql() {
  docker exec "$container_name" \
    psql -v ON_ERROR_STOP=1 -U postgres -d iris_test -f "$1"
}

run_sql /workspace/supabase/tests/local_auth_bootstrap.sql
run_sql /workspace/supabase/migrations/0001_core_schema.sql
run_sql /workspace/supabase/migrations/0005_patient_professional_link_rls.sql
run_sql /workspace/supabase/tests/professional_backend_legacy_duplicates.sql
run_sql /workspace/supabase/migrations/0006_professional_backend.sql
run_sql /workspace/supabase/migrations/0007_professional_invite_legacy_text_compat.sql
run_sql /workspace/supabase/tests/clinical_data_integrity_legacy_duplicates.sql
run_sql /workspace/supabase/migrations/0008_clinical_data_integrity.sql
# A migration de integridade tambem deve convergir com seguranca em bancos
# onde parte das alteracoes ja tenha sido aplicada manualmente.
run_sql /workspace/supabase/migrations/0008_clinical_data_integrity.sql
run_sql /workspace/supabase/tests/professional_backend_smoke.sql
run_sql /workspace/supabase/tests/professional_backend_flow.sql
run_sql /workspace/supabase/tests/clinical_data_integrity.sql

echo "Migrations e fluxo profissional validados."
