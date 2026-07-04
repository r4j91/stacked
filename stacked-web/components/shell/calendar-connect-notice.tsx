"use client";

import { useEffect } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { useToast } from "@/components/ui/toast-provider";
import { useWorkbench } from "./workbench-context";

export function CalendarConnectNotice() {
  const params = useSearchParams();
  const router = useRouter();
  const { showToast } = useToast();
  const { refreshTasks, refreshGoogleCalendar } = useWorkbench();

  useEffect(() => {
    const status = params.get("calendar");
    if (!status) return;

    const url = new URL(window.location.href);
    url.searchParams.delete("calendar");
    url.searchParams.delete("reason");
    router.replace(`${url.pathname}${url.search}`);

    if (status === "connected") {
      showToast("Google Calendar conectado.");
      void refreshGoogleCalendar();
      void refreshTasks();
      return;
    }

    if (status === "error") {
      const reason = params.get("reason");
      const message =
        reason === "config"
          ? "Calendário não configurado no servidor."
          : reason === "no_refresh"
            ? "Não foi possível obter acesso contínuo. Tente conectar de novo."
            : "Não foi possível conectar o Google Calendar.";
      showToast(message);
    }
  }, [params, router, showToast, refreshGoogleCalendar, refreshTasks]);

  return null;
}
