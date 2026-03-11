FROM node:18-alpine

# Install dependencies
RUN apk add --no-cache git

# Clone Drawnix repository
RUN git clone https://github.com/plait-board/drawnix.git /app

# Set working directory
WORKDIR /app

# Install dependencies and build
RUN npm install && npm run build

# Expose port
EXPOSE 7200

# Start the application in production mode
CMD ["npm", "run", "startDDDDDDD"]
