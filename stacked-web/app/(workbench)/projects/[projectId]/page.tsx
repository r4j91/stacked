import { CanvasArea } from "@/components/shell/canvas-area";

type Props = {
  params: Promise<{ projectId: string }>;
};

export default async function ProjectPage({ params }: Props) {
  await params;
  return <CanvasArea />;
}
