# Shared Penpot environment for all entrypoints.
# Sourced (NOT executed): . /app/penpot-env.sh
# PostgreSQL is EXTERNAL (managed by the user, e.g. a PostgreSQL server).
# Valkey runs embedded (ephemeral cache, like the official compose).
# Persists the generated secret key in /data/penpot/ so it survives restarts.

CONFIG_PATH="/data/options.json"
DATA_DIR="/data/penpot"
SECRET_FILE="${DATA_DIR}/.secret_key"

mkdir -p "${DATA_DIR}/assets"

penpot_opt() {
  # $1 = jq key, $2 = default
  local val
  val="$(jq --raw-output --arg d "$2" '.[$k] // $d | tostring' --arg k "$1" "$CONFIG_PATH" 2>/dev/null)"
  # jq returns "null"/"" when missing -> fallback to default
  if [ -z "$val" ] || [ "$val" = "null" ]; then
    echo "$2"
  else
    echo "$val"
  fi
}

# --- Timezone ---
TZ_VAL="$(jq --raw-output '.timezone // "Europe/Paris"' "$CONFIG_PATH")"
export TZ="${TZ_VAL}"

# --- Secret key (persisted, never regenerated once created) ---
SECRET_OPT="$(jq --raw-output '.secret_key // empty' "$CONFIG_PATH")"
if [ -n "$SECRET_OPT" ]; then
  PENPOT_SECRET_KEY="$SECRET_OPT"
elif [ -f "$SECRET_FILE" ]; then
  PENPOT_SECRET_KEY="$(cat "$SECRET_FILE")"
else
  PENPOT_SECRET_KEY="$(openssl rand -hex 64)"
  echo -n "$PENPOT_SECRET_KEY" > "$SECRET_FILE"
  chmod 600 "$SECRET_FILE"
fi
export PENPOT_SECRET_KEY

# --- External PostgreSQL (managed by the user) ---
DB_HOST="$(jq --raw-output '.DATABASE.db_host // empty' "$CONFIG_PATH")"
DB_PORT="$(jq --raw-output '.DATABASE.db_port // 5432' "$CONFIG_PATH")"
DB_USER="$(jq --raw-output '.DATABASE.db_user // "penpot"' "$CONFIG_PATH")"
DB_PASSWORD="$(jq --raw-output '.DATABASE.db_password // empty' "$CONFIG_PATH")"
DB_NAME="$(jq --raw-output '.DATABASE.db_name // "penpot"' "$CONFIG_PATH")"

if [ -z "$DB_HOST" ]; then
  echo "[penpot-env] FATAL: DATABASE.db_host is not set. Configure an external PostgreSQL server in the add-on options." >&2
fi
if [ -z "$DB_PASSWORD" ]; then
  echo "[penpot-env] WARNING: DATABASE.db_password is empty." >&2
fi

export PENPOT_DB_HOST="$DB_HOST"
export PENPOT_DB_PORT="$DB_PORT"
export PENPOT_DB_USER="$DB_USER"
export PENPOT_DB_PASSWORD="$DB_PASSWORD"
export PENPOT_DB_NAME="$DB_NAME"
export PENPOT_DATABASE_URI="postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}"
export PENPOT_DATABASE_USERNAME="$DB_USER"
export PENPOT_DATABASE_PASSWORD="$DB_PASSWORD"

# --- Redis/Valkey (embedded by default, external if configured) ---
REDIS_HOST="$(jq --raw-output '.REDIS.redis_host // "localhost"' "$CONFIG_PATH")"
REDIS_PORT="$(jq --raw-output '.REDIS.redis_port // 6379' "$CONFIG_PATH")"
REDIS_DB="$(jq --raw-output '.REDIS.redis_db // 0' "$CONFIG_PATH")"
export PENPOT_REDIS_HOST="$REDIS_HOST"
export PENPOT_REDIS_PORT="$REDIS_PORT"
export PENPOT_REDIS_DB="$REDIS_DB"
export PENPOT_REDIS_URI="redis://${REDIS_HOST}:${REDIS_PORT}/${REDIS_DB}"

# --- Feature flags ---
ALLOW_REG="$(jq --raw-output '.allow_registration // true' "$CONFIG_PATH")"
SMTP_HOST="$(jq --raw-output '.smtp_host // empty' "$CONFIG_PATH")"

PENPOT_FLAGS="disable-email-verification disable-secure-session-cookies enable-prepl-server enable-mcp"
if [ -n "$SMTP_HOST" ]; then
  PENPOT_FLAGS="$PENPOT_FLAGS enable-smtp"
fi
if [ "$ALLOW_REG" = "true" ]; then
  PENPOT_FLAGS="$PENPOT_FLAGS enable-registration"
else
  PENPOT_FLAGS="$PENPOT_FLAGS disable-registration"
fi
export PENPOT_FLAGS

# --- Public URI (internal; ingress serves it on 9001) ---
export PENPOT_PUBLIC_URI="http://localhost:9001"
export PENPOT_HTTP_SERVER_MAX_BODY_SIZE="367001600"
export PENPOT_HTTP_SERVER_MAX_MULTIPART_BODY_SIZE="367001600"

# --- Database / Valkey (see above) ---

# --- Assets storage (filesystem) ---
export PENPOT_OBJECTS_STORAGE_BACKEND="fs"
export PENPOT_OBJECTS_STORAGE_FS_DIRECTORY="/opt/data/assets"

# --- Telemetry ---
DISABLE_TEL="$(jq --raw-output '.disable_telemetry // true' "$CONFIG_PATH")"
if [ "$DISABLE_TEL" = "true" ]; then
  export PENPOT_TELEMETRY_ENABLED="false"
else
  export PENPOT_TELEMETRY_ENABLED="true"
fi
export PENPOT_TELEMETRY_REFERER="ha-addon"

# --- SMTP ---
SMTP_PORT="$(jq --raw-output '.smtp_port // 587' "$CONFIG_PATH")"
SMTP_USER="$(jq --raw-output '.smtp_username // empty' "$CONFIG_PATH")"
SMTP_PASS="$(jq --raw-output '.smtp_password // empty' "$CONFIG_PATH")"
SMTP_FROM="$(jq --raw-output '.smtp_from // "no-reply@example.com"' "$CONFIG_PATH")"
SMTP_REPLY="$(jq --raw-output '.smtp_reply_to // "no-reply@example.com"' "$CONFIG_PATH")"
export PENPOT_SMTP_DEFAULT_FROM="$SMTP_FROM"
export PENPOT_SMTP_DEFAULT_REPLY_TO="$SMTP_REPLY"
export PENPOT_SMTP_HOST="${SMTP_HOST:-localhost}"
export PENPOT_SMTP_PORT="$SMTP_PORT"
export PENPOT_SMTP_USERNAME="$SMTP_USER"
export PENPOT_SMTP_PASSWORD="$SMTP_PASS"
export PENPOT_SMTP_TLS="false"
export PENPOT_SMTP_SSL="false"

# --- Internal service URIs (all local, single container) ---
export PENPOT_BACKEND_URI="http://localhost:6060"
export PENPOT_EXPORTER_URI="http://localhost:6061"
export PENPOT_NITRATE_URI="http://localhost:3000"
# Lowercase alias: some frontend templates use $penpot_nitrate_uri
export penpot_nitrate_uri="http://localhost:3000"
export PENPOT_MCP_URI="http://localhost:4401"
export PENPOT_MCP_URI_WS="http://localhost:4402"
export PENPOT_INTERNAL_URI="http://localhost:8080"
