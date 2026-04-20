"use client";

import { useTranslations } from "next-intl";
import {
  Camera,
  Mic,
  Target,
  BookOpen,
  ChefHat,
  BarChart3,
} from "lucide-react";
import SectionReveal from "@/components/ui/section-reveal";
import { motion } from "framer-motion";

const featureKeys = [
  { key: "ai", icon: Camera, color: "bg-primary/10 text-primary" },
  { key: "multiInput", icon: Mic, color: "bg-accent-green/10 text-accent-green" },
  { key: "plan", icon: Target, color: "bg-accent-purple/10 text-accent-purple" },
  { key: "diary", icon: BookOpen, color: "bg-accent-orange/10 text-accent-orange" },
  { key: "recipes", icon: ChefHat, color: "bg-primary/10 text-primary" },
  { key: "stats", icon: BarChart3, color: "bg-accent-green/10 text-accent-green" },
] as const;

export default function Features() {
  const t = useTranslations("features");

  return (
    <section id="features" className="py-20 sm:py-28">
      <div className="max-w-6xl mx-auto px-4 sm:px-6">
        <SectionReveal>
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl font-bold text-foreground">
              {t("title")}
            </h2>
            <p className="mt-4 text-lg text-muted max-w-2xl mx-auto">
              {t("subtitle")}
            </p>
          </div>
        </SectionReveal>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-5">
          {featureKeys.map(({ key, icon: Icon, color }, i) => (
            <motion.div
              key={key}
              initial={{ opacity: 0, y: 24 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-40px" }}
              transition={{
                duration: 0.5,
                delay: i * 0.08,
                ease: [0.25, 0.1, 0.25, 1],
              }}
              className="group bg-card rounded-2xl p-6 hover:shadow-lg transition-all hover:-translate-y-0.5 border border-divider/50"
            >
              <div
                className={`w-11 h-11 rounded-xl ${color} flex items-center justify-center mb-4`}
              >
                <Icon size={22} />
              </div>
              <h3 className="text-base font-semibold text-foreground mb-2">
                {t(`${key}.title`)}
              </h3>
              <p className="text-muted text-sm leading-relaxed">
                {t(`${key}.description`)}
              </p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
