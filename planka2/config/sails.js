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
    }
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
  
  // Environment
  environment: 'production'
};
