"use client";

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
import { ProjectSheet } from "@/components/projects/project-sheet";
import { useMainFocusOnRoute } from "@/lib/hooks/use-main-focus-on-route";

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
      <div className="flex min-h-0 flex-1 pb-[calc(56px+env(safe-area-inset-bottom))] lg:pb-0">
        <Sidebar />
        {children}
        <InspectorPanel />
      </div>
      <BottomNav />
      <CommandPalette />
      <WorkbenchOverlays />
    </div>
  );
}
