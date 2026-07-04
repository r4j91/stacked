/** Slate theme tokens — paridade lib/theme/app_theme_data.dart */
export const theme = {
  background: "#16161A",
  surface: "#1C1C20",
  surfaceVariant: "#2C2C32",
  textPrimary: "#F2F2F4",
  textSecondary: "#9A9AA2",
  textTertiary: "#65656D",
  accent: "#E8E8EC",
  accentText: "#0A0A0A",
  done: "#7ECC49",
  overdue: "#EF5A5F",
  p1: "#EF5A5F",
  p2: "#F5A623",
  p3: "#4D9FEC",
  tagGreen: "#8FD46B",
} as const;

export const layout = {
  sidebarExpanded: 260,
  sidebarCollapsed: 56,
  inspectorWidth: 400,
  contentMaxWidth: 920,
  contentMinWidth: 280,
  desktopBreakpoint: 1024,
  /** sidebar expandida + inspector + padding mínimo do canvas */
  desktopChromeMin: 260 + 400 + 48,
} as const;

export type NavId = "home" | "inbox" | "today" | "upcoming" | "filters" | "done";

export const navItems: {
  id: NavId;
  href: string;
  label: string;
}[] = [
  { id: "home", href: "/home", label: "Início" },
  { id: "inbox", href: "/inbox", label: "Inbox" },
  { id: "today", href: "/today", label: "Hoje" },
  { id: "upcoming", href: "/upcoming", label: "Em breve" },
  { id: "filters", href: "/filters", label: "Filtros" },
  { id: "done", href: "/done", label: "Concluídas" },
];

export const canvasTitles: Record<string, { title: string; subtitle?: string }> = {
  "/home": { title: "Início", subtitle: "Resumo e atalhos" },
  "/inbox": { title: "Inbox", subtitle: "Tarefas sem data ou projeto" },
  "/today": { title: "Hoje" },
  "/upcoming": { title: "Em breve", subtitle: "Calendário e agenda" },
  "/filters": { title: "Filtros", subtitle: "Visão geral das suas tarefas" },
  "/done": { title: "Concluídas", subtitle: "Histórico recente" },
};
