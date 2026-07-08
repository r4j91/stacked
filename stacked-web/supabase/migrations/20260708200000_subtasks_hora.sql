-- Hora em subtarefas (paridade com tasks.hora — notificações e exibição)
ALTER TABLE subtasks ADD COLUMN IF NOT EXISTS hora text;
