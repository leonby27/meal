"use client";

import { useTranslations } from "next-intl";
import { Apple } from "lucide-react";
import SectionReveal from "@/components/ui/section-reveal";

export default function FinalCTA() {
  const t = useTranslations("finalCta");

  return (
    <section id="download" className="relative py-20 sm:py-28 bg-gradient-to-br from-primary to-[#2060CC] dark:from-[#1a3a7a] dark:to-[#142a5e] overflow-hidden">
      {/* Decorative blobs */}
      <div className="absolute top-0 right-0 w-96 h-96 bg-white/5 rounded-full blur-3xl -translate-y-1/2 translate-x-1/3" />
      <div className="absolute bottom-0 left-0 w-64 h-64 bg-white/5 rounded-full blur-3xl translate-y-1/3 -translate-x-1/4" />

      <div className="relative max-w-6xl mx-auto px-4 sm:px-6 text-center">
        <SectionReveal>
          <h2 className="text-3xl sm:text-4xl font-bold text-white">
            {t("title")}
          </h2>
          <p className="mt-4 text-lg text-white/70 max-w-xl mx-auto">
            {t("subtitle")}
          </p>
        </SectionReveal>

        <SectionReveal delay={0.15}>
          <div className="mt-10 flex flex-col sm:flex-row items-center justify-center gap-4">
            <a
              href="#"
              className="inline-flex items-center gap-3 h-14 px-6 rounded-xl bg-white text-foreground hover:bg-white/90 transition-opacity shadow-lg"
            >
              <svg
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="currentColor"
              >
                <path d="M3.609 1.814L13.792 12 3.61 22.186a.996.996 0 01-.61-.92V2.734a1 1 0 01.609-.92zm10.89 10.893l2.302 2.302-10.937 6.333 8.635-8.635zm3.199-3.199l2.302 2.302a1 1 0 010 1.38l-2.302 2.302L15.395 12l2.302-2.302zM5.864 3.657L16.8 9.99l-2.302 2.302L5.864 3.657z" />
              </svg>
              <div className="text-left">
                <div className="text-[10px] leading-none opacity-60">
                  Google Play
                </div>
                <div className="text-base font-semibold leading-tight">
                  {t("cta")}
                </div>
              </div>
            </a>
          </div>

          <div className="mt-4 flex items-center justify-center gap-2 text-sm text-white/50">
            <Apple size={16} />
            <span>{t("comingSoon")}</span>
          </div>

          <p className="mt-4 text-sm text-white/40">{t("note")}</p>
        </SectionReveal>
      </div>
    </section>
  );
}
