# Stacked — Ícones Web (stacked-web / Next.js 15)

## Estrutura

Cada pasta é uma variante de cor. **`grafite/` é a padrão do app.**
Cada variante contém:

| Arquivo | Uso |
|---|---|
| `favicon.ico` | Favicon multi-resolução (16/32/48) — aba do navegador |
| `favicon-16.png` / `favicon-32.png` / `favicon-48.png` | Favicons PNG individuais |
| `apple-touch-icon.png` (180×180) | Ícone ao adicionar à tela de início no iOS via Safari |
| `icon-192.png` / `icon-512.png` | Ícones PWA (manifest) |
| `icon-1024.png` | Master de referência |

Os favicons pequenos (16–48px) usam um recorte com zoom na pilha
para manter legibilidade em tamanho de aba.

## Instalação no Next.js 15 (App Router)

O App Router usa convenção de arquivos — basta colocar na pasta `app/`:

```
stacked-web/
  app/
    favicon.ico          ← copie de grafite/favicon.ico
    icon.png             ← copie de grafite/icon-512.png (renomeie)
    apple-icon.png       ← copie de grafite/apple-touch-icon.png (renomeie)
```

O Next.js gera as tags `<link rel="icon">` e `<link rel="apple-touch-icon">`
automaticamente a partir desses arquivos. Não precisa editar `layout.tsx`.

## PWA (manifest)

Se o projeto tem `app/manifest.ts` (ou `public/manifest.json`), aponte os ícones:

```json
{
  "icons": [
    { "src": "/icons/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icons/icon-512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "/icons/icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
```

Para isso, copie `icon-192.png` e `icon-512.png` para `public/icons/`.
O ícone funciona como maskable direto: a pilha ocupa ~67% do quadro,
dentro da zona segura de 80% exigida.

## Troca de variante

Para trocar a cor do ícone do site, repita os passos acima com a pasta
da variante desejada. Os nomes de arquivo são idênticos em todas.
