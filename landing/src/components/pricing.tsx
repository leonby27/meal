"use client";

import { useTranslations } from "next-intl";
import { Check, Crown } from "lucide-react";
import SectionReveal from "@/components/ui/section-reveal";
import { motion } from "framer-motion";

export default function Pricing() {
  const t = useTranslations("pricing");

  const freeFeatures: string[] = t.raw("free.features");
  const proFeatures: string[] = t.raw("pro.features");

  return (
    <section id="pricing" className="py-20 sm:py-28">
      <div className="max-w-4xl mx-auto px-4 sm:px-6">
        <SectionReveal>
          <div className="text-center mb-14">
            <h2 className="text-3xl sm:text-4xl font-bold text-foreground">
              {t("title")}
            </h2>
            <p className="mt-4 text-lg text-muted max-w-xl mx-auto">
              {t("subtitle")}
            </p>
          </div>
        </SectionReveal>

        <div className="grid md:grid-cols-2 gap-6">
          {/* Free */}
          <motion.div
            initial={{ opacity: 0, y: 24 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5 }}
            className="rounded-2xl border border-divider bg-card p-8"
          >
            <h3 className="text-lg font-semibold text-foreground">
              {t("free.name")}
            </h3>
            <div className="mt-4 flex items-baseline gap-1">
              <span className="text-4xl font-bold text-foreground">
                {t("free.price")}
              </span>
              <span className="text-muted text-sm">
                {t("free.period")}
              </span>
            </div>
            <ul className="mt-8 space-y-3">
              {freeFeatures.map((f: string) => (
                <li key={f} className="flex items-start gap-3 text-sm">
                  <Check
                    size={18}
                    className="text-accent-green mt-0.5 flex-shrink-0"
                  />
                  <span className="text-foreground">{f}</span>
                </li>
              ))}
            </ul>
            <a
              href="#download"
              className="mt-8 block w-full text-center h-11 leading-[2.75rem] rounded-full bg-surface-2 text-foreground font-medium hover:bg-card-hover transition-colors"
            >
              {t("free.cta")}
            </a>
          </motion.div>

          {/* Pro */}
          <motion.div
            initial={{ opacity: 0, y: 24 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.1 }}
            className="relative rounded-2xl border-2 border-primary bg-card p-8"
          >
            <div className="absolute -top-3.5 left-1/2 -translate-x-1/2 px-4 py-1 rounded-full bg-primary text-white text-xs font-semibold flex items-center gap-1.5">
              <Crown size={14} />
              {t("pro.badge")}
            </div>

            <h3 className="text-lg font-semibold text-foreground">
              {t("pro.name")}
            </h3>
            <div className="mt-4 flex items-baseline gap-1">
              <span className="text-4xl font-bold text-foreground">
                {t("pro.price")}
              </span>
              <span className="text-muted text-sm">
                {t("pro.period")}
              </span>
            </div>
            <p className="mt-1 text-xs text-muted">{t("pro.yearlyNote")}</p>

            <ul className="mt-8 space-y-3">
              {proFeatures.map((f: string) => (
                <li key={f} className="flex items-start gap-3 text-sm">
                  <Check
                    size={18}
                    className="text-primary mt-0.5 flex-shrink-0"
                  />
                  <span className="text-foreground">{f}</span>
                </li>
              ))}
            </ul>
            <a
              href="#download"
              className="mt-8 block w-full text-center h-11 leading-[2.75rem] rounded-full bg-primary text-white font-medium hover:bg-primary-hover transition-colors"
            >
              {t("pro.cta")}
            </a>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
