"use client";

import { useEffect, useState } from "react";
import {
  peekHomeWeatherCache,
  resolveHomeWeather,
  type HomeWeatherSnapshot,
} from "@/lib/home-weather";

/** Clima da Home — não bloqueia UI; null se sem permissão/offline. */
export function useHomeWeather(): HomeWeatherSnapshot | null {
  const [snapshot, setSnapshot] = useState<HomeWeatherSnapshot | null>(() =>
    peekHomeWeatherCache(),
  );

  useEffect(() => {
    let cancelled = false;
    void resolveHomeWeather().then((next) => {
      if (!cancelled) setSnapshot(next);
    });
    return () => {
      cancelled = true;
    };
  }, []);

  return snapshot;
}
