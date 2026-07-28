"use client";

import { useEffect, useRef, useState } from "react";
import type { Priority } from "@/lib/types/task";
import { priorityColor } from "@/lib/utils/priority";
import { AppIcon } from "@/components/ui/app-icon";
import { Tick01Icon } from "@/lib/icons/nav-icons";

/** Paridade iOS DoneCircle.RingStyle.inactiveFillAlpha */
const INACTIVE_RING_FILL = "8%";

type DoneCircleProps = {
  done: boolean;
  small?: boolean;
  /** Cor do anel/fill — prioridade; sem prioridade = terciário (cinza) */
  priority?: Priority | null;
  onClick?: (e: React.MouseEvent) => void;
  label: string;
};

/** Paridade iOS DoneCircle — concluído = fill sólido da prioridade + ✓ branco */
export function DoneCircle({ done, small, priority, onClick, label }: DoneCircleProps) {
  const size = small ? "h-[17px] w-[17px]" : "h-[22px] w-[22px]";
  const iconSize = small ? 10 : 13;
  const accent = priorityColor(priority);
  const prevDone = useRef(done);
  const [pop, setPop] = useState(false);

  useEffect(() => {
    const wasDone = prevDone.current;
    prevDone.current = done;
    if (done && !wasDone) {
      setPop(true);
      const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
      if (reduce) {
        setPop(false);
        return;
      }
      const t = window.setTimeout(() => setPop(false), 340);
      return () => window.clearTimeout(t);
    }
    if (!done && wasDone) setPop(false);
  }, [done]);

  if (done) {
    return (
      <button
        type="button"
        onClick={onClick}
        className={`done-circle done-circle--done flex shrink-0 items-center justify-center rounded-full border-2 text-white ${size} ${
          pop ? "done-circle--pop" : ""
        }`}
        style={{
          borderColor: accent,
          backgroundColor: accent,
          color: "#fff",
        }}
        aria-label={label}
      >
        <AppIcon
          icon={Tick01Icon}
          size={iconSize}
          strokeWidth={2.75}
          className={`done-circle__tick text-white ${pop ? "done-circle__tick--pop" : ""}`}
        />
      </button>
    );
  }

  return (
    <button
      type="button"
      onClick={onClick}
      className={`done-circle flex shrink-0 items-center justify-center rounded-full border-2 transition-colors hover:brightness-110 ${size}`}
      style={{
        borderColor: accent,
        backgroundColor: `color-mix(in srgb, ${accent} ${INACTIVE_RING_FILL}, transparent)`,
      }}
      aria-label={label}
    />
  );
}
