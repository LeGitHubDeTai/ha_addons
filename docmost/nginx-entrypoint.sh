#!/bin/bash
set -e
export NGINX_ALLOWED_IP="${NGINX_ALLOWED_IP:-any}"
envsubst '$NGINX_ALLOWED_IP' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
/usr/sbin/nginx -g "daemon off;"
