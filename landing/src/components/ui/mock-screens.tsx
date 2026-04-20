export function MockDiaryScreen() {
  return (
    <div className="w-full h-full bg-[#F5F6F8] dark:bg-[#14161B] flex flex-col text-[10px]">
      {/* Status bar */}
      <div className="flex items-center justify-between px-4 pt-3 pb-1 text-[8px] text-[#83899F]">
        <span>9:41</span>
        <div className="flex gap-1">
          <div className="w-3 h-1.5 rounded-sm bg-[#83899F]/40" />
          <div className="w-3 h-1.5 rounded-sm bg-[#83899F]/40" />
          <div className="w-4 h-1.5 rounded-sm bg-[#3DA43B]" />
        </div>
      </div>

      {/* Date header */}
      <div className="px-4 pt-2 pb-3">
        <div className="text-[13px] font-bold text-[#0A1B39] dark:text-white">Today</div>
        <div className="text-[8px] text-[#83899F] mt-0.5">Tuesday, April 15</div>
      </div>

      {/* Calorie ring */}
      <div className="mx-4 bg-white dark:bg-[#21262D] rounded-2xl p-3 shadow-sm">
        <div className="flex items-center gap-3">
          <div className="relative w-16 h-16 flex-shrink-0">
            <svg viewBox="0 0 64 64" className="w-full h-full -rotate-90">
              <circle cx="32" cy="32" r="28" fill="none" stroke="#E6E7EC" strokeWidth="5" className="dark:stroke-[#313843]" />
              <circle cx="32" cy="32" r="28" fill="none" stroke="#317BFF" strokeWidth="5" strokeDasharray="176" strokeDashoffset="53" strokeLinecap="round" />
            </svg>
            <div className="absolute inset-0 flex flex-col items-center justify-center">
              <span className="text-[11px] font-bold text-[#0A1B39] dark:text-white">1,248</span>
              <span className="text-[7px] text-[#83899F]">/ 1,850</span>
            </div>
          </div>
          <div className="flex-1 space-y-1.5">
            <MacroBar label="Protein" value={62} max={120} color="#317BFF" />
            <MacroBar label="Fat" value={45} max={65} color="#F0681B" />
            <MacroBar label="Carbs" value={156} max={230} color="#3DA43B" />
          </div>
        </div>
      </div>

      {/* Meal entries */}
      <div className="mt-3 mx-4 space-y-2 flex-1">
        <MealEntry icon="🌅" name="Breakfast" cal={420} items="Oatmeal, banana, honey" />
        <MealEntry icon="☀️" name="Lunch" cal={580} items="Chicken salad, rice" />
        <MealEntry icon="🌙" name="Dinner" cal={248} items="Tap to add..." muted />
      </div>

      {/* Bottom tab bar */}
      <div className="mt-auto px-2 pb-2 pt-1.5 bg-white dark:bg-[#21262D] border-t border-[#E6E7EC] dark:border-[#313843] flex justify-around">
        <TabItem icon="📖" label="Diary" active />
        <TabItem icon="📊" label="Stats" />
        <div className="w-8 h-8 rounded-full bg-[#317BFF] flex items-center justify-center -mt-3 shadow-md">
          <span className="text-white text-sm font-bold">+</span>
        </div>
        <TabItem icon="🔍" label="Search" />
        <TabItem icon="👤" label="Profile" />
      </div>
    </div>
  );
}

export function MockCameraScreen() {
  return (
    <div className="w-full h-full bg-[#0A1B39] flex flex-col text-[10px]">
      {/* Status bar */}
      <div className="flex items-center justify-between px-4 pt-3 pb-1 text-[8px] text-white/60">
        <span>9:41</span>
        <div className="flex gap-1">
          <div className="w-3 h-1.5 rounded-sm bg-white/30" />
          <div className="w-3 h-1.5 rounded-sm bg-white/30" />
          <div className="w-4 h-1.5 rounded-sm bg-[#3DA43B]" />
        </div>
      </div>

      {/* Header */}
      <div className="px-4 pt-2 pb-3 flex items-center justify-between">
        <div className="w-6 h-6 rounded-full bg-white/10 flex items-center justify-center">
          <span className="text-white text-[10px]">✕</span>
        </div>
        <span className="text-white text-[11px] font-semibold">AI Camera</span>
        <div className="w-6" />
      </div>

      {/* Viewfinder area */}
      <div className="flex-1 mx-4 mb-3 relative rounded-2xl bg-gradient-to-br from-[#1a2a4a] to-[#0d1625] overflow-hidden flex items-center justify-center">
        {/* Corner brackets */}
        <Corner position="top-left" />
        <Corner position="top-right" />
        <Corner position="bottom-left" />
        <Corner position="bottom-right" />

        {/* Scanning animation placeholder */}
        <div className="flex flex-col items-center gap-2">
          <div className="w-10 h-10 rounded-full border-2 border-[#317BFF]/60 flex items-center justify-center">
            <div className="w-6 h-6 rounded-full border-2 border-dashed border-[#317BFF] animate-spin" style={{ animationDuration: '3s' }} />
          </div>
          <span className="text-white/70 text-[9px]">Point at your meal</span>
        </div>

        {/* Scan line */}
        <div className="absolute left-6 right-6 h-[1px] top-1/3 bg-gradient-to-r from-transparent via-[#317BFF]/50 to-transparent" />
      </div>

      {/* Input method toggles */}
      <div className="px-4 pb-3 flex justify-center gap-3">
        <InputPill icon="📷" label="Photo" active />
        <InputPill icon="🎤" label="Voice" />
        <InputPill icon="✏️" label="Text" />
      </div>

      {/* Capture button */}
      <div className="flex items-center justify-center pb-6">
        <div className="w-14 h-14 rounded-full border-4 border-white/30 flex items-center justify-center">
          <div className="w-10 h-10 rounded-full bg-white" />
        </div>
      </div>
    </div>
  );
}

export function MockResultScreen() {
  return (
    <div className="w-full h-full bg-[#F5F6F8] dark:bg-[#14161B] flex flex-col text-[10px]">
      {/* Status bar */}
      <div className="flex items-center justify-between px-4 pt-3 pb-1 text-[8px] text-[#83899F]">
        <span>9:41</span>
        <div className="flex gap-1">
          <div className="w-3 h-1.5 rounded-sm bg-[#83899F]/40" />
          <div className="w-3 h-1.5 rounded-sm bg-[#83899F]/40" />
          <div className="w-4 h-1.5 rounded-sm bg-[#3DA43B]" />
        </div>
      </div>

      {/* Header */}
      <div className="px-4 pt-2 pb-3 flex items-center justify-between">
        <span className="text-[#317BFF] text-[10px]">← Back</span>
        <span className="text-[11px] font-semibold text-[#0A1B39] dark:text-white">AI Result</span>
        <span className="text-[#317BFF] text-[10px]">Save</span>
      </div>

      {/* Food image placeholder */}
      <div className="mx-4 h-28 rounded-xl bg-gradient-to-br from-[#FFE0B2] to-[#FFCC80] flex items-center justify-center overflow-hidden">
        <span className="text-3xl">🍲</span>
      </div>

      {/* Result card */}
      <div className="mx-4 mt-3 bg-white dark:bg-[#21262D] rounded-2xl p-4 shadow-sm">
        <div className="flex items-start justify-between">
          <div>
            <div className="text-[13px] font-bold text-[#0A1B39] dark:text-white">Chicken Caesar Salad</div>
            <div className="text-[9px] text-[#83899F] mt-0.5">~350g serving</div>
          </div>
          <div className="bg-[#3DA43B]/10 px-2 py-1 rounded-lg">
            <span className="text-[#3DA43B] text-[11px] font-bold">AI ✓</span>
          </div>
        </div>

        <div className="mt-3 flex items-center justify-center">
          <div className="text-center">
            <div className="text-[22px] font-bold text-[#0A1B39] dark:text-white">420</div>
            <div className="text-[8px] text-[#83899F]">kcal</div>
          </div>
        </div>

        <div className="mt-3 grid grid-cols-3 gap-2">
          <NutrientBadge label="Protein" value="32g" color="#317BFF" />
          <NutrientBadge label="Fat" value="22g" color="#F0681B" />
          <NutrientBadge label="Carbs" value="18g" color="#3DA43B" />
        </div>
      </div>

      {/* Ingredients */}
      <div className="mx-4 mt-3 bg-white dark:bg-[#21262D] rounded-2xl p-4 shadow-sm flex-1">
        <div className="text-[10px] font-semibold text-[#0A1B39] dark:text-white mb-2">Ingredients</div>
        <div className="space-y-1.5">
          <IngredientRow name="Chicken breast" amount="150g" cal="165" />
          <IngredientRow name="Romaine lettuce" amount="100g" cal="17" />
          <IngredientRow name="Parmesan" amount="30g" cal="120" />
          <IngredientRow name="Caesar dressing" amount="25g" cal="78" />
          <IngredientRow name="Croutons" amount="20g" cal="40" />
        </div>
      </div>

      {/* Save button */}
      <div className="px-4 py-3">
        <div className="w-full h-9 rounded-full bg-[#317BFF] flex items-center justify-center">
          <span className="text-white text-[11px] font-semibold">Add to Diary</span>
        </div>
      </div>
    </div>
  );
}

/* ---- Helper sub-components ---- */

function MacroBar({ label, value, max, color }: { label: string; value: number; max: number; color: string }) {
  const pct = Math.min((value / max) * 100, 100);
  return (
    <div>
      <div className="flex justify-between text-[8px] mb-0.5">
        <span className="text-[#83899F]">{label}</span>
        <span className="text-[#0A1B39] dark:text-white font-medium">{value}g / {max}g</span>
      </div>
      <div className="h-1.5 rounded-full bg-[#E6E7EC] dark:bg-[#313843]">
        <div className="h-full rounded-full" style={{ width: `${pct}%`, backgroundColor: color }} />
      </div>
    </div>
  );
}

function MealEntry({ icon, name, cal, items, muted }: { icon: string; name: string; cal: number; items: string; muted?: boolean }) {
  return (
    <div className="bg-white dark:bg-[#21262D] rounded-xl px-3 py-2.5 flex items-center gap-2.5 shadow-sm">
      <span className="text-sm">{icon}</span>
      <div className="flex-1 min-w-0">
        <div className="flex justify-between">
          <span className="font-semibold text-[#0A1B39] dark:text-white">{name}</span>
          <span className="text-[#317BFF] font-medium">{cal} kcal</span>
        </div>
        <span className={`text-[8px] ${muted ? 'text-[#317BFF]' : 'text-[#83899F]'} truncate block`}>{items}</span>
      </div>
    </div>
  );
}

function TabItem({ icon, label, active }: { icon: string; label: string; active?: boolean }) {
  return (
    <div className="flex flex-col items-center gap-0.5">
      <span className="text-xs">{icon}</span>
      <span className={`text-[7px] ${active ? 'text-[#317BFF] font-medium' : 'text-[#83899F]'}`}>{label}</span>
    </div>
  );
}

function Corner({ position }: { position: 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right' }) {
  const base = "absolute w-5 h-5 border-[#317BFF]/50";
  const styles = {
    'top-left': `${base} top-4 left-4 border-t-2 border-l-2 rounded-tl-md`,
    'top-right': `${base} top-4 right-4 border-t-2 border-r-2 rounded-tr-md`,
    'bottom-left': `${base} bottom-4 left-4 border-b-2 border-l-2 rounded-bl-md`,
    'bottom-right': `${base} bottom-4 right-4 border-b-2 border-r-2 rounded-br-md`,
  };
  return <div className={styles[position]} />;
}

function InputPill({ icon, label, active }: { icon: string; label: string; active?: boolean }) {
  return (
    <div className={`flex items-center gap-1 px-2.5 py-1 rounded-full text-[9px] ${active ? 'bg-[#317BFF] text-white' : 'bg-white/10 text-white/60'}`}>
      <span className="text-[10px]">{icon}</span>
      <span>{label}</span>
    </div>
  );
}

function NutrientBadge({ label, value, color }: { label: string; value: string; color: string }) {
  return (
    <div className="text-center rounded-xl py-2" style={{ backgroundColor: `${color}10` }}>
      <div className="font-bold text-[12px]" style={{ color }}>{value}</div>
      <div className="text-[7px] text-[#83899F] mt-0.5">{label}</div>
    </div>
  );
}

function IngredientRow({ name, amount, cal }: { name: string; amount: string; cal: string }) {
  return (
    <div className="flex items-center justify-between text-[9px]">
      <span className="text-[#0A1B39] dark:text-white">{name}</span>
      <div className="flex gap-2 text-[#83899F]">
        <span>{amount}</span>
        <span className="font-medium text-[#0A1B39] dark:text-white">{cal}</span>
      </div>
    </div>
  );
}
