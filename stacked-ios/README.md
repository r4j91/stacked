# Stacked iOS (nativo)

App iPhone em **Swift + SwiftUI/UIKit**, port do design e UX do Flutter em `lib/`.

O Flutter **não é modificado** — este diretório é um projeto Xcode independente.

## Requisitos

- Xcode 16+ (iOS 17 deployment target)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- Conta Supabase (mesmo projeto do Flutter / `stacked-web`)

## Setup (primeira vez)

```bash
cd stacked-ios

# 1. Secrets Supabase (copie a anon key de lib/main.dart ou stacked-web/.env.local)
cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
# Edite Config/Secrets.xcconfig com SUPABASE_URL e SUPABASE_ANON_KEY

# 2. Gerar .xcodeproj
./scripts/bootstrap.sh

# 3. Abrir no Xcode
open Stacked.xcodeproj
```

Selecione o scheme **Stacked** e rode no simulador ou no seu iPhone.

## Estrutura

```
stacked-ios/
├── Stacked/                 # Código-fonte Swift
│   ├── App/                 # Entry point, views raiz
│   ├── DesignSystem/        # Tokens (paridade lib/theme/)
│   ├── Models/              # Task, Subtask, Label
│   ├── Services/            # Supabase, repositories
│   └── UIKitBridge/         # (Fase 2+) swipe, context menu
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

## Paridade com Flutter

- Design tokens: `lib/theme/app_theme_data.dart` → `DesignSystem/AppTheme.swift`
- Query unificada: `kTaskSelect` em `task_repository.dart` → `Services/TaskSelect.swift`
- Web desktop: `stacked-web/` (Next.js) — independente, mesmo Supabase
