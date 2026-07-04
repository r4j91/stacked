import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { fetchGoogleCalendarEvents } from "@/lib/google/calendar-server";
import { isGoogleCalendarConfigured } from "@/lib/google/config";

export async function GET(request: Request) {
  if (!isGoogleCalendarConfigured()) {
    return NextResponse.json({ events: [] });
  }

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: "Não autenticado" }, { status: 401 });
  }

  const url = new URL(request.url);
  const fromParam = url.searchParams.get("from");
  const toParam = url.searchParams.get("to");
  if (!fromParam || !toParam) {
    return NextResponse.json({ error: "Parâmetros from e to são obrigatórios" }, { status: 400 });
  }

  const timeMin = new Date(fromParam);
  const timeMax = new Date(toParam);
  if (Number.isNaN(timeMin.getTime()) || Number.isNaN(timeMax.getTime())) {
    return NextResponse.json({ error: "Datas inválidas" }, { status: 400 });
  }

  try {
    const events = await fetchGoogleCalendarEvents(user.id, timeMin, timeMax);
    return NextResponse.json({ events });
  } catch (e) {
    const message = e instanceof Error ? e.message : "Erro ao buscar calendário";
    return NextResponse.json({ error: message, events: [] }, { status: 502 });
  }
}
