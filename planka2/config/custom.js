/**
 * Custom configuration for Planka
 */

module.exports = {
  // Base URL for the application
  baseUrl: process.env.BASE_URL || '/',

  // Database configuration
  datastores: {
    default: {
      adapter: 'sails-postgresql',
      url: process.env.DATABASE_URL
    }
  },

  // Security settings
  security: {
    cors: {
      allowOrigins: process.env.CORS_ORIGIN ? process.env.CORS_ORIGIN.split(',') : ['*'],
      allowCredentials: true
    }
  },

  // Session configuration
  session: {
    secret: process.env.SECRET_KEY || 'default-secret-change-me'
  },

  // Trust proxy settings for ingress
  http: {
    trustProxy: process.env.TRUST_PROXY === '1'
  },

  // Explicit host to prevent EADDRINUSE errors
  host: process.env.EXPLICIT_HOST || 'localhost',

  // Admin user creation
  admin: {
    email: process.env.DEFAULT_ADMIN_EMAIL,
    password: process.env.DEFAULT_ADMIN_PASSWORD,
    name: process.env.DEFAULT_ADMIN_NAME
  },

  // File upload settings
  uploads: {
    maxBytes: 100 * 1024 * 1024, // 100MB
    dirname: process.env.UPLOADS_PATH || '/app/user-data/uploads'
  },

  // Logging
  log: {
    level: process.env.LOG_LEVEL || 'info'
  }
};
