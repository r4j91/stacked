---
target: stacked-web task row layout
total_score: 28
p0_count: 0
p1_count: 2
timestamp: 2026-07-10T23-15-20Z
slug: stacked-web-components-tasks
---
# Critique: stacked-web task row layout

Target: `stacked-web/components/tasks` (TaskRow, SwipeableTaskRow, actions)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Toasts and loading work; hover actions appear without persistent affordance |
| 2 | Match System / Real World | 4 | Familiar todo patterns, PT-BR copy |
| 3 | User Control and Freedom | 3 | Swipe + undo delete; hover actions easy to mis-click |
| 4 | Consistency and Standards | 2 | List row uses flex/grid hybrid; inspector uses cleaner single-column pattern |
| 5 | Error Prevention | 3 | Delete undo; duplicate complete paths |
| 6 | Recognition Rather Than Recall | 2 | Desktop actions icon-only on hover at row edge |
| 7 | Flexibility and Efficiency | 4 | Keyboard nav, command palette, swipe |
| 8 | Aesthetic and Minimalist Design | 2 | Too many controls per row; hover layer feels detached |
| 9 | Error Recovery | 3 | Clear toasts on failure |
| 10 | Help and Documentation | 2 | Shortcuts exist but not surfaced on task rows |
| **Total** | | **28/40** | **Good foundation, row chrome needs tightening** |

## Anti-Patterns Verdict

**LLM assessment:** Does not read as generic AI marketing slop. It reads as a competent productivity clone with iOS parity goals. The "off" feeling is structural: controls are bolted on at different layers (inline buttons, absolute hover strip, swipe layer) instead of one coherent row grammar.

**Deterministic scan:** Unavailable (`bundled detector not found`). Assessment based on source review.

**Browser overlays:** Not run (analysis-only request; no dev server session).

## Overall Impression

The task list is functionally rich and visually close to Things/Todoist, but the **action architecture is split across three zones** (left DoneCircle, right inline icons, desktop hover overlay). That split is likely what feels "wrong" when you stare at rows: buttons seem to float or compete instead of belonging to one rhythm.

## What's Working

1. **DoneCircle + priority ring** — clear primary action, matches iOS, good touch target (20px).
2. **Compact row density** — 52px min-height, truncation, meta line below title: appropriate for a task tool.
3. **Swipe on mobile** — direction lock and three actions map well to iOS behavior without cluttering narrow screens.

## Priority Issues

### [P1] Duplicate completion affordances on desktop
- **What:** Completing a task can happen via left `DoneCircle` OR via hover strip (`Concluir` tick) on the right (`swipeable-task-row.tsx` lines 101–115 vs `task-list.tsx` lines 191–198).
- **Why it matters:** Two different visual languages for the same action; hover strip appears suddenly and overlaps content.
- **Fix:** Pick one desktop pattern: keep DoneCircle only and move defer/delete to context menu or a single trailing "more" control; OR hide DoneCircle on hover and show the trio as the row's trailing slot (not absolute overlay).
- **Suggested command:** `/impeccable distill stacked-web/components/tasks`

### [P1] Right column is a loose cluster (time, WhatsApp, chevron)
- **What:** `TaskRowTime` sits in the title row (`mt-1`); WhatsApp + expand chevron sit in a sibling column (`mt-0.5`, `h-8 w-8` each) with `reserveRight` magic numbers (40px per control).
- **Why it matters:** Baselines don't align; when 0, 1, or 2 right icons show, the row's optical center shifts. `reserveRight` also pushes desktop hover buttons, so everything on the right feels calculated rather than designed.
- **Fix:** Define a fixed **trailing actions rail** (e.g. 72–96px): `[time optional] [whatsapp?] [chevron?]` with shared vertical centering (`items-center`), constant width slots (empty = invisible spacer).
- **Suggested command:** `/impeccable layout stacked-web/components/tasks/task-list.tsx`

### [P2] Desktop hover actions use absolute positioning outside the grid
- **What:** `SwipeableTaskRow` injects `absolute top-0 ... right: reserveRight` action buttons on `lg:flex`, while project rows use CSS grid (`globals.css` `.reorder-row-with-gutter.grid`).
- **Why it matters:** Actions don't participate in layout; they paint on top of title/meta text on smaller desktop widths or long titles.
- **Fix:** Make actions a real grid column (`auto` width) visible on `lg+`, hidden on mobile (swipe only).
- **Suggested command:** `/impeccable layout stacked-web/components/tasks/swipeable-task-row.tsx`

### [P2] Asymmetric horizontal padding (`pl-1 pr-0.5`)
- **What:** Row uses `py-2 pl-1 pr-0.5` while side buttons are 32px — content breathes left, crushes right.
- **Why it matters:** Reinforces "buttons stuck on the edge" feeling.
- **Fix:** Use symmetric horizontal padding (`px-2` or `pl-2 pr-2`) and let the trailing rail handle icon inset.
- **Suggested command:** `/impeccable polish stacked-web/components/tasks/task-list.tsx`

### [P3] Reorder gutter changes row geometry in projects only
- **What:** Project lists add 16px gutter + drag handle; inbox/today use plain flex rows.
- **Why it matters:** Same `TaskRow` component feels different across views; DoneCircle and text don't start at the same x-position.
- **Fix:** Optional unified leading column (empty spacer when reorder off) so checklist alignment is consistent app-wide.
- **Suggested command:** `/impeccable layout stacked-web/components/tasks/project-task-list.tsx`

## Persona Red Flags

**Alex (Power User):** Hover-only defer/delete forces mouse travel to the right edge while DoneCircle is left. No single keyboard-visible action column. `reserveRight` means hover hit area shifts per task (WhatsApp on/off).

**Casey (Mobile / thumb):** Right-side chevron and WhatsApp are top-aligned (`items-start`) while DoneCircle is vertically centered in the row — thumb targets feel uneven on one-handed use.

**Sam (Accessibility):** Desktop defer/delete only appear on hover (`opacity-0` until `group-hover`) — not keyboard-discoverable without focusing the row first. Icon buttons have `title`/`aria-label` but no visible text.

## Minor Observations

- Inspector header crams breadcrumb + WhatsApp pill + close; list row crams a different action set — **inspector/list vocabulary diverges**.
- `TaskMetaLine` wraps chips + project text; on busy tasks the row height jumps and pushes trailing icons further from the title baseline.
- `content-visibility: auto` on `.scroll-list-item` is fine for perf but can make hover transitions feel late on fast scroll (minor).

## Questions to Consider

- Should desktop rows ever show defer/delete inline, or only via context menu / swipe?
- If time is shown, should it live in the meta line (with date chip) instead of the title row?
- Would a single 32px "more" button replace WhatsApp + chevron + hover trio?
