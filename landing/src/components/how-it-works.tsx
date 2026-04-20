"use client";

import { useTranslations } from "next-intl";
import { Camera, Cpu, TrendingUp } from "lucide-react";
import SectionReveal from "@/components/ui/section-reveal";
import PhoneMockup from "@/components/ui/phone-mockup";
import { MockCameraScreen, MockResultScreen, MockDiaryScreen } from "@/components/ui/mock-screens";
import { motion } from "framer-motion";

const steps = [
  { key: "step1", icon: Camera, number: "01", Screen: MockCameraScreen },
  { key: "step2", icon: Cpu, number: "02", Screen: MockResultScreen },
  { key: "step3", icon: TrendingUp, number: "03", Screen: MockDiaryScreen },
] as const;

export default function HowItWorks() {
  const t = useTranslations("howItWorks");

  return (
    <section id="how-it-works" className="py-20 sm:py-28 bg-surface">
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

        <div className="grid md:grid-cols-3 gap-10 lg:gap-14">
          {steps.map(({ key, number, Screen }, i) => (
            <motion.div
              key={key}
              initial={{ opacity: 0, y: 24 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-40px" }}
              transition={{ duration: 0.5, delay: i * 0.15 }}
              className="text-center"
            >
              <div className="mb-6 flex justify-center">
                <PhoneMockup className="w-[180px] sm:w-[200px]">
                  <Screen />
                </PhoneMockup>
              </div>

              <div className="inline-flex items-center justify-center w-10 h-10 rounded-full bg-primary text-white text-sm font-bold mb-4">
                {number}
              </div>
              <h3 className="text-lg font-semibold text-foreground mb-2">
                {t(`${key}.title`)}
              </h3>
              <p className="text-muted text-sm leading-relaxed max-w-xs mx-auto">
                {t(`${key}.description`)}
              </p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
