"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { navItems, type NavId } from "@/lib/theme/tokens";
import { useWorkbench } from "./workbench-context";
import { AppIcon } from "@/components/ui/app-icon";
import { UserAvatar } from "@/components/ui/user-avatar";
import { ProjectIcon } from "@/components/ui/project-icon";
import { anchorFromElement } from "@/components/ui/anchored-popover";
import {
  Home01Icon,
  InboxIcon,
  Calendar03Icon,
  FilterHorizontalIcon,
  TaskDone01Icon,
  Sun01Icon,
  Add01Icon,
  Settings01Icon,
  ViewIcon,
  ViewOffIcon,
} from "@/lib/icons/nav-icons";

const NAV_ICONS: Record<NavId, typeof Home01Icon> = {
  home: Home01Icon,
  inbox: InboxIcon,
  today: Sun01Icon,
  upcoming: Calendar03Icon,
  filters: FilterHorizontalIcon,
  done: TaskDone01Icon,
};

function navBadge(id: string, counts: { inbox: number; today: number }): number | null {
  if (id === "inbox" && counts.inbox > 0) return counts.inbox;
  if (id === "today" && counts.today > 0) return counts.today;
  return null;
}

export function Sidebar() {
  const pathname = usePathname();
  const {
    sidebarCollapsed,
    toggleSidebar,
    navCounts,
    projects,
    projectId,
    openQuickAdd,
    openSettings,
    openProjectCreate,
    openProductivity,
    userProfile,
  } = useWorkbench();
  const w = sidebarCollapsed ? 56 : 260;

  return (
    <aside
      className="hidden shrink-0 flex-col overflow-hidden border-r border-[var(--color-border)] bg-[var(--color-surface)] transition-[width] duration-200 ease-out lg:flex"
      style={{ width: w }}
      aria-label="Barra lateral"
    >
      <div className={`shrink-0 px-3 pt-4 ${sidebarCollapsed ? "px-2" : ""}`}>
        <div className="mb-4 flex w-full items-center justify-center px-1">
          <span
            className={`font-bold tracking-tight text-[var(--color-text)] ${
              sidebarCollapsed ? "text-[15px]" : "text-[17px]"
            }`}
          >
            {sidebarCollapsed ? "S" : "Stacked"}
          </span>
        </div>

        <button
          type="button"
          onClick={(e) => openProductivity(anchorFromElement(e.currentTarget))}
          className={`mb-3 flex w-full items-center text-left transition-colors ${
            sidebarCollapsed
              ? "h-10 justify-center rounded-[var(--radius-sm)] p-0 hover:bg-[var(--color-hover-overlay)]"
              : "gap-3 rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)]/80 p-2 px-2.5 hover:bg-[var(--color-hover-overlay)]"
          }`}
          title={sidebarCollapsed ? userProfile.name || "Relatório" : undefined}
          aria-label={sidebarCollapsed ? "Relatório de produtividade" : undefined}
        >
          <UserAvatar
            name={userProfile.name}
            email={userProfile.email}
            avatarUrl={userProfile.avatarUrl}
            size={sidebarCollapsed ? 32 : 40}
          />
          {!sidebarCollapsed && (
            <span className="min-w-0 flex-1">
              <span className="block truncate text-sm font-semibold text-[var(--color-text)]">
                {userProfile.name || "Conta"}
              </span>
              <span className="block truncate text-xs text-[var(--color-text-tertiary)]">Relatório</span>
            </span>
          )}
        </button>

        <button
          type="button"
          onClick={() => openQuickAdd()}
          className={`btn-secondary mb-3 flex items-center justify-center gap-1.5 rounded-[var(--radius-sm)] font-semibold ${
            sidebarCollapsed ? "h-9 w-full p-0" : "h-9 w-full text-[13px]"
          }`}
        >
          <AppIcon icon={Add01Icon} size={sidebarCollapsed ? 18 : 16} />
          {!sidebarCollapsed && <span>Nova tarefa</span>}
        </button>
      </div>

      <nav className={`shrink-0 ${sidebarCollapsed ? "px-2" : "px-3"}`} aria-label="Navegação">
        {navItems.map((item) => {
          const href = item.href;
          const active =
            href === "/home"
              ? pathname === "/home"
              : pathname === href || pathname.startsWith(`${href}/`);
          const Icon = NAV_ICONS[item.id];
          return (
            <Link
              key={item.id}
              href={href}
              className={`mb-0.5 flex min-h-10 items-center gap-2.5 rounded-[var(--radius-sm)] px-2.5 py-2 text-[13px] transition-colors ${
                sidebarCollapsed ? "justify-center px-0" : ""
              } ${
                active
                  ? "bg-[var(--color-nav-indicator)] font-semibold text-[var(--color-text)]"
                  : "text-[var(--color-text-secondary)] hover:bg-[var(--color-hover-overlay)] hover:text-[var(--color-text)]"
              }`}
              title={sidebarCollapsed ? item.label : undefined}
              aria-label={sidebarCollapsed ? item.label : undefined}
            >
              <span className="flex h-5 w-5 items-center justify-center">
                <AppIcon icon={Icon} size={18} />
              </span>
              {!sidebarCollapsed && (
                <>
                  <span className="flex-1">{item.label}</span>
                  {(() => {
                    const badge = navBadge(item.id, navCounts);
                    return badge != null ? (
                      <span className="text-xs tabular-nums text-[var(--color-nav-badge)]">{badge}</span>
                    ) : null;
                  })()}
                </>
              )}
            </Link>
          );
        })}
      </nav>

      <div className="mx-3 my-2 h-px bg-[var(--color-border)]" />

      <div className={`scroll-thin min-h-0 flex-1 overflow-y-auto ${sidebarCollapsed ? "px-2" : "px-3"}`}>
        {!sidebarCollapsed && (
          <div className="flex items-center justify-between px-2.5 py-2">
            <p className="text-xs font-semibold uppercase tracking-wide text-[var(--color-text-tertiary)]">Projetos</p>
            <button
              type="button"
              onClick={openProjectCreate}
              className="flex h-6 w-6 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-tertiary)] hover:bg-[var(--color-surface-variant)] hover:text-[var(--color-text)]"
              title="Novo projeto"
              aria-label="Novo projeto"
            >
              <AppIcon icon={Add01Icon} size={14} />
            </button>
          </div>
        )}
        {sidebarCollapsed && (
          <button
            type="button"
            onClick={openProjectCreate}
            className="mb-1 flex w-full items-center justify-center rounded-[var(--radius-sm)] py-2 text-[var(--color-text-tertiary)] hover:bg-[var(--color-surface-variant)] hover:text-[var(--color-text)]"
            title="Novo projeto"
            aria-label="Novo projeto"
          >
            <AppIcon icon={Add01Icon} size={16} />
          </button>
        )}
        {projects.map((p) => {
          const href = `/projects/${p.id}`;
          const active = projectId === p.id;
          return (
            <Link
              key={p.id}
              href={href}
              className={`mb-0.5 flex min-h-10 items-center gap-2.5 rounded-[var(--radius-sm)] px-2.5 py-2 text-[13px] transition-colors hover:bg-[var(--color-hover-overlay)] hover:text-[var(--color-text)] ${
                sidebarCollapsed ? "justify-center px-0" : ""
              } ${
                active
                  ? "bg-[var(--color-nav-indicator)] font-semibold text-[var(--color-text)]"
                  : "text-[var(--color-text-secondary)]"
              }`}
              title={sidebarCollapsed ? p.name : undefined}
              aria-label={sidebarCollapsed ? p.name : undefined}
            >
              <ProjectIcon iconKey={p.icon} color={p.color} size={18} />
              {!sidebarCollapsed && (
                <>
                  <span className="flex-1 truncate">{p.name}</span>
                  {p.pendingCount > 0 && (
                    <span className="text-xs tabular-nums text-[var(--color-nav-badge)]">{p.pendingCount}</span>
                  )}
                </>
              )}
            </Link>
          );
        })}
      </div>

      <div className="shrink-0 border-t border-[var(--color-border)] p-2">
        <div className={`flex items-center gap-1 ${sidebarCollapsed ? "flex-col" : ""}`}>
          <button
            type="button"
            onClick={(e) => openSettings(anchorFromElement(e.currentTarget))}
            className={`flex min-h-10 items-center gap-2.5 rounded-[var(--radius-sm)] px-2.5 py-2 text-[13px] text-[var(--color-text-secondary)] hover:bg-[var(--color-hover-overlay)] hover:text-[var(--color-text)] ${
              sidebarCollapsed ? "w-full justify-center px-0" : "flex-1"
            }`}
            title="Configurações"
          >
            <AppIcon icon={Settings01Icon} size={18} />
            {!sidebarCollapsed && <span>Configurações</span>}
          </button>
          <button
            type="button"
            onClick={toggleSidebar}
            className="flex h-10 w-10 shrink-0 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-tertiary)] hover:bg-[var(--color-hover-overlay)] hover:text-[var(--color-text-secondary)]"
            title={sidebarCollapsed ? "Expandir barra lateral" : "Recolher barra lateral"}
            aria-label={sidebarCollapsed ? "Expandir barra lateral" : "Recolher barra lateral"}
          >
            <AppIcon icon={sidebarCollapsed ? ViewIcon : ViewOffIcon} size={18} />
          </button>
        </div>
      </div>
    </aside>
  );
}
