import type { Home01Icon } from "@hugeicons/core-free-icons"
import {
  Folder01Icon,
  Briefcase01Icon,
  Home01Icon as HomeIcon,
  Mortarboard01Icon,
  Dumbbell01Icon,
  ShoppingCart01Icon,
  FavouriteIcon,
  StarCircleIcon,
  Rocket01Icon,
  Idea01Icon,
  MusicNote01Icon,
  Globe02Icon,
  Money01Icon,
  Shield01Icon,
  CodeIcon,
  PaintBrush01Icon,
} from "@hugeicons/core-free-icons"

export type ProjectIconKey =
  | "folder"
  | "work"
  | "home"
  | "school"
  | "fitness"
  | "shopping"
  | "favorite"
  | "star"
  | "rocket"
  | "lightbulb"
  | "music"
  | "travel"
  | "money"
  | "health"
  | "code"
  | "art"

export type ProjectIconData = typeof Home01Icon

/** Paridade lib/utils/project_icons.dart */
export const PROJECT_ICON_MAP: Record<ProjectIconKey, ProjectIconData> = {
  folder: Folder01Icon,
  work: Briefcase01Icon,
  home: HomeIcon,
  school: Mortarboard01Icon,
  fitness: Dumbbell01Icon,
  shopping: ShoppingCart01Icon,
  favorite: FavouriteIcon,
  star: StarCircleIcon,
  rocket: Rocket01Icon,
  lightbulb: Idea01Icon,
  music: MusicNote01Icon,
  travel: Globe02Icon,
  money: Money01Icon,
  health: Shield01Icon,
  code: CodeIcon,
  art: PaintBrush01Icon,
}

export const PROJECT_ICON_KEYS = Object.keys(PROJECT_ICON_MAP) as ProjectIconKey[]

export const DEFAULT_PROJECT_ICON: ProjectIconKey = "folder"

export function isProjectIconKey(value: string): value is ProjectIconKey {
  return value in PROJECT_ICON_MAP
}

export function resolveProjectIcon(iconKey?: string | null): ProjectIconData {
  if (iconKey && isProjectIconKey(iconKey)) return PROJECT_ICON_MAP[iconKey]
  return PROJECT_ICON_MAP[DEFAULT_PROJECT_ICON]
}
