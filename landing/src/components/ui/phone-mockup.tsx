"use client";

import { motion } from "framer-motion";
import type { ReactNode } from "react";

type Props = {
  children: ReactNode;
  className?: string;
  animate?: boolean;
};

export default function PhoneMockup({
  children,
  className = "",
  animate = false,
}: Props) {
  const inner = (
    <div className="relative rounded-[2.5rem] border-[6px] border-foreground/10 bg-card shadow-2xl overflow-hidden aspect-[9/19.2]">
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-24 h-5 bg-foreground/10 rounded-b-xl z-10" />
      <div className="w-full h-full">{children}</div>
    </div>
  );

  if (animate) {
    return (
      <motion.div
        className={`relative mx-auto w-[260px] sm:w-[280px] ${className}`}
        animate={{ y: [0, -8, 0] }}
        transition={{
          duration: 4,
          repeat: Infinity,
          ease: "easeInOut" as const,
        }}
      >
        {inner}
      </motion.div>
    );
  }

  return (
    <div className={`relative mx-auto w-[260px] sm:w-[280px] ${className}`}>
      {inner}
    </div>
  );
}
