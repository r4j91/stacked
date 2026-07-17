#!/usr/bin/env node
/**
 * Cria seção "Rotina do dia" no projeto Rodrigo + etiquetas + tarefas recorrentes + filtro.
 *
 * Uso: node scripts/seed-rodrigo-rotina-do-dia.mjs
 *      node scripts/seed-rodrigo-rotina-do-dia.mjs --dry-run
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

const WEEKDAY_TO_JS = { dom: 0, seg: 1, ter: 2, qua: 3, qui: 4, sex: 5, sab: 6 };

function pad2(n) {
  return String(n).padStart(2, "0");
}

function toDateStr(d) {
  return `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`;
}

/** Próximo dia a partir de amanhã (não inclui hoje) que casa com weekdays PT. null = todo dia. */
function nextDueDate(weekdays) {
  const base = new Date();
  base.setHours(0, 0, 0, 0);
  base.setDate(base.getDate() + 1); // começa amanhã de manhã
  if (!weekdays?.length) return toDateStr(base);
  const wanted = new Set(weekdays.map((d) => WEEKDAY_TO_JS[d]));
  for (let i = 0; i < 8; i++) {
    const d = new Date(base);
    d.setDate(base.getDate() + i);
    if (wanted.has(d.getDay())) return toDateStr(d);
  }
  throw new Error(`Sem dia válido para ${weekdays.join(",")}`);
}

function recurrenceJson(weekdays) {
  if (!weekdays?.length) return JSON.stringify({ tipo: "diario" });
  return JSON.stringify({ tipo: "personalizado", dias: weekdays });
}

const DAILY = null;
const WEEK_OFF_MON_WORK = ["seg", "ter", "qua", "qui", "dom"]; // folga sem turno 10h
const FRI_SAT = ["sex", "sab"];
const WORK_EVENING = ["ter", "qua", "qui", "sex", "sab", "dom"]; // sem segunda

const TASKS = [
  { title: "Banho", time: "08:00", days: DAILY, labels: ["Rotina"], ordem: 0 },
  { title: "Café", time: "09:00", days: DAILY, labels: ["Rotina"], ordem: 1 },
  { title: "Aurora", time: "09:15", days: DAILY, labels: ["Rotina"], ordem: 2 },
  { title: "Casa", time: "10:00", days: WEEK_OFF_MON_WORK, labels: ["Rotina"], ordem: 3 },
  {
    title: "Trabalhar (manhã)",
    time: "10:00",
    days: FRI_SAT,
    labels: ["Rotina", "Trabalho"],
    ordem: 4,
  },
  { title: "Almoço", time: "12:00", days: WEEK_OFF_MON_WORK, labels: ["Rotina"], ordem: 5 },
  { title: "Academia Cinara", time: "13:00", days: WEEK_OFF_MON_WORK, labels: ["Rotina"], ordem: 6 },
  { title: "Estudar", time: "14:00", days: WEEK_OFF_MON_WORK, labels: ["Rotina"], ordem: 7 },
  { title: "Almoço", time: "14:30", days: FRI_SAT, labels: ["Rotina"], ordem: 8 },
  { title: "Academia Cinara", time: "15:00", days: FRI_SAT, labels: ["Rotina"], ordem: 9 },
  { title: "Café à tarde", time: "16:00", days: WEEK_OFF_MON_WORK, labels: ["Rotina"], ordem: 10 },
  { title: "Café à tarde", time: "16:15", days: FRI_SAT, labels: ["Rotina"], ordem: 11 },
  { title: "Ajeitar banho Catarina", time: "16:30", days: DAILY, labels: ["Rotina"], ordem: 12 },
  {
    title: "Trabalhar",
    time: "17:00",
    days: WORK_EVENING,
    labels: ["Rotina", "Trabalho"],
    ordem: 13,
  },
];

const LABEL_DEFS = [
  { nome: "Rotina", cor: "#63C7D8" },
  { nome: "Trabalho", cor: "#6F8FB8" },
];

async function ensureLabel(existing, def, userId, nextSort) {
  const found = existing.find((l) => l.nome.toLowerCase() === def.nome.toLowerCase());
  if (found) {
    console.log(`↷ Etiqueta já existe: ${found.nome}`);
    return found;
  }
  if (dryRun) {
    console.log(`+ Criaria etiqueta: ${def.nome} (${def.cor})`);
    return { id: `dry-${def.nome}`, nome: def.nome, cor: def.cor };
  }
  const inserted = await rest("labels", {
    method: "POST",
    body: { nome: def.nome, cor: def.cor, user_id: userId, sort_order: nextSort },
  });
  const row = inserted[0];
  console.log(`✓ Etiqueta: ${row.nome}`);
  return row;
}

async function main() {
  console.log(dryRun ? "DRY RUN — nada será gravado\n" : "Gravando no Supabase…\n");

  const projects = await rest("projects", {
    query: { select: "id,nome,user_id", limit: "50" },
  });
  const project = projects?.find((p) => p.nome?.toLowerCase() === "rodrigo");
  if (!project) throw new Error('Projeto "Rodrigo" não encontrado.');
  const userId = project.user_id;
  if (!userId) throw new Error("Projeto Rodrigo sem user_id.");
  console.log(`Projeto: ${project.nome} (${project.id})`);

  // Labels
  const existingLabels = (await rest("labels", {
    query: { select: "id,nome,cor,sort_order", user_id: `eq.${userId}`, order: "sort_order" },
  })) ?? [];
  let sortBase =
    existingLabels.reduce((m, l) => Math.max(m, typeof l.sort_order === "number" ? l.sort_order : -1), -1) +
    1;
  const labelByName = {};
  for (const def of LABEL_DEFS) {
    const row = await ensureLabel(existingLabels, def, userId, sortBase++);
    labelByName[def.nome] = row;
    if (!existingLabels.find((l) => l.id === row.id)) existingLabels.push(row);
  }

  // Section
  const sections =
    (await rest("sections", {
      query: {
        select: "id,name,order,project_id",
        project_id: `eq.${project.id}`,
        limit: "50",
      },
    })) ?? [];
  let section = sections.find((s) => s.name?.toLowerCase() === "rotina do dia");
  if (section) {
    console.log(`↷ Seção já existe: ${section.name}`);
  } else if (dryRun) {
    console.log(`+ Criaria seção: Rotina do dia`);
    section = { id: "dry-section", name: "Rotina do dia" };
  } else {
    const maxOrder = sections.reduce((m, s) => Math.max(m, Number(s.order) || 0), -1);
    const inserted = await rest("sections", {
      method: "POST",
      body: { project_id: project.id, name: "Rotina do dia", order: maxOrder + 1 },
    });
    section = inserted[0];
    console.log(`✓ Seção: ${section.name}`);
  }

  // Existing tasks in section (idempotent by title+time)
  const existingTasks =
    section.id.startsWith("dry-")
      ? []
      : ((await rest("tasks", {
          query: {
            select: "id,titulo,hora,data_vencimento,recorrencia",
            project_id: `eq.${project.id}`,
            section_id: `eq.${section.id}`,
            concluida: "eq.false",
          },
        })) ?? []);

  let created = 0;
  let skipped = 0;

  for (const t of TASKS) {
    const already = existingTasks.find(
      (e) => e.titulo === t.title && (e.hora === t.time || (!e.hora && !t.time)),
    );
    if (already) {
      console.log(`↷ Já existe: ${t.title} ${t.time}`);
      skipped++;
      continue;
    }

    const due = nextDueDate(t.days);
    const recorrencia = recurrenceJson(t.days);
    const labelIds = t.labels.map((n) => labelByName[n].id);
    const payload = {
      titulo: t.title,
      project_id: project.id,
      section_id: section.id,
      data_vencimento: due,
      hora: t.time,
      recorrencia,
      prioridade: null,
      concluida: false,
      user_id: userId,
      ordem: t.ordem,
    };

    if (dryRun) {
      console.log(
        `+ ${t.title} ${t.time} · due ${due} · ${t.days ? t.days.join(",") : "todo dia"} · [${t.labels.join(", ")}]`,
      );
      created++;
      continue;
    }

    const inserted = await rest("tasks", { method: "POST", body: payload });
    const task = inserted[0];
    if (labelIds.length) {
      await rest("task_labels", {
        method: "POST",
        body: labelIds.map((label_id) => ({ task_id: task.id, label_id })),
      });
    }
    console.log(
      `✓ ${t.title} ${t.time} · ${due} · ${t.days ? t.days.join(",") : "todo dia"}`,
    );
    created++;
  }

  // Saved filter
  const rotinaId = labelByName["Rotina"].id;
  const existingFilters =
    (await rest("saved_filters", {
      query: { select: "id,name,criteria", user_id: `eq.${userId}` },
    })) ?? [];
  const filterName = "Rotina de hoje";
  const hasFilter = existingFilters.find((f) => f.name?.toLowerCase() === filterName.toLowerCase());
  if (hasFilter) {
    console.log(`↷ Filtro já existe: ${filterName}`);
  } else if (dryRun) {
    console.log(`+ Criaria filtro: ${filterName}`);
  } else {
    await rest("saved_filters", {
      method: "POST",
      body: {
        user_id: userId,
        name: filterName,
        color: "#63C7D8",
        criteria: {
          labelIds: [rotinaId],
          priorities: [],
          projectId: null,
          dateScope: "today",
        },
      },
    });
    console.log(`✓ Filtro: ${filterName}`);
  }

  console.log("—".repeat(40));
  console.log(
    dryRun
      ? `Simulação: ${created} tarefas (${skipped} já existiam)`
      : `Pronto: ${created} tarefas criadas (${skipped} puladas)`,
  );
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
