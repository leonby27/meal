"use client";

import { useTranslations } from "next-intl";
import { Database, Zap, Globe, Smartphone } from "lucide-react";
import Counter from "@/components/ui/counter";

const statIcons = [Database, Zap, Globe, Smartphone];
const statKeys = [
  { value: "products", label: "productsLabel" },
  { value: "aiSpeed", label: "aiSpeedLabel" },
  { value: "languages", label: "languagesLabel" },
  { value: "inputMethods", label: "inputMethodsLabel" },
] as const;

export default function SocialProof() {
  const t = useTranslations("socialProof");

  return (
    <section className="py-14 sm:py-16 bg-primary">
      <div className="max-w-6xl mx-auto px-4 sm:px-6">
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-8">
          {statKeys.map(({ value, label }, i) => {
            const Icon = statIcons[i];
            return (
              <div key={value} className="text-center">
                <Icon size={24} className="mx-auto mb-3 text-white/50" />
                <Counter
                  value={t(value)}
                  className="block text-3xl sm:text-4xl font-bold text-white"
                />
                <div className="mt-2 text-sm text-white/70">{t(label)}</div>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
