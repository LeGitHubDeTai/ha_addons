FROM node:18-alpine

# Install dependencies
RUN apk add --no-cache git

# Clone Drawnix repository
RUN git clone https://github.com/plait-board/drawnix.git /app

# Set working directory
WORKDIR /app

# Copy custom Vite config for Home Assistant compatibility
COPY vite.config.js ./apps/web/

RUN npm install

# Expose port
EXPOSE 7200

# Start the application
CMD ["npm", "run", "start"]
