# Stacked

Task manager estilo Todoist/Things 3 — monorepo com duas stacks ativas.

| Plataforma | Diretório | Stack | Produção |
|------------|-----------|-------|----------|
| iPhone | [`stacked-ios/`](stacked-ios/) | Swift + SwiftUI | TestFlight |
| Web | [`stacked-web/`](stacked-web/) | Next.js + Supabase | [get-stacked-app.netlify.app](https://get-stacked-app.netlify.app) |

Backend compartilhado: **Supabase**.

## Quick start

### iOS
```bash
cd stacked-ios
cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
# Edite SUPABASE_URL e SUPABASE_ANON_KEY
./scripts/bootstrap.sh
open Stacked.xcodeproj
```

Ver [`stacked-ios/README.md`](stacked-ios/README.md).

### Web
```bash
cd stacked-web
npm install
cp .env.local.example .env.local
npm run dev
```

Ver [`stacked-web/README.md`](stacked-web/README.md).

## Outros diretórios

- [`assets/`](assets/) — ícones e recursos visuais compartilhados
- [`docs/`](docs/) — conceitos e explorations de design

## Histórico

O app Flutter legado (`lib/`, `android/`, etc.) foi removido. Código preservado na tag git `flutter-archive`.
