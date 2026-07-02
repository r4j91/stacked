"use client";

import { useRef, useState } from "react";
import { AnchoredPopover, type AnchorRect } from "@/components/ui/anchored-popover";
import { DEFAULT_PALETTE_HEX, PALETTE_HEX, PALETTE_PREVIEW_HEX } from "@/lib/theme/palette-colors";

type ColorPalettePickerProps = {
  value: string;
  onChange: (hex: string) => void;
  swatchSize?: "sm" | "md";
};

function Swatch({
  hex,
  selected,
  size,
  onClick,
}: {
  hex: string;
  selected: boolean;
  size: "sm" | "md";
  onClick: () => void;
}) {
  const dim = size === "sm" ? "h-7 w-7" : "h-8 w-8";
  return (
    <button
      type="button"
      onClick={onClick}
      className={`${dim} rounded-full border-2 transition-transform hover:scale-105 ${
        selected ? "border-[var(--color-text)]" : "border-transparent"
      }`}
      style={{ background: hex }}
      aria-label={`Cor ${hex}`}
      aria-pressed={selected}
    />
  );
}

export function ColorPalettePicker({ value, onChange, swatchSize = "md" }: ColorPalettePickerProps) {
  const [moreOpen, setMoreOpen] = useState(false);
  const [moreAnchor, setMoreAnchor] = useState<AnchorRect | null>(null);
  const moreBtnRef = useRef<HTMLButtonElement>(null);

  const resolvedValue = value || DEFAULT_PALETTE_HEX;
  const previewIncludesValue = (PALETTE_PREVIEW_HEX as readonly string[]).includes(resolvedValue);

  function openMore() {
    const rect = moreBtnRef.current?.getBoundingClientRect();
    if (!rect) return;
    setMoreAnchor({
      top: rect.top,
      left: rect.left,
      right: rect.right,
      bottom: rect.bottom,
      width: rect.width,
      height: rect.height,
    });
    setMoreOpen(true);
  }

  return (
    <>
      <div className="flex flex-wrap items-center gap-2">
        {PALETTE_PREVIEW_HEX.map((hex) => (
          <Swatch
            key={hex}
            hex={hex}
            selected={resolvedValue === hex}
            size={swatchSize}
            onClick={() => onChange(hex)}
          />
        ))}
        <button
          ref={moreBtnRef}
          type="button"
          onClick={openMore}
          className={`flex items-center justify-center rounded-full border-2 transition-transform hover:scale-105 ${
            !previewIncludesValue && (PALETTE_HEX as readonly string[]).includes(resolvedValue)
              ? "border-[var(--color-text)]"
              : "border-[var(--color-border)]"
          } ${swatchSize === "sm" ? "h-7 w-7" : "h-8 w-8"}`}
          style={{ background: !previewIncludesValue ? resolvedValue : "var(--color-surface-variant)" }}
          aria-label="Mais cores"
          title="Mais cores"
        >
          {previewIncludesValue && (
            <span className="text-[11px] font-bold text-[var(--color-text-secondary)]">+</span>
          )}
        </button>
      </div>

      <AnchoredPopover
        open={moreOpen}
        onClose={() => setMoreOpen(false)}
        anchorRect={moreAnchor}
        width={248}
        placement="below"
        className="p-3"
      >
        <p className="mb-2 text-[11px] font-semibold uppercase tracking-wide text-[var(--color-text-tertiary)]">
          Paleta completa
        </p>
        <div className="grid grid-cols-8 gap-1.5">
          {PALETTE_HEX.map((hex) => (
            <button
              key={hex}
              type="button"
              onClick={() => {
                onChange(hex);
                setMoreOpen(false);
              }}
              className={`h-6 w-6 rounded-full border-2 transition-transform hover:scale-110 ${
                resolvedValue === hex ? "border-[var(--color-text)]" : "border-transparent"
              }`}
              style={{ background: hex }}
              aria-label={`Cor ${hex}`}
            />
          ))}
        </div>
      </AnchoredPopover>
    </>
  );
}
