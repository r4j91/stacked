#!/usr/bin/env node
/**
 * Cria tarefas pai (meses 07–12) + subtarefas do apto praia
 * no projeto FINANCEIRO / seção APARTAMENTO PRAIA.
 *
 * Subtarefas: Praia Condomínio, Praia Energia — sem data/hora.
 * Etiquetas: Pendente Pgto + mês de referência (Julho…Dezembro)
 *
 * Uso: node scripts/seed-financeiro-apartamento-praia.mjs
 *      node scripts/seed-financeiro-apartamento-praia.mjs --dry-run
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

const ITEMS = [
  { title: "Praia Condomínio", ordem: 0 },
  { title: "Praia Energia", ordem: 1 },
];

async function main() {
  console.log(dryRun ? "DRY RUN — nada será gravado\n" : "Gravando no Supabase…\n");

  const projects = await rest("projects", {
    query: { select: "id,nome,user_id", limit: "50" },
  });
  const project = projects?.find((p) => p.nome?.toLowerCase() === "financeiro");
  if (!project) {
    throw new Error('Projeto "Financeiro" não encontrado.');
  }
  console.log(`Projeto: ${project.nome} (${project.id})`);

  const sections = await rest("sections", {
    query: {
      select: "id,name,project_id",
      project_id: `eq.${project.id}`,
      limit: "50",
    },
  });
  const section = sections?.find((s) => s.name?.toLowerCase() === "apartamento praia");
  if (!section) {
    throw new Error('Seção "Apartamento Praia" não encontrada.');
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
    const labelIds = [PENDENTE_PGTO_LABEL, month.labelId];

    for (const item of ITEMS) {
      const already = existingSubs.find((s) => s.titulo === item.title);
      if (already) {
        const hasDate = already.data_vencimento != null;
        const hasHora = already.hora != null;
        const sameLabels =
          JSON.stringify([...(already.label_ids ?? [])].sort()) ===
          JSON.stringify([...labelIds].sort());
        if ((hasDate || hasHora || !sameLabels) && !dryRun) {
          await rest("subtasks", {
            method: "PATCH",
            query: { id: `eq.${already.id}` },
            body: {
              data_vencimento: null,
              hora: null,
              label_ids: labelIds,
              ordem: item.ordem,
            },
          });
          console.log(`  ↻ atualizada: ${item.title} [Pendente Pgto, ${month.name}]`);
        } else if (hasDate || hasHora || !sameLabels) {
          console.log(`  ↻ atualizaria: ${item.title}`);
        } else {
          console.log(`  ↷ subtarefa já existe: ${item.title}`);
        }
        skipped++;
        continue;
      }

      const subPayload = {
        task_id: parent.id,
        titulo: item.title,
        data_vencimento: null,
        hora: null,
        concluida: false,
        ordem: item.ordem,
        label_ids: labelIds,
      };

      if (dryRun) {
        console.log(`  + subtarefa: ${item.title} [Pendente Pgto, ${month.name}]`);
      } else {
        await rest("subtasks", { method: "POST", body: subPayload });
        console.log(`  ✓ ${item.title} [Pendente Pgto, ${month.name}]`);
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
