#!/usr/bin/env node
/**
 * Aplica um arquivo SQL de migration no Supabase remoto.
 *
 * Uso:
 *   node scripts/apply-sql-migration.mjs supabase/migrations/20260708220000_supabase_hygiene.sql
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, "..");

function loadEnvFile(filePath) {
  if (!fs.existsSync(filePath)) return;
  for (const line of fs.readFileSync(filePath, "utf8").split("\n")) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const i = trimmed.indexOf("=");
    if (i <= 0) continue;
    const key = trimmed.slice(0, i);
    const value = trimmed.slice(i + 1);
    if (!process.env[key]) process.env[key] = value;
  }
}

loadEnvFile(path.join(root, ".env.local"));

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const accessToken = process.env.SUPABASE_ACCESS_TOKEN;
const dbPassword = process.env.SUPABASE_DB_PASSWORD;
const databaseUrl = process.env.DATABASE_URL;

const relPath = process.argv[2];
if (!relPath) {
  console.error("Usage: node scripts/apply-sql-migration.mjs <path-to.sql>");
  process.exit(1);
}

const migrationPath = path.isAbsolute(relPath) ? relPath : path.join(root, relPath);
if (!fs.existsSync(migrationPath)) {
  console.error("File not found:", migrationPath);
  process.exit(1);
}

if (!supabaseUrl) {
  console.error("Missing NEXT_PUBLIC_SUPABASE_URL in .env.local");
  process.exit(1);
}

const projectRef = new URL(supabaseUrl).hostname.split(".")[0];
const sql = fs.readFileSync(migrationPath, "utf8");

async function applyViaManagementApi() {
  const res = await fetch(
    `https://api.supabase.com/v1/projects/${projectRef}/database/query`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ query: sql }),
    },
  );
  const body = await res.text();
  if (!res.ok) throw new Error(`Management API (${res.status}): ${body}`);
  console.log("Applied via Management API:", path.basename(migrationPath));
}

async function applyViaPostgres() {
  const { Client } = await import("pg");
  let connectionString = databaseUrl;
  if (!connectionString && dbPassword) {
    connectionString = `postgresql://postgres.${projectRef}:${encodeURIComponent(dbPassword)}@aws-0-us-east-1.pooler.supabase.com:6543/postgres`;
  }
  if (!connectionString) throw new Error("No DATABASE_URL or SUPABASE_DB_PASSWORD");
  const client = new Client({ connectionString, ssl: { rejectUnauthorized: false } });
  await client.connect();
  try {
    await client.query(sql);
    console.log("Applied via Postgres:", path.basename(migrationPath));
  } finally {
    await client.end();
  }
}

async function main() {
  console.log(`Project: ${projectRef}`);
  console.log(`File: ${migrationPath}\n`);
  if (accessToken) await applyViaManagementApi();
  else if (databaseUrl || dbPassword) await applyViaPostgres();
  else {
    console.error("Add SUPABASE_ACCESS_TOKEN or SUPABASE_DB_PASSWORD to .env.local");
    process.exit(1);
  }
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
