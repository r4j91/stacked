#!/usr/bin/env node
/**
 * Cria tarefas pai (meses 07–12) + subtarefas de despesas fixas
 * no projeto FINANCEIRO / seção DESPESAS FIXAS.
 *
 * Uso: node scripts/seed-financeiro-despesas-fixas.mjs
 *      node scripts/seed-financeiro-despesas-fixas.mjs --dry-run
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
const dryRun = process.argv.includes("--dry-run");

if (!supabaseUrl || !serviceRoleKey) {
  console.error("Missing NEXT_PUBLIC_SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env.local");
  process.exit(1);
}

const headers = {
  apikey: serviceRoleKey,
  Authorization: `Bearer ${serviceRoleKey}`,
  "Content-Type": "application/json",
  Prefer: "return=representation",
};

async function rest(pathname, { method = "GET", body, query } = {}) {
  const url = new URL(`${supabaseUrl}/rest/v1/${pathname}`);
  if (query) {
    for (const [k, v] of Object.entries(query)) url.searchParams.set(k, v);
  }
  const res = await fetch(url, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`${method} ${pathname} (${res.status}): ${text}`);
  return text ? JSON.parse(text) : null;
}

const MONTHS = [
  { num: 7, name: "Julho" },
  { num: 8, name: "Agosto" },
  { num: 9, name: "Setembro" },
  { num: 10, name: "Outubro" },
  { num: 11, name: "Novembro" },
  { num: 12, name: "Dezembro" },
];

/** Ordem e datas fixas — paridade Todoist (print Julho 2026) */
const PAYMENTS = [
  { title: "Bressanone Unifique", day: 25, time: "14:00" },
  { title: "Bressanone Condomínio", day: 15, time: "14:00" },
  { title: "Bressanone Ultragaz", day: 20, time: "14:00" },
  { title: "Bressanone Celesc", day: 15, time: "14:30" },
  { title: "Fatura Vivo", day: 1, time: "13:00" },
];

const YEAR = 2026;

function pad2(n) {
  return String(n).padStart(2, "0");
}

function dueDate(year, month, day) {
  return `${year}-${pad2(month)}-${pad2(day)}`;
}

async function main() {
  console.log(dryRun ? "DRY RUN — nada será gravado\n" : "Gravando no Supabase…\n");

  const projects = await rest("projects", {
    query: { select: "id,nome,user_id", limit: "50" },
  });
  const project = projects?.find((p) => p.nome?.toLowerCase() === "financeiro");
  if (!project) {
    throw new Error('Projeto "Financeiro" não encontrado. Crie o projeto no app primeiro.');
  }
  console.log(`Projeto: ${project.nome} (${project.id})`);

  const sections = await rest("sections", {
    query: {
      select: "id,name,project_id",
      project_id: `eq.${project.id}`,
      limit: "50",
    },
  });
  const section = sections?.find((s) => s.name?.toLowerCase() === "despesas fixas");
  if (!section) {
    throw new Error('Seção "Despesas Fixas" não encontrada no projeto Financeiro.');
  }
  console.log(`Seção: ${section.name} (${section.id})\n`);

  const existingTasks = await rest("tasks", {
    query: {
      select: "id,titulo,subtasks(id,titulo,data_vencimento,descricao,hora,ordem)",
      project_id: `eq.${project.id}`,
      section_id: `eq.${section.id}`,
    },
  });

  let createdParents = 0;
  let createdSubtasks = 0;
  let skipped = 0;

  for (const month of MONTHS) {
    const parentTitle = `${month.name} ${YEAR}`;
    let parent = existingTasks.find((t) => t.titulo === parentTitle);

    if (parent) {
      console.log(`↷ Já existe: ${parentTitle}`);
    } else {
      const payload = {
        titulo: parentTitle,
        project_id: project.id,
        section_id: section.id,
        concluida: false,
        data_vencimento: null,
        hora: null,
        ...(project.user_id ? { user_id: project.user_id } : {}),
      };
      if (dryRun) {
        console.log(`+ Criaria tarefa pai: ${parentTitle}`);
        parent = { id: "dry-run", titulo: parentTitle, subtasks: [] };
      } else {
        const inserted = await rest("tasks", { method: "POST", body: payload });
        parent = inserted[0];
        existingTasks.push(parent);
        console.log(`✓ Tarefa pai: ${parentTitle}`);
      }
      createdParents++;
    }

    const existingSubs = parent.subtasks ?? [];
    for (let i = 0; i < PAYMENTS.length; i++) {
      const p = PAYMENTS[i];
      const date = dueDate(YEAR, month.num, p.day);
      const already = existingSubs.find(
        (s) => s.titulo === p.title && s.data_vencimento?.startsWith(date),
      );
      if (already) {
        const needsHora = !already.hora && /^\d{1,2}:\d{2}$/.test(String(already.descricao ?? "").trim());
        if (needsHora && !dryRun) {
          await rest("subtasks", {
            method: "PATCH",
            query: { id: `eq.${already.id}` },
            body: { hora: p.time, descricao: null },
          });
          console.log(`  ↻ corrigida: ${p.title} (${date}) — hora ${p.time}`);
        } else {
          console.log(`  ↷ subtarefa já existe: ${p.title} (${date})`);
        }
        skipped++;
        continue;
      }

      const subPayload = {
        task_id: parent.id,
        titulo: p.title,
        data_vencimento: date,
        hora: p.time,
        concluida: false,
        ordem: i,
      };

      if (dryRun) {
        console.log(`  + subtarefa: ${p.title} — ${date} ${p.time}`);
      } else {
        await rest("subtasks", { method: "POST", body: subPayload });
        console.log(`  ✓ ${p.title} — ${date} ${p.time}`);
      }
      createdSubtasks++;
    }
    console.log("");
  }

  console.log("—".repeat(40));
  console.log(
    dryRun
      ? `Simulação: ${createdParents} pais, ${createdSubtasks} subtarefas (${skipped} já existiam)`
      : `Pronto: ${createdParents} tarefas pai, ${createdSubtasks} subtarefas (${skipped} puladas)`,
  );
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
