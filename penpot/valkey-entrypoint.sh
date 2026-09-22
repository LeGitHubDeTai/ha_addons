#!/bin/bash
# Valkey (or Redis fallback) for Penpot websockets/cache.
set -e
mkdir -p /data/penpot/valkey
if command -v valkey-server >/dev/null 2>&1; then
  echo "[valkey] starting valkey-server..."
  exec valkey-server --appendonly yes --maxmemory 128mb --maxmemory-policy volatile-lfu --dir /data/penpot/valkey --port 6379
elif command -v redis-server >/dev/null 2>&1; then
  echo "[valkey] valkey-server not found, using redis-server..."
  exec redis-server --appendonly yes --maxmemory 128mb --maxmemory-policy volatile-lfu --dir /data/penpot/valkey --port 6379
else
  echo "[valkey] ERROR: neither valkey-server nor redis-server found" >&2
  exit 1
fi
