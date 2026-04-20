"use client";

import { useTranslations } from "next-intl";

export default function Footer() {
  const t = useTranslations("footer");
  const year = new Date().getFullYear();

  return (
    <footer className="bg-surface border-t border-divider">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 py-10">
        <div className="flex flex-col sm:flex-row items-center justify-between gap-6">
          <div className="flex items-center gap-2.5">
            <div className="w-7 h-7 rounded-lg bg-primary flex items-center justify-center">
              <span className="text-white font-bold text-xs">B</span>
            </div>
            <span className="font-semibold text-foreground">BodyMeal</span>
          </div>

          <div className="flex flex-wrap items-center justify-center gap-x-6 gap-y-2 text-sm text-muted">
            <a href="#" className="hover:text-foreground transition-colors">
              {t("privacy")}
            </a>
            <a href="#" className="hover:text-foreground transition-colors">
              {t("terms")}
            </a>
            <a
              href="mailto:support@bodymeal.online"
              className="hover:text-foreground transition-colors"
            >
              {t("support")}
            </a>
          </div>
        </div>

        <div className="mt-8 pt-6 border-t border-divider text-center text-sm text-muted">
          &copy; {year} BodyMeal. {t("rights")}
        </div>
      </div>
    </footer>
  );
}
