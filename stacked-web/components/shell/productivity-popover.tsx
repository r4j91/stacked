"use client";

import { useEffect, useMemo, useState } from "react";
import { useWorkbench } from "./workbench-context";
import { AnchoredPopover } from "@/components/ui/anchored-popover";
import { UserAvatar } from "@/components/ui/user-avatar";
import { AppIcon } from "@/components/ui/app-icon";
import { Cancel01Icon } from "@/lib/icons/nav-icons";
import { parseCompletionTimestamp, startOfDay, toIsoTimestamp } from "@/lib/utils/date";
import { createClient } from "@/lib/supabase/client";
import { isSupabaseConfigured } from "@/lib/supabase/config";

function dayKey(d: Date) {
  return startOfDay(d).getTime();
}

export function ProductivityPopover() {
  const { productivityOpen, productivityAnchor, closeProductivity, userProfile } = useWorkbench();
  const [tab, setTab] = useState<0 | 1>(0);
  const [loading, setLoading] = useState(true);
  const [dates, setDates] = useState<Date[]>([]);
  const [totalCompleted, setTotalCompleted] = useState(0);

  useEffect(() => {
    if (!productivityOpen) return;
    setLoading(true);
    if (!isSupabaseConfigured()) {
      setDates([]);
      setTotalCompleted(0);
      setLoading(false);
      return;
    }
    void (async () => {
      const client = createClient();
      const today = startOfDay(new Date());
      const monday = new Date(today);
      monday.setDate(today.getDate() - (today.getDay() === 0 ? 6 : today.getDay() - 1));
      const lastMonday = new Date(monday);
      lastMonday.setDate(monday.getDate() - 7);

      const [{ data: completionRows }, { count: total }] = await Promise.all([
        client
          .from("tasks")
          .select("data_conclusao")
          .eq("concluida", true)
          .not("data_conclusao", "is", null)
          .gte("data_conclusao", toIsoTimestamp(lastMonday))
          .order("data_conclusao", { ascending: false }),
        client.from("tasks").select("id", { count: "exact", head: true }).eq("concluida", true),
      ]);

      const parsed =
        completionRows
          ?.map((r) => parseCompletionTimestamp(r.data_conclusao))
          .filter((d): d is Date => d != null) ?? [];
      setDates(parsed);
      setTotalCompleted(total ?? 0);
      setLoading(false);
    })();
  }, [productivityOpen]);

  const today = startOfDay(new Date());
  const todayKey = dayKey(today);

  const stats = useMemo(() => {
    const keys = dates.map(dayKey);
    const todayCount = keys.filter((k) => k === todayKey).length;
    const last7 = Array.from({ length: 7 }, (_, i) => {
      const d = new Date(today);
      d.setDate(d.getDate() - (6 - i));
      const k = dayKey(d);
      return keys.filter((x) => x === k).length;
    });
    const monday = new Date(today);
    monday.setDate(today.getDate() - (today.getDay() === 0 ? 6 : today.getDay() - 1));
    const mondayKey = dayKey(monday);
    const thisWeek = keys.filter((k) => k >= mondayKey).length;
    const lastMonday = new Date(monday);
    lastMonday.setDate(monday.getDate() - 7);
    const lastMondayKey = dayKey(lastMonday);
    const lastWeek = keys.filter((k) => k >= lastMondayKey && k < mondayKey).length;
    const weekByDay = Array.from({ length: 7 }, (_, i) => {
      const d = new Date(monday);
      d.setDate(monday.getDate() + i);
      const k = dayKey(d);
      return keys.filter((x) => x === k).length;
    });
    const weekDelta =
      lastWeek === 0 ? (thisWeek > 0 ? 100 : 0) : Math.round(((thisWeek - lastWeek) / lastWeek) * 100);
    return { todayCount, last7, thisWeek, lastWeek, weekByDay, weekDelta, total: totalCompleted };
  }, [dates, todayKey, totalCompleted]);

  const maxBar = Math.max(1, ...(tab === 0 ? stats.last7 : stats.weekByDay));

  return (
    <AnchoredPopover
      open={productivityOpen}
      onClose={closeProductivity}
      anchorRect={productivityAnchor}
      width={340}
      preferSide="right"
      className="max-h-[min(85vh,560px)] p-0"
      labelledBy="productivity-sheet-title"
    >
      <div className="border-b border-[var(--color-border)] px-4 py-3">
        <div className="flex items-center justify-between gap-2">
          <h2 id="productivity-sheet-title" className="text-base font-bold">Relatório</h2>
          <button
            type="button"
            onClick={closeProductivity}
            className="flex h-8 w-8 items-center justify-center rounded-full bg-[var(--color-surface-variant)] text-[var(--color-text-tertiary)] hover:text-[var(--color-text-secondary)]"
            aria-label="Fechar"
          >
            <AppIcon icon={Cancel01Icon} size={16} />
          </button>
        </div>
      </div>

      <div className="scroll-thin overflow-y-auto px-4 pb-4 pt-3">
        <div className="mb-4 flex items-center gap-3 rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-variant)]/50 p-3">
          <UserAvatar name={userProfile.name} email={userProfile.email} avatarUrl={userProfile.avatarUrl} size={48} />
          <div className="min-w-0">
            <p className="truncate text-sm font-semibold">{userProfile.name || "Conta"}</p>
            <p className="text-xs text-[var(--color-text-tertiary)]">
              {stats.total} tarefa{stats.total === 1 ? "" : "s"} concluída{stats.total === 1 ? "" : "s"}
            </p>
          </div>
        </div>

        <div className="mb-4 flex rounded-[var(--radius-sm)] bg-[var(--color-surface-variant)] p-0.5">
          {(["Diário", "Semanal"] as const).map((label, i) => (
            <button
              key={label}
              type="button"
              onClick={() => setTab(i as 0 | 1)}
              className={`flex-1 rounded-[6px] py-1.5 text-xs font-semibold transition-colors ${
                tab === i
                  ? "bg-[var(--color-surface)] text-[var(--color-text)] shadow-sm"
                  : "text-[var(--color-text-tertiary)] hover:text-[var(--color-text-secondary)]"
              }`}
            >
              {label}
            </button>
          ))}
        </div>

        {loading ? (
          <ProductivitySkeleton />
        ) : tab === 0 ? (
          <>
            <p className="mb-1 text-3xl font-extrabold tabular-nums">{stats.todayCount}</p>
            <p className="mb-4 text-xs text-[var(--color-text-tertiary)]">Concluídas hoje</p>
            <BarChart values={stats.last7} max={maxBar} labels={last7Labels()} />
          </>
        ) : (
          <>
            <div className="mb-4 flex items-end gap-2">
              <p className="text-3xl font-extrabold tabular-nums">{stats.thisWeek}</p>
              <p
                className={`mb-1 text-xs font-semibold ${
                  stats.weekDelta >= 0 ? "text-[var(--color-done)]" : "text-[var(--color-overdue)]"
                }`}
              >
                {stats.weekDelta >= 0 ? "+" : ""}
                {stats.weekDelta}% vs semana passada
              </p>
            </div>
            <BarChart values={stats.weekByDay} max={maxBar} labels={["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"]} />
          </>
        )}
      </div>
    </AnchoredPopover>
  );
}

function ProductivitySkeleton() {
  return (
    <div className="animate-pulse space-y-4 py-2">
      <div className="h-9 w-16 rounded bg-[var(--color-surface-variant)]" />
      <div className="h-3 w-28 rounded bg-[var(--color-surface-variant)]" />
      <div className="flex items-end justify-between gap-1.5 pt-2">
        {Array.from({ length: 7 }).map((_, i) => (
          <div key={i} className="flex min-w-0 flex-1 flex-col items-center gap-1">
            <div className="h-24 w-full max-w-[28px] rounded-t bg-[var(--color-surface-variant)]" />
            <div className="h-2 w-3 rounded bg-[var(--color-surface-variant)]" />
          </div>
        ))}
      </div>
    </div>
  );
}

function last7Labels() {
  const today = startOfDay(new Date());
  return Array.from({ length: 7 }, (_, i) => {
    const d = new Date(today);
    d.setDate(d.getDate() - (6 - i));
    return d.toLocaleDateString("pt-BR", { weekday: "narrow" });
  });
}

function BarChart({ values, max, labels }: { values: number[]; max: number; labels: string[] }) {
  const summary = labels.map((label, i) => `${label}: ${values[i]}`).join(", ");
  return (
    <div
      className="flex items-end justify-between gap-1.5 pt-2"
      role="img"
      aria-label={`Gráfico de barras. ${summary}`}
    >
      {values.map((v, i) => (
        <div key={i} className="flex min-w-0 flex-1 flex-col items-center gap-1">
          <div className="flex h-24 w-full items-end justify-center">
            <div
              className="w-full max-w-[28px] rounded-t-[4px] bg-[var(--color-done)]/80 transition-all"
              style={{ height: `${Math.max(4, (v / max) * 100)}%` }}
              title={`${labels[i]}: ${v}`}
              aria-hidden="true"
            />
          </div>
          <span className="type-micro text-[var(--color-text-tertiary)]">{labels[i]}</span>
        </div>
      ))}
    </div>
  );
}
