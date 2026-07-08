#!/usr/bin/env node
/**
 * Aplica migration subtasks.hora e corrige subtarefas com hora em descricao.
 *
 * Uso: node scripts/apply-subtask-hora.mjs
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
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const accessToken = process.env.SUPABASE_ACCESS_TOKEN;
const dbPassword = process.env.SUPABASE_DB_PASSWORD;
const databaseUrl = process.env.DATABASE_URL;
const migrationPath = path.join(root, "supabase/migrations/20260708200000_subtasks_hora.sql");

if (!supabaseUrl || !serviceRoleKey) {
  console.error("Missing NEXT_PUBLIC_SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
  process.exit(1);
}

const projectRef = new URL(supabaseUrl).hostname.split(".")[0];
const sql = fs.readFileSync(migrationPath, "utf8");

const headers = {
  apikey: serviceRoleKey,
  Authorization: `Bearer ${serviceRoleKey}`,
  "Content-Type": "application/json",
  Prefer: "return=representation",
};

async function columnExists() {
  const res = await fetch(
    `${supabaseUrl}/rest/v1/subtasks?select=hora&limit=1`,
    { headers },
  );
  if (res.status === 200) return true;
  const body = await res.text();
  if (body.includes("hora") && body.includes("does not exist")) return false;
  throw new Error(`Unexpected check (${res.status}): ${body}`);
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
  if (!res.ok) throw new Error(`Management API (${res.status}): ${body}`);
  console.log("Migration applied via Management API.");
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
    console.log("Migration applied via Postgres.");
  } finally {
    await client.end();
  }
}

async function backfillFromDescription() {
  const res = await fetch(
    `${supabaseUrl}/rest/v1/subtasks?select=id,descricao,hora&descricao=not.is.null`,
    { headers },
  );
  if (!res.ok) throw new Error(await res.text());
  const rows = await res.json();
  let updated = 0;
  for (const row of rows) {
    const desc = String(row.descricao ?? "").trim();
    if (!/^\d{1,2}:\d{2}$/.test(desc)) continue;
    if (row.hora) continue;
    const patch = await fetch(`${supabaseUrl}/rest/v1/subtasks?id=eq.${row.id}`, {
      method: "PATCH",
      headers,
      body: JSON.stringify({ hora: desc, descricao: null }),
    });
    if (!patch.ok) throw new Error(await patch.text());
    updated++;
  }
  console.log(`Backfill: ${updated} subtarefa(s) — hora movida de descricao → hora.`);
}

async function main() {
  console.log(`Project: ${projectRef}`);
  if (!(await columnExists())) {
    console.log("Coluna hora ausente — aplicando migration…");
    if (accessToken) await applyViaManagementApi();
    else if (databaseUrl || dbPassword) await applyViaPostgres();
    else {
      console.error(`
Não foi possível aplicar a migration automaticamente.

1. Abra o SQL Editor:
   https://supabase.com/dashboard/project/${projectRef}/sql/new

2. Cole e execute:

${sql.trim()}

3. Rode de novo: node scripts/apply-subtask-hora.mjs

Ou adicione SUPABASE_ACCESS_TOKEN ou SUPABASE_DB_PASSWORD em .env.local.
`);
      process.exit(1);
    }
  } else {
    console.log("Coluna hora já existe.");
  }
  await backfillFromDescription();
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
