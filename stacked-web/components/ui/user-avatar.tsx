import Image from "next/image";

export function userInitials(name: string, email?: string): string {
  const trimmed = name.trim();
  if (trimmed.length >= 2) return trimmed.slice(0, 2).toUpperCase();
  if (trimmed.length === 1) return trimmed.toUpperCase();
  const e = email?.trim() ?? "";
  return e.length >= 2 ? e.slice(0, 2).toUpperCase() : "?";
}

type UserAvatarProps = {
  name: string;
  email?: string;
  avatarUrl?: string | null;
  size?: number;
  className?: string;
};

export function UserAvatar({ name, email, avatarUrl, size = 40, className = "" }: UserAvatarProps) {
  const initials = userInitials(name, email);
  if (avatarUrl) {
    return (
      <Image
        src={avatarUrl}
        alt=""
        width={size}
        height={size}
        className={`shrink-0 rounded-full object-cover ${className}`}
        style={{ width: size, height: size }}
        unoptimized
      />
    );
  }
  return (
    <span
      className={`flex shrink-0 items-center justify-center overflow-hidden rounded-full bg-[var(--color-surface-variant)] font-semibold text-[var(--color-text)] ${className}`}
      style={{ width: size, height: size, fontSize: Math.max(11, size * 0.34) }}
    >
      {initials}
    </span>
  );
}
