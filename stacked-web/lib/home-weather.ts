/**
 * Clima da Home (paridade iOS HomeWeatherService) — Open-Meteo + geolocation.
 * Cache ~30 min em localStorage; sem permissão/offline → null (header mostra só a data).
 */

const CACHE_KEY = "stacked.homeWeather.v1";
const CACHE_MS = 30 * 60 * 1000;
const COORDS_KEY = "stacked.homeWeather.coords.v1";
const COORDS_MAX_AGE_MS = 7 * 24 * 60 * 60 * 1000;

export type HomeWeatherSnapshot = {
  temperatureC: number;
  /** Label curto estilo iOS weatherDegreeLabel: "24°" */
  degreeLabel: string;
  fetchedAt: number;
};

type CachedPayload = {
  snapshot: HomeWeatherSnapshot;
  expiresAt: number;
};

type CoordsPayload = {
  lat: number;
  lon: number;
  savedAt: number;
};

function readCache(): HomeWeatherSnapshot | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = localStorage.getItem(CACHE_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as CachedPayload;
    if (!parsed?.snapshot || !parsed.expiresAt || parsed.expiresAt <= Date.now()) {
      localStorage.removeItem(CACHE_KEY);
      return null;
    }
    return parsed.snapshot;
  } catch {
    return null;
  }
}

function writeCache(snapshot: HomeWeatherSnapshot) {
  if (typeof window === "undefined") return;
  const payload: CachedPayload = {
    snapshot,
    expiresAt: Date.now() + CACHE_MS,
  };
  localStorage.setItem(CACHE_KEY, JSON.stringify(payload));
}

function readCoords(): { lat: number; lon: number } | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = localStorage.getItem(COORDS_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as CoordsPayload;
    if (
      typeof parsed?.lat !== "number" ||
      typeof parsed?.lon !== "number" ||
      !parsed.savedAt ||
      Date.now() - parsed.savedAt > COORDS_MAX_AGE_MS
    ) {
      return null;
    }
    return { lat: parsed.lat, lon: parsed.lon };
  } catch {
    return null;
  }
}

function writeCoords(lat: number, lon: number) {
  if (typeof window === "undefined") return;
  const payload: CoordsPayload = { lat, lon, savedAt: Date.now() };
  localStorage.setItem(COORDS_KEY, JSON.stringify(payload));
}

function getCurrentPosition(): Promise<GeolocationPosition | null> {
  if (typeof navigator === "undefined" || !navigator.geolocation) {
    return Promise.resolve(null);
  }
  return new Promise((resolve) => {
    navigator.geolocation.getCurrentPosition(
      (pos) => resolve(pos),
      () => resolve(null),
      { enableHighAccuracy: false, timeout: 8000, maximumAge: 20 * 60 * 1000 },
    );
  });
}

async function fetchOpenMeteo(lat: number, lon: number): Promise<HomeWeatherSnapshot | null> {
  const url = new URL("https://api.open-meteo.com/v1/forecast");
  url.searchParams.set("latitude", String(lat));
  url.searchParams.set("longitude", String(lon));
  url.searchParams.set(
    "current",
    "temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m",
  );
  url.searchParams.set("wind_speed_unit", "kmh");
  url.searchParams.set("timezone", "auto");

  try {
    const res = await fetch(url.toString());
    if (!res.ok) return null;
    const data = (await res.json()) as {
      current?: { temperature_2m?: number };
    };
    const temp = data.current?.temperature_2m;
    if (typeof temp !== "number" || Number.isNaN(temp)) return null;
    const temperatureC = Math.round(temp);
    return {
      temperatureC,
      degreeLabel: `${temperatureC}°`,
      fetchedAt: Date.now(),
    };
  } catch {
    return null;
  }
}

/** Snapshot síncrono do cache (evita flash). */
export function peekHomeWeatherCache(): HomeWeatherSnapshot | null {
  return readCache();
}

/** Resolve clima: cache fresco → geolocation → coords salvas → null. */
export async function resolveHomeWeather(): Promise<HomeWeatherSnapshot | null> {
  const cached = readCache();
  if (cached) return cached;

  const position = await getCurrentPosition();
  if (position) {
    const { latitude: lat, longitude: lon } = position.coords;
    writeCoords(lat, lon);
    const live = await fetchOpenMeteo(lat, lon);
    if (live) {
      writeCache(live);
      return live;
    }
  }

  const saved = readCoords();
  if (saved) {
    const fromSaved = await fetchOpenMeteo(saved.lat, saved.lon);
    if (fromSaved) {
      writeCache(fromSaved);
      return fromSaved;
    }
  }

  return null;
}
