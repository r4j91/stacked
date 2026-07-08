# Stacked iOS — Migração por fases

App nativo Swift (SwiftUI + UIKit híbrido), **separado** do Flutter em `lib/`.
Nada no projeto Flutter é alterado durante a migração.

## Princípios

- **Port, não redesign** — mesmas cores, densidade (~52–56px), menus e fluxos do app atual
- **Supabase compartilhado** — mesmo schema e `kTaskSelect` que Flutter/web
- **Flutter continua no iPhone** até o nativo atingir paridade mínima
- **Web no Chrome** segue em `stacked-web/` (Next.js), independente

---

## Fase 0 — Fundação ✅

**Objetivo:** projeto Xcode compilável, design tokens, models e camada Supabase espelhada.

| Entrega | Status |
|---------|--------|
| `stacked-ios/` + Xcode project | ✅ |
| Design System (`AppTheme`, `AppColors`, `AppLayout`, `AppTypography`) | ✅ |
| Models (`Task`, `Subtask`, `TaskLabel`, `Priority`) | ✅ |
| `TaskSelect` + `TaskMapper` (paridade `task_repository.dart`) | ✅ |
| `SupabaseConfig` via xcconfig (sem secrets no git) | ✅ |

---

## Fase 1 — Auth + shell de navegação ✅

**Objetivo:** login Supabase e estrutura das 5 abas.

| Entrega | Status |
|---------|--------|
| Supabase Swift SDK + `SupabaseService` | ✅ |
| Auth gate + `AuthView` (email/senha, PKCE) | ✅ |
| `RootView` com 5 abas (placeholders) | ✅ |
| Pill flutuante + FAB expansível | ✅ |
| Haptics básicos | ✅ |

---

## Fase 2 — Core loop (Hoje + Inbox) ✅

**Objetivo:** primeiro uso real no dia a dia.

| Entrega | Status |
|---------|--------|
| `TaskRepository` real (fetch, toggle, delete, adiar) | ✅ |
| `TaskRowDTO` + `TaskMapper` Codable | ✅ |
| `TaskStore` @Observable (estado central) | ✅ |
| `TodayView` — atrasadas + hoje + concluídas | ✅ |
| `InboxView` — lista + concluídas | ✅ |
| Swipe nativo (Concluir / Adiar / Excluir) | ✅ |
| Pull-to-refresh | ✅ |
| `TaskRow` (~54px, título, preview) | ✅ |

**Como validar:** login → aba Hoje ou Inbox → tarefas do Supabase, swipe, checkbox, refresh.

**Não inclui ainda:** animação de conclusão do Flutter, recorrência, comentários.

---

## Fase 3 — Task detail sheet ✅

**Objetivo:** editor completo ao tocar numa tarefa.

| Entrega | Status |
|---------|--------|
| `TaskDetailView` full-screen ao tocar na linha | ✅ |
| Título + descrição com autosave (debounce) | ✅ |
| Metadados: projeto, data, prioridade, etiquetas | ✅ |
| Pickers (sheets) para cada campo | ✅ |
| Subtarefas: listar, concluir, adicionar | ✅ |
| Concluir tarefa / excluir | ✅ |
| `TaskDetailPersistence` + repos auxiliares | ✅ |

**Como validar:** Inbox ou Hoje → toque no título da tarefa → edite campos → feche (X) → lista atualiza.

**Não inclui ainda:** seções de projeto, recorrência, comentários, editor avançado de subtarefa, animação de conclusão.

---

## Fase 4 — Home + Projetos ✅

**Objetivo:** tela Navegar e detalhe de projeto.

| Entrega | Status |
|---------|--------|
| `HomeView` — saudação, atrasadas, atalhos | ✅ |
| Contadores Inbox / Hoje / Em breve | ✅ |
| Lista de projetos com contagem de tarefas | ✅ |
| Criar projeto (alert simples) | ✅ |
| `ProjectDetailView` — tarefas por seção | ✅ |
| Swipe + task detail no projeto | ✅ |
| Navegação Home → abas / projeto | ✅ |

**Como validar:** aba Navegar → ver projetos → toque num projeto → lista de tarefas com seções.

**Não inclui ainda:** opções de projeto (long-press), modo cards, criar seção, filtros dashboard.

---

## Fase 5 — Em breve + Filtros ✅

**Objetivo:** completar as 5 abas + busca e configurações básicas.

| Entrega | Status |
|---------|--------|
| `UpcomingView` — agenda agrupada por dia | ✅ |
| Calendário mês/semana + filtro por dia | ✅ |
| `fetchDatedPendingTasks` no `TaskRepository` | ✅ |
| `FiltersView` — dashboard 4 cards + projetos | ✅ |
| Drill-down por filtro (atrasadas, hoje, 7 dias, concluídas) | ✅ |
| `fetchFilterDashboardCounts` + `fetchFilteredTasks` | ✅ |
| `fetchProjectsWithTaskStats` | ✅ |
| `SearchView` — busca client-side (FAB) | ✅ |
| `SettingsView` — perfil + sair da conta | ✅ |
| FAB: buscar + novo projeto | ✅ |
| Avatar na Home → configurações | ✅ |

**Como validar:** aba Em breve → calendário + lista; Filtros → cards → lista; FAB → Buscar; avatar → Configurações → Sair.

**Não inclui ainda:** produtividade/gráficos, logbook, ícones alternativos, tema claro, notificações locais, gerenciar etiquetas, animação de calendário (drag collapse).

---

## Fase 6 — Polish + integrações iOS ✅

**Objetivo:** integrações nativas e preparação para TestFlight.

| Entrega | Status |
|---------|--------|
| `HapticService` — padrões Flutter (completar, excluir, FAB, abas) | ✅ |
| Widget **Hoje** (small + medium) via App Group | ✅ |
| `WidgetSnapshotSync` — atualiza ao carregar/concluir Hoje | ✅ |
| App Intents — Hoje, Inbox, Buscar (Siri / Atalhos) | ✅ |
| Deep links `stacked://today` etc. | ✅ |
| `AppearanceView` — 5 temas com persistência | ✅ |
| `PARITY.md` — checklist TestFlight / cutover Flutter | ✅ |

**Como validar:** adicionar widget na Home Screen; atalho Siri "Abrir Hoje no Stacked"; Configurações → Aparência; concluir tarefa em Hoje → widget atualiza.

**Não inclui:** Live Activities, notificações locais, ícones alternativos, nova tarefa pelo FAB, logbook/produtividade.

**Próximo passo manual:** configurar Team ID + App Group no Apple Developer → Archive → TestFlight (ver `PARITY.md`).

---

## Fase 7 — Quick Add + FAB + projetos ✅

**Objetivo:** criar tarefas e projetos pelo FAB; sheets completos.

| Entrega | Status |
|---------|--------|
| `QuickAddTaskView` — título, descrição, prioridade, data, projeto, seção, etiquetas | ✅ |
| FAB expansível — nova tarefa, buscar, novo projeto | ✅ |
| `NewProjectSheetView` — nome, cor, ícone | ✅ |
| `createTask` / `duplicateTask` no `TaskRepository` | ✅ |
| `StackedIcons` — mapeamento semântico (SF Symbols) | ✅ |

**Como validar:** FAB → Nova tarefa → salvar; FAB → Novo projeto; long-press em tarefa → Duplicar.

---

## Fase 8 — Context menu, seções, detail+, settings ✅

**Objetivo:** paridade de menus de contexto, CRUD de seções/etiquetas, settings completos.

| Entrega | Status |
|---------|--------|
| `TaskContextMenu` — editar, concluir, duplicar, excluir | ✅ |
| Context menu em Hoje, Inbox, Projeto | ✅ |
| `SectionRepository` — criar/renomear/excluir seção | ✅ |
| `ProjectOptionsSheet` — editar nome/cor, excluir | ✅ |
| `ProjectDetailView` — nova tarefa, nova seção, opções | ✅ |
| `CommentRepository` + comentários no task detail | ✅ |
| Recorrência básica (diária/semanal/mensal/anual) | ✅ |
| `SubtaskDetailView` — editor de subtarefa | ✅ |
| `LabelsManagementView` — CRUD etiquetas | ✅ |
| `SettingsView` — perfil, notificações, etiquetas, logbook, aparência | ✅ |

**Como validar:** long-press em tarefa; projeto → ⋯ → nova seção; task detail → comentários/recorrência; Configurações → Gerenciar Etiquetas.

---

## Fase 9 — Home header, produtividade, logbook ✅

**Objetivo:** header da Home, sheets de produtividade/notificações, registro de concluídas.

| Entrega | Status |
|---------|--------|
| `HomeHeaderBar` — avatar → produtividade; notificações + configurações | ✅ |
| `ProductivityView` — resumo semanal | ✅ |
| `LogbookView` — tarefas concluídas agrupadas | ✅ |
| `ProfileEditView` — editar nome | ✅ |
| `NotificationsSettingsView` + preview | ✅ |
| Ícones de projeto na Home (`iconKey` do Supabase) | ✅ |

**Como validar:** Home → avatar (produtividade); sino (notificações); engrenagem (settings); Configurações → Registro.

**Não inclui ainda:** animação de conclusão Flutter, drag collapse do calendário, modo cards no projeto.

---

## Fase 10 — Ícones + docs de paridade ✅

**Objetivo:** sistema de ícones semântico e documentação de cutover.

| Entrega | Status |
|---------|--------|
| `StackedIcons` + `ProjectIcons` (SF Symbols, paridade HugeIcons) | ✅ |
| `PaletteColors` — paleta de cores de projeto | ✅ |
| `PARITY.md` atualizado (Fases 7–10) | ✅ |
| HugeIcons SPM | ⏳ futuro (mapeamento SF já cobre UI) |
| Ícones alternativos do app (runtime switch) | ⏳ futuro |

**Como validar:** navegação usa ícones consistentes; `PARITY.md` reflete estado atual.

---

## Fases Impeccable A–H — Polish visual/motion ✅

Ciclo documentado em [`AUDITORIA_FLUIDEZ.md`](AUDITORIA_FLUIDEZ.md) (Slate default, `AppMotion`, chrome unificado, context menu, settings cards).

---

## Fases I–N — Fluidez estrutural (Auditoria II) ✅

**Objetivo:** sensação “liso” / ProMotion — preservar estado entre abas, menos jank em listas, design system enforced, tablet.

| Fase | Entrega | Status |
|------|---------|--------|
| **I** | `RootTabContent` preserva 5 abas; `TabRefreshPolicy`; reduce motion em `selectTab` | ✅ |
| **J** | Subtarefas clip SwiftUI; calendário Em breve fora da `List` | ✅ |
| **K** | `AppSpacing.swift`; tokens `AppTypography` estendidos; Home/Filters/TaskDetail/EmptyState | ✅ |
| **L** | Touch 44pt; VoiceOver TaskRow/DoneCircle/HomeHeaderBar | ✅ |
| **M** | Tablet centering: Projeto, Registro, Settings, Etiquetas (**sem desktop**) | ✅ |
| **N** | Build + [`AUDITORIA_FLUIDEZ.md`](AUDITORIA_FLUIDEZ.md) seção Auditoria II | ✅ |

**Como validar:** trocar abas 20× (scroll preservado); expandir subtarefas em scroll; Em breve modo Mês; VoiceOver numa tarefa; abrir Projeto/Registro no iPad.

**Fora de escopo:** shell desktop ≥1024; encurtar dwell de conclusão.

---

## Referências no repo

| Conceito | iOS nativo | Web |
|----------|------------|-----|
| Design tokens | `Stacked/DesignSystem/AppTheme.swift` | `stacked-web/lib/theme/tokens.ts` |
| Task repository | `Stacked/Services/TaskRepository.swift` | `stacked-web/lib/repositories/task-repository.ts` |
| Task row UI | `TaskRow` (Fase 2) | `stacked-web/components/tasks/task-list.tsx` |
| Swipe actions | UIKit bridge | — |
