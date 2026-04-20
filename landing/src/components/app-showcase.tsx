"use client";

import { useTranslations } from "next-intl";
import { Check } from "lucide-react";
import Image from "next/image";
import SectionReveal from "@/components/ui/section-reveal";

export default function AppShowcase() {
  const t = useTranslations("lifestyle");

  const bullets = [t("bullet1"), t("bullet2"), t("bullet3")];

  return (
    <section className="py-20 sm:py-28">
      <div className="max-w-6xl mx-auto px-4 sm:px-6">
        <div className="flex flex-col lg:flex-row items-center gap-12 lg:gap-16">
          {/* Left: text */}
          <div className="flex-1">
            <SectionReveal>
              <h2 className="text-3xl sm:text-4xl font-bold text-foreground">
                {t("title")}
              </h2>
              <p className="mt-4 text-lg text-muted leading-relaxed max-w-lg">
                {t("subtitle")}
              </p>
              <ul className="mt-8 space-y-4">
                {bullets.map((b) => (
                  <li key={b} className="flex items-start gap-3">
                    <div className="w-6 h-6 rounded-full bg-accent-green/10 flex items-center justify-center flex-shrink-0 mt-0.5">
                      <Check size={14} className="text-accent-green" />
                    </div>
                    <span className="text-foreground">{b}</span>
                  </li>
                ))}
              </ul>
            </SectionReveal>
          </div>

          {/* Right: lifestyle photo */}
          <SectionReveal delay={0.15}>
            <div className="relative w-full max-w-md lg:max-w-lg flex-shrink-0">
              <div className="rounded-2xl overflow-hidden shadow-xl">
                <Image
                  src="/images/lifestyle-cooking.jpg"
                  alt={t("imageAlt")}
                  width={800}
                  height={600}
                  className="w-full h-auto object-cover"
                />
              </div>
              {/* Decorative accent */}
              <div className="absolute -z-10 -bottom-4 -right-4 w-full h-full rounded-2xl bg-primary/10" />
            </div>
          </SectionReveal>
        </div>
      </div>
    </section>
  );
}
