"use client";

import { useState, useRef, useEffect } from "react";
import { useLocale } from "next-intl";
import { useRouter, usePathname } from "@/i18n/routing";
import { type Locale, locales } from "@/i18n/routing";
import { Globe } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";

const labels: Record<Locale, string> = {
  ru: "RU",
  en: "EN",
  de: "DE",
  es: "ES",
  fr: "FR",
  pt: "PT",
};

const fullLabels: Record<Locale, string> = {
  ru: "Русский",
  en: "English",
  de: "Deutsch",
  es: "Español",
  fr: "Français",
  pt: "Português",
};

export default function LangSwitcher() {
  const locale = useLocale() as Locale;
  const router = useRouter();
  const pathname = usePathname();
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClick);
    return () => document.removeEventListener("mousedown", handleClick);
  }, []);

  function switchLocale(next: Locale) {
    setOpen(false);
    router.replace(pathname, { locale: next });
  }

  return (
    <div ref={ref} className="relative">
      <button
        onClick={() => setOpen(!open)}
        className="flex items-center gap-1.5 h-9 px-2.5 rounded-lg bg-surface-2 hover:bg-card-hover transition-colors text-sm font-medium text-foreground"
      >
        <Globe size={16} className="text-muted" />
        {labels[locale]}
      </button>

      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ opacity: 0, y: -4 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -4 }}
            transition={{ duration: 0.15 }}
            className="absolute right-0 top-full mt-2 w-40 rounded-xl bg-card border border-divider shadow-lg overflow-hidden z-50"
          >
            {locales.map((l) => (
              <button
                key={l}
                onClick={() => switchLocale(l)}
                className={`w-full text-left px-4 py-2.5 text-sm transition-colors ${
                  l === locale
                    ? "bg-primary-light text-primary font-medium"
                    : "text-foreground hover:bg-surface-2"
                }`}
              >
                {fullLabels[l]}
              </button>
            ))}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
