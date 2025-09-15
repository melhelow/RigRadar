#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$PWD}"
PGDATA="${PGDATA:-$ROOT/tmp/pgdata}"
PGLOG="${PGLOG:-$ROOT/tmp/pg.log}"
PGPORT="${PGPORT:-5434}"
PGSOCKDIR="${PGSOCKDIR:-$ROOT/tmp}"
mkdir -p "$ROOT/tmp"

# Prefer distro Postgres tools if present
PG_BIN=$(ls -d /usr/lib/postgresql/*/bin 2>/dev/null | sort -V | tail -n1 || true)
[ -n "${PG_BIN:-}" ] && export PATH="$PG_BIN:$PATH"
