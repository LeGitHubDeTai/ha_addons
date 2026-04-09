/**
 * Local configuration overrides for Planka
 */

module.exports = {
  // Force all URLs to use nginx proxy with dynamic host
  baseUrl: process.env.EXTERNAL_URL || 'http://localhost:1339',
  clientUrl: process.env.EXTERNAL_URL || 'http://localhost:1339',
  serverUrl: process.env.SERVER_BASE_URL || 'http://localhost:1338',
  
  // WebSocket configuration - fix CORS error
  sockets: {
    baseUrl: process.env.EXTERNAL_URL || 'http://localhost:1339',
    url: process.env.EXTERNAL_URL || 'http://localhost:1339',
    onlyAllowOrigins: ['*']
  },
  
  // HTTP configuration
  http: {
    trustProxy: true,
    explicitHost: '0.0.0.0'
  },
  
  // Environment
  environment: 'production'
};
