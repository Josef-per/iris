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

for _ in 1 2 3 4 5 6 7 8 9 10; do
  if docker exec "$container_name" \
    pg_isready -U postgres -d iris_test >/dev/null; then
    break
  fi
  sleep 1
done

run_sql() {
  docker exec "$container_name" \
    psql -v ON_ERROR_STOP=1 -U postgres -d iris_test -f "$1"
}

run_sql /workspace/supabase/tests/local_auth_bootstrap.sql
run_sql /workspace/supabase/migrations/0001_core_schema.sql
run_sql /workspace/supabase/migrations/0005_patient_professional_link_rls.sql
run_sql /workspace/supabase/tests/professional_backend_legacy_duplicates.sql
run_sql /workspace/supabase/migrations/0006_professional_backend.sql
run_sql /workspace/supabase/tests/professional_backend_smoke.sql
run_sql /workspace/supabase/tests/professional_backend_flow.sql

echo "Migrations e fluxo profissional validados."
