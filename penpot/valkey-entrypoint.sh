#!/bin/bash
# Embedded Valkey: ephemeral cache/message-bus (like the official compose,
# which persists nothing for valkey). No data to back up.
set -e
mkdir -p /var/lib/valkey
if command -v valkey-server >/dev/null 2>&1; then
  echo "[valkey] starting embedded valkey-server (ephemeral, no persistence)..."
  exec valkey-server --save '' --appendonly no --maxmemory 128mb --maxmemory-policy volatile-lfu --dir /var/lib/valkey --port 6379
elif command -v redis-server >/dev/null 2>&1; then
  echo "[valkey] valkey-server not found, using redis-server (ephemeral)..."
  exec redis-server --save '' --appendonly no --maxmemory 128mb --maxmemory-policy volatile-lfu --dir /var/lib/valkey --port 6379
else
  echo "[valkey] ERROR: neither valkey-server nor redis-server found" >&2
  exit 1
fi
