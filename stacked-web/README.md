# Stacked Web

App web do Stacked — Next.js + Supabase.

## Fases

| Fase | Status | Conteúdo |
|------|--------|----------|
| 0 | ✅ | Mock HTML (`mock/workbench.html`) |
| 1 | ✅ | Scaffold Next.js, shell, rotas, tema Slate |
| 2 | ✅ | Queries Supabase (Hoje/Inbox/Em breve), auth, toggle done, badges |
| 3 | ✅ | Inspector com autosave (título + notas) |
| 4 | ✅ | Projetos + seções (sidebar, `/projects/[id]`, CRUD seções) |
| 5 | ✅ | Em breve calendário, filtros, command palette ⌘K |
| 6 | ✅ | Deploy Netlify (`netlify.toml`, Node 20, docs) |
| 7 | ✅ | Polish desktop (P0–P2 Impeccable): inspector coluna, tokens, teclado, a11y |
| 8 | ✅ | Paridade restante: empty states, produtividade skeleton, menu seção ancorado |
| 9 | ✅ | Drag reorder tarefas/seções (projetos, desktop) |

## Rodar localmente

```bash
cd stacked-web
npm install
cp .env.local.example .env.local
```

Edite `.env.local` — use a mesma URL e `publishableKey` do `lib/main.dart`:

```
NEXT_PUBLIC_SUPABASE_URL=https://gbpoenvogrcqhcqfjldd.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
```

```bash
npm run dev
```

Abra [http://localhost:3000](http://localhost:3000) → login → `/today`.

Sem `.env.local` válido, o app usa **dados mock** com aviso na tela.

## Auth

- `/login` — e-mail + senha (mesmas credenciais do app Flutter)
- Middleware protege rotas do workbench
- Sessão via cookies (`@supabase/ssr`)

## Rotas

| Rota | Query |
|------|-------|
| `/today` | `fetchTodayTasks` + `fetchCompletedTodayTasks` |
| `/inbox` | `fetchInboxTasks` + concluídas inbox |
| `/upcoming` | tarefas com data (calendário + agenda) |
| `/filters` | dashboard de filtros + drill-down |
| `/done` | concluídas hoje |
| `/projects/[id]` | tarefas do projeto + seções |

## Arquitetura Fase 2–3

```
lib/repositories/task-repository.ts     ← paridade task_repository.dart
lib/repositories/task-persistence.ts  ← paridade task_detail_persistence.dart
lib/supabase/map-task.ts              ← Task.fromJson
components/shell/workbench-context.tsx ← fetch + optimistic updates + autosave
components/tasks/autosave-textarea.tsx ← debounce 600ms + flush on blur
```

## Mock Fase 0

Referência visual: [`mock/workbench.html`](mock/workbench.html)

## Deploy (Netlify)

O app usa **Next.js 15 com SSR** (middleware + Supabase cookies). Netlify detecta Next.js automaticamente via [OpenNext adapter](https://docs.netlify.com/build/frameworks/framework-setup-guides/nextjs/overview/) — não é export estático.

### Site em produção

Repo linkado ao site **get-stacked-app** → [https://get-stacked-app.netlify.app](https://get-stacked-app.netlify.app)

O slug `stacked` e `stacked-app` já estão ocupados globalmente na Netlify; usamos `get-stacked-app`.

```bash
cd stacked-web
netlify deploy --build          # draft / preview
netlify deploy --build --prod   # produção
```

### 1. Conectar o repositório (novo site)

1. [Netlify](https://app.netlify.com) → **Add new site** → **Import from Git**
2. Selecione este repositório
3. **Base directory:** `stacked-web`
4. **Build command:** `npm run build` (já em `netlify.toml`)
5. **Publish directory:** deixe em branco (Netlify define via runtime Next.js)

### 2. Variáveis de ambiente

Em **Site configuration → Environment variables**, adicione:

| Variável | Valor |
|----------|--------|
| `NEXT_PUBLIC_SUPABASE_URL` | URL do projeto Supabase |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Anon / publishable key (`lib/main.dart`) |

Use os mesmos valores do `.env.local` local.

### 3. Supabase Auth (obrigatório para login em produção)

No painel Supabase → **Authentication → URL Configuration**:

- **Site URL:** `https://get-stacked-app.netlify.app`
- **Redirect URLs:** adicione
  - `https://get-stacked-app.netlify.app/auth/callback`
  - `https://*.netlify.app/auth/callback` (draft deploys)
  - `http://localhost:3000/auth/callback` (dev)

### 4. Deploy manual (CLI)

```bash
cd stacked-web
npm install
npx netlify login
npx netlify init          # linka ao site (primeira vez)
npx netlify deploy --build   # preview
npx netlify deploy --build --prod   # produção
```

### 5. Monorepo

O `netlify.toml` inclui `ignore` para só rebuildar quando arquivos em `stacked-web/` mudam — commits só no Flutter não disparam deploy web.

### Checklist pós-deploy

- [ ] Login com e-mail/senha funciona
- [ ] `/today` carrega tarefas reais
- [ ] ⌘K abre a command palette
- [ ] Projetos na sidebar navegam para `/projects/[id]`
