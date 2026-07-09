#!/usr/bin/env node
/**
 * Cria tarefas pai (meses 07–12) + subtarefas de cartões
 * no projeto FINANCEIRO / seção CARTÕES.
 *
 * Datas (paridade Todoist):
 *   Cartão Itaú      — dia 1 do mês, 09:00
 *   Cartão Santander — dia 14 do mês, 09:00
 *   Cartão C6        — dia 15 do mês, 09:00
 *
 * Etiquetas: Pendente Pgto + mês de referência (Julho…Dezembro)
 *
 * Uso: node scripts/seed-financeiro-cartoes.mjs
 *      node scripts/seed-financeiro-cartoes.mjs --dry-run
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
  { num: 7, name: "Julho", labelId: "e3003b66-6ccf-443b-aea9-5104ae426507" },
  { num: 8, name: "Agosto", labelId: "476b5d2d-b586-4d8f-b929-9967656bc356" },
  { num: 9, name: "Setembro", labelId: "2f8ef297-f153-4b37-948e-b900ac329f1f" },
  { num: 10, name: "Outubro", labelId: "de1c1c0e-5868-4487-bb06-730397885fb8" },
  { num: 11, name: "Novembro", labelId: "af7e8260-266c-4d70-b0f4-2edf35b2bb51" },
  { num: 12, name: "Dezembro", labelId: "453164f6-9c83-4b51-a050-c56efb19f041" },
];

const PENDENTE_PGTO_LABEL = "090f0e68-c5a7-4bec-89e1-aaebac1028fe";
const YEAR = 2026;

function pad2(n) {
  return String(n).padStart(2, "0");
}

function dueDate(year, month, day) {
  return `${year}-${pad2(month)}-${pad2(day)}`;
}

const CARD_TIME = "09:00";

function cardsForMonth() {
  return [
    { title: "Cartão C6", day: 15, ordem: 0 },
    { title: "Cartão Santander", day: 14, ordem: 1 },
    { title: "Cartão Itaú", day: 1, ordem: 2 },
  ];
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
  const section = sections?.find((s) => s.name?.toLowerCase() === "cartões");
  if (!section) {
    throw new Error('Seção "Cartões" não encontrada no projeto Financeiro.');
  }
  console.log(`Seção: ${section.name} (${section.id})\n`);

  const existingTasks = await rest("tasks", {
    query: {
      select: "id,titulo,subtasks(id,titulo,data_vencimento,hora,label_ids,ordem)",
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
    const cards = cardsForMonth();
    const labelIds = [PENDENTE_PGTO_LABEL, month.labelId];

    for (const card of cards) {
      const date = dueDate(YEAR, month.num, card.day);
      const already = existingSubs.find((s) => s.titulo === card.title);
      if (already) {
        const wrongDate = !already.data_vencimento?.startsWith(date);
        const wrongHora = already.hora !== CARD_TIME;
        const sameLabels =
          JSON.stringify([...(already.label_ids ?? [])].sort()) ===
          JSON.stringify([...labelIds].sort());
        if ((wrongDate || wrongHora || !sameLabels) && !dryRun) {
          await rest("subtasks", {
            method: "PATCH",
            query: { id: `eq.${already.id}` },
            body: {
              data_vencimento: date,
              hora: CARD_TIME,
              label_ids: labelIds,
              ordem: card.ordem,
            },
          });
          console.log(`  ↻ atualizada: ${card.title} — ${date} ${CARD_TIME}`);
        } else if (wrongDate || wrongHora || !sameLabels) {
          console.log(`  ↻ atualizaria: ${card.title} — ${date} ${CARD_TIME}`);
        } else {
          console.log(`  ↷ subtarefa já existe: ${card.title} (${date} ${CARD_TIME})`);
        }
        skipped++;
        continue;
      }

      const subPayload = {
        task_id: parent.id,
        titulo: card.title,
        data_vencimento: date,
        hora: CARD_TIME,
        concluida: false,
        ordem: card.ordem,
        label_ids: labelIds,
      };

      if (dryRun) {
        console.log(`  + subtarefa: ${card.title} — ${date} ${CARD_TIME} [Pendente Pgto, ${month.name}]`);
      } else {
        await rest("subtasks", { method: "POST", body: subPayload });
        console.log(`  ✓ ${card.title} — ${date} ${CARD_TIME} [Pendente Pgto, ${month.name}]`);
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
