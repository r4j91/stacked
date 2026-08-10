/** Paridade iOS InstallmentProgressStorage — progresso de parcelas no card. */
export const INSTALLMENT_PROGRESS_ON_CARD_KEY = "appearance.installmentProgressOnCard";
export const INSTALLMENT_PROGRESS_ON_CARD_EVENT = "stacked:installment-progress-on-card";
export const DEFAULT_INSTALLMENT_PROGRESS_ON_CARD = true;

export function readInstallmentProgressOnCard(): boolean {
  if (typeof window === "undefined") return DEFAULT_INSTALLMENT_PROGRESS_ON_CARD;
  const raw = window.localStorage.getItem(INSTALLMENT_PROGRESS_ON_CARD_KEY);
  if (raw === null) return DEFAULT_INSTALLMENT_PROGRESS_ON_CARD;
  return raw === "1" || raw === "true";
}

export function writeInstallmentProgressOnCard(enabled: boolean) {
  if (typeof window === "undefined") return;
  window.localStorage.setItem(INSTALLMENT_PROGRESS_ON_CARD_KEY, enabled ? "1" : "0");
  window.dispatchEvent(new Event(INSTALLMENT_PROGRESS_ON_CARD_EVENT));
}

export function subscribeInstallmentProgressOnCard(onStoreChange: () => void) {
  if (typeof window === "undefined") return () => {};
  const handler = () => onStoreChange();
  window.addEventListener(INSTALLMENT_PROGRESS_ON_CARD_EVENT, handler);
  window.addEventListener("storage", handler);
  return () => {
    window.removeEventListener(INSTALLMENT_PROGRESS_ON_CARD_EVENT, handler);
    window.removeEventListener("storage", handler);
  };
}
