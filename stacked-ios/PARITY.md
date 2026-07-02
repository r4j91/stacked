# Stacked iOS — Checklist de paridade (TestFlight)

Use este documento antes de substituir o app Flutter no iPhone.

## Core loop diário

| Fluxo | Flutter | Nativo | Notas |
|-------|---------|--------|-------|
| Login / logout | ✅ | ✅ | PKCE Supabase |
| Inbox — listar, swipe, concluir | ✅ | ✅ | |
| Hoje — atrasadas + hoje + concluídas | ✅ | ✅ | |
| Task detail — editar, subtarefas | ✅ | ✅ | Comentários + recorrência básica |
| Pull-to-refresh | ✅ | ✅ | |
| Context menu (editar, duplicar, excluir) | ✅ | ✅ | Long-press / clique direito |
| Nova tarefa (FAB) | ✅ | ✅ | `QuickAddTaskView` |

## Navegação (5 abas)

| Aba | Flutter | Nativo | Notas |
|-----|---------|--------|-------|
| Navegar (Home) | ✅ | ✅ | Header com produtividade + notificações |
| Inbox | ✅ | ✅ | |
| Hoje | ✅ | ✅ | |
| Em breve | ✅ | ✅ | Sem drag collapse do calendário |
| Filtros | ✅ | ✅ | |

## Projetos

| Fluxo | Flutter | Nativo | Notas |
|-------|---------|--------|-------|
| Listar projetos na Home | ✅ | ✅ | Com ícone e cor |
| Criar projeto | ✅ | ✅ | Sheet com paleta de cores |
| Detalhe por seção | ✅ | ✅ | |
| Criar seção | ✅ | ✅ | Menu ⋯ no projeto |
| Opções de projeto | ✅ | ✅ | Long-press na Home ou menu no detalhe |
| Modo cards | ✅ | ❌ | P2 |

## Busca e configurações

| Fluxo | Flutter | Nativo | Notas |
|-------|---------|--------|-------|
| Busca (FAB) | ✅ | ✅ | |
| Configurações / perfil | ✅ | ✅ | `ProfileEditView` |
| Aparência (temas) | ✅ | ✅ | 5 temas |
| Notificações locais | ✅ | ⚠️ | UI + preview; agendamento local pendente |
| Gerenciar etiquetas | ✅ | ✅ | |
| Logbook (registro) | ✅ | ✅ | |
| Produtividade / gráficos | ✅ | ✅ | Resumo semanal simplificado |
| Ícones alternativos do app | ✅ | ❌ | P2 |

## Integrações iOS (Fase 6)

| Recurso | Status |
|---------|--------|
| Widget Hoje (small/medium) | ✅ |
| Atalhos Siri / App Intents | ✅ Hoje, Inbox, Buscar |
| Deep links `stacked://` | ✅ |
| Haptics refinados | ✅ |
| Live Activities | ❌ opcional |

## Gaps conhecidos (aceitáveis para cutover?)

- Animação de conclusão de tarefa (Flutter custom)
- Recorrência custom (dias da semana / intervalo)
- Drag collapse do calendário em Em breve
- Modo cards no detalhe de projeto
- HugeIcons SPM (hoje SF Symbols via `StackedIcons`)
- Ícones alternativos do app em runtime
- Notificações locais agendadas (UI pronta)
- Desktop / web — fora do escopo iOS nativo

## TestFlight — passos

1. Configurar **Team ID** em `project.yml` → `DEVELOPMENT_TEAM`
2. Criar App ID + App Group `group.com.stacked.app` no Apple Developer
3. Habilitar App Groups no app e na extensão do widget
4. Archive → Distribute → TestFlight
5. Validar checklist acima em dispositivo físico
6. Quando paridade mínima OK: parar de publicar Flutter iOS; manter Android/web

## Desligar Flutter iOS (quando pronto)

- Não remover `lib/` — continua Android
- Opcional: renomear target iOS Flutter ou remover do workflow de release iOS
- Atualizar ícone/TestFlight listing para build nativo `stacked-ios/`
