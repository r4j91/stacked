# Supabase — Stacked

Projeto: `gbpoenvogrcqhcqfjldd` · compartilhado entre **stacked-web** e **stacked-ios**.

## Tabelas

| Tabela | Descrição |
|--------|-----------|
| `projects` | Projetos do usuário |
| `sections` | Seções dentro de um projeto |
| `tasks` | Tarefas (`data_vencimento` date, `hora` time) |
| `subtasks` | Subtarefas (`data_vencimento` timestamptz, `hora` text) |
| `labels` | Etiquetas |
| `task_labels` | Vínculo tarefa ↔ etiqueta |
| `task_comments` | Comentários |
| `saved_filters` | Filtros salvos (JSON) |
| `google_calendar_connections` | OAuth Google (só service role) |

Storage: bucket `avatars` (público leitura, upload por usuário).

## Migrations

Arquivos em `supabase/migrations/` — ordem pelo prefixo de data:

```
20260704120000_google_calendar_connections.sql
20260705200000_saved_filters.sql
20260708200000_subtasks_hora.sql
20260708220000_supabase_hygiene.sql
```

> O schema base (tasks, projects, etc.) foi criado manualmente no SQL Editor antes do versionamento. Não recrie essas tabelas — use apenas migrations incrementais.

### Aplicar uma migration

```bash
cd stacked-web
node scripts/apply-sql-migration.mjs supabase/migrations/NOME.sql
```

Requer `SUPABASE_ACCESS_TOKEN` ou `SUPABASE_DB_PASSWORD` em `.env.local`.

Scripts específicos:

- `node scripts/apply-subtask-hora.mjs` — coluna `hora` + backfill
- `node scripts/seed-financeiro-despesas-fixas.mjs` — seed despesas fixas

## RLS (Row Level Security)

| Tabela | RLS | Escopo |
|--------|-----|--------|
| tasks, projects, labels | ✅ | `auth.uid() = user_id` |
| subtasks, task_labels | ✅ | via ownership da tarefa pai |
| sections | ✅ | via ownership do projeto |
| task_comments | ✅ | `auth.uid() = user_id` |
| saved_filters | ✅ | `auth.uid() = user_id` |
| google_calendar_connections | ✅ | sem policies — só service role |

## Tipos inconsistentes (legado — não alterar sem migration)

- `tasks.hora` → `time` · `subtasks.hora` → `text` (HH:MM)
- `tasks.data_vencimento` → `date` · `subtasks.data_vencimento` → `timestamptz`

Os apps normalizam isso no mapper (`TaskMapper` / `map-task.ts`).

## Índices principais

- `idx_tasks_user_pending_due` — Hoje / Em breve
- `idx_subtasks_task_ordem` — lista de subtarefas
- `idx_subtasks_due_pending` — notificações de subtarefas
- `saved_filters_user_sort_idx` — ordem dos filtros
