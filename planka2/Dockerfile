# Dockerfile pour Home Assistant avec Planka officiel
FROM ghcr.io/plankanban/planka:latest

# Variables d'environnement Planka (officiel)
ENV NODE_ENV=production
ENV PORT=1337
ENV BASE_URL=http://localhost:1337
ENV TRUST_PROXY=true
ENV EXPLICIT_HOST=0.0.0.0

# Copier les scripts de configuration
COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Créer dossier de données
RUN mkdir -p /app/data

# Set supervisord as entrypoint
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
