import { createClient } from "@/lib/supabase/client";

export type NoteColor = "mint" | "ash" | "amber" | "violet" | "rose";

export type Note = {
  id: string;
  title: string | null;
  body: string;
  color: NoteColor;
  pinned: boolean;
  createdAt: string;
  updatedAt: string;
};

type NoteRow = {
  id: string;
  title: string | null;
  body: string | null;
  color: string | null;
  pinned: boolean | null;
  created_at: string;
  updated_at: string;
};

const COLORS: NoteColor[] = ["mint", "ash", "amber", "violet", "rose"];

function mapRow(row: NoteRow): Note {
  const color = COLORS.includes(row.color as NoteColor) ? (row.color as NoteColor) : "mint";
  return {
    id: row.id,
    title: row.title,
    body: row.body ?? "",
    color,
    pinned: Boolean(row.pinned),
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export function noteDisplayTitle(note: Note): string {
  const t = note.title?.trim() ?? "";
  if (t) return t;
  const first = note.body.split("\n")[0]?.trim() ?? "";
  return first || "Nota";
}

export function noteTaskSplit(note: Note): { title: string; description: string | null } {
  const t = note.title?.trim() ?? "";
  const body = note.body.trim();
  if (t) return { title: t, description: body || null };
  const lines = body.split("\n");
  const head = lines[0]?.trim() || "Nota";
  const rest = lines.slice(1).join("\n").trim();
  return { title: head, description: rest || null };
}

export class NoteRepository {
  static async list(): Promise<Note[]> {
    const supabase = createClient();
    const { data, error } = await supabase
      .from("notes")
      .select("id, title, body, color, pinned, created_at, updated_at")
      .is("archived_at", null)
      .order("pinned", { ascending: false })
      .order("updated_at", { ascending: false });
    if (error) throw error;
    return (data as NoteRow[] | null)?.map(mapRow) ?? [];
  }

  static async create(input: {
    title?: string | null;
    body: string;
    color: NoteColor;
    pinned?: boolean;
  }): Promise<Note> {
    const supabase = createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) throw new Error("Faça login para salvar notas.");
    const { data, error } = await supabase
      .from("notes")
      .insert({
        user_id: user.id,
        title: input.title?.trim() || null,
        body: input.body,
        color: input.color,
        pinned: input.pinned ?? false,
      })
      .select("id, title, body, color, pinned, created_at, updated_at")
      .single();
    if (error) throw error;
    return mapRow(data as NoteRow);
  }

  static async update(
    id: string,
    input: { title?: string | null; body: string; color: NoteColor; pinned: boolean },
  ): Promise<void> {
    const supabase = createClient();
    const { error } = await supabase
      .from("notes")
      .update({
        title: input.title?.trim() || null,
        body: input.body,
        color: input.color,
        pinned: input.pinned,
      })
      .eq("id", id);
    if (error) throw error;
  }

  static async remove(id: string): Promise<void> {
    const supabase = createClient();
    const { error } = await supabase.from("notes").delete().eq("id", id);
    if (error) throw error;
  }

  static async convertToTask(note: Note): Promise<void> {
    const supabase = createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) throw new Error("Faça login.");
    const { title, description } = noteTaskSplit(note);
    const { error: taskError } = await supabase.from("tasks").insert({
      titulo: title,
      descricao: description,
      user_id: user.id,
      concluida: false,
    });
    if (taskError) throw taskError;
    await this.remove(note.id);
  }
}
