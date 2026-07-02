import { SHORTCUT_GROUPS } from "@/lib/shortcuts";

export function ShortcutsContent({ compact }: { compact?: boolean }) {
  return (
    <div className={compact ? "space-y-4" : "space-y-5"}>
      <p className="text-[13px] leading-relaxed text-[var(--color-text-secondary)]">
        Atalhos do app desktop. Em Windows/Linux, use <kbd className="kbd-inline">Ctrl</kbd> no lugar de{" "}
        <kbd className="kbd-inline">⌘</kbd>.
      </p>
      {SHORTCUT_GROUPS.map((group) => (
        <section key={group.title}>
          <h3 className="mb-1.5 text-[11px] font-semibold uppercase tracking-wide text-[var(--color-text-tertiary)]">
            {group.title}
          </h3>
          {group.hint && (
            <p className="mb-2 text-[11px] text-[var(--color-text-tertiary)]">{group.hint}</p>
          )}
          <ul className="space-y-1.5">
            {group.items.map((item) => (
              <li
                key={item.description}
                className="flex items-center justify-between gap-3 rounded-[var(--radius-sm)] px-1 py-0.5 text-[13px]"
              >
                <span className="text-[var(--color-text-secondary)]">{item.description}</span>
                <span className="flex shrink-0 flex-wrap justify-end gap-1">
                  {item.keys.map((k) => (
                    <kbd key={k} className="kbd-chip">
                      {k}
                    </kbd>
                  ))}
                </span>
              </li>
            ))}
          </ul>
        </section>
      ))}
    </div>
  );
}
