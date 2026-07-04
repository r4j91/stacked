import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Stacked",
  description: "Gerenciador de tarefas",
  manifest: "/manifest.json",
  icons: {
    icon: [{ url: "/favicon.png?v=3", type: "image/png" }],
    apple: [{ url: "/apple-touch-icon.png?v=3", type: "image/png" }],
  },
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
