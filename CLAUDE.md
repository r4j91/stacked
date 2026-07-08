# Stacked — Contexto do Projeto

## Visão Geral
Monorepo do Stacked — app de gerenciamento de tarefas estilo Todoist/Things 3.

**Não existe Flutter neste repositório.** O app Flutter legado foi removido (tag `flutter-archive` no git).

## Stacks ativas (IMPORTANTE)

| Plataforma | Diretório | Stack |
|------------|-----------|-------|
| **iPhone** | `stacked-ios/` | Swift + SwiftUI/UIKit |
| **Web / desktop** | `stacked-web/` | Next.js + TypeScript + Supabase |

### Regras para agentes
- Pedido de **iOS** → editar **somente** `stacked-ios/`
- Pedido de **web** → editar **somente** `stacked-web/`
- **Nunca** criar ou editar `lib/` na raiz (não existe)
- `stacked-web/lib/` é código TypeScript do Next.js — **não** confundir com Flutter
- Backend compartilhado: **Supabase** (mesmo projeto entre iOS e web)
- Ícones compartilhados: `assets/`

## Design System

### Paleta de cores (semânticas — não mudam com tema)
- Fundo: #1A1B1E
- Superfície: #242529
- Superfície variante: #2C2D33
- Texto primário: #F2F3F5
- Texto secundário: #9296A0
- Texto terciário: #6B6E76
- Destaque (accent): #5FD3DC
- Prioridade alta: #EF5A5F
- Prioridade média: #F5A623
- Prioridade baixa: #4D9FEC
- Tag roxo (Ideia): #B18CF5
- Tag verde (Em Andamento): #8FD46B

Referências por stack:
- iOS: `stacked-ios/Stacked/DesignSystem/AppColors.swift`, `AppTheme.swift`
- Web: `stacked-web/lib/theme/tokens.ts`, `themes.ts`, `palette-colors.ts`

### Tipografia e densidade
- Fonte do sistema
- Linhas de tarefa compactas (~52–56px de altura)
- Título de tela: 30px, weight 800
- Título de tarefa: 15.5px, weight 600
- Texto secundário (projeto/descrição): ~12.5–13px

### Telas (5 abas)
1. Navegar (Home) — hub com visão geral e projetos
2. Inbox — tarefas sem projeto/data
3. Hoje — lista de tarefas do dia
4. Em breve — calendário + próximas tarefas
5. Filtros — dashboard de filtros e projetos

### Layout responsivo (web)
- **Mobile/tablet (< 1024px):** bottom nav flutuante (pill) + FAB
- **Desktop (≥ 1024px):** sidebar customizada
- **Tablet centering (≥ 600px):** conteúdo centralizado, max-width 640px (≥ 768px: 720px)
- **720px** é max-width de conteúdo em tablet; breakpoint mobile/desktop é **1024px**

## Estrutura do monorepo
```
stacked/
├── stacked-ios/     # App iPhone (Swift)
├── stacked-web/     # App web (Next.js)
├── assets/          # Ícones e recursos compartilhados
└── docs/            # Conceitos de design
```

## Bugs conhecidos e soluções (não repetir)

### Hero animations em listas de tarefas
Testado e causou problemas visuais nas listas. **Nunca usar Hero animations** neste projeto.

### Coluna descricao na tabela subtasks
A coluna `descricao text` precisa existir no Supabase antes de incluí-la em queries. Migration: `ALTER TABLE subtasks ADD COLUMN IF NOT EXISTS descricao text;`. Sem ela, qualquer SELECT que inclua `descricao` retorna erro e a tela fica em branco.

## Workflow de validação

### Web (`stacked-web/`)
Após editar UI: `npm run build` ou lint nos arquivos tocados. **Não** tirar screenshots por padrão a cada ajuste pontual.

### iOS (`stacked-ios/`)
Build via Xcode ou `xcodebuild`. **Não** relançar simulador/screenshots por padrão a cada ajuste pontual — só quando o usuário pedir explicitamente.

## Padrões de interação alvo
- Swipe para a esquerda no item de tarefa revela: Concluir (verde), Adiar (amarelo), Excluir (vermelho). Threshold de ~60–80px, com direction lock para não conflitar com scroll vertical.
- Long-press (ou clique direito no desktop/web) abre menu de contexto compacto: Editar, Concluir, Adiar, Duplicar, depois linhas resumidas "Prioridade: Alta ›", "Etiquetas (N) ›", "Mover para: Projeto ›" que expandem em sub-painéis ao tocar, e por fim Excluir (vermelho).
- Botão de expandir (chevron) ao lado do contador de subtarefas (ex: "5/5") expande a lista de subtarefas inline, sem navegar de tela, com animação fluida.
- Tarefas com descrição mostram uma linha de preview (truncada com ellipsis) abaixo do título.
