#!/bin/sh
set -e

echo "Running database schema..."
node -e "
const { Pool } = require('pg');
const fs = require('fs');
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
pool.query(fs.readFileSync('./src/config/schema.sql', 'utf8'))
  .then(() => { console.log('Schema applied.'); pool.end(); })
  .catch(e => { console.error('Schema error:', e.message); pool.end(); });
"

echo "Starting server..."
node src/index.js
