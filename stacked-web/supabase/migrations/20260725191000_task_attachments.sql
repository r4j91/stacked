-- Anexos de tarefa/subtarefa (imagem ou PDF) via Storage bucket `attachments`.

CREATE TABLE IF NOT EXISTS public.task_attachments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  task_id uuid NOT NULL REFERENCES public.tasks (id) ON DELETE CASCADE,
  subtask_id uuid REFERENCES public.subtasks (id) ON DELETE CASCADE,
  storage_path text NOT NULL,
  file_name text NOT NULL,
  mime_type text NOT NULL,
  size_bytes bigint NOT NULL
    CHECK (size_bytes > 0 AND size_bytes <= 20971520),
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT task_attachments_mime_check CHECK (
    mime_type LIKE 'image/%' OR mime_type = 'application/pdf'
  )
);

COMMENT ON TABLE public.task_attachments IS
  'Metadados de anexos. Arquivos no bucket Storage `attachments` (path = storage_path).';

COMMENT ON COLUMN public.task_attachments.subtask_id IS
  'NULL = anexo da tarefa; preenchido = anexo da subtarefa (task_id continua preenchido).';

CREATE INDEX IF NOT EXISTS idx_task_attachments_task
  ON public.task_attachments (task_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_task_attachments_subtask
  ON public.task_attachments (subtask_id, created_at DESC)
  WHERE subtask_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_task_attachments_user
  ON public.task_attachments (user_id, created_at DESC);

ALTER TABLE public.task_attachments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS task_attachments_select_own ON public.task_attachments;
CREATE POLICY task_attachments_select_own
  ON public.task_attachments FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS task_attachments_insert_own ON public.task_attachments;
CREATE POLICY task_attachments_insert_own
  ON public.task_attachments FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS task_attachments_delete_own ON public.task_attachments;
CREATE POLICY task_attachments_delete_own
  ON public.task_attachments FOR DELETE
  USING (auth.uid() = user_id);

-- Bucket privado; path: {user_id}/{attachment_id}/{filename}
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'attachments',
  'attachments',
  false,
  20971520,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS attachments_storage_select_own ON storage.objects;
CREATE POLICY attachments_storage_select_own
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'attachments'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS attachments_storage_insert_own ON storage.objects;
CREATE POLICY attachments_storage_insert_own
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'attachments'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS attachments_storage_update_own ON storage.objects;
CREATE POLICY attachments_storage_update_own
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'attachments'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS attachments_storage_delete_own ON storage.objects;
CREATE POLICY attachments_storage_delete_own
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'attachments'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );
