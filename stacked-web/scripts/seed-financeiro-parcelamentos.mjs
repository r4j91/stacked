#!/usr/bin/env node
/**
 * Cria tarefas de parcelamento no projeto FINANCEIRO / seção PARCELAMENTOS.
 *
 * 1. IPTU Bressanone — 11× dia 10 (1ª em 10/02/2026), 12:00
 * 2. Santander - Cartões — 72× dia 20 (1ª em 20/04/2026), R$ 385,31, 12:00
 * 3. Santander - CC — 72× dia 22 (1ª em 22/04/2026), R$ 322,43, 12:00
 *
 * Etiquetas: Pendente Pgto em todas; mês (Jul–Dez) só nas parcelas futuras de 2026.
 *
 * Uso: node scripts/seed-financeiro-parcelamentos.mjs
 *      node scripts/seed-financeiro-parcelamentos.mjs --dry-run
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

const PENDENTE_PGTO_LABEL = "090f0e68-c5a7-4bec-89e1-aaebac1028fe";

const MONTH_LABEL_BY_NUM = {
  7: "e3003b66-6ccf-443b-aea9-5104ae426507", // Julho
  8: "476b5d2d-b586-4d8f-b929-9967656bc356", // Agosto
  9: "2f8ef297-f153-4b37-948e-b900ac329f1f", // Setembro
  10: "de1c1c0e-5868-4487-bb06-730397885fb8", // Outubro
  11: "af7e8260-266c-4d70-b0f4-2edf35b2bb51", // Novembro
  12: "453164f6-9c83-4b51-a050-c56efb19f041", // Dezembro
};

const TIME = "12:00";
const LABEL_YEAR = 2026;
const LABEL_MONTH_FROM = 7;
const LABEL_MONTH_TO = 12;

const PLANS = [
  {
    title: "IPTU Bressanone",
    count: 11,
    startYear: 2026,
    startMonth: 2,
    day: 10,
    valor: null,
  },
  {
    title: "Santander - Cartões",
    count: 72,
    startYear: 2026,
    startMonth: 4,
    day: 20,
    valor: 385.31,
  },
  {
    title: "Santander - CC",
    count: 72,
    startYear: 2026,
    startMonth: 4,
    day: 22,
    valor: 322.43,
  },
];

function pad2(n) {
  return String(n).padStart(2, "0");
}

function dueDate(year, month, day) {
  return `${year}-${pad2(month)}-${pad2(day)}`;
}

function addMonths(year, month, day, offset) {
  const total = year * 12 + (month - 1) + offset;
  const y = Math.floor(total / 12);
  const m = (total % 12) + 1;
  const lastDay = new Date(y, m, 0).getDate();
  const d = Math.min(day, lastDay);
  return { year: y, month: m, day: d, iso: dueDate(y, m, d) };
}

function labelIdsFor(year, month) {
  const ids = [PENDENTE_PGTO_LABEL];
  if (
    year === LABEL_YEAR &&
    month >= LABEL_MONTH_FROM &&
    month <= LABEL_MONTH_TO &&
    MONTH_LABEL_BY_NUM[month]
  ) {
    ids.push(MONTH_LABEL_BY_NUM[month]);
  }
  return ids;
}

function buildInstallments(plan) {
  return Array.from({ length: plan.count }, (_, i) => {
    const slot = addMonths(plan.startYear, plan.startMonth, plan.day, i);
    const n = i + 1;
    return {
      ordem: i,
      titulo: `${plan.title} / Parcela ${n}`,
      data_vencimento: slot.iso,
      hora: TIME,
      valor: plan.valor,
      label_ids: labelIdsFor(slot.year, slot.month),
      concluida: false,
    };
  });
}

async function upsertParent(project, section, title, existingTasks) {
  let parent = existingTasks.find((t) => t.titulo === title);
  if (parent) {
    console.log(`↷ Já existe: ${title}`);
    return { parent, created: false };
  }

  const payload = {
    titulo: title,
    project_id: project.id,
    section_id: section.id,
    concluida: false,
    data_vencimento: null,
    hora: null,
    ...(project.user_id ? { user_id: project.user_id } : {}),
  };

  if (dryRun) {
    console.log(`+ Criaria tarefa pai: ${title}`);
    return { parent: { id: `dry-${title}`, titulo: title, subtasks: [] }, created: true };
  }

  const inserted = await rest("tasks", { method: "POST", body: payload });
  parent = inserted[0];
  existingTasks.push(parent);
  console.log(`✓ Tarefa pai: ${title}`);
  return { parent, created: true };
}

async function upsertSubtasks(parent, installments) {
  const existingSubs = parent.subtasks ?? [];
  let created = 0;
  let updated = 0;
  let skipped = 0;

  for (const inst of installments) {
    const already = existingSubs.find((s) => s.titulo === inst.titulo);
    if (already) {
      const wrongDate = !already.data_vencimento?.startsWith(inst.data_vencimento);
      const wrongHora = already.hora !== inst.hora;
      const wrongValor = inst.valor != null && already.valor !== inst.valor;
      const sameLabels =
        JSON.stringify([...(already.label_ids ?? [])].sort()) ===
        JSON.stringify([...inst.label_ids].sort());
      if ((wrongDate || wrongHora || wrongValor || !sameLabels) && !dryRun) {
        await rest("subtasks", {
          method: "PATCH",
          query: { id: `eq.${already.id}` },
          body: {
            data_vencimento: inst.data_vencimento,
            hora: inst.hora,
            valor: inst.valor,
            label_ids: inst.label_ids,
            ordem: inst.ordem,
          },
        });
        updated++;
      } else if (wrongDate || wrongHora || wrongValor || !sameLabels) {
        updated++;
      } else {
        skipped++;
      }
      continue;
    }

    const payload = { task_id: parent.id, ...inst };
    if (dryRun) {
      created++;
      continue;
    }
    await rest("subtasks", { method: "POST", body: payload });
    created++;
  }

  return { created, updated, skipped };
}

async function main() {
  console.log(dryRun ? "DRY RUN — nada será gravado\n" : "Gravando no Supabase…\n");

  const projects = await rest("projects", {
    query: { select: "id,nome,user_id", limit: "50" },
  });
  const project = projects?.find((p) => p.nome?.toLowerCase() === "financeiro");
  if (!project) throw new Error('Projeto "Financeiro" não encontrado.');

  const sections = await rest("sections", {
    query: { select: "id,name,project_id", project_id: `eq.${project.id}`, limit: "50" },
  });
  const section = sections?.find((s) => s.name?.toLowerCase() === "parcelamentos");
  if (!section) throw new Error('Seção "Parcelamentos" não encontrada.');

  console.log(`Projeto: ${project.nome}`);
  console.log(`Seção: ${section.name}\n`);

  const existingTasks = await rest("tasks", {
    query: {
      select: "id,titulo,subtasks(id,titulo,data_vencimento,hora,valor,label_ids,ordem,concluida)",
      project_id: `eq.${project.id}`,
      section_id: `eq.${section.id}`,
    },
  });

  let parentsCreated = 0;
  let subsCreated = 0;
  let subsUpdated = 0;
  let subsSkipped = 0;

  for (const plan of PLANS) {
    const installments = buildInstallments(plan);
    const { parent, created } = await upsertParent(project, section, plan.title, existingTasks);
    if (created) parentsCreated++;

    const stats = await upsertSubtasks(parent, installments);
    subsCreated += stats.created;
    subsUpdated += stats.updated;
    subsSkipped += stats.skipped;

    const first = installments[0];
    const last = installments[installments.length - 1];
    console.log(
      `  ${plan.count} parcelas: ${first.data_vencimento} → ${last.data_vencimento} (${TIME})` +
        (plan.valor != null ? ` · R$ ${plan.valor.toFixed(2)}` : ""),
    );
    if (dryRun) {
      console.log(`  + criaria ${stats.created} subtarefas (${stats.updated} atualizariam, ${stats.skipped} ok)`);
    } else {
      console.log(`  ✓ ${stats.created} criadas, ${stats.updated} atualizadas, ${stats.skipped} já ok`);
    }
    console.log("");
  }

  console.log("—".repeat(40));
  console.log(
    dryRun
      ? `Simulação: ${parentsCreated} pais, ${subsCreated} subtarefas novas (${subsUpdated} atualizações, ${subsSkipped} ok)`
      : `Pronto: ${parentsCreated} pais, ${subsCreated} subtarefas criadas (${subsUpdated} atualizadas, ${subsSkipped} ok)`,
  );
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
