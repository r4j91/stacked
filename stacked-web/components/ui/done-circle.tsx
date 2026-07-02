import { AppIcon } from "@/components/ui/app-icon";
import { Tick01Icon } from "@/lib/icons/nav-icons";

type DoneCircleProps = {
  done: boolean;
  small?: boolean;
  onClick?: (e: React.MouseEvent) => void;
  label: string;
};

/** Paridade Flutter DoneCircle — fundo verde translúcido + borda + check */
export function DoneCircle({ done, small, onClick, label }: DoneCircleProps) {
  const size = small ? "h-[17px] w-[17px]" : "h-5 w-5";
  const iconSize = small ? 10 : 12;

  return (
    <button
      type="button"
      onClick={onClick}
      className={`flex shrink-0 items-center justify-center rounded-full border-2 transition-colors ${size} ${
        done
          ? "border-[var(--color-done)] bg-[color-mix(in_srgb,var(--color-done)_15%,transparent)] text-[var(--color-done)]"
          : "border-[var(--color-text-tertiary)] bg-transparent hover:border-[var(--color-text-secondary)]"
      }`}
      aria-label={label}
    >
      {done && <AppIcon icon={Tick01Icon} size={iconSize} strokeWidth={2.75} className="text-[var(--color-done)]" />}
    </button>
  );
}
