"use client";

import dynamic from "next/dynamic";
import { Suspense } from "react";
import { Sidebar } from "./sidebar";
import { CommandPalette } from "./command-palette";
import { BottomNav } from "./bottom-nav";
import { WorkbenchProvider, useWorkbench } from "./workbench-context";
import { useMainFocusOnRoute } from "@/lib/hooks/use-main-focus-on-route";
import { useCompactDesktopChrome } from "@/lib/hooks/use-compact-desktop-chrome";

const InspectorPanel = dynamic(
  () => import("./inspector-panel").then((m) => m.InspectorPanel),
  { ssr: false },
);

const QuickAddSheet = dynamic(
  () => import("@/components/tasks/quick-add-sheet").then((m) => m.QuickAddSheet),
  { ssr: false },
);

const ProjectSheet = dynamic(
  () => import("@/components/projects/project-sheet").then((m) => m.ProjectSheet),
  { ssr: false },
);

const SettingsSheet = dynamic(
  () => import("@/components/settings/settings-sheet").then((m) => m.SettingsSheet),
  { ssr: false },
);

const AppearanceSheet = dynamic(
  () => import("@/components/settings/appearance-sheet").then((m) => m.AppearanceSheet),
  { ssr: false },
);

const ProfileEditPanel = dynamic(
  () => import("@/components/settings/profile-edit-panel").then((m) => m.ProfileEditPanel),
  { ssr: false },
);

const ProductivityPopover = dynamic(
  () => import("@/components/shell/productivity-popover").then((m) => m.ProductivityPopover),
  { ssr: false },
);

const LabelsManager = dynamic(
  () => import("@/components/labels/labels-manager").then((m) => m.LabelsManager),
  { ssr: false },
);

const CalendarSettingsSheet = dynamic(
  () => import("@/components/settings/calendar-settings-sheet").then((m) => m.CalendarSettingsSheet),
  { ssr: false },
);

const ShortcutsDialog = dynamic(
  () => import("./shortcuts-dialog").then((m) => m.ShortcutsDialog),
  { ssr: false },
);

const CalendarConnectNotice = dynamic(
  () => import("@/components/shell/calendar-connect-notice").then((m) => m.CalendarConnectNotice),
  { ssr: false },
);

function WorkbenchOverlays() {
  const {
    quickAddOpen,
    closeQuickAdd,
    quickAddInitial,
    projectSheetOpen,
    projectSheetMode,
    projectSheetProject,
    closeProjectSheet,
  } = useWorkbench();

  return (
    <>
      <QuickAddSheet
        open={quickAddOpen}
        onClose={closeQuickAdd}
        initialProjectId={quickAddInitial.projectId}
        initialSectionId={quickAddInitial.sectionId}
      />
      <ProjectSheet
        open={projectSheetOpen}
        mode={projectSheetMode}
        project={projectSheetProject}
        onClose={closeProjectSheet}
      />
      <SettingsSheet />
      <AppearanceSheet />
      <ProfileEditPanel />
      <ProductivityPopover />
      <LabelsManager />
      <CalendarSettingsSheet />
      <ShortcutsDialog />
    </>
  );
}

export function WorkbenchShell({ children }: { children?: React.ReactNode }) {
  return (
    <WorkbenchProvider>
      <WorkbenchShellInner>{children}</WorkbenchShellInner>
    </WorkbenchProvider>
  );
}

function WorkbenchShellInner({ children }: { children?: React.ReactNode }) {
  useMainFocusOnRoute();
  useCompactDesktopChrome();

  return (
    <div className="flex h-dvh flex-col overflow-hidden">
      <a
        href="#workbench-main-content"
        className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-[calc(var(--z-toast)+1)] focus:rounded-[var(--radius-sm)] focus:bg-[var(--color-surface)] focus:px-4 focus:py-2 focus:text-sm focus:font-semibold focus:shadow-lg focus:outline focus:outline-2 focus:outline-offset-2 focus:outline-[var(--color-focus-ring)]"
      >
        Pular para o conteúdo
      </a>
      <div className="flex min-h-0 flex-1 pb-[var(--mobile-scroll-inset)] lg:pb-0">
        <Sidebar />
        {children}
        <InspectorPanel />
      </div>
      <BottomNav />
      <CommandPalette />
      <Suspense fallback={null}>
        <CalendarConnectNotice />
      </Suspense>
      <WorkbenchOverlays />
    </div>
  );
}
