/**
 * Local configuration overrides for Planka
 */

module.exports = {
  // Force all URLs to use nginx proxy
  baseUrl: 'http://localhost:1339',
  clientUrl: 'http://localhost:1339',
  serverUrl: 'http://localhost:1339',
  
  // WebSocket configuration
  sockets: {
    baseUrl: 'http://localhost:1339',
    url: 'http://localhost:1339',
    onlyAllowOrigins: ['*'],
    cors: {
      origin: '*',
      credentials: true
    }
  },
  
  // HTTP configuration
  http: {
    trustProxy: true,
    explicitHost: '0.0.0.0'
  },
  
  // Environment
  environment: 'production'
};
