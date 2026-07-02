"use client";

import { useRef } from "react";
import { useDebouncedCallback } from "@/lib/hooks/use-debounced-callback";

type AutosaveTextareaProps = {
  value: string;
  onChange: (value: string) => void;
  onSave: (value: string) => void | Promise<void>;
  className?: string;
  placeholder?: string;
  "aria-label"?: string;
  rows?: number;
  debounceMs?: number;
};

export function AutosaveTextarea({
  value,
  onChange,
  onSave,
  className,
  placeholder,
  "aria-label": ariaLabel,
  rows = 1,
  debounceMs = 600,
}: AutosaveTextareaProps) {
  const latestRef = useRef(value);
  latestRef.current = value;

  const debouncedSave = useDebouncedCallback((text: string) => {
    void onSave(text);
  }, debounceMs);

  return (
    <textarea
      className={className}
      value={value}
      placeholder={placeholder}
      aria-label={ariaLabel}
      rows={rows}
      onChange={(e) => {
        const next = e.target.value;
        onChange(next);
        debouncedSave(next);
      }}
      onBlur={() => {
        void onSave(latestRef.current);
      }}
    />
  );
}
