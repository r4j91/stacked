# Stacked Web — Mock Fase 0

Provas visuais interativas (sem Supabase, dados fake).

## Abrir no Chrome

**Workbench (control room):**

```bash
open stacked-web/mock/workbench.html
```

**Filtros personalizados (Fase 0 — validar antes de implementar):**

```bash
open stacked-web/mock/custom-filters.html
```

Ou arraste o `.html` para o Chrome.

Também existe um canvas interativo equivalente em `canvases/stacked-workbench-mock.canvas.tsx` (painel Canvas do Cursor).

## Mock — Filtros personalizados

| Controle | Ação |
|----------|------|
| **Mobile (iOS)** / **Web (desktop)** | Alterna frame Graphite (390×844) vs Slate (1120×720) |
| **Dashboard** | Grid de stats + seção **Meus filtros** + Projetos |
| **Construtor** | Mobile: projectChip + ícones circulares (QuickAdd) · Web: MetaChips · menus ancorados + paleta de cor |
| **Filtro salvo** | Ícone de filtro tintado, sem fundo · drill-down com **Mostrar concluídas** |

Mobile usa tokens **Graphite** (`#1A1B1E`, accent `#5FD3DC`); desktop usa **Slate** (`globals.css`). Tipografia alinhada a `AppTypography` (título 30px/800, task 15.5px/600, section label 11px/bold).

## Layout (v3)

**3 colunas:** Sidebar colapsável (260px ↔ 56px) | Canvas | Inspector

Sidebar alinhada ao shell desktop do `stacked-web`: logo, Nova tarefa, nav com ícone + label, projetos expansíveis, perfil. Filtros (Atrasadas/Hoje) ficam **só na lista**, não na sidebar.

| Atalho | Ação |
|--------|------|
| `⌘B` / `Ctrl+B` | Recolher / expandir sidebar |
| `⌘K` / `Ctrl+K` | Command palette |

## Interações

| Ação | Resultado |
|------|-----------|
| Clicar numa tarefa | Abre o **Inspector** à direita |
| `⌘K` / `Ctrl+K` | Abre a **Command palette** |
| `Esc` | Fecha palette ou inspector |
| Hover numa linha | Mostra ações (Concluir · Adiar · Mover · Excluir) |
| Sidebar | Nav principal + projetos; botão inferior recolhe/expande |
| Checkbox | Marca concluída (visual local) |

## Tema

Mock usa **Slate** (`stacked-web/lib/theme/tokens.ts`): fundo `#16161A`, superfícies `#1C1C20` / `#2C2C32`, accent `#E8E8EC`, texto `#F2F2F4`. Cores semânticas (prioridade, atrasadas, tags) não mudam com o tema.

## O que validar (v2)

- Densidade das linhas (~54px) com preview de descrição
- Ícones SVG (rail, ações, meta) — sem emoji como ícone
- Profundidade por camadas de tom, sem box-shadow
- Inspector inline com breadcrumb, progresso de subtarefas, field pills
- Stats strip no header (atrasadas · hoje · concluídas)
- Hover actions com ícones semânticos
- Command palette com blur, hints de teclado, navegação ↑↓

Próxima fase: Next.js + Supabase real.
