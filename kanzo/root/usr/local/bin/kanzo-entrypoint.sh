#!/usr/bin/env bash
# Point d'entrée Kanzo (lancé par supervisord) : applique les options Home
# Assistant (TZ, data_dir, env_vars_list), aligne config.toml sur le reverse
# proxy nginx (port 4242 en loopback, cf. nginx.conf) puis lance le board.
set -euo pipefail

# Charge bashio (fonctions bashio::*) — présent dans les images de base HA.
for _bashio in /usr/lib/bashio/bashio.sh /usr/local/lib/bashio-standalone.sh; do
    if [ -f "${_bashio}" ]; then
        # shellcheck disable=SC1090
        source "${_bashio}"
        break
    fi
done

# --- Options HA ---
HA_TZ="$(bashio::config 'TZ' 2>/dev/null || true)"
if [ -n "${HA_TZ}" ] && [ "${HA_TZ}" != "null" ]; then
    export TZ="${HA_TZ}"
fi

DATA_DIR="$(bashio::config 'data_dir' 2>/dev/null || true)"
if [ -z "${DATA_DIR}" ] || [ "${DATA_DIR}" = "null" ]; then
    DATA_DIR="/share/kanzo"
fi
if ! mkdir -p "${DATA_DIR}" 2>/dev/null; then
    bashio::log.warning "Impossible de créer ${DATA_DIR}, répertoire courant utilisé"
    DATA_DIR="$(pwd)"
fi
export KANZO_HOME="${DATA_DIR}"
bashio::log.info "Dossier de données : ${DATA_DIR}"

# --- config.toml : nginx attend Kanzo sur 127.0.0.1:4242 (cf. nginx.conf) ---
# port et listen sont forcés : une valeur différente casserait le proxy.
CONFIG_TOML="${DATA_DIR}/config.toml"
if [ ! -f "${CONFIG_TOML}" ]; then
    cat > "${CONFIG_TOML}" <<'EOF'
port = 4242
listen = "127.0.0.1"
mcp_http = true
EOF
    bashio::log.info "config.toml créé (port 4242, listen 127.0.0.1, mcp_http true)"
else
    KANZO_FORCED=0
    if ! grep -Eq '^port[[:space:]]*=[[:space:]]*4242[[:space:]]*$' "${CONFIG_TOML}"; then
        if grep -Eq '^port[[:space:]]*=' "${CONFIG_TOML}"; then
            sed -i 's/^port[[:space:]]*=.*/port = 4242/' "${CONFIG_TOML}"
        else
            printf 'port = 4242\n' >> "${CONFIG_TOML}"
        fi
        KANZO_FORCED=1
    fi
    if ! grep -Eq '^listen[[:space:]]*=[[:space:]]*"127\.0\.0\.1"[[:space:]]*$' "${CONFIG_TOML}"; then
        if grep -Eq '^listen[[:space:]]*=' "${CONFIG_TOML}"; then
            sed -i 's/^listen[[:space:]]*=.*/listen = "127.0.0.1"/' "${CONFIG_TOML}"
        else
            printf 'listen = "127.0.0.1"\n' >> "${CONFIG_TOML}"
        fi
        KANZO_FORCED=1
    fi
    if [ "${KANZO_FORCED}" = "1" ]; then
        bashio::log.info "config.toml : port 4242 / listen 127.0.0.1 forcés (attendus par nginx)"
    fi
    # MCP sur /mcp : activé par défaut, l'utilisateur peut le désactiver.
    if ! grep -Eq '^mcp_http[[:space:]]*=' "${CONFIG_TOML}"; then
        printf 'mcp_http = true\n' >> "${CONFIG_TOML}"
        bashio::log.info "config.toml : mcp_http true ajouté"
    fi
fi

# --- Variables d'environnement libres (env_vars_list, format "CLE: valeur") ---
if bashio::config.has_value 'env_vars_list'; then
    while IFS= read -r line; do
        [ -z "${line}" ] && continue
        KEY=$(printf '%s' "${line}" | cut -d: -f1 | tr -d ' ')
        VAL=$(printf '%s' "${line}" | cut -d: -f2- | sed 's/^ //')
        if [ -n "${KEY}" ]; then
            export "${KEY}=${VAL}"
            bashio::log.info "env: ${KEY} défini"
        fi
    done < <(bashio::config 'env_vars_list | .[]' 2>/dev/null || jq -r '.env_vars_list[]?' /data/options.json 2>/dev/null || true)
fi

bashio::log.info "Démarrage de Kanzo (KANZO_HOME=${KANZO_HOME})"
exec kanzo --no-open
