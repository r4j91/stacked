export type Project = {
  id: string;
  name: string;
  color: string;
  icon?: string | null;
  pendingCount: number;
};

export type Section = {
  id: string;
  projectId: string;
  name: string;
  order: number;
  createdAt: string;
};
