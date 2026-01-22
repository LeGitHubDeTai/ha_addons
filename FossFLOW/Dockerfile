ARG BUILD_FROM
FROM $BUILD_FROM

# Set environment variables
ENV NODE_ENV=production
ENV ENABLE_SERVER_STORAGE=true
ENV STORAGE_PATH=/data/diagrams
ENV ENABLE_GIT_BACKUP=false

ENTRYPOINT ["/docker-entrypoint.sh"]
