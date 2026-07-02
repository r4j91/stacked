"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { AppIcon } from "@/components/ui/app-icon";
import {
  Home01Icon,
  InboxIcon,
  Sun01Icon,
  Calendar03Icon,
  FilterHorizontalIcon,
} from "@/lib/icons/nav-icons";
import { useWorkbench } from "./workbench-context";

const TABS = [
  { id: "home", href: "/home", label: "Navegar", icon: Home01Icon },
  { id: "inbox", href: "/inbox", label: "Inbox", icon: InboxIcon, countKey: "inbox" as const },
  { id: "today", href: "/today", label: "Hoje", icon: Sun01Icon, countKey: "today" as const },
  { id: "upcoming", href: "/upcoming", label: "Em breve", icon: Calendar03Icon },
  { id: "filters", href: "/filters", label: "Filtros", icon: FilterHorizontalIcon },
];

export function BottomNav() {
  const pathname = usePathname();
  const { navCounts } = useWorkbench();

  return (
    <nav
      className="fixed bottom-0 left-0 right-0 z-40 border-t border-[var(--color-border)] bg-[var(--color-surface)] px-1 pb-[max(8px,env(safe-area-inset-bottom))] pt-1 lg:hidden"
      aria-label="Navegação principal"
    >
      <div className="mx-auto flex max-w-lg items-stretch justify-around">
        {TABS.map((tab) => {
          const active =
            tab.href === "/home"
              ? pathname === "/home"
              : pathname === tab.href || pathname.startsWith(`${tab.href}/`);
          const count =
            tab.countKey && navCounts[tab.countKey] > 0 ? navCounts[tab.countKey] : null;

          return (
            <Link
              key={tab.id}
              href={tab.href}
              className={`relative flex min-h-12 min-w-0 flex-1 flex-col items-center justify-center gap-0.5 rounded-[var(--radius-sm)] px-1 py-1.5 text-[11px] font-medium transition-colors ${
                active
                  ? "bg-[var(--color-nav-indicator)] text-[var(--color-text)]"
                  : "text-[var(--color-text-secondary)] hover:text-[var(--color-text)]"
              }`}
            >
              <span className="relative">
                <AppIcon icon={tab.icon} size={22} strokeWidth={active ? 2 : 1.75} />
                {count != null && (
                  <span className="absolute -right-2 -top-1 flex h-4 min-w-4 items-center justify-center rounded-full bg-[var(--color-accent)] px-1 text-[9px] font-bold text-[var(--color-accent-text)]">
                    {count > 99 ? "99+" : count}
                  </span>
                )}
              </span>
              <span className="truncate">{tab.label}</span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
