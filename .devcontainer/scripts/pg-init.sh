#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/pg-common.sh"

# If postgres tools aren’t in the image, just skip (don’t crash)
command -v initdb >/dev/null 2>&1 || { echo "initdb not found; skipping init"; exit 0; }

# Initialize once
if [ ! -s "$PGDATA/PG_VERSION" ]; then
  echo "Initializing local cluster in $PGDATA"
  rm -rf "$PGDATA"
  initdb -D "$PGDATA" -U postgres --auth-local=trust --auth-host=scram-sha-256
  {
    echo "listen_addresses = '127.0.0.1'"
    echo "port = $PGPORT"
    echo "unix_socket_directories = '$PGSOCKDIR'"
    echo "password_encryption = 'scram-sha-256'"
  } >> "$PGDATA/postgresql.conf"
fi
