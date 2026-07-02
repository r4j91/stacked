# Stacked Web — Mock Fase 0

Prova visual interativa do **Control Room Workbench** (sem Supabase, dados fake).

## Abrir no Chrome

```bash
open stacked-web/mock/workbench.html
```

Ou arraste `workbench.html` para o Chrome.

Também existe um canvas interativo equivalente em `canvases/stacked-workbench-mock.canvas.tsx` (painel Canvas do Cursor).

## Layout (v3)

**3 colunas:** Sidebar colapsável (260px ↔ 56px) | Canvas | Inspector

Sidebar alinhada ao [`desktop_sidebar.dart`](../../lib/widgets/desktop_shell/desktop_sidebar.dart): logo, Nova tarefa, nav com ícone + label, projetos expansíveis, perfil. Filtros (Atrasadas/Hoje) ficam **só na lista**, não na sidebar.

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

Mock usa **Slate** (`lib/theme/app_theme_data.dart`): fundo `#16161A`, superfícies `#1C1C20` / `#2C2C32`, accent `#E8E8EC`, texto `#F2F2F4`. Cores semânticas (prioridade, atrasadas, tags) seguem `AppColors` e não mudam com o tema.

## O que validar (v2)

- Densidade das linhas (~54px) com preview de descrição
- Ícones SVG (rail, ações, meta) — sem emoji como ícone
- Profundidade por camadas de tom, sem box-shadow
- Inspector inline com breadcrumb, progresso de subtarefas, field pills
- Stats strip no header (atrasadas · hoje · concluídas)
- Hover actions com ícones semânticos
- Command palette com blur, hints de teclado, navegação ↑↓

Próxima fase: Next.js + Supabase real.
