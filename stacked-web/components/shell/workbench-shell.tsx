"use client";

import { Suspense } from "react";
import { Sidebar } from "./sidebar";
import { InspectorPanel } from "./inspector-panel";
import { CommandPalette } from "./command-palette";
import { BottomNav } from "./bottom-nav";
import { ShortcutsDialog } from "./shortcuts-dialog";
import { WorkbenchProvider, useWorkbench } from "./workbench-context";
import { QuickAddSheet } from "@/components/tasks/quick-add-sheet";
import { SettingsSheet } from "@/components/settings/settings-sheet";
import { AppearanceSheet } from "@/components/settings/appearance-sheet";
import { ProfileEditPanel } from "@/components/settings/profile-edit-panel";
import { ProductivityPopover } from "@/components/shell/productivity-popover";
import { LabelsManager } from "@/components/labels/labels-manager";
import { CalendarSettingsSheet } from "@/components/settings/calendar-settings-sheet";
import { ProjectSheet } from "@/components/projects/project-sheet";
import { useMainFocusOnRoute } from "@/lib/hooks/use-main-focus-on-route";
import { CalendarConnectNotice } from "@/components/shell/calendar-connect-notice";

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

  return (
    <div className="flex h-dvh flex-col overflow-hidden">
      <a
        href="#workbench-main-content"
        className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-[calc(var(--z-toast)+1)] focus:rounded-[var(--radius-sm)] focus:bg-[var(--color-surface)] focus:px-4 focus:py-2 focus:text-sm focus:font-semibold focus:shadow-lg focus:outline focus:outline-2 focus:outline-offset-2 focus:outline-[var(--color-focus-ring)]"
      >
        Pular para o conteúdo
      </a>
      <div className="flex min-h-0 flex-1 pb-[calc(56px+env(safe-area-inset-bottom))] lg:pb-0">
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
