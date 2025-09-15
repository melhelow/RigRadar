#!/usr/bin/env bash
set -euo pipefail
cd /workspaces/RigRadar
mkdir -p tmp/pgdata tmp/log

: "${DB_HOST:=127.0.0.1}"
: "${DB_PORT:=5433}"
: "${DB_USER:=postgres}"
: "${DB_PASSWORD:=postgres}"

# Ensure server binaries exist; try to install only if sudo is non-interactive
if ! command -v initdb >/dev/null 2>&1; then
  if sudo -n true 2>/dev/null; then
    sudo apt-get update -y
    sudo apt-get install -y postgresql postgresql-contrib postgresql-client
  fi
fi
command -v initdb >/dev/null 2>&1 || { echo "initdb not found; cannot initialize private Postgres"; exit 1; }

# First-time init
if [ ! -s tmp/pgdata/PG_VERSION ]; then
  printf "%s" "$DB_PASSWORD" > tmp/pgpw
  initdb -D tmp/pgdata -U "$DB_USER" -A scram-sha-256 --pwfile=tmp/pgpw
  rm -f tmp/pgpw
  {
    echo "listen_addresses = '$DB_HOST'"
    echo "port = $DB_PORT"
  } >> tmp/pgdata/postgresql.conf
  grep -q '127.0.0.1/32' tmp/pgdata/pg_hba.conf || \
    echo "host all all 127.0.0.1/32 scram-sha-256" >> tmp/pgdata/pg_hba.conf
fi

# Start (idempotent)
pg_ctl -D tmp/pgdata -l tmp/pg.log -o "-p $DB_PORT -h $DB_HOST" start || true

# Wait until ready
for i in {1..50}; do
  pg_isready -h "$DB_HOST" -p "$DB_PORT" && break || sleep 0.2
done

# Ensure dev/test DBs exist
PGPASSWORD="$DB_PASSWORD" createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" rig_radar_development || true
PGPASSWORD="$DB_PASSWORD" createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" rig_radar_test || true
