"use client";

import { useEffect, useRef, useState } from "react";
import { useInView, motion } from "framer-motion";

type Props = {
  value: string;
  className?: string;
};

export default function Counter({ value, className }: Props) {
  const ref = useRef<HTMLSpanElement>(null);
  const isInView = useInView(ref, { once: true, margin: "-40px" });
  const [display, setDisplay] = useState(value);

  const numericPart = value.replace(/[^0-9]/g, "");
  const isNumeric = numericPart.length > 0 && /^\d+$/.test(numericPart);

  useEffect(() => {
    if (!isInView || !isNumeric) return;

    const target = parseInt(numericPart, 10);
    const duration = 1200;
    const start = performance.now();

    function animate(now: number) {
      const elapsed = now - start;
      const progress = Math.min(elapsed / duration, 1);
      const eased = 1 - Math.pow(1 - progress, 3);
      const current = Math.round(eased * target);

      const formatted = value.replace(numericPart, current.toLocaleString());
      setDisplay(formatted);

      if (progress < 1) requestAnimationFrame(animate);
    }

    requestAnimationFrame(animate);
  }, [isInView, isNumeric, numericPart, value]);

  return (
    <motion.span
      ref={ref}
      className={className}
      initial={{ opacity: 0, scale: 0.8 }}
      whileInView={{ opacity: 1, scale: 1 }}
      viewport={{ once: true }}
      transition={{ duration: 0.4 }}
    >
      {display}
    </motion.span>
  );
}
