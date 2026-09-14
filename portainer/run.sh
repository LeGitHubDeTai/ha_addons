#!/bin/sh

# Run Portainer
if [ "$1" = "portainer" ]; then
    exec portainer "$@"
fi

exec portainer "$@"