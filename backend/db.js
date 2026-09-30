const { Pool } = require("pg");

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
    throw new Error("DATABASE_URL is missing. Start with `node --env-file=.env server.js`.");
}

const databaseHost = new URL(connectionString).hostname;
const isSupabase = databaseHost.endsWith(".supabase.co") ||
    databaseHost.endsWith(".pooler.supabase.com");

const pool = new Pool({
    connectionString,
    ssl: isSupabase ? { rejectUnauthorized: false } : false
});

pool.on("error", (err) => {
    console.error("Unexpected PostgreSQL error:", err);
});

module.exports = pool;