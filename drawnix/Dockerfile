FROM node:18-alpine

# Install dependencies
RUN apk add --no-cache git

# Clone Drawnix repository
RUN git clone https://github.com/plait-board/drawnix.git /app

# Set working directory
WORKDIR /app

# Copy custom Vite config for Home Assistant compatibility
COPY vite.config.js ./apps/web/

# Increase Node.js memory limit and install dependencies
ENV NODE_OPTIONS="--max-old-space-size=2048"
RUN npm ci --no-audit --no-fund

# Build the application
RUN npm run build

# Expose port
EXPOSE 7200

# Start the application
CMD ["npm", "run", "start"]
