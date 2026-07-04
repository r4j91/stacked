"use client";

import { useRouter } from "next/navigation";
import { useWorkbench } from "@/components/shell/workbench-context";
import { AnchoredPopover } from "@/components/ui/anchored-popover";
import { AppIcon } from "@/components/ui/app-icon";
import {
  PaintBoardIcon,
  Tag01Icon,
  Logout01Icon,
  UserIcon,
  ArrowRight01Icon,
  KeyboardIcon,
  Calendar03Icon,
} from "@/lib/icons/nav-icons";
import { createClient } from "@/lib/supabase/client";
import { isSupabaseConfigured } from "@/lib/supabase/config";

export function SettingsSheet() {
  const {
    settingsOpen,
    settingsAnchor,
    closeSettings,
    openAppearance,
    openProfile,
    openLabels,
    openShortcuts,
    openCalendar,
  } = useWorkbench();
  const router = useRouter();

  async function signOut() {
    if (isSupabaseConfigured()) {
      await createClient().auth.signOut();
    }
    closeSettings();
    router.replace("/login");
    router.refresh();
  }

  return (
    <AnchoredPopover
      open={settingsOpen}
      onClose={closeSettings}
      anchorRect={settingsAnchor}
      width={260}
      preferSide="right"
      verticalAlign="end"
      className="p-2"
      labelledBy="settings-sheet-title"
    >
      <p
        id="settings-sheet-title"
        className="px-2 pb-1 pt-0.5 text-xs font-semibold uppercase tracking-wide text-[var(--color-text-tertiary)]"
      >
        Configurações
      </p>
      <SettingsLink
        icon={Calendar03Icon}
        label="Calendário"
        onClick={() => {
          const anchor = settingsAnchor;
          closeSettings();
          openCalendar(anchor ?? undefined);
        }}
      />
      <SettingsLink
        icon={UserIcon}
        label="Perfil"
        onClick={() => {
          const anchor = settingsAnchor;
          closeSettings();
          openProfile(anchor ?? undefined);
        }}
      />
      <SettingsLink
        icon={PaintBoardIcon}
        label="Aparência"
        onClick={() => {
          const anchor = settingsAnchor;
          closeSettings();
          openAppearance(anchor ?? undefined);
        }}
      />
      <SettingsLink
        icon={Tag01Icon}
        label="Etiquetas"
        onClick={() => {
          const anchor = settingsAnchor;
          closeSettings();
          openLabels(anchor ?? undefined);
        }}
      />
      <SettingsLink
        icon={KeyboardIcon}
        label="Atalhos"
        onClick={() => {
          const anchor = settingsAnchor;
          closeSettings();
          openShortcuts(anchor ?? undefined);
        }}
      />
      <div className="my-1 h-px bg-[var(--color-border)]" />
      <SettingsLink icon={Logout01Icon} label="Sair" destructive onClick={() => void signOut()} />
    </AnchoredPopover>
  );
}

function SettingsLink({
  icon,
  label,
  onClick,
  destructive,
}: {
  icon: typeof PaintBoardIcon;
  label: string;
  onClick: () => void;
  destructive?: boolean;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`flex w-full min-h-10 items-center gap-2.5 rounded-[var(--radius-sm)] px-2.5 py-2 text-left text-[13px] hover:bg-[var(--color-hover-overlay)] ${
        destructive ? "text-[var(--color-overdue)]" : "text-[var(--color-text)]"
      }`}
    >
      <AppIcon icon={icon} size={17} className="shrink-0 opacity-85" />
      <span className="flex-1">{label}</span>
      {!destructive && <AppIcon icon={ArrowRight01Icon} size={14} className="opacity-35" />}
    </button>
  );
}
