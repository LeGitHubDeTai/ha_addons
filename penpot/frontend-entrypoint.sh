#!/bin/bash
# Penpot frontend (nginx serving static + proxy to backend/exporter/mcp).
# Adapted from official penpotapp/frontend entrypoint.sh for localhost.
set -e

# shellcheck disable=SC1091
. /app/penpot-env.sh

echo "[frontend] waiting for backend..."
for i in $(seq 1 120); do
  if curl -fsS -o /dev/null http://localhost:6060/readyz 2>/dev/null; then
    break
  fi
  sleep 2
done

# --- config.js flags (same sed logic as official image) ---
if [ -n "$PENPOT_FLAGS" ]; then
  sed -i -e "s|^//var penpotFlags = .*;|var penpotFlags = \"$PENPOT_FLAGS\";|g" /var/www/app/js/config.js || true
fi
if [ -n "$PENPOT_PUBLIC_URI" ]; then
  if grep -q "penpotPublicURI" /var/www/app/js/config.js; then
    echo "[frontend] public URI already present"
  else
    echo "var penpotPublicURI = \"$PENPOT_PUBLIC_URI\";" >> /var/www/app/js/config.js
  fi
fi

# --- nginx config from official template, pointed at localhost ---
export PENPOT_BACKEND_URI="http://localhost:6060"
export PENPOT_EXPORTER_URI="http://localhost:6061"
export PENPOT_NITRATE_URI="${PENPOT_NITRATE_URI:-http://localhost:3000}"
export penpot_nitrate_uri="${penpot_nitrate_uri:-http://localhost:3000}"
export PENPOT_HTTP_SERVER_MAX_BODY_SIZE="${PENPOT_HTTP_SERVER_MAX_BODY_SIZE}"
export PENPOT_IPV6_LISTEN_DIRECTIVE=""
# IPv6 listen disabled by default in HA (kernel may lack IPv6)

envsubst '$PENPOT_BACKEND_URI,$PENPOT_EXPORTER_URI,$PENPOT_NITRATE_URI,$penpot_nitrate_uri,$PENPOT_HTTP_SERVER_MAX_BODY_SIZE,$PENPOT_IPV6_LISTEN_DIRECTIVE' \
  < /tmp/penpot-nginx.conf.template > /etc/nginx/nginx.conf

# Guard: upstream templates gain new $PENPOT_* vars over time (e.g. nitrate in
# 2.17). Any leftover would emerg-fail nginx, so warn loudly here instead.
REMAINING_VARS="$(grep -o '\$PENPOT_[A-Z_0-9]*\|\$penpot_[a-z_0-9]*' /etc/nginx/nginx.conf | sort -u || true)"
if [ -n "$REMAINING_VARS" ]; then
  echo "[frontend] WARNING: unsubstituted template vars remain: $REMAINING_VARS"
fi

if echo "$PENPOT_FLAGS" | grep -q "enable-mcp"; then
  export PENPOT_MCP_URI="http://localhost:4401"
  export PENPOT_MCP_URI_WS="http://localhost:4402"
  if [ -f /tmp/penpot-mcp-locations.conf.template ]; then
    envsubst '$PENPOT_MCP_URI,$PENPOT_MCP_URI_WS' \
      < /tmp/penpot-mcp-locations.conf.template > /etc/nginx/overrides/server.d/mcp-locations.conf
  else
    # Fallback: upstream template missing in this image, write known-good locations
    cat > /etc/nginx/overrides/server.d/mcp-locations.conf <<'EOF'
location /mcp/ws {
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_pass http://localhost:4402;
    proxy_http_version 1.1;
}
location /mcp/stream {
    proxy_pass http://localhost:4401/mcp$is_args$args;
    proxy_http_version 1.1;
}
location /mcp/sse {
    proxy_pass http://localhost:4401/sse$is_args$args;
    proxy_http_version 1.1;
}
EOF
  fi
else
  rm -f /etc/nginx/overrides/server.d/mcp-locations.conf
fi
rm -f /etc/nginx/overrides/server.d/admin-console-locations.conf

# Internal resolver for nginx (localhost DNS)
PENPOT_DEFAULT_INTERNAL_RESOLVER="$(awk 'BEGIN{ORS=" "} $1=="nameserver" { sub(/%.*$/,"",$2); print ($2 ~ ":")? "["$2"]": $2}' /etc/resolv.conf)"
export PENPOT_INTERNAL_RESOLVER="${PENPOT_INTERNAL_RESOLVER:-$PENPOT_DEFAULT_INTERNAL_RESOLVER}"
if [ -f /tmp/penpot-resolvers.conf.template ]; then
  envsubst '$PENPOT_INTERNAL_RESOLVER' \
    < /tmp/penpot-resolvers.conf.template > /etc/nginx/overrides/http.d/resolvers.conf
fi

mkdir -p /run/nginx /tmp/cache /tmp/client_temp /tmp/proxy_temp_path
nginx -t

echo "[frontend] starting nginx on :8080..."
exec nginx -g "daemon off;"
