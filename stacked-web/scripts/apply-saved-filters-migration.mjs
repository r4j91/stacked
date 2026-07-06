#!/usr/bin/env node
/**
 * Applies saved_filters migration to remote Supabase.
 * Requires one of:
 *   - SUPABASE_ACCESS_TOKEN (Dashboard → Account → Access Tokens)
 *   - SUPABASE_DB_PASSWORD or DATABASE_URL (Dashboard → Project Settings → Database)
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, "..");
const migrationPath = path.join(
  root,
  "supabase/migrations/20260705200000_saved_filters.sql",
);

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
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const accessToken = process.env.SUPABASE_ACCESS_TOKEN;
const dbPassword = process.env.SUPABASE_DB_PASSWORD;
const databaseUrl = process.env.DATABASE_URL;

if (!supabaseUrl || !serviceRoleKey) {
  console.error("Missing NEXT_PUBLIC_SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env.local");
  process.exit(1);
}

const projectRef = new URL(supabaseUrl).hostname.split(".")[0];
const sql = fs.readFileSync(migrationPath, "utf8");

async function tableExists() {
  const res = await fetch(`${supabaseUrl}/rest/v1/saved_filters?select=id&limit=1`, {
    headers: {
      apikey: serviceRoleKey,
      Authorization: `Bearer ${serviceRoleKey}`,
    },
  });
  if (res.status === 200) return true;
  const body = await res.text();
  if (body.includes("PGRST205") || body.includes("does not exist")) return false;
  throw new Error(`Unexpected response checking saved_filters (${res.status}): ${body}`);
}

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
  if (!res.ok) {
    throw new Error(`Management API failed (${res.status}): ${body}`);
  }
  console.log("Migration applied via Supabase Management API.");
}

async function applyViaPostgres() {
  const { Client } = await import("pg");
  let connectionString = databaseUrl;
  if (!connectionString && dbPassword) {
    connectionString = `postgresql://postgres.${projectRef}:${encodeURIComponent(dbPassword)}@aws-0-us-east-1.pooler.supabase.com:6543/postgres`;
  }
  if (!connectionString) {
    throw new Error("No DATABASE_URL or SUPABASE_DB_PASSWORD");
  }
  const client = new Client({ connectionString, ssl: { rejectUnauthorized: false } });
  await client.connect();
  try {
    await client.query(sql);
    console.log("Migration applied via Postgres connection.");
  } finally {
    await client.end();
  }
}

async function main() {
  console.log(`Project: ${projectRef}`);
  const exists = await tableExists();
  if (exists) {
    console.log("saved_filters already exists — nothing to do.");
    return;
  }
  console.log("saved_filters not found — applying migration...");

  if (accessToken) {
    await applyViaManagementApi();
    return;
  }
  if (databaseUrl || dbPassword) {
    await applyViaPostgres();
    return;
  }

  console.error(`
Cannot apply migration automatically: missing credentials.

Add ONE of these to stacked-web/.env.local:

1) SUPABASE_ACCESS_TOKEN=<token from https://supabase.com/dashboard/account/tokens>
   then rerun: node scripts/apply-saved-filters-migration.mjs

2) SUPABASE_DB_PASSWORD=<database password from Project Settings → Database>
   then rerun: node scripts/apply-saved-filters-migration.mjs

Or paste the SQL manually in Supabase Dashboard → SQL Editor:
  ${migrationPath}
`);
  process.exit(1);
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
