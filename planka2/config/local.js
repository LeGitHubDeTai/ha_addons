/**
 * Local configuration overrides for Planka
 */

module.exports = {
  // Force correct URLs for client and server
  baseUrl: process.env.EXTERNAL_URL || 'http://localhost:1339',
  clientUrl: process.env.EXTERNAL_URL || 'http://localhost:1339',
  serverUrl: process.env.SERVER_BASE_URL || 'http://localhost:1337',
  
  // HTTP configuration
  http: {
    trustProxy: true,
    explicitHost: '0.0.0.0'
  },
  
  // Environment
  environment: 'production'
};
