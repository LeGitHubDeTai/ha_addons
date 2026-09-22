#!/bin/bash
# HA Ingress reverse-proxy: :9001 -> Penpot frontend :8080
export NGINX_ALLOWED_IP="${NGINX_ALLOWED_IP:-172.30.32.2}"
envsubst '$NGINX_ALLOWED_IP' < /etc/nginx/hass-nginx.conf.template > /etc/nginx/hass-nginx.conf
mkdir -p /run
nginx -t -c /etc/nginx/hass-nginx.conf
exec nginx -g "daemon off;" -c /etc/nginx/hass-nginx.conf
