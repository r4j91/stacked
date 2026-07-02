export type ShortcutEntry = {
  keys: string[];
  description: string;
};

export type ShortcutGroup = {
  title: string;
  hint?: string;
  items: ShortcutEntry[];
};

export const SHORTCUT_GROUPS: ShortcutGroup[] = [
  {
    title: "Ações gerais",
    items: [
      { keys: ["Q"], description: "Nova tarefa" },
      { keys: ["⌘", "K"], description: "Buscar (command palette)" },
      { keys: ["⌘", "B"], description: "Recolher / expandir barra lateral" },
      { keys: ["?"], description: "Abrir esta lista de atalhos" },
      { keys: ["Esc"], description: "Fechar painel, menu ou seleção" },
    ],
  },
  {
    title: "Navegação",
    items: [
      { keys: ["⌘", "1"], description: "Início" },
      { keys: ["⌘", "2"], description: "Inbox" },
      { keys: ["⌘", "3"], description: "Hoje" },
      { keys: ["⌘", "4"], description: "Em breve" },
      { keys: ["⌘", "5"], description: "Filtros" },
      { keys: ["⌘", "6"], description: "Concluídas" },
    ],
  },
  {
    title: "Lista de tarefas",
    hint: "Funciona em Hoje, Inbox, Concluídas e dentro de projetos.",
    items: [
      { keys: ["↑", "↓"], description: "Selecionar tarefa acima / abaixo" },
      { keys: ["J", "K"], description: "Mesmo que ↑ / ↓ (estilo Linear)" },
      { keys: ["Enter"], description: "Abrir tarefa no inspector" },
      { keys: ["Space"], description: "Concluir ou reabrir tarefa" },
    ],
  },
  {
    title: "Projetos",
    hint: "Dentro de um projeto, segure o clique (~0,2s) em uma tarefa ou seção e arraste sobre outra para reordenar (mesma seção para tarefas).",
    items: [
      { keys: ["Segurar", "Arrastar"], description: "Reordenar tarefas pendentes na mesma seção" },
      { keys: ["Segurar", "Arrastar"], description: "Reordenar cabeçalhos de seção" },
    ],
  },
];

export const ALL_SHORTCUTS = SHORTCUT_GROUPS.flatMap((g) => g.items);
