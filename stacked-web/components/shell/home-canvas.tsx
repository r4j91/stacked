"use client";

import Link from "next/link";
import { useWorkbench } from "@/components/shell/workbench-context";
import { AppIcon } from "@/components/ui/app-icon";
import { ProjectIcon } from "@/components/ui/project-icon";
import {
  Home01Icon,
  InboxIcon,
  Calendar03Icon,
  FilterHorizontalIcon,
  TaskDone01Icon,
  Sun01Icon,
  ArrowRight01Icon,
  Notification01Icon,
} from "@/lib/icons/nav-icons";

function greeting(name: string): string {
  const hour = new Date().getHours();
  const prefix = hour < 12 ? "Bom dia" : hour < 18 ? "Boa tarde" : "Boa noite";
  return `${prefix}, ${name}`;
}

export function HomeCanvas() {
  const { userProfile, navCounts, filterCounts, projects } = useWorkbench();
  const displayName = userProfile.name || "você";

  return (
    <main
      id="workbench-main-content"
      data-workbench-main
      tabIndex={-1}
      className="flex min-w-0 flex-1 flex-col overflow-hidden bg-[var(--color-bg)] outline-none"
    >
      <div className="mx-auto flex h-full w-full max-w-[var(--content-max-width)] min-w-0 flex-col px-4 lg:px-6">
        <header className="shrink-0 border-b border-[var(--color-border)] pb-4 pt-5">
          <h1 className="type-screen-title">
            {greeting(displayName)}
          </h1>
          <p className="mt-1 text-[13px] text-[var(--color-text-secondary)]">
            Resumo e atalhos para o seu dia
          </p>
        </header>

        <div className="scroll-hidden min-h-0 flex-1 overflow-y-auto pb-8 pt-4">
          {filterCounts.overdue > 0 && (
            <Link
              href="/filters?kind=overdue"
              className="mb-4 flex items-center gap-3 rounded-[var(--radius-md)] border border-[var(--color-overdue)]/30 bg-[var(--color-overdue)]/10 px-4 py-3 text-sm hover:bg-[var(--color-overdue)]/15"
            >
              <AppIcon icon={Notification01Icon} size={20} className="text-[var(--color-overdue)]" />
              <span className="flex-1 font-medium text-[var(--color-overdue)]">
                {filterCounts.overdue} tarefa{filterCounts.overdue === 1 ? "" : "s"} atrasada
                {filterCounts.overdue === 1 ? "" : "s"}
              </span>
              <AppIcon icon={ArrowRight01Icon} size={16} className="text-[var(--color-overdue)]" />
            </Link>
          )}

          <section className="mb-6">
            <h2 className="mb-2 px-1 text-xs font-semibold uppercase tracking-wide text-[var(--color-text-tertiary)]">
              Acesso rápido
            </h2>
            <div className="grid gap-2 sm:grid-cols-3">
              <QuickLink
                href="/inbox"
                icon={InboxIcon}
                label="Inbox"
                count={navCounts.inbox}
              />
              <QuickLink
                href="/today"
                icon={Sun01Icon}
                label="Hoje"
                count={navCounts.today}
              />
              <QuickLink
                href="/upcoming"
                icon={Calendar03Icon}
                label="Em breve"
                count={filterCounts.week}
              />
            </div>
          </section>

          <section>
            <h2 className="mb-2 px-1 text-xs font-semibold uppercase tracking-wide text-[var(--color-text-tertiary)]">
              Projetos
            </h2>
            {projects.length === 0 ? (
              <p className="px-1 py-4 text-sm text-[var(--color-text-tertiary)]">
                Nenhum projeto ainda.
              </p>
            ) : (
              <div className="flex flex-col gap-0.5">
                {projects.map((p) => (
                  <Link
                    key={p.id}
                    href={`/projects/${p.id}`}
                    className="flex items-center gap-2.5 rounded-[var(--radius-sm)] px-2.5 py-2.5 text-[var(--color-text-secondary)] hover:bg-[var(--color-surface)] hover:text-[var(--color-text)]"
                  >
                    <ProjectIcon iconKey={p.icon} color={p.color} size={20} />
                    <span className="flex-1 truncate font-medium">{p.name}</span>
                    {p.pendingCount > 0 && (
                      <span className="text-xs tabular-nums text-[var(--color-text-tertiary)]">
                        {p.pendingCount}
                      </span>
                    )}
                    <AppIcon icon={ArrowRight01Icon} size={14} className="opacity-40" />
                  </Link>
                ))}
              </div>
            )}
          </section>
        </div>
      </div>
    </main>
  );
}

function QuickLink({
  href,
  icon,
  label,
  count,
}: {
  href: string;
  icon: typeof Home01Icon;
  label: string;
  count: number;
}) {
  return (
    <Link
      href={href}
      className="flex items-center gap-3 rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] px-4 py-3 hover:bg-[var(--color-surface-variant)]"
    >
      <AppIcon icon={icon} size={20} className="text-[var(--color-text-secondary)]" />
      <span className="flex-1 font-semibold">{label}</span>
      {count > 0 && (
        <span className="rounded-full bg-[var(--color-surface-variant)] px-2 py-0.5 text-xs font-semibold tabular-nums">
          {count}
        </span>
      )}
    </Link>
  );
}
