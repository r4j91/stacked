"use client";

import { useCallback, useEffect, useState } from "react";
import {
  DEFAULT_SAVED_FILTER_SORT_MODE,
  loadSavedFilterSortMode,
  saveSavedFilterSortMode,
  type SavedFilterSortMode,
} from "@/lib/utils/saved-filter-sort";

/** Persiste a ordenação por id de filtro (salvo ou preset) — chave `saved_filter_sort_${id}`. */
export function useSavedFilterSort(filterId: string | null | undefined) {
  const [mode, setMode] = useState<SavedFilterSortMode>(DEFAULT_SAVED_FILTER_SORT_MODE);

  useEffect(() => {
    setMode(filterId ? loadSavedFilterSortMode(filterId) : DEFAULT_SAVED_FILTER_SORT_MODE);
  }, [filterId]);

  const setSortMode = useCallback(
    (next: SavedFilterSortMode) => {
      setMode(next);
      if (filterId) saveSavedFilterSortMode(filterId, next);
    },
    [filterId],
  );

  return [mode, setSortMode] as const;
}
