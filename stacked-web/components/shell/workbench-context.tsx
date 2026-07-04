"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from "react";
import { usePathname, useRouter } from "next/navigation";
import type { Project, Section } from "@/lib/types/project";
import type { Label } from "@/lib/types/label";
import type {
  Priority,
  Subtask,
  Task,
  TodayStats,
  ViewMode,
  ViewTasks,
  FilterDashboardCounts,
} from "@/lib/types/task";
import { useToast } from "@/components/ui/toast-provider";
import { LabelRepository } from "@/lib/repositories/label-repository";
import { CommentRepository } from "@/lib/repositories/comment-repository";
import { computeNextRecurrenceDate, parseRecurrence } from "@/lib/utils/recurrence";
import { toDateStr, parseDueDate, formatTaskDate, startOfDay } from "@/lib/utils/date";
import {
  MOCK_TASKS,
  mockProjectById,
  mockProjectTasks,
  mockProjectsAsSidebar,
  mockSectionsForProject,
  mockDatedPendingTasks,
  mockAllPendingTasks,
  mockFilterCounts,
} from "@/lib/data/mock-tasks";
import { createClient } from "@/lib/supabase/client";
import { isSupabaseConfigured } from "@/lib/supabase/config";
import { ProjectRepository } from "@/lib/repositories/project-repository";
import { SectionRepository } from "@/lib/repositories/section-repository";
import { TaskRepository } from "@/lib/repositories/task-repository";
import { TaskPersistence } from "@/lib/repositories/task-persistence";
import { splitTodayPending } from "@/lib/supabase/map-task";

export type NavCounts = { inbox: number; today: number };
export type SubtaskKey = `${string}:${number}`;
import type { UserProfile } from "@/lib/types/user-profile";
import type { CalendarEvent, GoogleCalendarStatus } from "@/lib/types/calendar-event";
import {
  fetchGoogleCalendarEvents,
  fetchGoogleCalendarStatus,
} from "@/lib/services/google-calendar-client";
import type { AnchorRect } from "@/components/ui/anchored-popover";
import { profileFromUser } from "@/lib/services/profile-service";
import type { ReorderDropKind } from "@/lib/hooks/use-hold-to-reorder";
export type QuickAddOptions = { projectId?: string | null; sectionId?: string | null };

const MOCK_LABELS: Label[] = [
  { id: "l1", name: "Em Andamento", color: "#8FD46B" },
  { id: "l2", name: "Ideia", color: "#B18CF5" },
];

const SHOW_COMPLETED_KEY = "stacked-show-completed";
const NAV_ROUTES = ["/home", "/inbox", "/today", "/upcoming", "/filters", "/done"] as const;

function resolveRoute(pathname: string): { view: ViewMode; projectId: string | null } {
  const projectMatch = pathname.match(/^\/projects\/([^/]+)/);
  if (projectMatch) return { view: "project", projectId: projectMatch[1] };
  const viewMap: Record<string, ViewMode> = {
    "/today": "today",
    "/inbox": "inbox",
    "/upcoming": "upcoming",
    "/done": "done",
    "/filters": "filters",
  };
  return { view: viewMap[pathname] ?? "today", projectId: null };
}

type WorkbenchContextValue = {
  view: ViewMode;
  projectId: string | null;
  currentProject: Project | null;
  projects: Project[];
  sections: Section[];
  viewTasks: ViewTasks;
  todayStats: TodayStats;
  navCounts: NavCounts;
  loading: boolean;
  error: string | null;
  usingMock: boolean;
  collapsedSectionIds: Set<string>;
  projectCompletedExpanded: boolean;
  selectedTaskId: string | null;
  selectedSubtaskKey: SubtaskKey | null;
  expandedSubtasks: Set<string>;
  sidebarCollapsed: boolean;
  inspectorOpen: boolean;
  paletteOpen: boolean;
  searchTasks: Task[];
  filterCounts: FilterDashboardCounts;
  openPalette: () => void;
  closePalette: () => void;
  openTaskInspector: (task: Task) => void;
  refreshTasks: () => Promise<void>;
  selectTask: (id: string | null) => void;
  selectSubtask: (taskId: string, index: number) => void;
  clearSubtaskSelection: () => void;
  closeInspector: () => void;
  toggleSubtaskExpand: (taskId: string) => void;
  toggleTaskDone: (id: string) => void;
  toggleSubtaskDone: (key: SubtaskKey) => void;
  autosaveTaskTitle: (id: string, title: string) => Promise<void>;
  autosaveTaskNotes: (id: string, notes: string) => Promise<void>;
  autosaveSubtaskTitle: (key: SubtaskKey, title: string) => Promise<void>;
  autosaveSubtaskNotes: (key: SubtaskKey, notes: string) => Promise<void>;
  updateSubtaskPriority: (key: SubtaskKey, priority: Priority | null) => Promise<void>;
  updateSubtaskDueDate: (key: SubtaskKey, dueDate: string | null) => Promise<void>;
  updateSubtaskLabels: (key: SubtaskKey, labelIds: string[]) => Promise<void>;
  toggleSidebar: () => void;
  toggleSectionCollapsed: (sectionId: string) => void;
  toggleProjectCompletedExpanded: () => void;
  createSection: (name: string) => Promise<void>;
  renameSection: (sectionId: string, name: string) => Promise<void>;
  deleteSection: (sectionId: string) => Promise<void>;
  getSubtaskContext: (key?: SubtaskKey | null) => {
    task: Task;
    index: number;
    sub: Subtask;
  } | null;
  selectedTask: Task | null;
  allTasks: Task[];
  /** Perfil do usuário autenticado (Supabase) */
  userProfile: UserProfile;
  /** Etiquetas disponíveis */
  labels: Label[];
  quickAddOpen: boolean;
  quickAddInitial: QuickAddOptions;
  settingsOpen: boolean;
  appearanceOpen: boolean;
  profileOpen: boolean;
  productivityOpen: boolean;
  settingsAnchor: AnchorRect | null;
  appearanceAnchor: AnchorRect | null;
  profileAnchor: AnchorRect | null;
  productivityAnchor: AnchorRect | null;
  labelsAnchor: AnchorRect | null;
  labelsOpen: boolean;
  shortcutsOpen: boolean;
  shortcutsAnchor: AnchorRect | null;
  calendarOpen: boolean;
  calendarAnchor: AnchorRect | null;
  calendarEvents: CalendarEvent[];
  googleCalendar: GoogleCalendarStatus;
  calendarError: string | null;
  showCompleted: Partial<Record<ViewMode, boolean>>;
  openQuickAdd: (opts?: QuickAddOptions) => void;
  closeQuickAdd: () => void;
  openSettings: (anchor?: AnchorRect) => void;
  closeSettings: () => void;
  openAppearance: (anchor?: AnchorRect) => void;
  closeAppearance: () => void;
  openProfile: (anchor?: AnchorRect) => void;
  closeProfile: () => void;
  openProductivity: (anchor?: AnchorRect) => void;
  closeProductivity: () => void;
  refreshUserProfile: () => Promise<void>;
  openLabels: (anchor?: AnchorRect) => void;
  closeLabels: () => void;
  openShortcuts: (anchor?: AnchorRect) => void;
  closeShortcuts: () => void;
  openCalendar: (anchor?: AnchorRect) => void;
  closeCalendar: () => void;
  refreshGoogleCalendar: () => Promise<void>;
  toggleShowCompleted: (mode?: ViewMode) => void;
  isShowCompleted: (mode?: ViewMode) => boolean;
  createTask: (input: {
    title: string;
    description?: string;
    priority?: Priority;
    projectId?: string | null;
    sectionId?: string | null;
    dueDate?: string | null;
    labelIds?: string[];
  }) => Promise<void>;
  deleteTask: (id: string) => Promise<void>;
  deferTask: (id: string) => Promise<void>;
  duplicateTask: (id: string) => Promise<void>;
  reorderProjectTasks: (draggedId: string, targetId: string, targetKind?: ReorderDropKind) => Promise<void>;
  reorderSections: (draggedId: string, targetId: string) => Promise<void>;
  updateTaskPriority: (id: string, priority: Priority | null) => Promise<void>;
  updateTaskDueDate: (id: string, dueDate: string | null) => Promise<void>;
  updateTaskProject: (id: string, projectId: string | null) => Promise<void>;
  updateTaskProjectAndSection: (
    id: string,
    projectId: string | null,
    sectionId: string | null,
  ) => Promise<void>;
  getProjectSections: (projectId: string) => Promise<Section[]>;
  updateTaskLabels: (id: string, labelIds: string[]) => Promise<void>;
  updateTaskRecurrence: (id: string, recurrence: string | null) => Promise<void>;
  createSubtask: (taskId: string, title: string) => Promise<void>;
  deleteSubtask: (key: SubtaskKey) => Promise<void>;
  addComment: (taskId: string, text: string) => Promise<void>;
  createLabel: (name: string, color: string) => Promise<void>;
  updateLabel: (id: string, patch: { name?: string; color?: string }) => Promise<void>;
  deleteLabel: (id: string) => Promise<void>;
  projectSheetOpen: boolean;
  projectSheetMode: "create" | "edit";
  projectSheetProject: Project | null;
  openProjectCreate: () => void;
  openProjectEdit: (projectId: string) => void;
  closeProjectSheet: () => void;
  createProject: (name: string, color: string, icon?: string) => Promise<void>;
  updateProject: (id: string, patch: { name?: string; color?: string; icon?: string }) => Promise<void>;
  deleteProject: (id: string) => Promise<void>;
};

const WorkbenchContext = createContext<WorkbenchContextValue | null>(null);
const SIDEBAR_KEY = "stacked-sidebar-collapsed";

function mockViewTasks(mode: ViewMode, projectId: string | null): ViewTasks {
  if (mode === "project" && projectId) return mockProjectTasks(projectId);
  if (mode === "upcoming") {
    const pending = mockDatedPendingTasks();
    return { pending, completed: [] };
  }
  if (mode === "today") {
    const pending = MOCK_TASKS.filter((t) => !t.done);
    const completed = MOCK_TASKS.filter((t) => t.done);
    const { overdue, today } = splitTodayPending(pending);
    return { pending, completed, overdue, today };
  }
  return { pending: MOCK_TASKS.filter((t) => !t.done), completed: MOCK_TASKS.filter((t) => t.done) };
}

function mockProjectsList(): Project[] {
  return mockProjectsAsSidebar().map((p) => ({
    id: p.id,
    name: p.name,
    color: p.color,
    icon: p.icon ?? "folder",
    pendingCount: p.count,
  }));
}

export function WorkbenchProvider({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const { showToast } = useToast();
  const { view, projectId } = resolveRoute(pathname);

  const [viewTasks, setViewTasks] = useState<ViewTasks>({ pending: [], completed: [] });
  const [projects, setProjects] = useState<Project[]>([]);
  const [currentProject, setCurrentProject] = useState<Project | null>(null);
  const [sections, setSections] = useState<Section[]>([]);
  const [navCounts, setNavCounts] = useState<NavCounts>({ inbox: 0, today: 0 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [usingMock, setUsingMock] = useState(false);
  const [collapsedSectionIds, setCollapsedSectionIds] = useState<Set<string>>(new Set());
  const [projectCompletedExpanded, setProjectCompletedExpanded] = useState(false);
  const [selectedTaskId, setSelectedTaskId] = useState<string | null>(null);
  const [selectedSubtaskKey, setSelectedSubtaskKey] = useState<SubtaskKey | null>(null);
  const [expandedSubtasks, setExpandedSubtasks] = useState<Set<string>>(new Set());
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [paletteOpen, setPaletteOpen] = useState(false);
  const [searchTasks, setSearchTasks] = useState<Task[]>([]);
  const [filterCounts, setFilterCounts] = useState<FilterDashboardCounts>(mockFilterCounts());
  const [inspectorOverride, setInspectorOverride] = useState<Task | null>(null);
  const [userProfile, setUserProfile] = useState<UserProfile>({
    name: "",
    email: "",
    avatarUrl: null,
    apelido: "",
    nome: "",
  });
  const [labels, setLabels] = useState<Label[]>([]);
  const [quickAddOpen, setQuickAddOpen] = useState(false);
  const [quickAddInitial, setQuickAddInitial] = useState<QuickAddOptions>({});
  const [settingsOpen, setSettingsOpen] = useState(false);
  const [appearanceOpen, setAppearanceOpen] = useState(false);
  const [profileOpen, setProfileOpen] = useState(false);
  const [productivityOpen, setProductivityOpen] = useState(false);
  const [settingsAnchor, setSettingsAnchor] = useState<AnchorRect | null>(null);
  const [appearanceAnchor, setAppearanceAnchor] = useState<AnchorRect | null>(null);
  const [profileAnchor, setProfileAnchor] = useState<AnchorRect | null>(null);
  const [productivityAnchor, setProductivityAnchor] = useState<AnchorRect | null>(null);
  const [labelsAnchor, setLabelsAnchor] = useState<AnchorRect | null>(null);
  const [labelsOpen, setLabelsOpen] = useState(false);
  const [shortcutsOpen, setShortcutsOpen] = useState(false);
  const [shortcutsAnchor, setShortcutsAnchor] = useState<AnchorRect | null>(null);
  const [calendarOpen, setCalendarOpen] = useState(false);
  const [calendarAnchor, setCalendarAnchor] = useState<AnchorRect | null>(null);
  const [calendarEvents, setCalendarEvents] = useState<CalendarEvent[]>([]);
  const [googleCalendar, setGoogleCalendar] = useState<GoogleCalendarStatus>({
    configured: false,
    connected: false,
    email: null,
    importEnabled: false,
  });
  const [calendarError, setCalendarError] = useState<string | null>(null);
  const [showCompleted, setShowCompleted] = useState<Partial<Record<ViewMode, boolean>>>({});
  const [projectSheetOpen, setProjectSheetOpen] = useState(false);
  const [projectSheetMode, setProjectSheetMode] = useState<"create" | "edit">("create");
  const [projectSheetProject, setProjectSheetProject] = useState<Project | null>(null);
  const pendingDeletesRef = useRef<
    Map<string, { timer: ReturnType<typeof setTimeout>; snapshot: { task: Task; wasPending: boolean } }>
  >(new Map());

  const allTasks = useMemo(
    () => [...viewTasks.pending, ...viewTasks.completed],
    [viewTasks],
  );

  const todayStats = useMemo<TodayStats>(
    () => ({
      overdue: viewTasks.overdue?.length ?? 0,
      today: viewTasks.today?.length ?? viewTasks.pending.length,
      completed: viewTasks.completed.length,
    }),
    [viewTasks],
  );

  const refreshGoogleCalendar = useCallback(async () => {
    if (!isSupabaseConfigured()) {
      setGoogleCalendar({ configured: false, connected: false, email: null, importEnabled: false });
      setCalendarEvents([]);
      return;
    }
    try {
      const status = await fetchGoogleCalendarStatus();
      setGoogleCalendar(status);
    } catch {
      setGoogleCalendar({ configured: false, connected: false, email: null, importEnabled: false });
    }
  }, []);

  const loadCalendarEvents = useCallback(async (mode: ViewMode) => {
    if (!isSupabaseConfigured() || (mode !== "today" && mode !== "upcoming")) {
      setCalendarEvents([]);
      setCalendarError(null);
      return;
    }

    const status = await fetchGoogleCalendarStatus();
    setGoogleCalendar(status);

    if (!status.connected || !status.importEnabled) {
      setCalendarEvents([]);
      setCalendarError(null);
      return;
    }

    const start = startOfDay(new Date());
    const end =
      mode === "today"
        ? new Date(start.getTime() + 86400000)
        : new Date(start.getTime() + 86400000 * 120);

    try {
      const events = await fetchGoogleCalendarEvents(start, end);
      setCalendarEvents(events);
      setCalendarError(null);
    } catch (e) {
      setCalendarEvents([]);
      setCalendarError(e instanceof Error ? e.message : "Erro ao carregar calendário");
    }
  }, []);

  const refreshTasks = useCallback(async () => {
    setLoading(true);
    setError(null);

    if (!isSupabaseConfigured()) {
      setUsingMock(true);
      setProjects(mockProjectsList());
      setViewTasks(mockViewTasks(view, projectId));
      setSections(projectId ? mockSectionsForProject(projectId) : []);
      setCurrentProject(
        projectId
          ? (() => {
              const p = mockProjectById(projectId);
              return p
                ? { id: p.id, name: p.name, color: p.color, icon: p.icon ?? "folder", pendingCount: p.count }
                : null;
            })()
          : null,
      );
      setNavCounts({
        inbox: MOCK_TASKS.filter((t) => !t.done && !t.dueDate && !t.projectId).length,
        today: MOCK_TASKS.filter((t) => !t.done).length,
      });
      setFilterCounts(mockFilterCounts());
      setSearchTasks(mockAllPendingTasks());
      setLabels(MOCK_LABELS);
      setUserProfile({ name: "Rodrigo", email: "dev@stacked.app", avatarUrl: null, apelido: "Rodrigo", nome: "Rodrigo" });
      setCalendarEvents([]);
      setCalendarError(null);
      setLoading(false);
      return;
    }

    try {
      const client = createClient();
      const taskRepo = new TaskRepository(client);
      const projectRepo = new ProjectRepository(client);

      const loads: Promise<unknown>[] = [
        taskRepo.loadView(view, projectId),
        projectRepo.fetchProjects(),
        taskRepo.fetchNavCounts(),
        taskRepo.fetchFilterDashboardCounts(),
        taskRepo.fetchAllPendingTasks(),
        new LabelRepository(client).fetchLabels(),
      ];

      if (view === "project" && projectId) {
        loads.push(projectRepo.fetchProjectById(projectId));
        loads.push(new SectionRepository(client).getSectionsForProject(projectId));
      }

      const results = await Promise.all(loads);
      const data = results[0] as ViewTasks;
      const projectList = results[1] as Project[];
      const counts = results[2] as NavCounts;
      const filterDashboard = results[3] as FilterDashboardCounts;
      const search = results[4] as Task[];
      const labelList = results[5] as Label[];

      const {
        data: { user },
      } = await client.auth.getUser();
      if (user) {
        setUserProfile(profileFromUser(user));
      }

      setUsingMock(false);
      setViewTasks(data);
      setProjects(projectList);
      setNavCounts(counts);
      setFilterCounts(filterDashboard);
      setSearchTasks(search);
      setLabels(labelList);

      if (view === "project" && projectId) {
        setCurrentProject((results[6] as Project | null) ?? null);
        setSections((results[7] as Section[]) ?? []);
      } else {
        setCurrentProject(null);
        setSections([]);
      }
      await loadCalendarEvents(view);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Erro ao carregar tarefas");
      setUsingMock(true);
      setProjects(mockProjectsList());
      setViewTasks(mockViewTasks(view, projectId));
      setSections(projectId ? mockSectionsForProject(projectId) : []);
      setCurrentProject(
        projectId && mockProjectById(projectId)
          ? {
              id: projectId,
              name: mockProjectById(projectId)!.name,
              color: mockProjectById(projectId)!.color,
              icon: mockProjectById(projectId)!.icon ?? "folder",
              pendingCount: mockProjectById(projectId)!.count,
            }
          : null,
      );
      setNavCounts({ inbox: 0, today: 0 });
      setFilterCounts(mockFilterCounts());
      setSearchTasks(mockAllPendingTasks());
      setLabels(MOCK_LABELS);
      setUserProfile({ name: "Rodrigo", email: "dev@stacked.app", avatarUrl: null, apelido: "Rodrigo", nome: "Rodrigo" });
    } finally {
      setLoading(false);
    }
  }, [view, projectId, loadCalendarEvents]);

  useEffect(() => {
    setSelectedTaskId(null);
    setSelectedSubtaskKey(null);
    refreshTasks();
  }, [refreshTasks]);

  useEffect(() => {
    const stored = localStorage.getItem(SIDEBAR_KEY);
    if (stored === "true") setSidebarCollapsed(true);
    try {
      const sc = localStorage.getItem(SHOW_COMPLETED_KEY);
      if (sc) setShowCompleted(JSON.parse(sc) as Partial<Record<ViewMode, boolean>>);
    } catch {
      /* ignore */
    }
  }, []);

  useEffect(() => {
    localStorage.setItem(SHOW_COMPLETED_KEY, JSON.stringify(showCompleted));
  }, [showCompleted]);

  useEffect(() => {
    localStorage.setItem(SIDEBAR_KEY, String(sidebarCollapsed));
  }, [sidebarCollapsed]);

  useEffect(() => {
    if (!isSupabaseConfigured() || usingMock) return;
    const client = createClient();
    const channel = client
      .channel("tasks-realtime")
      .on("postgres_changes", { event: "*", schema: "public", table: "tasks" }, () => {
        void refreshTasks();
      })
      .subscribe();
    return () => {
      void client.removeChannel(channel);
    };
  }, [refreshTasks, usingMock]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement | null;
      const typing =
        target?.tagName === "INPUT" ||
        target?.tagName === "TEXTAREA" ||
        target?.isContentEditable;

      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault();
        setPaletteOpen((o) => !o);
        return;
      }
      if (paletteOpen || typing) return;

      if (e.key === "q" || e.key === "Q") {
        e.preventDefault();
        setQuickAddInitial({});
        setQuickAddOpen(true);
        return;
      }
      if (e.key === "?" || (e.shiftKey && e.key === "/")) {
        e.preventDefault();
        setShortcutsAnchor(null);
        setShortcutsOpen(true);
        return;
      }
      if ((e.metaKey || e.ctrlKey) && e.key >= "1" && e.key <= "6") {
        e.preventDefault();
        router.push(NAV_ROUTES[Number(e.key) - 1]);
        return;
      }
      if ((e.metaKey || e.ctrlKey) && e.key === "b") {
        e.preventDefault();
        setSidebarCollapsed((c) => !c);
      }
      if (e.key === "Escape") {
        if (shortcutsOpen) {
          setShortcutsOpen(false);
          setShortcutsAnchor(null);
        }
        else if (quickAddOpen) setQuickAddOpen(false);
        else if (profileOpen) {
          setProfileOpen(false);
          setProfileAnchor(null);
        } else if (productivityOpen) {
          setProductivityOpen(false);
          setProductivityAnchor(null);
        } else if (settingsOpen) {
          setSettingsOpen(false);
          setSettingsAnchor(null);
        } else if (calendarOpen) {
          setCalendarOpen(false);
          setCalendarAnchor(null);
        } else if (appearanceOpen) {
          setAppearanceOpen(false);
          setAppearanceAnchor(null);
        }
        else if (labelsOpen) {
          setLabelsOpen(false);
          setLabelsAnchor(null);
        }
        else if (selectedSubtaskKey) setSelectedSubtaskKey(null);
        else if (selectedTaskId) {
          setSelectedTaskId(null);
          setInspectorOverride(null);
        }
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [
    paletteOpen,
    quickAddOpen,
    shortcutsOpen,
    settingsOpen,
    appearanceOpen,
    calendarOpen,
    profileOpen,
    productivityOpen,
    labelsOpen,
    selectedSubtaskKey,
    selectedTaskId,
    router,
  ]);

  const getSubtaskContext = useCallback(
    (key: SubtaskKey | null = selectedSubtaskKey) => {
      if (!key) return null;
      const [taskId, indexStr] = key.split(":");
      const task = allTasks.find((t) => t.id === taskId);
      const index = Number(indexStr);
      const sub = task?.subtasks?.[index];
      if (!task || !sub) return null;
      return { task, index, sub };
    },
    [allTasks, selectedSubtaskKey],
  );

  const selectedTask = useMemo(() => {
    if (!selectedTaskId) return null;
    return (
      allTasks.find((t) => t.id === selectedTaskId) ??
      (inspectorOverride?.id === selectedTaskId ? inspectorOverride : null)
    );
  }, [allTasks, selectedTaskId, inspectorOverride]);

  const patchTaskInView = useCallback((id: string, patch: Partial<Task>) => {
    const map = (list: Task[]) => list.map((t) => (t.id === id ? { ...t, ...patch } : t));
    setViewTasks((prev) => ({
      ...prev,
      pending: map(prev.pending),
      completed: map(prev.completed),
      overdue: prev.overdue ? map(prev.overdue) : undefined,
      today: prev.today ? map(prev.today) : undefined,
    }));
  }, []);

  const removeTaskFromView = useCallback((id: string) => {
    const filter = (list: Task[]) => list.filter((t) => t.id !== id);
    setViewTasks((prev) => ({
      ...prev,
      pending: filter(prev.pending),
      completed: filter(prev.completed),
      overdue: prev.overdue ? filter(prev.overdue) : undefined,
      today: prev.today ? filter(prev.today) : undefined,
    }));
  }, []);

  const restoreTaskToView = useCallback((snapshot: { task: Task; wasPending: boolean }) => {
    const { task, wasPending } = snapshot;
    setViewTasks((prev) => {
      if (wasPending) {
        return { ...prev, pending: [...prev.pending, task] };
      }
      return { ...prev, completed: [...prev.completed, task] };
    });
  }, []);

  const handleRecurrenceOnComplete = useCallback(
    async (task: Task) => {
      if (!task.recurrence || !task.dueDate) return;
      const recurrence = parseRecurrence(task.recurrence);
      if (!recurrence) return;
      const due = new Date(`${task.dueDate}T12:00:00`);
      const next = computeNextRecurrenceDate(due, recurrence);
      if (!next) return;

      if (usingMock || !isSupabaseConfigured()) {
        showToast("Próxima ocorrência criada");
        return;
      }

      try {
        const client = createClient();
        const taskRepo = new TaskRepository(client);
        const userId = (await client.auth.getUser()).data.user?.id;
        const { data: inserted, error } = await client
          .from("tasks")
          .insert({
            titulo: task.title,
            descricao: task.notes ?? null,
            prioridade: task.priority === "P1" ? "high" : task.priority === "P2" ? "medium" : task.priority === "P3" ? "low" : null,
            project_id: task.projectId ?? null,
            section_id: task.sectionId ?? null,
            data_vencimento: toDateStr(next),
            hora: task.time ?? null,
            recorrencia: task.recurrence,
            concluida: false,
            ...(userId ? { user_id: userId } : {}),
          })
          .select("id")
          .single();
        if (error) throw error;
        const newId = String(inserted.id);
        if (task.labelIds?.length) {
          await new LabelRepository(client).setTaskLabels(newId, task.labelIds);
        }
        showToast("Próxima ocorrência criada");
        await refreshTasks();
      } catch {
        showToast("Erro ao criar próxima ocorrência");
      }
    },
    [refreshTasks, showToast, usingMock],
  );

  const selectTask = useCallback((id: string | null) => {
    setSelectedTaskId(id);
    setSelectedSubtaskKey(null);
    setInspectorOverride(null);
  }, []);

  const selectSubtask = useCallback((taskId: string, index: number) => {
    setSelectedTaskId(taskId);
    setSelectedSubtaskKey(`${taskId}:${index}`);
    setExpandedSubtasks((prev) => new Set(prev).add(taskId));
  }, []);

  const clearSubtaskSelection = useCallback(() => setSelectedSubtaskKey(null), []);

  const closeInspector = useCallback(() => {
    setSelectedTaskId(null);
    setSelectedSubtaskKey(null);
    setInspectorOverride(null);
  }, []);

  const openPalette = useCallback(() => setPaletteOpen(true), []);
  const closePalette = useCallback(() => setPaletteOpen(false), []);

  const openTaskInspector = useCallback((task: Task) => {
    setInspectorOverride(task);
    setSelectedTaskId(task.id);
    setSelectedSubtaskKey(null);
  }, []);

  const toggleSubtaskExpand = useCallback((taskId: string) => {
    setExpandedSubtasks((prev) => {
      const next = new Set(prev);
      if (next.has(taskId)) next.delete(taskId);
      else next.add(taskId);
      return next;
    });
  }, []);

  const toggleSectionCollapsed = useCallback((sectionId: string) => {
    setCollapsedSectionIds((prev) => {
      const next = new Set(prev);
      if (next.has(sectionId)) next.delete(sectionId);
      else next.add(sectionId);
      return next;
    });
  }, []);

  const toggleProjectCompletedExpanded = useCallback(() => {
    setProjectCompletedExpanded((v) => !v);
  }, []);

  const createSection = useCallback(
    async (name: string) => {
      if (!projectId) return;
      const trimmed = name.trim();
      if (!trimmed) return;

      if (usingMock || !isSupabaseConfigured()) {
        const section: Section = {
          id: `mock-${Date.now()}`,
          projectId,
          name: trimmed,
          order: sections.length,
          createdAt: new Date().toISOString(),
        };
        setSections((prev) => [...prev, section]);
        return;
      }

      try {
        const section = await new SectionRepository(createClient()).createSection(projectId, trimmed);
        setSections((prev) => [...prev, section]);
      } catch (e) {
        setError(e instanceof Error ? e.message : "Erro ao criar seção");
      }
    },
    [projectId, sections.length, usingMock],
  );

  const renameSection = useCallback(
    async (sectionId: string, name: string) => {
      const trimmed = name.trim();
      if (!trimmed) return;
      const prev = sections.find((s) => s.id === sectionId);
      if (!prev || prev.name === trimmed) return;

      setSections((list) => list.map((s) => (s.id === sectionId ? { ...s, name: trimmed } : s)));

      if (!usingMock && isSupabaseConfigured()) {
        try {
          await new SectionRepository(createClient()).updateSection(sectionId, { name: trimmed });
        } catch {
          setSections((list) => list.map((s) => (s.id === sectionId ? prev : s)));
        }
      }
    },
    [sections, usingMock],
  );

  const deleteSection = useCallback(
    async (sectionId: string) => {
      const removed = sections.find((s) => s.id === sectionId);
      if (!removed) return;

      setSections((list) => list.filter((s) => s.id !== sectionId));
      setViewTasks((prev) => ({
        ...prev,
        pending: prev.pending.map((t) => (t.sectionId === sectionId ? { ...t, sectionId: null } : t)),
        completed: prev.completed.map((t) =>
          t.sectionId === sectionId ? { ...t, sectionId: null } : t,
        ),
      }));

      if (!usingMock && isSupabaseConfigured()) {
        try {
          await new SectionRepository(createClient()).deleteSection(sectionId);
        } catch {
          setSections((list) => [...list, removed]);
          await refreshTasks();
        }
      }
    },
    [sections, refreshTasks, usingMock],
  );

  const reorderProjectTasks = useCallback(
    async (draggedId: string, targetId: string, targetKind: ReorderDropKind = "task") => {
      if (draggedId === targetId && targetKind === "task") return;
      const dragged = viewTasks.pending.find((t) => t.id === draggedId);
      if (!dragged) return;

      const oldSectionKey = dragged.sectionId ?? null;
      let newSectionKey: string | null;
      let insertBeforeTaskId: string | null;

      if (targetKind === "section") {
        newSectionKey = targetId;
        insertBeforeTaskId = null;
      } else {
        const target = viewTasks.pending.find((t) => t.id === targetId);
        if (!target) return;
        newSectionKey = target.sectionId ?? null;
        insertBeforeTaskId = targetId;
      }

      const sortByOrder = (tasks: typeof viewTasks.pending) =>
        [...tasks].sort((a, b) => (a.order ?? 0) - (b.order ?? 0) || a.id.localeCompare(b.id));

      const destBucket = sortByOrder(
        viewTasks.pending.filter((t) => (t.sectionId ?? null) === newSectionKey && t.id !== draggedId),
      );

      const moved = { ...dragged, sectionId: newSectionKey };
      let nextDest: typeof viewTasks.pending;

      if (insertBeforeTaskId) {
        const to = destBucket.findIndex((t) => t.id === insertBeforeTaskId);
        nextDest = [...destBucket];
        nextDest.splice(to < 0 ? nextDest.length : to, 0, moved);
      } else {
        nextDest = [moved, ...destBucket];
      }

      const destOrderMap = new Map(nextDest.map((t, i) => [t.id, i]));

      let sourceOrderMap = new Map<string, number>();
      if (oldSectionKey !== newSectionKey) {
        const sourceBucket = sortByOrder(
          viewTasks.pending.filter((t) => (t.sectionId ?? null) === oldSectionKey && t.id !== draggedId),
        );
        sourceOrderMap = new Map(sourceBucket.map((t, i) => [t.id, i]));
      }

      setViewTasks((prev) => ({
        ...prev,
        pending: prev.pending.map((t) => {
          if (t.id === draggedId) {
            return { ...t, sectionId: newSectionKey, order: destOrderMap.get(t.id) };
          }
          if (destOrderMap.has(t.id)) {
            return { ...t, order: destOrderMap.get(t.id) };
          }
          if (sourceOrderMap.has(t.id)) {
            return { ...t, order: sourceOrderMap.get(t.id) };
          }
          return t;
        }),
      }));

      if (!usingMock && isSupabaseConfigured()) {
        try {
          const repo = new TaskRepository(createClient());
          const orderUpdates = [
            ...nextDest.map((t, i) => ({ id: t.id, order: i })),
          ];
          if (oldSectionKey !== newSectionKey) {
            const sourceBucket = sortByOrder(
              viewTasks.pending.filter(
                (t) => (t.sectionId ?? null) === oldSectionKey && t.id !== draggedId,
              ),
            );
            orderUpdates.push(...sourceBucket.map((t, i) => ({ id: t.id, order: i })));
          }
          await repo.updateTaskOrders(orderUpdates);
          if (oldSectionKey !== newSectionKey) {
            await repo.updateTaskMeta(draggedId, { sectionId: newSectionKey });
          }
        } catch {
          await refreshTasks();
        }
      }
    },
    [viewTasks.pending, refreshTasks, usingMock],
  );

  const reorderSections = useCallback(
    async (draggedId: string, targetId: string) => {
      if (draggedId === targetId) return;
      const sorted = [...sections].sort((a, b) => a.order - b.order);
      const from = sorted.findIndex((s) => s.id === draggedId);
      const to = sorted.findIndex((s) => s.id === targetId);
      if (from < 0 || to < 0) return;

      const next = [...sorted];
      const [moved] = next.splice(from, 1);
      next.splice(to, 0, moved);

      const withOrder = next.map((s, i) => ({ ...s, order: i }));
      setSections(withOrder);

      if (!usingMock && isSupabaseConfigured()) {
        try {
          const repo = new SectionRepository(createClient());
          await Promise.all(withOrder.map((s) => repo.updateSection(s.id, { order: s.order })));
        } catch {
          await refreshTasks();
        }
      }
    },
    [sections, refreshTasks, usingMock],
  );

  const toggleTaskDone = useCallback(
    async (id: string) => {
      const task = allTasks.find((t) => t.id === id);
      if (!task) return;
      const newDone = !task.done;
      patchTaskInView(id, { done: newDone });
      setSelectedSubtaskKey(null);

      if (!usingMock && isSupabaseConfigured()) {
        try {
          await new TaskRepository(createClient()).toggleTaskDone(id, newDone);
          if (newDone && view === "today" && task.recurrence) {
            await handleRecurrenceOnComplete(task);
          } else {
            await refreshTasks();
          }
          showToast(newDone ? "Tarefa concluída" : "Tarefa reaberta");
        } catch {
          patchTaskInView(id, { done: task.done });
          showToast("Erro ao atualizar tarefa");
        }
      } else {
        if (newDone && view === "today" && task.recurrence) {
          await handleRecurrenceOnComplete(task);
        }
        if (newDone) showToast("Tarefa concluída");
      }
    },
    [allTasks, patchTaskInView, refreshTasks, usingMock, view, handleRecurrenceOnComplete, showToast],
  );

  const toggleSubtaskDone = useCallback(
    async (key: SubtaskKey) => {
      const ctx = getSubtaskContext(key);
      if (!ctx) return;
      const { task, index, sub } = ctx;
      const newDone = !sub.done;
      const subtasks = [...(task.subtasks ?? [])];
      subtasks[index] = { ...sub, done: newDone };
      patchTaskInView(task.id, { subtasks });

      if (!usingMock && isSupabaseConfigured() && sub.id) {
        try {
          await new TaskRepository(createClient()).toggleSubtaskDone(sub.id, newDone);
        } catch {
          subtasks[index] = sub;
          patchTaskInView(task.id, { subtasks });
        }
      }
    },
    [getSubtaskContext, patchTaskInView, usingMock],
  );

  const autosaveTaskTitle = useCallback(
    async (id: string, title: string) => {
      const task = allTasks.find((t) => t.id === id);
      if (!task) return;
      const trimmed = title.trim();
      if (!trimmed || trimmed === task.title) return;

      const prev = task.title;
      patchTaskInView(id, { title: trimmed });

      if (!usingMock && isSupabaseConfigured()) {
        try {
          await new TaskPersistence(createClient()).autosaveTaskTitle(id, trimmed);
        } catch {
          patchTaskInView(id, { title: prev });
        }
      }
    },
    [allTasks, patchTaskInView, usingMock],
  );

  const autosaveTaskNotes = useCallback(
    async (id: string, notes: string) => {
      const task = allTasks.find((t) => t.id === id);
      if (!task) return;
      const normalized = notes.trim();
      const prevNotes = task.notes ?? "";
      if (normalized === prevNotes.trim()) return;

      const preview = normalized || undefined;
      patchTaskInView(id, { notes: normalized || undefined, preview });

      if (!usingMock && isSupabaseConfigured()) {
        try {
          await new TaskPersistence(createClient()).autosaveTaskDescription(id, notes);
        } catch {
          patchTaskInView(id, { notes: task.notes, preview: task.preview });
        }
      }
    },
    [allTasks, patchTaskInView, usingMock],
  );

  const autosaveSubtaskTitle = useCallback(
    async (key: SubtaskKey, title: string) => {
      const ctx = getSubtaskContext(key);
      if (!ctx) return;
      const { task, index, sub } = ctx;
      const trimmed = title.trim();
      if (!trimmed || trimmed === sub.name) return;

      const subtasks = [...(task.subtasks ?? [])];
      const prev = sub.name;
      subtasks[index] = { ...sub, name: trimmed };
      patchTaskInView(task.id, { subtasks });

      if (!usingMock && isSupabaseConfigured() && sub.id) {
        try {
          await new TaskPersistence(createClient()).autosaveSubtaskTitle(sub.id, trimmed);
        } catch {
          subtasks[index] = { ...sub, name: prev };
          patchTaskInView(task.id, { subtasks });
        }
      }
    },
    [getSubtaskContext, patchTaskInView, usingMock],
  );

  const autosaveSubtaskNotes = useCallback(
    async (key: SubtaskKey, notes: string) => {
      const ctx = getSubtaskContext(key);
      if (!ctx) return;
      const { task, index, sub } = ctx;
      const normalized = notes.trim();
      const prevNotes = sub.notes ?? "";
      if (normalized === prevNotes.trim()) return;

      const subtasks = [...(task.subtasks ?? [])];
      subtasks[index] = { ...sub, notes: normalized || undefined };
      patchTaskInView(task.id, { subtasks });

      if (!usingMock && isSupabaseConfigured() && sub.id) {
        try {
          await new TaskPersistence(createClient()).autosaveSubtaskDescription(sub.id, notes);
        } catch {
          subtasks[index] = sub;
          patchTaskInView(task.id, { subtasks });
        }
      }
    },
    [getSubtaskContext, patchTaskInView, usingMock],
  );

  const patchSubtaskMeta = useCallback(
    (key: SubtaskKey, patch: Partial<Subtask>) => {
      const ctx = getSubtaskContext(key);
      if (!ctx) return null;
      const { task, index, sub } = ctx;
      const subtasks = [...(task.subtasks ?? [])];
      subtasks[index] = { ...sub, ...patch };
      patchTaskInView(task.id, { subtasks });
      return { task, index, sub: subtasks[index]!, prev: sub };
    },
    [getSubtaskContext, patchTaskInView],
  );

  const updateSubtaskPriority = useCallback(
    async (key: SubtaskKey, priority: Priority | null) => {
      const result = patchSubtaskMeta(key, { priority: priority ?? undefined });
      if (!result) return;
      const { task, index, sub, prev } = result;
      if (!usingMock && isSupabaseConfigured() && sub.id) {
        try {
          await new TaskPersistence(createClient()).updateSubtaskPriority(sub.id, priority);
        } catch {
          const subtasks = [...(task.subtasks ?? [])];
          subtasks[index] = prev;
          patchTaskInView(task.id, { subtasks });
        }
      }
    },
    [patchSubtaskMeta, patchTaskInView, usingMock],
  );

  const updateSubtaskDueDate = useCallback(
    async (key: SubtaskKey, dueDate: string | null) => {
      const due = parseDueDate(dueDate);
      const result = patchSubtaskMeta(key, {
        dueDate,
        date: formatTaskDate(due),
      });
      if (!result) return;
      const { task, index, sub, prev } = result;
      if (!usingMock && isSupabaseConfigured() && sub.id) {
        try {
          await new TaskPersistence(createClient()).updateSubtaskDueDate(sub.id, dueDate);
        } catch {
          const subtasks = [...(task.subtasks ?? [])];
          subtasks[index] = prev;
          patchTaskInView(task.id, { subtasks });
        }
      }
    },
    [patchSubtaskMeta, patchTaskInView, usingMock],
  );

  const updateSubtaskLabels = useCallback(
    async (key: SubtaskKey, labelIds: string[]) => {
      const result = patchSubtaskMeta(key, { labelIds: labelIds.length ? labelIds : undefined });
      if (!result) return;
      const { task, index, sub, prev } = result;
      if (!usingMock && isSupabaseConfigured() && sub.id) {
        try {
          await new TaskPersistence(createClient()).updateSubtaskLabelIds(sub.id, labelIds);
        } catch {
          const subtasks = [...(task.subtasks ?? [])];
          subtasks[index] = prev;
          patchTaskInView(task.id, { subtasks });
        }
      }
    },
    [patchSubtaskMeta, patchTaskInView, usingMock],
  );

  const toggleSidebar = useCallback(() => setSidebarCollapsed((c) => !c), []);

  const openQuickAdd = useCallback((opts?: QuickAddOptions) => {
    setQuickAddInitial(opts ?? {});
    setQuickAddOpen(true);
  }, []);
  const closeQuickAdd = useCallback(() => setQuickAddOpen(false), []);
  const refreshUserProfile = useCallback(async () => {
    if (!isSupabaseConfigured()) return;
    const {
      data: { user },
    } = await createClient().auth.getUser();
    if (user) setUserProfile(profileFromUser(user));
  }, []);

  const openSettings = useCallback((anchor?: AnchorRect) => {
    setSettingsAnchor(anchor ?? null);
    setSettingsOpen(true);
  }, []);
  const closeSettings = useCallback(() => {
    setSettingsOpen(false);
    setSettingsAnchor(null);
  }, []);
  const openAppearance = useCallback((anchor?: AnchorRect) => {
    setAppearanceAnchor(anchor ?? null);
    setAppearanceOpen(true);
  }, []);
  const closeAppearance = useCallback(() => {
    setAppearanceOpen(false);
    setAppearanceAnchor(null);
  }, []);
  const openProfile = useCallback((anchor?: AnchorRect) => {
    setProfileAnchor(anchor ?? null);
    setProfileOpen(true);
  }, []);
  const closeProfile = useCallback(() => {
    setProfileOpen(false);
    setProfileAnchor(null);
  }, []);
  const openProductivity = useCallback((anchor?: AnchorRect) => {
    setProductivityAnchor(anchor ?? null);
    setProductivityOpen(true);
  }, []);
  const closeProductivity = useCallback(() => {
    setProductivityOpen(false);
    setProductivityAnchor(null);
  }, []);
  const openLabels = useCallback((anchor?: AnchorRect) => {
    setLabelsAnchor(anchor ?? null);
    setLabelsOpen(true);
  }, []);
  const closeLabels = useCallback(() => {
    setLabelsOpen(false);
    setLabelsAnchor(null);
  }, []);
  const openShortcuts = useCallback((anchor?: AnchorRect) => {
    setShortcutsAnchor(anchor ?? null);
    setShortcutsOpen(true);
  }, []);
  const closeShortcuts = useCallback(() => {
    setShortcutsOpen(false);
    setShortcutsAnchor(null);
  }, []);
  const openCalendar = useCallback((anchor?: AnchorRect) => {
    setCalendarAnchor(anchor ?? null);
    setCalendarOpen(true);
  }, []);
  const closeCalendar = useCallback(() => {
    setCalendarOpen(false);
    setCalendarAnchor(null);
  }, []);

  const isShowCompleted = useCallback(
    (mode: ViewMode = view) => Boolean(showCompleted[mode]),
    [showCompleted, view],
  );

  const toggleShowCompleted = useCallback((mode: ViewMode = view) => {
    setShowCompleted((prev) => ({ ...prev, [mode]: !prev[mode] }));
  }, [view]);

  const createTask = useCallback(
    async (input: {
      title: string;
      description?: string;
      priority?: Priority;
      projectId?: string | null;
      sectionId?: string | null;
      dueDate?: string | null;
      labelIds?: string[];
    }) => {
      const trimmed = input.title.trim();
      if (!trimmed) return;

      if (usingMock || !isSupabaseConfigured()) {
        const task: Task = {
          id: `mock-${Date.now()}`,
          title: trimmed,
          notes: input.description,
          preview: input.description,
          projectId: input.projectId ?? null,
          sectionId: input.sectionId ?? null,
          dueDate: input.dueDate ?? null,
          priority: input.priority,
          done: false,
        };
        setViewTasks((prev) => ({ ...prev, pending: [...prev.pending, task] }));
        showToast("Tarefa criada");
        await refreshTasks();
        return;
      }

      try {
        await new TaskRepository(createClient()).createTask(input);
        showToast("Tarefa criada");
        await refreshTasks();
      } catch {
        showToast("Erro ao criar tarefa");
      }
    },
    [refreshTasks, showToast, usingMock],
  );

  const deleteTask = useCallback(
    async (id: string) => {
      const task = allTasks.find((t) => t.id === id);
      if (!task) return;

      const existing = pendingDeletesRef.current.get(id);
      if (existing) clearTimeout(existing.timer);

      const wasPending = viewTasks.pending.some((t) => t.id === id);
      const snapshot = { task: { ...task }, wasPending };

      removeTaskFromView(id);
      if (selectedTaskId === id) closeInspector();

      const performDelete = async () => {
        pendingDeletesRef.current.delete(id);
        if (!usingMock && isSupabaseConfigured()) {
          try {
            await new TaskRepository(createClient()).deleteTask(id);
            await refreshTasks();
          } catch {
            restoreTaskToView(snapshot);
            showToast("Erro ao excluir tarefa");
          }
        }
      };

      const timer = setTimeout(() => void performDelete(), 5000);
      pendingDeletesRef.current.set(id, { timer, snapshot });

      showToast("Tarefa excluída", {
        duration: 5000,
        action: {
          label: "Desfazer",
          onClick: () => {
            const pending = pendingDeletesRef.current.get(id);
            if (pending) {
              clearTimeout(pending.timer);
              pendingDeletesRef.current.delete(id);
            }
            restoreTaskToView(snapshot);
          },
        },
      });
    },
    [
      allTasks,
      closeInspector,
      refreshTasks,
      removeTaskFromView,
      restoreTaskToView,
      selectedTaskId,
      showToast,
      usingMock,
      viewTasks.pending,
    ],
  );

  const deferTask = useCallback(
    async (id: string) => {
      const task = allTasks.find((t) => t.id === id);
      if (!task) return;

      if (!usingMock && isSupabaseConfigured()) {
        try {
          await new TaskRepository(createClient()).deferTask(id, task.dueDate);
          showToast("Tarefa adiada");
          await refreshTasks();
        } catch {
          showToast("Erro ao adiar tarefa");
        }
      } else {
        showToast("Tarefa adiada");
      }
    },
    [allTasks, refreshTasks, showToast, usingMock],
  );

  const duplicateTask = useCallback(
    async (id: string) => {
      if (!usingMock && isSupabaseConfigured()) {
        try {
          await new TaskRepository(createClient()).duplicateTask(id);
          showToast("Tarefa duplicada");
          await refreshTasks();
        } catch {
          showToast("Erro ao duplicar tarefa");
        }
      } else {
        showToast("Tarefa duplicada");
      }
    },
    [refreshTasks, showToast, usingMock],
  );

  const updateTaskPriority = useCallback(
    async (id: string, priority: Priority | null) => {
      patchTaskInView(id, { priority: priority ?? undefined });
      if (!usingMock && isSupabaseConfigured()) {
        try {
          await new TaskPersistence(createClient()).updateTaskPriority(id, priority);
          showToast("Prioridade atualizada");
        } catch {
          await refreshTasks();
          showToast("Erro ao atualizar prioridade");
        }
      }
    },
    [patchTaskInView, refreshTasks, showToast, usingMock],
  );

  const updateTaskDueDate = useCallback(
    async (id: string, dueDate: string | null) => {
      patchTaskInView(id, { dueDate });
      if (!usingMock && isSupabaseConfigured()) {
        try {
          await new TaskPersistence(createClient()).updateTaskDueDate(id, dueDate);
          showToast("Data atualizada");
          await refreshTasks();
        } catch {
          await refreshTasks();
          showToast("Erro ao atualizar data");
        }
      }
    },
    [patchTaskInView, refreshTasks, showToast, usingMock],
  );

  const updateTaskProject = useCallback(
    async (id: string, projectId: string | null) => {
      const project = projects.find((p) => p.id === projectId);
      patchTaskInView(id, { projectId, project: project?.name ?? null, sectionId: null });
      if (!usingMock && isSupabaseConfigured()) {
        try {
          await new TaskRepository(createClient()).updateTaskMeta(id, {
            projectId,
            sectionId: null,
          });
          showToast("Projeto atualizado");
          await refreshTasks();
        } catch {
          await refreshTasks();
          showToast("Erro ao mover tarefa");
        }
      }
    },
    [patchTaskInView, projects, refreshTasks, showToast, usingMock],
  );

  const getProjectSections = useCallback(
    async (targetProjectId: string) => {
      if (usingMock || !isSupabaseConfigured()) {
        return mockSectionsForProject(targetProjectId);
      }
      return new SectionRepository(createClient()).getSectionsForProject(targetProjectId);
    },
    [usingMock],
  );

  const updateTaskProjectAndSection = useCallback(
    async (id: string, projectId: string | null, sectionId: string | null) => {
      const project = projects.find((p) => p.id === projectId);
      const resolvedSectionId = projectId ? sectionId : null;
      patchTaskInView(id, {
        projectId,
        project: project?.name ?? null,
        sectionId: resolvedSectionId,
      });
      if (!usingMock && isSupabaseConfigured()) {
        try {
          await new TaskRepository(createClient()).updateTaskMeta(id, {
            projectId,
            sectionId: resolvedSectionId,
          });
          showToast("Projeto atualizado");
          await refreshTasks();
        } catch {
          await refreshTasks();
          showToast("Erro ao mover tarefa");
        }
      }
    },
    [patchTaskInView, projects, refreshTasks, showToast, usingMock],
  );

  const updateTaskLabels = useCallback(
    async (id: string, labelIds: string[]) => {
      const labelMeta = labelIds
        .map((lid) => labels.find((l) => l.id === lid))
        .filter((l): l is NonNullable<typeof l> => Boolean(l));
      patchTaskInView(id, {
        labelIds,
        tag: labelMeta[0]?.name,
        labels: labelMeta.length ? labelMeta.map((l) => ({ id: l.id, name: l.name, color: l.color })) : undefined,
      });
      if (!usingMock && isSupabaseConfigured()) {
        try {
          await new LabelRepository(createClient()).setTaskLabels(id, labelIds);
          showToast("Etiquetas atualizadas");
        } catch {
          await refreshTasks();
          showToast("Erro ao atualizar etiquetas");
        }
      }
    },
    [labels, patchTaskInView, refreshTasks, showToast, usingMock],
  );

  const updateTaskRecurrence = useCallback(
    async (id: string, recurrence: string | null) => {
      patchTaskInView(id, { recurrence: recurrence ?? undefined });
      if (!usingMock && isSupabaseConfigured()) {
        try {
          await new TaskPersistence(createClient()).updateTaskRecurrence(id, recurrence);
          showToast("Repetição atualizada");
        } catch {
          await refreshTasks();
          showToast("Erro ao atualizar repetição");
        }
      }
    },
    [patchTaskInView, refreshTasks, showToast, usingMock],
  );

  const openProjectCreate = useCallback(() => {
    setProjectSheetMode("create");
    setProjectSheetProject(null);
    setProjectSheetOpen(true);
  }, []);

  const openProjectEdit = useCallback(
    (editProjectId: string) => {
      const project = projects.find((p) => p.id === editProjectId) ?? currentProject;
      if (!project) return;
      setProjectSheetMode("edit");
      setProjectSheetProject(project);
      setProjectSheetOpen(true);
    },
    [currentProject, projects],
  );

  const closeProjectSheet = useCallback(() => {
    setProjectSheetOpen(false);
    setProjectSheetProject(null);
  }, []);

  const createProject = useCallback(
    async (name: string, color: string, icon?: string) => {
      if (usingMock || !isSupabaseConfigured()) {
        const id = `mock-p-${Date.now()}`;
        setProjects((prev) => [
          ...prev,
          { id, name, color, icon: icon ?? "folder", pendingCount: 0 },
        ]);
        showToast("Projeto criado");
        router.push(`/projects/${id}`);
        return;
      }
      try {
        const id = await new ProjectRepository(createClient()).createProject({
          name,
          color,
          icon,
        });
        showToast("Projeto criado");
        await refreshTasks();
        router.push(`/projects/${id}`);
      } catch {
        showToast("Erro ao criar projeto");
      }
    },
    [refreshTasks, router, showToast, usingMock],
  );

  const updateProject = useCallback(
    async (id: string, patch: { name?: string; color?: string; icon?: string }) => {
      setProjects((prev) => prev.map((p) => (p.id === id ? { ...p, ...patch } : p)));
      if (currentProject?.id === id) {
        setCurrentProject((prev) => (prev ? { ...prev, ...patch } : prev));
      }
      if (!usingMock && isSupabaseConfigured()) {
        try {
          await new ProjectRepository(createClient()).updateProject(id, patch);
          showToast("Projeto atualizado");
          await refreshTasks();
        } catch {
          await refreshTasks();
          showToast("Erro ao atualizar projeto");
        }
      } else {
        showToast("Projeto atualizado");
      }
    },
    [currentProject?.id, refreshTasks, showToast, usingMock],
  );

  const deleteProject = useCallback(
    async (id: string) => {
      if (!usingMock && isSupabaseConfigured()) {
        try {
          await new ProjectRepository(createClient()).deleteProject(id);
          showToast("Projeto excluído");
          if (projectId === id) router.push("/home");
          await refreshTasks();
        } catch {
          showToast("Erro ao excluir projeto");
        }
      } else {
        setProjects((prev) => prev.filter((p) => p.id !== id));
        showToast("Projeto excluído");
        if (projectId === id) router.push("/home");
      }
    },
    [projectId, refreshTasks, router, showToast, usingMock],
  );

  const createSubtask = useCallback(
    async (taskId: string, title: string) => {
      const task = allTasks.find((t) => t.id === taskId);
      if (!task) return;

      if (usingMock || !isSupabaseConfigured()) {
        const subtasks = [...(task.subtasks ?? []), { name: title.trim(), done: false }];
        patchTaskInView(taskId, { subtasks });
        showToast("Subtarefa criada");
        return;
      }

      try {
        await new TaskRepository(createClient()).createSubtask(taskId, title);
        showToast("Subtarefa criada");
        await refreshTasks();
      } catch {
        showToast("Erro ao criar subtarefa");
      }
    },
    [allTasks, patchTaskInView, refreshTasks, showToast, usingMock],
  );

  const deleteSubtask = useCallback(
    async (key: SubtaskKey) => {
      const ctx = getSubtaskContext(key);
      if (!ctx) return;
      const { task, index, sub } = ctx;
      const subtasks = (task.subtasks ?? []).filter((_, i) => i !== index);
      patchTaskInView(task.id, { subtasks });

      if (!usingMock && isSupabaseConfigured() && sub.id) {
        try {
          await new TaskRepository(createClient()).deleteSubtask(sub.id);
          showToast("Subtarefa excluída");
        } catch {
          patchTaskInView(task.id, { subtasks: task.subtasks });
          showToast("Erro ao excluir subtarefa");
        }
      } else {
        showToast("Subtarefa excluída");
      }
    },
    [getSubtaskContext, patchTaskInView, showToast, usingMock],
  );

  const addComment = useCallback(
    async (taskId: string, text: string) => {
      if (!usingMock && isSupabaseConfigured()) {
        try {
          await new CommentRepository(createClient()).addComment(taskId, text);
          patchTaskInView(taskId, {
            commentCount: (allTasks.find((t) => t.id === taskId)?.commentCount ?? 0) + 1,
          });
          showToast("Comentário adicionado");
        } catch {
          showToast("Erro ao adicionar comentário");
        }
      } else {
        showToast("Comentário adicionado");
      }
    },
    [allTasks, patchTaskInView, showToast, usingMock],
  );

  const createLabel = useCallback(
    async (name: string, color: string) => {
      if (usingMock || !isSupabaseConfigured()) {
        setLabels((prev) => [...prev, { id: `mock-l-${Date.now()}`, name, color }]);
        showToast("Etiqueta criada");
        return;
      }
      try {
        await new LabelRepository(createClient()).createLabel(name, color);
        const list = await new LabelRepository(createClient()).fetchLabels();
        setLabels(list);
        showToast("Etiqueta criada");
      } catch {
        showToast("Erro ao criar etiqueta");
      }
    },
    [showToast, usingMock],
  );

  const updateLabel = useCallback(
    async (id: string, patch: { name?: string; color?: string }) => {
      setLabels((prev) => prev.map((l) => (l.id === id ? { ...l, ...patch } : l)));
      if (!usingMock && isSupabaseConfigured()) {
        try {
          await new LabelRepository(createClient()).updateLabel(id, patch);
          showToast("Etiqueta atualizada");
        } catch {
          const list = await new LabelRepository(createClient()).fetchLabels();
          setLabels(list);
          showToast("Erro ao atualizar etiqueta");
        }
      }
    },
    [showToast, usingMock],
  );

  const deleteLabel = useCallback(
    async (id: string) => {
      setLabels((prev) => prev.filter((l) => l.id !== id));
      if (!usingMock && isSupabaseConfigured()) {
        try {
          await new LabelRepository(createClient()).deleteLabel(id);
          showToast("Etiqueta excluída");
        } catch {
          const list = await new LabelRepository(createClient()).fetchLabels();
          setLabels(list);
          showToast("Erro ao excluir etiqueta");
        }
      } else {
        showToast("Etiqueta excluída");
      }
    },
    [showToast, usingMock],
  );

  const value: WorkbenchContextValue = {
    view,
    projectId,
    currentProject,
    projects,
    sections,
    viewTasks,
    todayStats,
    navCounts,
    loading,
    error,
    usingMock,
    collapsedSectionIds,
    projectCompletedExpanded,
    selectedTaskId,
    selectedSubtaskKey,
    expandedSubtasks,
    sidebarCollapsed,
    inspectorOpen: selectedTaskId !== null,
    paletteOpen,
    searchTasks,
    filterCounts,
    openPalette,
    closePalette,
    openTaskInspector,
    refreshTasks,
    selectTask,
    selectSubtask,
    clearSubtaskSelection,
    closeInspector,
    toggleSubtaskExpand,
    toggleTaskDone,
    toggleSubtaskDone,
    autosaveTaskTitle,
    autosaveTaskNotes,
    autosaveSubtaskTitle,
    autosaveSubtaskNotes,
    updateSubtaskPriority,
    updateSubtaskDueDate,
    updateSubtaskLabels,
    toggleSidebar,
    toggleSectionCollapsed,
    toggleProjectCompletedExpanded,
    createSection,
    renameSection,
    deleteSection,
    reorderProjectTasks,
    reorderSections,
    getSubtaskContext,
    selectedTask,
    allTasks,
    userProfile,
    labels,
    quickAddOpen,
    quickAddInitial,
    settingsOpen,
    appearanceOpen,
    profileOpen,
    productivityOpen,
    settingsAnchor,
    appearanceAnchor,
    profileAnchor,
    productivityAnchor,
    labelsAnchor,
    labelsOpen,
    shortcutsOpen,
    shortcutsAnchor,
    calendarOpen,
    calendarAnchor,
    calendarEvents,
    googleCalendar,
    calendarError,
    showCompleted,
    openQuickAdd,
    closeQuickAdd,
    openSettings,
    closeSettings,
    openAppearance,
    closeAppearance,
    openProfile,
    closeProfile,
    openProductivity,
    closeProductivity,
    refreshUserProfile,
    openLabels,
    closeLabels,
    openShortcuts,
    closeShortcuts,
    openCalendar,
    closeCalendar,
    refreshGoogleCalendar,
    toggleShowCompleted,
    isShowCompleted,
    createTask,
    deleteTask,
    deferTask,
    duplicateTask,
    updateTaskPriority,
    updateTaskDueDate,
    updateTaskProject,
    updateTaskProjectAndSection,
    getProjectSections,
    updateTaskLabels,
    updateTaskRecurrence,
    createSubtask,
    deleteSubtask,
    addComment,
    createLabel,
    updateLabel,
    deleteLabel,
    projectSheetOpen,
    projectSheetMode,
    projectSheetProject,
    openProjectCreate,
    openProjectEdit,
    closeProjectSheet,
    createProject,
    updateProject,
    deleteProject,
  };

  return <WorkbenchContext.Provider value={value}>{children}</WorkbenchContext.Provider>;
}

export function useWorkbench() {
  const ctx = useContext(WorkbenchContext);
  if (!ctx) throw new Error("useWorkbench must be used within WorkbenchProvider");
  return ctx;
}
