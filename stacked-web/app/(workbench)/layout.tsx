"use client";

import { ThemeProvider } from "@/components/theme/theme-provider";
import { ToastProvider } from "@/components/ui/toast-provider";
import { WorkbenchShell } from "@/components/shell/workbench-shell";

export default function WorkbenchLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <ThemeProvider>
      <ToastProvider>
        <WorkbenchShell>{children}</WorkbenchShell>
      </ToastProvider>
    </ThemeProvider>
  );
}
