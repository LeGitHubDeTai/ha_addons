/**
 * Sails.js configuration for WebSocket support
 */

module.exports = {
  // Allow all origins for WebSocket connections
  sockets: {
    onlyAllowOrigins: ['*'],
    cors: {
      origin: '*',
      credentials: true
    },
    // Force WebSocket URL to use nginx proxy
    url: 'http://localhost:1339',
    transports: ['websocket', 'polling']
  },
  
  // Security settings
  security: {
    cors: {
      allowOrigins: '*',
      allowCredentials: true
    }
  },
  
  // HTTP settings
  http: {
    trustProxy: true
  },
  
  // Explicit host binding
  host: '0.0.0.0',
  
  // Force URLs for client
  urls: {
    base: 'http://localhost:1339'
  },
  
  // Environment
  environment: 'production'
};
