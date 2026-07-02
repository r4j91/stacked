#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "XcodeGen não encontrado. Instale: brew install xcodegen"
  exit 1
fi

if [[ ! -f Config/Secrets.xcconfig ]]; then
  echo "Criando Config/Secrets.xcconfig a partir do exemplo…"
  cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
  echo "⚠ Edite Config/Secrets.xcconfig com SUPABASE_ANON_KEY antes da Fase 1."
fi

if [[ ! -f Config/Signing.xcconfig ]]; then
  echo "Criando Config/Signing.xcconfig a partir do exemplo…"
  cp Config/Signing.xcconfig.example Config/Signing.xcconfig
  echo "⚠ Edite Config/Signing.xcconfig com seu DEVELOPMENT_TEAM se o build falhar em signing."
fi

xcodegen generate
echo "✓ Stacked.xcodeproj gerado em $ROOT"
