import type { Home01Icon } from "@hugeicons/core-free-icons"
import {
  Folder01Icon,
  HashIcon,
  Asterisk02Icon,
  StarIcon,
  FavouriteIcon,
  Flag01Icon,
  Bookmark01Icon,
  Tag01Icon,
  Target01Icon,
  InboxIcon,
  ArchiveIcon,
  Briefcase01Icon,
  Building03Icon,
  Chart01Icon,
  CodeIcon,
  Idea01Icon,
  BrainIcon,
  Mortarboard01Icon,
  Book02Icon,
  Note01Icon,
  Pen01Icon,
  Mail01Icon,
  ChatIcon,
  Calendar01Icon,
  Clock01Icon,
  Home01Icon as HomeIcon,
  Coffee01Icon,
  Restaurant01Icon,
  CakeIcon,
  Plant01Icon,
  Leaf01Icon,
  Tree01Icon,
  Dumbbell01Icon,
  Shield01Icon,
  PillIcon,
  ShoppingCart01Icon,
  Money01Icon,
  Wallet01Icon,
  CreditCardIcon,
  Car01Icon,
  Airplane01Icon,
  BicycleIcon,
  Globe02Icon,
  Location01Icon,
  Ticket01Icon,
  GiftIcon,
  Key01Icon,
  LockIcon,
  MusicNote01Icon,
  HeadphonesIcon,
  Camera01Icon,
  Video01Icon,
  Image01Icon,
  Film01Icon,
  GamepadIcon,
  PaintBrush01Icon,
  Rocket01Icon,
  Settings01Icon,
  Wrench01Icon,
  Bug01Icon,
  CloudIcon,
  DatabaseIcon,
  PuzzleIcon,
  Award01Icon,
  FireIcon,
  Moon02Icon,
} from "@hugeicons/core-free-icons"

export type ProjectIconKey =
  // Marcadores
  | "folder"
  | "hash"
  | "asterisk"
  | "star"
  | "favorite"
  | "flag"
  | "bookmark"
  | "tag"
  | "target"
  | "inbox"
  | "archive"
  // Trabalho e estudo
  | "work"
  | "building"
  | "chart"
  | "code"
  | "lightbulb"
  | "brain"
  | "school"
  | "book"
  | "note"
  | "pen"
  // Comunicação e tempo
  | "mail"
  | "chat"
  | "calendar"
  | "clock"
  // Casa e rotina
  | "home"
  | "coffee"
  | "food"
  | "cake"
  | "plant"
  | "leaf"
  | "tree"
  // Saúde
  | "fitness"
  | "health"
  | "pill"
  // Compras e finanças
  | "shopping"
  | "money"
  | "wallet"
  | "card"
  // Lugares e transporte
  | "car"
  | "plane"
  | "bike"
  | "travel"
  | "location"
  | "ticket"
  | "gift"
  | "key"
  | "lock"
  // Mídia e lazer
  | "music"
  | "headphones"
  | "camera"
  | "video"
  | "image"
  | "film"
  | "game"
  | "art"
  // Tech e utilidades
  | "rocket"
  | "settings"
  | "tools"
  | "bug"
  | "cloud"
  | "database"
  | "puzzle"
  | "award"
  | "fire"
  | "moon"

export type ProjectIconData = typeof Home01Icon

/** Espelha ProjectIcons em stacked-ios/Stacked/DesignSystem/StackedIcons.swift —
 *  o iconKey vem do Supabase e é compartilhado entre as duas plataformas. */
export const PROJECT_ICON_MAP: Record<ProjectIconKey, ProjectIconData> = {
  // Marcadores
  folder: Folder01Icon,
  hash: HashIcon,
  asterisk: Asterisk02Icon,
  star: StarIcon,
  favorite: FavouriteIcon,
  flag: Flag01Icon,
  bookmark: Bookmark01Icon,
  tag: Tag01Icon,
  target: Target01Icon,
  inbox: InboxIcon,
  archive: ArchiveIcon,
  // Trabalho e estudo
  work: Briefcase01Icon,
  building: Building03Icon,
  chart: Chart01Icon,
  code: CodeIcon,
  lightbulb: Idea01Icon,
  brain: BrainIcon,
  school: Mortarboard01Icon,
  book: Book02Icon,
  note: Note01Icon,
  pen: Pen01Icon,
  // Comunicação e tempo
  mail: Mail01Icon,
  chat: ChatIcon,
  calendar: Calendar01Icon,
  clock: Clock01Icon,
  // Casa e rotina
  home: HomeIcon,
  coffee: Coffee01Icon,
  food: Restaurant01Icon,
  cake: CakeIcon,
  plant: Plant01Icon,
  leaf: Leaf01Icon,
  tree: Tree01Icon,
  // Saúde
  fitness: Dumbbell01Icon,
  health: Shield01Icon,
  pill: PillIcon,
  // Compras e finanças
  shopping: ShoppingCart01Icon,
  money: Money01Icon,
  wallet: Wallet01Icon,
  card: CreditCardIcon,
  // Lugares e transporte
  car: Car01Icon,
  plane: Airplane01Icon,
  bike: BicycleIcon,
  travel: Globe02Icon,
  location: Location01Icon,
  ticket: Ticket01Icon,
  gift: GiftIcon,
  key: Key01Icon,
  lock: LockIcon,
  // Mídia e lazer
  music: MusicNote01Icon,
  headphones: HeadphonesIcon,
  camera: Camera01Icon,
  video: Video01Icon,
  image: Image01Icon,
  film: Film01Icon,
  game: GamepadIcon,
  art: PaintBrush01Icon,
  // Tech e utilidades
  rocket: Rocket01Icon,
  settings: Settings01Icon,
  tools: Wrench01Icon,
  bug: Bug01Icon,
  cloud: CloudIcon,
  database: DatabaseIcon,
  puzzle: PuzzleIcon,
  award: Award01Icon,
  fire: FireIcon,
  moon: Moon02Icon,
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
