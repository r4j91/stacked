import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { setImportEnabled } from "@/lib/google/calendar-server";
import { isGoogleCalendarConfigured } from "@/lib/google/config";

export async function PATCH(request: Request) {
  if (!isGoogleCalendarConfigured()) {
    return NextResponse.json({ error: "Não configurado" }, { status: 503 });
  }

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: "Não autenticado" }, { status: 401 });
  }

  const body = (await request.json()) as { importEnabled?: boolean };
  if (typeof body.importEnabled !== "boolean") {
    return NextResponse.json({ error: "importEnabled inválido" }, { status: 400 });
  }

  await setImportEnabled(user.id, body.importEnabled);
  return NextResponse.json({ importEnabled: body.importEnabled });
}
