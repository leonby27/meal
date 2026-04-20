"use client";

import { useTheme } from "next-themes";
import { useEffect, useState } from "react";
import { Sun, Moon } from "lucide-react";

export default function ThemeToggle() {
  const { resolvedTheme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  useEffect(() => setMounted(true), []);

  return (
    <button
      onClick={() => setTheme(resolvedTheme === "dark" ? "light" : "dark")}
      className="relative w-9 h-9 rounded-lg bg-surface-2 flex items-center justify-center hover:bg-card-hover transition-colors"
      aria-label="Toggle theme"
      suppressHydrationWarning
    >
      {mounted ? (
        resolvedTheme === "dark" ? (
          <Sun size={18} className="text-foreground" />
        ) : (
          <Moon size={18} className="text-foreground" />
        )
      ) : (
        <div className="w-[18px] h-[18px]" />
      )}
    </button>
  );
}
