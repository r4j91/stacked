import type { Priority } from "@/lib/types/task";
import { priorityColor } from "@/lib/utils/priority";
import { AppIcon } from "@/components/ui/app-icon";
import { Tick01Icon } from "@/lib/icons/nav-icons";

/** Paridade iOS DoneCircle.RingStyle.inactiveFillAlpha */
const INACTIVE_RING_FILL = "8%";

type DoneCircleProps = {
  done: boolean;
  small?: boolean;
  /** Cor do anel quando pendente — paridade iOS PriorityDot */
  priority?: Priority | null;
  onClick?: (e: React.MouseEvent) => void;
  label: string;
};

/** Paridade iOS PriorityDot + DoneCircle — prioridade no anel, check verde ao concluir */
export function DoneCircle({ done, small, priority, onClick, label }: DoneCircleProps) {
  const size = small ? "h-[17px] w-[17px]" : "h-5 w-5";
  const iconSize = small ? 10 : 12;
  const ringColor = priorityColor(priority);

  if (done) {
    return (
      <button
        type="button"
        onClick={onClick}
        className={`flex shrink-0 items-center justify-center rounded-full border-2 border-[var(--color-done)] bg-[color-mix(in_srgb,var(--color-done)_15%,transparent)] text-[var(--color-done)] transition-colors ${size}`}
        aria-label={label}
      >
        <AppIcon icon={Tick01Icon} size={iconSize} strokeWidth={2.75} className="text-[var(--color-done)]" />
      </button>
    );
  }

  return (
    <button
      type="button"
      onClick={onClick}
      className={`flex shrink-0 items-center justify-center rounded-full border-2 transition-colors hover:brightness-110 ${size}`}
      style={{
        borderColor: ringColor,
        backgroundColor: `color-mix(in srgb, ${ringColor} ${INACTIVE_RING_FILL}, transparent)`,
      }}
      aria-label={label}
    />
  );
}
