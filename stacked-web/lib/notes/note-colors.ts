import type { NoteColor } from "@/lib/repositories/note-repository";

export const NOTE_COLOR_STYLE: Record<
  NoteColor,
  { bg: string; ink: string; rot: string }
> = {
  mint: { bg: "#1F3A36", ink: "#C8F0EA", rot: "-1.2deg" },
  ash: { bg: "#2A2E36", ink: "#E4E8EE", rot: "1deg" },
  amber: { bg: "#3A2E1A", ink: "#F5E0B8", rot: "0.8deg" },
  violet: { bg: "#2C2438", ink: "#E4D4F8", rot: "-0.6deg" },
  rose: { bg: "#3A2226", ink: "#F5C8CE", rot: "1.4deg" },
};

export const NOTE_COLORS = Object.keys(NOTE_COLOR_STYLE) as NoteColor[];
