const { Pool } = require('pg');
const fs = require('fs');

let config;

if (process.env.DB_HOST) {
  config = {
    port: parseInt(process.env.APP_PORT || '8000'),
    db: {
      user: process.env.DB_USER || 'student',
      host: process.env.DB_HOST || 'localhost',
      database: process.env.DB_NAME || 'tasktracker',
      password: process.env.DB_PASSWORD || '',
      port: parseInt(process.env.DB_PORT || '5432'),
    },
  };
} else {
  const configPath = process.env.NODE_ENV === 'production'
    ? '/etc/mywebapp/config.json'
    : './config.json';
  config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
}

const pool = new Pool(config.db);

module.exports = { pool, config };