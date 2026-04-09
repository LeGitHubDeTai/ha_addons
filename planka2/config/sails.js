/**
 * Sails.js configuration for WebSocket support
 */

module.exports = {
  // Allow all origins for WebSocket connections
  sockets: {
    onlyAllowOrigins: ['*']
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
