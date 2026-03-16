FROM node:25-alpine

RUN apk add --no-cache git

# Clone repo
RUN git clone https://github.com/plait-board/drawnix.git /app

WORKDIR /app

COPY vite.config.js ./apps/web/

# Installer dépendances
RUN npm install

# Build production
RUN npm run build

EXPOSE 7200

CMD ["npm", "start"]
