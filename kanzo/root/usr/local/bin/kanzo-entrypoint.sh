#!/usr/bin/env bash
# Point d'entrée Kanzo : applique les options Home Assistant (TZ, data_dir,
# env_vars_list), force l'écoute réseau dans config.toml (nécessaire pour
# l'Ingress HA) puis lance le tableau de bord sur le port 4242.
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

# --- config.toml : le board doit écouter sur 0.0.0.0 (Ingress + réseau) ---
CONFIG_TOML="${DATA_DIR}/config.toml"
if [ ! -f "${CONFIG_TOML}" ]; then
    cat > "${CONFIG_TOML}" <<'EOF'
port = 4242
listen = "0.0.0.0"
mcp_http = true
EOF
    bashio::log.info "config.toml créé (port 4242, listen 0.0.0.0, mcp_http true)"
elif grep -Eq '^listen[[:space:]]*=[[:space:]]*"127\.0\.0\.1"' "${CONFIG_TOML}"; then
    sed -i 's/^listen[[:space:]]*=.*/listen = "0.0.0.0"/' "${CONFIG_TOML}"
    bashio::log.info "config.toml : listen passé de 127.0.0.1 à 0.0.0.0"
elif ! grep -Eq '^listen[[:space:]]*=' "${CONFIG_TOML}"; then
    printf '\nlisten = "0.0.0.0"\n' >> "${CONFIG_TOML}"
    bashio::log.info "config.toml : listen 0.0.0.0 ajouté"
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
