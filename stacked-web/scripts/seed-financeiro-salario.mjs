#!/usr/bin/env node
/**
 * Cria a seção SALÁRIO no projeto FINANCEIRO, com tarefas pai
 * Setembro–Dezembro 2026 e uma subtarefa de R$ 1.700,00 em cada
 * segunda-feira (entrada no fluxo, vinculada à Conta C6).
 *
 * Sem hora: o fluxo de caixa agrupa por data.
 *
 * Uso: node scripts/seed-financeiro-salario.mjs
 *      node scripts/seed-financeiro-salario.mjs --dry-run
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

const YEAR = 2026;
const VALOR = 1700;
const SUBTASK_TITLE = "Salário";
const MONTHS = [
  { num: 9, name: "Setembro" },
  { num: 10, name: "Outubro" },
  { num: 11, name: "Novembro" },
  { num: 12, name: "Dezembro" },
];

function pad2(n) {
  return String(n).padStart(2, "0");
}

function dueDate(year, month, day) {
  return `${year}-${pad2(month)}-${pad2(day)}`;
}

function mondaysInMonth(year, month) {
  const last = new Date(Date.UTC(year, month, 0)).getUTCDate();
  const days = [];
  for (let day = 1; day <= last; day++) {
    const dt = new Date(Date.UTC(year, month - 1, day));
    if (dt.getUTCDay() === 1) days.push(day);
  }
  return days;
}

function normalize(name) {
  return (name ?? "")
    .toLowerCase()
    .normalize("NFD")
    .replace(/\p{M}/gu, "")
    .trim();
}

async function main() {
  console.log(dryRun ? "DRY RUN — nada será gravado\n" : "Gravando no Supabase…\n");

  const projects = await rest("projects", {
    query: { select: "id,nome,user_id", limit: "50" },
  });
  const project = projects?.find((p) => normalize(p.nome) === "financeiro");
  if (!project) {
    throw new Error('Projeto "Financeiro" não encontrado.');
  }
  console.log(`Projeto: ${project.nome} (${project.id})`);

  let sections = await rest("sections", {
    query: {
      select: "id,name,project_id,order",
      project_id: `eq.${project.id}`,
      limit: "50",
    },
  });
  let section = sections?.find((s) => normalize(s.name) === "salario");
  if (!section) {
    if (dryRun) {
      console.log('+ Criaria seção: Salário');
      section = { id: "dry-run-section", name: "Salário" };
    } else {
      const inserted = await rest("sections", {
        method: "POST",
        body: { project_id: project.id, name: "Salário", order: 0 },
      });
      section = inserted[0];
      console.log(`✓ Seção: ${section.name} (${section.id})`);
    }
  } else {
    console.log(`Seção: ${section.name} (${section.id})`);
  }

  const accounts = await rest("money_accounts", {
    query: {
      select: "id,name,kind,user_id",
      user_id: `eq.${project.user_id}`,
      limit: "50",
    },
  });
  const c6 = accounts?.find(
    (a) =>
      a.kind === "checking" &&
      normalize(a.name).includes("c6") &&
      !normalize(a.name).includes("cartao"),
  );
  if (!c6) {
    throw new Error('Conta corrente "Conta C6" não encontrada.');
  }
  console.log(`Conta: ${c6.name} (${c6.id})\n`);

  const existingTasks =
    section.id === "dry-run-section"
      ? []
      : await rest("tasks", {
          query: {
            select:
              "id,titulo,subtasks(id,titulo,data_vencimento,valor,valor_entrada,incluir_fluxo_caixa,hora,ordem)",
            project_id: `eq.${project.id}`,
            section_id: `eq.${section.id}`,
          },
        }) ?? [];

  let createdParents = 0;
  let createdSubtasks = 0;
  let createdLinks = 0;
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
        incluir_fluxo_caixa: true,
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
    const mondays = mondaysInMonth(YEAR, month.num);

    for (let i = 0; i < mondays.length; i++) {
      const date = dueDate(YEAR, month.num, mondays[i]);
      let sub = existingSubs.find(
        (s) => s.titulo === SUBTASK_TITLE && s.data_vencimento?.startsWith(date),
      );

      if (sub) {
        const needsPatch =
          Number(sub.valor) !== VALOR ||
          sub.valor_entrada !== true ||
          sub.incluir_fluxo_caixa === false ||
          Boolean(sub.hora);
        if (needsPatch && !dryRun) {
          await rest("subtasks", {
            method: "PATCH",
            query: { id: `eq.${sub.id}` },
            body: {
              valor: VALOR,
              valor_entrada: true,
              incluir_fluxo_caixa: true,
              hora: null,
              ordem: i,
            },
          });
          console.log(`  ↻ corrigida: ${SUBTASK_TITLE} (${date})`);
        } else {
          console.log(`  ↷ subtarefa já existe: ${SUBTASK_TITLE} (${date})`);
        }
        skipped++;
      } else {
        const subPayload = {
          task_id: parent.id,
          titulo: SUBTASK_TITLE,
          data_vencimento: date,
          hora: null,
          valor: VALOR,
          valor_entrada: true,
          incluir_fluxo_caixa: true,
          concluida: false,
          ordem: i,
        };
        if (dryRun) {
          console.log(`  + subtarefa: ${SUBTASK_TITLE} — ${date} · R$ 1.700,00 · Entrada · C6`);
          sub = { id: `dry-run-${date}` };
        } else {
          const inserted = await rest("subtasks", { method: "POST", body: subPayload });
          sub = inserted[0];
          console.log(`  ✓ ${SUBTASK_TITLE} — ${date} · R$ 1.700,00`);
        }
        createdSubtasks++;
      }

      if (sub?.id && !String(sub.id).startsWith("dry-run")) {
        const existingLink = await rest("money_obligation_links", {
          query: {
            select: "subtask_id,account_id,valor",
            subtask_id: `eq.${sub.id}`,
            limit: "1",
          },
        });
        const link = existingLink?.[0];
        const linkOk = link?.account_id === c6.id && Number(link?.valor) === VALOR;
        if (linkOk) {
          continue;
        }
        const linkPayload = {
          subtask_id: sub.id,
          user_id: project.user_id,
          account_id: c6.id,
          valor: VALOR,
        };
        if (dryRun) {
          console.log(`    + vincularia Conta C6`);
        } else if (link) {
          await rest("money_obligation_links", {
            method: "PATCH",
            query: { subtask_id: `eq.${sub.id}` },
            body: { account_id: c6.id, valor: VALOR },
          });
          console.log(`    ↻ vínculo Conta C6`);
        } else {
          await rest("money_obligation_links", { method: "POST", body: linkPayload });
          console.log(`    ✓ vinculada à Conta C6`);
        }
        createdLinks++;
      } else if (dryRun) {
        console.log(`    + vincularia Conta C6`);
        createdLinks++;
      }
    }
    console.log("");
  }

  console.log("—".repeat(40));
  console.log(
    dryRun
      ? `Simulação: ${createdParents} pais, ${createdSubtasks} subtarefas, ${createdLinks} vínculos (${skipped} já existiam)`
      : `Pronto: ${createdParents} tarefas pai, ${createdSubtasks} subtarefas, ${createdLinks} vínculos (${skipped} puladas)`,
  );
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
