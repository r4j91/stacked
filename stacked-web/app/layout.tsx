import type { Metadata, Viewport } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Stacked",
  description: "Gerenciador de tarefas",
  manifest: "/manifest.json",
};

export const viewport: Viewport = {
  themeColor: "#1A1B1E",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="pt-BR">
      <body className="antialiased">{children}</body>
    </html>
  );
}
