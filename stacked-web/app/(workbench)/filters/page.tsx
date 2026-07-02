import { Suspense } from "react";
import { CanvasArea } from "@/components/shell/canvas-area";

export default function FiltersPage() {
  return (
    <Suspense fallback={null}>
      <CanvasArea />
    </Suspense>
  );
}
