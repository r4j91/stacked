# Stacked iOS (nativo)

App iPhone em **Swift + SwiftUI/UIKit**.

Projeto Xcode independente em `stacked-ios/`. Compartilha Supabase e design tokens com `stacked-web/`.

## Requisitos

- Xcode 16+ (iOS 17 deployment target)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- Conta Supabase (mesmo projeto do `stacked-web`)

## Setup (primeira vez)

```bash
cd stacked-ios

# 1. Secrets Supabase (copie de stacked-web/.env.local)
cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
# Edite Config/Secrets.xcconfig com SUPABASE_URL e SUPABASE_ANON_KEY

# 2. Gerar .xcodeproj
./scripts/bootstrap.sh

# 3. Abrir no Xcode
open Stacked.xcodeproj
```

Selecione o scheme **Stacked** e rode no simulador ou no seu iPhone.

Atalho na raiz do monorepo: `bin/stacked ios`

## Estrutura

```
stacked-ios/
├── Stacked/                 # Código-fonte Swift
│   ├── App/                 # Entry point, views raiz
│   ├── DesignSystem/        # Tokens de tema, cores, spacing
│   ├── Models/              # Task, Subtask, Label
│   ├── Services/            # Supabase, repositories
│   └── UIKitBridge/         # swipe, context menu
├── Config/                  # xcconfig (secrets fora do git)
├── project.yml              # XcodeGen
└── PHASES.md                # Roadmap completo por fases
```

## Fases

Ver [PHASES.md](./PHASES.md) para o roadmap detalhado.

| Fase | Escopo |
|------|--------|
| **0** ✅ | Fundação: tokens, models, Supabase config, Xcode |
| **1** ✅ | Auth + 5 abas + pill + FAB |
| **2** ✅ | Hoje + Inbox + swipe + TaskStore |
| **3** ✅ | Task detail sheet |
| **4** ✅ | Home + projetos |
| **5** | Em breve, filtros, settings |
| **6** | Widgets, Shortcuts, TestFlight |

## Paridade com web

| Conceito | iOS | Web |
|----------|-----|-----|
| Design tokens | `DesignSystem/AppTheme.swift` | `stacked-web/lib/theme/tokens.ts` |
| Tasks CRUD | `Services/TaskRepository.swift` | `stacked-web/lib/repositories/task-repository.ts` |
| Task row UI | `Components/TaskRow` etc. | `stacked-web/components/tasks/task-list.tsx` |
| Modos de projeto | `ProjectDisplayMode.swift` | `stacked-web/lib/theme/project-display-mode.ts` |
