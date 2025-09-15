#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/pg-common.sh"

command -v pg_ctl >/dev/null 2>&1 || { echo "pg_ctl not found; skipping start"; exit 0; }

# Already running?
if pg_ctl -D "$PGDATA" status >/dev/null 2>&1; then
  echo "Postgres already running on port $PGPORT"
  exit 0
fi

echo "Starting Postgres (data=$PGDATA, port=$PGPORT)"
pg_ctl -D "$PGDATA" -l "$PGLOG" -o "-p $PGPORT -k $PGSOCKDIR" -w start || {
  echo "Failed to start Postgres. Log tail:"
  tail -n 200 "$PGLOG"
  exit 1
}

# Ensure password (idempotent)
psql -h "$PGSOCKDIR" -p "$PGPORT" -U postgres -d postgres \
  -c "ALTER ROLE postgres WITH LOGIN PASSWORD 'postgres';" >/dev/null 2>&1 || true

pg_isready -h 127.0.0.1 -p "$PGPORT" || { tail -n 200 "$PGLOG"; exit 1; }
echo "Postgres is ready on 127.0.0.1:$PGPORT"
