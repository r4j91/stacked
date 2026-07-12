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
import { MobileFab } from "./mobile-fab";

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
    <>
      <nav
        className="pointer-events-none fixed inset-x-0 z-40 flex justify-center px-4 lg:hidden"
        style={{ bottom: "var(--mobile-pill-bottom)" }}
        aria-label="Navegação principal"
      >
        <div className="pointer-events-auto w-[min(calc(100%-88px),420px)] rounded-[32px] border border-[var(--color-border)] bg-[color-mix(in_srgb,var(--color-surface)_92%,transparent)] p-1 shadow-[0_8px_32px_rgba(0,0,0,0.38)] backdrop-blur-md">
          <div className="flex items-stretch justify-around">
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
                  className={`relative flex min-h-[62px] min-w-0 flex-1 flex-col items-center justify-center gap-0.5 rounded-[28px] px-0.5 py-1 text-[10.5px] font-medium transition-colors duration-150 ${
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
                  <span className="max-w-full truncate">{tab.label}</span>
                </Link>
              );
            })}
          </div>
        </div>
      </nav>
      <MobileFab />
    </>
  );
}
