/** Título + valor em accent do tema (parcelas). */
export function SubtaskTitleWithValor({
  name,
  valor,
  done,
  className = "",
}: {
  name: string;
  valor?: number | null;
  done?: boolean;
  className?: string;
}) {
  const amount =
    valor != null && Number.isFinite(valor)
      ? new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(valor)
      : null;

  return (
    <span className={`inline-flex min-w-0 max-w-full items-baseline gap-1.5 ${className}`}>
      <span
        className={`min-w-0 truncate ${
          done
            ? "text-[var(--color-text-tertiary)] line-through"
            : "text-[var(--color-text)]"
        }`}
      >
        {name}
      </span>
      {amount ? (
        <span
          className={`shrink-0 tabular-nums ${
            done ? "text-[var(--color-accent)]/45" : "text-[var(--color-accent)]"
          }`}
        >
          {amount}
        </span>
      ) : null}
    </span>
  );
}
