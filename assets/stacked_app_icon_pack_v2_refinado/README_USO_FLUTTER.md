# Stacked App Icon Pack V2 Refinado

Este pacote foi montado para uso real no app usando PNGs, porque o acabamento premium do ícone depende de sombras, luz e gradientes rasterizados.

## Arquivo recomendado
Use `lumen_icon_master_1024.png` ou `preto_grafite/lumen_icon_preto_grafite_1024.png` como base principal.

## Importante sobre SVG
O SVG incluído é apenas uma aproximação. Para ícone de app no iOS/Android/Flutter, use os PNGs.

## Flutter Launcher Icons
Copie o PNG 1024 para `assets/icon/lumen_icon_master_1024.png` e configure:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/lumen_icon_master_1024.png"
  remove_alpha_ios: true
```

Depois rode:

```bash
flutter pub run flutter_launcher_icons
```

## Variantes incluídas
- preto_grafite: recomendada para o app principal
- grafite_claro: alternativa mais suave
- azul_nevoa: versão fria e premium
- azul_oceano: versão azul mais forte
- branco_cinza: versão clara para testes/branding
