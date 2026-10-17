const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.PGHOST || 'localhost',
  port: parseInt(process.env.PGPORT || '5432', 10),
  database: process.env.PGDATABASE || 'farmer_market_db',
  user: process.env.PGUSER || 'postgres',
  password: process.env.PGPASSWORD || undefined,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

pool.on('error', (err) => {
  const msg = err.message || err.code || err.toString();
  console.error('[PostgreSQL Pool Error]:', msg);
});

async function query(text, params) {
  const start = Date.now();
  try {
    const res = await pool.query(text, params);
    const duration = Date.now() - start;
    // Log in development if needed
    // console.log(`[SQL Executed] ${duration}ms: ${text.slice(0, 60)}...`);
    return res;
  } catch (error) {
    const errorMsg = error.message || error.code || error.toString();
    console.error(`[SQL Error] in query: "${text}":`, errorMsg);
    throw error;
  }
}

async function testConnection() {
  try {
    const res = await pool.query('SELECT current_database() as db, current_user as usr, version() as ver');
    return {
      connected: true,
      database: res.rows[0].db,
      user: res.rows[0].usr,
      version: res.rows[0].ver
    };
  } catch (err) {
    return {
      connected: false,
      error: err.message
    };
  }
}

module.exports = {
  pool,
  query,
  testConnection
};
