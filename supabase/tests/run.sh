#!/bin/bash
# Uso: ./run.sh [migraciones...]  → restaura base limpia, aplica migraciones, siembra y prueba
set -e
cd /home/claude/staging
su postgres -c "psql -q -c 'drop database if exists dyf_test' -c 'create database dyf_test'" >/dev/null
su postgres -c "pg_restore -d dyf_test /home/claude/staging/dyf_base.dump" 2>&1 | grep -v "already exists" | head -5 || true
for m in "$@"; do su postgres -c "psql -q -d dyf_test -v ON_ERROR_STOP=1 -1 -f '$m'" || { echo "MIGRACION FALLÓ: $m"; exit 1; }; done
su postgres -c "psql -q -d dyf_test -v ON_ERROR_STOP=1 -f seed.sql" >/dev/null
su postgres -c "psql -q -d dyf_test -At -f tests.sql" 2>&1 | grep -v "^$"
