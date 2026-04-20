import { setRequestLocale } from "next-intl/server";
import Header from "@/components/header";
import Hero from "@/components/hero";
import SocialProof from "@/components/social-proof";
import Features from "@/components/features";
import HowItWorks from "@/components/how-it-works";
import AppShowcase from "@/components/app-showcase";
import Pricing from "@/components/pricing";
import FAQ from "@/components/faq";
import FinalCTA from "@/components/final-cta";
import Footer from "@/components/footer";

type Props = {
  params: Promise<{ locale: string }>;
};

export default async function Home({ params }: Props) {
  const { locale } = await params;
  setRequestLocale(locale);

  return (
    <>
      <Header />
      <main>
        <Hero />
        <SocialProof />
        <Features />
        <HowItWorks />
        <AppShowcase />
        <Pricing />
        <FAQ />
        <FinalCTA />
      </main>
      <Footer />
    </>
  );
}
