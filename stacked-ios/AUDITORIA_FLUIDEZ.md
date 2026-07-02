# AUDITORIA_FLUIDEZ — Stacked iOS

**Data:** 30 jun 2026  
**Escopo:** `stacked-ios/` (Passo 0 — read-only)  
**Skills aplicadas:** `impeccable` (motion, interaction, reduced-motion), `ui-ux-pro-max` (§3 Performance, §7 Animation, §9 Navigation)

---

## Resumo executivo

O projeto **não é UIKit** como o brief assume: é **100% SwiftUI** para UI (único `UIKit` explícito: `HapticService`). Não há `UIView.animate`, `UIVisualEffectView`, `UIGlassEffect` ou `UIGlassContainerEffect` em código próprio. O “liquid glass” atual é uma **simulação Flutter** em `LiquidGlass.swift`: empilha tinta sólida + `Material` + (no iOS 26) `.glassEffect()`, o que **mata a aparência nativa** e viola a diretriz Apple de não empilhar glass sobre glass.

A fluidez “não nativa” vem principalmente de:
1. Materiais simulados em vez de glass do sistema usado corretamente  
2. Animações de **layout** (`frame(maxHeight:)`) em vez de `transform`/`opacity`  
3. Conclusão de tarefa **instantânea** (sem animação de saída da célula)  
4. Press states ausentes na maior parte das células/botões  
5. `easeOut`/`easeInOut` genéricos espalhados; springs só em navbar/popover recentes  
6. Sombras pesadas (radius 20–24) em elementos flutuantes glass  

**ProMotion:** `CADisableMinimumFrameDurationOnPhone = true` já está configurado.  
**Liquid Glass opt-out:** `UIDesignRequiresCompatibility` **não existe** no Info.plist (bom: app não está optando por sair do glass do sistema).

---

## 0.1 — Configuração do projeto

| Item | Valor |
|------|--------|
| **Xcode** | 26.6 (Build 17F113) |
| **iOS SDK** | 26.5 |
| **Deployment target** | iOS **17.0** (`project.yml`) |
| **Swift** | 5.10 |
| **Stack UI** | SwiftUI (`@main StackedApp`, views em `Stacked/`) |
| **UIKit bridge** | Ausente (`UIKitBridge/` não existe no repo) |

### Info.plist (`Stacked/Info.plist`)

| Chave | Valor | Avaliação |
|-------|--------|-----------|
| `CADisableMinimumFrameDurationOnPhone` | `true` | Correto para 120Hz em animações customizadas |
| `UIDesignRequiresCompatibility` | **ausente** | Correto — app **não** força modo legado sem Liquid Glass |
| `UILaunchScreen` | `{}` | Neutro |

### Implicações

- **iOS 17–25:** sempre cai no fallback `LiquidGlass` com `.ultraThinMaterial` + cor sólida (não glass nativo iOS 26).  
- **iOS 26+:** usa `.glassEffect(.regular)` mas **ainda com fill opaco por cima** — implementação híbrida, não glass puro.  
- Build **Debug** no device físico continua mais pesado que Release; validar fluidez final em Release (fora do escopo desta auditoria, mas relevante para QA).

---

## 0.2 — Inventário de materiais / blur

### Ocorrências de glass/blur no código próprio

| Arquivo | Componente | Implementação atual | Classificação |
|---------|------------|---------------------|---------------|
| `DesignSystem/LiquidGlass.swift` | `navBarPill` | iOS 26: `fill(0.52)` + `.glassEffect(.regular)` + `clipShape` + **shadow r24**; fallback: `.ultraThinMaterial` + fill + stroke | **(a)** Migrar: glass puro iOS 26; remover empilhamento material+fill; **(c)** remover shadow pesada ou trocar por elevação do sistema |
| `LiquidGlass.swift` | `popoverCard` | Mesmo padrão (fill 0.78 + glass/material) + stroke + shadow r20 em `StackedPopoverMenu` | **(a)** + **(c)** |
| `LiquidGlass.swift` | `headerPill` | fill 0.55 + glass/material em `HomeHeaderBar` | **(a)** |
| `LiquidGlass.swift` | `toolbarPill` | idem em `ProjectDetailView`, `GlassPillButton` | **(a)** |
| `LiquidGlass.swift` | `sheetPanel` | fill **0.82** + glass/material em `QuickAddTaskView` | **(a)** + **(c)** — opacidade alta mata translucidez; Quick Add deveria usar sheet nativo ou glass sem tinta pesada |
| `Components/BottomNavPill.swift` | Navbar 5 abas | Consome `navBarPill` | **(a)** — prioridade máxima (benchmark Todoist) |
| `Components/StackedPopoverMenu.swift` | Menus ancorados | `popoverCard` + scrim `Color.black.opacity(0.18)` | **(a)** scrim ok; card precisa glass nativo sem double-stack |
| `Components/HomeHeaderBar.swift` | Avatar + sino/config | `headerPill` ×2 | **(a)** |
| `Features/QuickAdd/QuickAddTaskView.swift` | Painel inferior | `sheetPanel` + scrim 0.32; **não** usa `.sheet` do sistema | **(a)** + **(c)** — overlay custom bloqueia material de sheet nativo |
| `Features/Projects/ProjectDetailView.swift` | Pills “Lista” / “…” | `toolbarPill` | **(a)** |
| `Components/FabActionMenuOverlay.swift` | Itens do FAB | `c.surface` sólido + stroke (sem glass) | **(b)** conteúdo/ação — ok sólido; **(a)** se quiser fusão glass com navbar via container |
| `Components/ExpandableFAB.swift` | FAB | `c.accent` sólido + stroke | **(b)** FAB pode permanecer sólido (Todoist usa FAB sólido) |
| `Components/MobileShell.swift` | Scrim FAB | `Color.black.opacity(0.55)` | **(b)** scrim de modal — ok |
| `Features/Upcoming/UpcomingView.swift` | Toggle Mês/Semana/Agenda | `c.surface` sólido + stroke | **(b)** conteúdo — não migrar para glass |
| `Components/TaskRow.swift` | Cards de tarefa | `c.surface` / `surfaceVariant` | **(b)** conteúdo — **nunca** glass |
| Demais telas | Backgrounds | `c.background`, `c.surface` | **(b)** |

### O que NÃO existe no projeto

- `UIBlurEffect` / `UIVisualEffectView`  
- `UIGlassEffect` / `UIGlassContainerEffect` (UIKit)  
- Snapshots borrados, `BackdropFilter` manual  

### Diagnóstico de material (ui-ux-pro-max §4 `blur-purpose`, Apple HIG)

O padrão atual em **todos** os helpers `LiquidGlass.*` viola:

> *Liquid Glass é para camada flutuante; nunca glass empilhado sobre glass; nunca em conteúdo.*

Hoje: `Material` + `Color.fill(opacity)` + `.glassEffect()` = **três camadas** competindo. Resultado visual: opaco, “Flutter-like”, sem profundidade do Todoist.

### Recomendação Fase 1 (ajustada para SwiftUI)

1. iOS 26+: **apenas** `.glassEffect(.regular.tint(navBarColor))` (ou API equivalente) **sem** `.ultraThinMaterial` por baixo.  
2. iOS 17–25: **um** material (`.regularMaterial` ou tint mínima), sem segunda camada de fill 0.5+.  
3. Avaliar `GlassEffectContainer` (SwiftUI iOS 26) para **navbar + FAB** próximos — equivalente conceitual ao `UIGlassContainerEffect`.  
4. Se SwiftUI insuficiente: bridge pontual `UIViewRepresentable` com `UIGlassEffect` **somente** na navbar (sem refatorar arquitetura).

---

## 0.3 — Inventário de animações

### UIKit / Core Animation

| Tecnologia | Ocorrências |
|------------|-------------|
| `UIView.animate` | **0** |
| `UIViewPropertyAnimator` | **0** |
| `UISpringTimingParameters` | **0** |
| `CATransaction` / `CABasicAnimation` | **0** |

**Conclusão:** Todo movimento é SwiftUI. Fase 2 deve criar `MotionTokens.swift` com `Animation` springs +, onde necessário, bridges UIKit para gestos interruptíveis.

### SwiftUI — animações por categoria

#### Springs (relativamente bons)

| Arquivo | Uso |
|---------|-----|
| `AppMotion.swift` | `navIndicatorSpring`, `popoverSpring`, `iconBounceSpring` |
| `BottomNavPill.swift` | Indicador de aba + bounce de ícone |
| `StackedPopoverMenu.swift` | Entrada/saída scale+opacity do popover |
| `FiltersView.swift` | Troca dashboard/detalhe |
| `UpcomingView.swift` | Toggle de modo calendário |
| `ExpandableFAB.swift` | Rotação do “+” |

#### easeOut / easeInOut (genéricos — candidatos a substituição)

| Arquivo | Trecho | Problema |
|---------|--------|----------|
| `TaskRow.swift` | `.animation(.easeOut(0.22), value: expanded)` | Anima **layout** (`maxHeight` 0↔nil), não transform |
| `DoneCircle.swift` | `.animation(.easeOut(0.15), value: done)` | Sem spring no check; sem escala |
| `RootView.swift` | `.animation(.easeOut(0.22), value: showQuickAdd)` | Quick Add fade genérico |
| `AuthGateView.swift` | `.animation(.easeInOut(0.2), auth)` | Transição de auth |
| `ProjectDetailView.swift` | idem Quick Add | duplicado |
| `TaskDatePickerSheet.swift` | `easeOut(0.2)` | Calendário |
| `ProductivityView.swift` | `easeOut(0.2)` tabs | |
| `AppMotion.swift` | fallback `easeInOut` | ok como fallback reduce-motion |

#### Transições de apresentação

| Mecanismo | Onde | Notas |
|-----------|------|-------|
| `.sheet` + `presentationDetents` | Home, Settings, ProjectOptions, Labels, Notifications, NewProject, Search, DatePicker | Material **do sistema** no iOS 26 — **não customizar background** se quiser glass nativo |
| `.fullScreenCover` | TaskDetail, várias listas | Transição padrão sistema; sem custom transition |
| Overlay custom (`ZStack`) | `QuickAddTaskView`, `RootView` | Substitui sheet; animação `move(edge: .bottom)` + opacity |
| `PopoverPresenter` + `StackedPopoverOverlay` | Global | Scale 0.9→1 spring; dismiss com delay 0.12s |

#### Animações de lista / tarefas

| Comportamento | Implementação | Gap vs Todoist |
|---------------|---------------|----------------|
| Completar tarefa | `TaskStore.complete*` remove do array **sem** `withAnimation` | Célula some instantaneamente |
| Checkbox | `DoneCircle` troca ícone com easeOut 0.15 | Sem spring de escala/preenchimento |
| Expandir subtarefas | `frame(maxHeight: expanded ? nil : 0)` + clip | Layout thrashing; salto possível |
| Swipe actions | `.swipeActions` nativo SwiftUI | Elástico do sistema, **não** custom interactive spring |
| Reorder | Não implementado | — |

#### Gestos

| Gesto | Arquivo | Interruptível? |
|-------|---------|----------------|
| Swipe actions | List rows | Sistema — parcialmente |
| Long-press menu | `TaskContextMenu` `minimumDuration: 0.45` | Dispara só ao completar; **sem** preview interativo |
| FAB open | `ExpandableFAB` toggle bool | Scrim fade; menu sem spring por item |
| Popover tap-outside | `StackedPopoverMenu` | Dismiss animado (recente) |

---

## 0.4 — Feedback tátil e press states

### Hápticos (`Services/HapticService.swift`)

| Aspecto | Estado |
|---------|--------|
| Geradores | `UIImpactFeedbackGenerator` light/medium/heavy, `UISelectionFeedbackGenerator`, `UINotificationFeedbackGenerator` |
| `prepare()` | Chamado **uma vez** em `StackedApp.onAppear` |
| Cobertura | Boa: tabs, FAB, swipe, complete, save, popover, etc. |
| `taskCompleted()` | Sequência com `Task.sleep` 80ms+80ms entre impacts | Pode parecer **atrasada** em relação à animação visual (que nem existe) |
| `fabOpened()` | 3 impacts encadeados com sleeps | Idem |
| Antes de cada ação | **Não** chama `prepare()` imediatamente antes do impacto individual |

### Press states

| Componente | Press feedback |
|------------|----------------|
| `PopoverRowButtonStyle` | Highlight branco 6% no press — **bom** |
| `NavPillItem` | Bounce só na seleção, não no touch-down |
| `TaskRow` / list rows | **Nenhum** scale/highlight no toque |
| `ExpandableFAB` | Sem press scale |
| Metadata pills Quick Add | Sem `ButtonStyle` custom |
| Botões header | `.buttonStyle(.plain)` sem feedback |

### Reduce Motion / Reduce Transparency

| API | Uso |
|-----|-----|
| `@Environment(\.accessibilityReduceMotion)` | `StackedPopoverMenu`, `ContentView` apenas |
| `AppMotion.animation(reduceMotion:)` | Helper existe; **não usado globalmente** |
| `UIAccessibility.isReduceTransparencyEnabled` | **Não tratado** — glass sem fallback sólido |

---

## 0.5 — Auditoria de performance de render

### Sombras (offscreen rendering provável)

| Local | Valor |
|-------|--------|
| `LiquidGlass.navBarPill` | `radius: 24, y: 10, opacity 0.28` |
| `StackedPopoverMenu` menu card | `radius: 20, y: 8` |
| `ExpandableFAB` | sem shadow |

SwiftUI não expõe `shadowPath`; sombras grandes em elementos com `clipShape` + blur custam GPU em scroll.

### Animação de propriedades de layout

| Anti-pattern | Onde |
|--------------|------|
| `frame(maxHeight: 0 ↔ nil)` animado | `TaskRow.subtaskList` (card + list) |
| `.animation(..., value: expanded)` no `VStack` pai | Propaga re-layout a toda a linha |

**ui-ux-pro-max §7 `layout-shift-avoid`:** animar `transform`/`opacity`, não altura.

### z-index arbitrários

| Valor | Onde |
|-------|------|
| `99_999` | `StackedApp` → `PopoverOverlayGate` |
| `9_999` | `PopoverPresenter` |
| `200` | Quick Add overlays |

Não quebram performance sozinhos, mas indicam overlays pesados sempre no topo.

### Main thread / listas

| Item | Risco |
|------|--------|
| `List` + `TaskRow` complexo | Cada row: múltiplos `@State`, `ForEach` subtarefas, `GeometryReader` implícito no expand |
| `TaskMapper` / formatação de datas | Em body das rows — avaliar memoização na Fase 5 |
| `await` em `TaskRow.task(id:)` para labels | Fetch por row se subtarefa tem labels |
| Quick Add `asyncAfter(0.42)` focus | Percepção de lentidão na abertura |
| `@Observable` stores | Refresh amplo da lista ao completar tarefa |

### Rasterização / layers UIKit

Não aplicável — sem `shouldRasterize` ou layers UIKit custom.

---

## Top 10 ofensores (impacto na fluidez × esforço)

Ordenados para máximo ganho sensorial com menor risco:

| # | Ofensor | Impacto | Esforço | Arquivos-chave |
|---|---------|---------|---------|----------------|
| 1 | **Glass empilhado** (Material + fill + glassEffect) na navbar | 🔴 Alto | 🟡 Médio | `LiquidGlass.swift`, `BottomNavPill.swift` |
| 2 | **Completar tarefa sem animação** de saída da célula | 🔴 Alto | 🟡 Médio | `TaskStore.swift`, `TodayView`, `InboxView`, etc. |
| 3 | **Expansão de subtarefas via `maxHeight`** (layout animation) | 🔴 Alto | 🟢 Baixo | `TaskRow.swift` |
| 4 | **Ausência de press state** universal em células/botões | 🔴 Alto | 🟡 Médio | Novo `PressableButtonStyle`, `TaskRow` |
| 5 | **`DoneCircle` sem spring** de preenchimento | 🟠 Médio-alto | 🟢 Baixo | `DoneCircle.swift` |
| 6 | **Quick Add overlay custom** (não sheet nativo + fill 0.82) | 🟠 Médio | 🟡 Médio | `QuickAddTaskView.swift`, `RootView.swift` |
| 7 | **`easeOut`/`easeInOut` espalhados** em vez de tokens spring | 🟠 Médio | 🟢 Baixo | `AppMotion.swift` + 6 call sites |
| 8 | **Sombras pesadas** em navbar/popover com blur | 🟠 Médio | 🟢 Baixo | `LiquidGlass.swift`, `StackedPopoverMenu.swift` |
| 9 | **Hápticos encadeados com `sleep`** desincronizados da UI | 🟡 Médio | 🟢 Baixo | `HapticService.swift` |
| 10 | **Reduce Motion / Reduce Transparency** não globais | 🟡 Médio | 🟡 Médio | `AppMotion`, `LiquidGlass` |

**Honorable mentions:** long-press 0.45s sem preview; `prepare()` não antes de cada háptico; Debug build no device; swipe actions não customizadas (esforço alto, ficar para depois da Fase 3).

---

## Plano de fases refinado (pós-auditoria)

> **Nota arquitetural:** Fases abaixo adaptam o brief UIKit para **SwiftUI + bridges pontuais**. Restrições do prompt (sem mudar layout/cores/espaçamentos) mantidas.

### FASE 1 — Fundação Liquid Glass nativo (navegação)

**Objetivo:** Navbar, header pills, popovers e sheets com material do sistema — sem double-stack.

- Refatorar `LiquidGlass.swift`: ramo iOS 26 usa **só** `.glassEffect` com tint leve; ramo 17–25 usa **um** material.  
- Remover fills 0.52–0.82 sobre glass onde classificado **(a)**.  
- Avaliar `GlassEffectContainer` para proximidade navbar ↔ FAB.  
- Sheets do sistema (`.sheet`): **não** aplicar `background` custom em iOS 26.  
- Quick Add: manter layout idêntico; trocar **material** do painel (não posição).  
- Fallback `isReduceTransparencyEnabled` → superfície sólida `navBar` sem blur.  
- **Marcadores:** `// SUBSTITUIDO_FASE1` no código antigo comentado (não deletar).  
- **QA:** 1 screenshot da Home com navbar.

### FASE 2 — Sistema de animação (MotionTokens)

**Objetivo:** Um ponto de verdade para movimento.

- Criar `MotionTokens.swift` (SwiftUI `Animation` + constantes de duração; espelho UIKit opcional para bridges).  
- Substituir `easeOut`/`easeInOut` nos 6+ call sites por `MotionTokens.snappy` / `smooth`.  
- Popover/FAB/Quick Add: springs unificados.  
- Gestos interruptíveis: priorizar sheets e popovers; documentar onde SwiftUI limita e bridge é necessário.  
- **QA:** 1 gravação curta abrindo menu de etiquetas.

### FASE 3 — Micro-interações da lista (benchmark Todoist)

- `DoneCircle`: spring scale + fill.  
- `TaskStore.complete*`: `withAnimation(MotionTokens.snappy)` + remoção com transição (opacity + move).  
- `PressableRowStyle`: scale 0.97 no touch-down, revert no cancel.  
- `TaskRow` subtarefas: trocar `maxHeight` por `SizeTransition`/opacity ou `matchedGeometryEffect` sem animar layout pai.  
- Háptico `light`/`medium` **sincronizado** com frame 0 da animação do check.  
- Swipe: manter nativo na Fase 3; custom elastic só se validação pedir (esforço alto).  
- **QA:** gravação completar 1 tarefa.

### FASE 4 — Transições e gestos de navegação

- Quick Add: spring from-bottom alinhado à âncora (FAB).  
- Popovers: âncora `UnitPoint` já parcialmente ok; refinar origem scale.  
- `fullScreenCover` TaskDetail: avaliar `.navigationTransition` iOS 18+ ou zoom source sem mudar layout.  
- Long-press: reduzir delay ou adicionar preview scale progressivo.  
- **QA:** 1 gravação transição representativa.

### FASE 5 — Performance, ProMotion e acessibilidade

- Reduzir/remover shadows em elementos glass (ou usar elevação mínima).  
- `CADisableMinimumFrameDurationOnPhone` já ok; validar 120Hz em **Release** no device.  
- `accessibilityReduceMotion` em `AppMotion.animated()` global.  
- `isReduceTransparencyEnabled` fallback em `LiquidGlass`.  
- `HapticService.prepare()` antes de impacts críticos; remover sleeps desnecessários.  
- Perfil: Time Profiler em scroll da lista Hoje (opcional, só se eu pedir).  
- **QA:** relato de fluidez no iPhone físico.

---

## Critérios de aceite do Passo 0

- [x] Configuração do projeto documentada  
- [x] Inventário de materiais/blur completo  
- [x] Inventário de animações completo  
- [x] Inventário hápticos + press states  
- [x] Auditoria de performance de render  
- [x] Top 10 ofensores priorizados  
- [x] Plano de fases refinado  
- [x] **Nenhum arquivo de código alterado** (apenas este relatório criado)

---

## Próximo passo

**Aguardando sua aprovação** deste relatório antes de iniciar a Fase 1.

Sugestões para validação rápida:
1. Confirmar se o alvo de glass é **só SwiftUI `.glassEffect`** ou se quer bridge UIKit `UIGlassEffect` na navbar.  
2. Confirmar se Quick Add deve migrar para `.sheet` nativo (mesmo layout, material diferente) ou manter overlay.  
3. Após aprovação: **commit git** antes de qualquer código da Fase 1 (conforme suas regras).
