import asyncio
import base64
import copy
import io
import json
import logging
import re

import httpx
from PIL import Image, ImageOps

from app.config import settings
from app.services import openfoodfacts

logger = logging.getLogger(__name__)

_JSON_SCHEMA = """{
  "name": "Dish name",
  "meal_quote": "<one fresh witty sentence about THIS dish — DO NOT copy the examples in the rules>",
  "health_rating": 7,
  "health_comment": "Сбалансированный завтрак с хорошим белком; помидоры добавляют клетчатку, сыр — насыщенный жир.",
  "total_grams": 350,
  "ingredients": [
    {"name": "Chicken egg (2 шт.)", "grams": 110, "protein": 14.0, "fat": 11.0, "carbs": 0.8, "calories": 155},
    {"name": "Tomatoes", "grams": 80, "protein": 0.9, "fat": 0.2, "carbs": 3.2, "calories": 18},
    {"name": "Hard cheese", "grams": 30, "protein": 7.5, "fat": 8.4, "carbs": 0.0, "calories": 105}
  ],
  "suggestions": [
    {"name": "Bacon", "grams": 30, "protein": 11.0, "fat": 12.0, "carbs": 0.4, "calories": 155},
    {"name": "Sausage", "grams": 50, "protein": 6.5, "fat": 14.0, "carbs": 1.5, "calories": 155},
    {"name": "Mushrooms", "grams": 40, "protein": 1.2, "fat": 0.1, "carbs": 1.3, "calories": 11}
  ],
  "per_100g": {"protein": 10.5, "fat": 8.5, "carbs": 2.2, "calories": 127},
  "total": {"protein": 22.4, "fat": 19.6, "carbs": 4.0, "calories": 278},
  "complete_macro": {
    "sugar_g": 2.4,
    "added_sugar_g": 0.5,
    "fiber_g": 2.5,
    "saturated_fat_g": 9.8,
    "cholesterol_mg": 380,
    "trans_fat_g": 0.0,
    "sodium_mg": 520,
    "glycemic_load": 4,
    "caloric_density": 1.27,
    "processing_level": 2
  },
  "goal_fit": {
    "positive": ["HIGH_PROTEIN", "BREAKFAST_FRIENDLY", "BALANCED_MACROS"],
    "negative": ["HIGH_SAT_FAT", "LOW_FIBER"]
  }
}"""

# Closed list of tag codes for `goal_fit.positive` / `goal_fit.negative`.
# Client localises each code into the user's language. Adding a new code here
# requires adding it to all 6 ARB files (app/lib/l10n/app_*.arb) too.
_TAG_CODES = (
    # Protein
    "HIGH_PROTEIN", "CONTAINS_PROTEIN", "LOW_PROTEIN", "COMPLETE_PROTEIN",
    # Fats
    "HEALTHY_FATS", "RICH_IN_OMEGA3", "HIGH_FAT", "HIGH_SAT_FAT",
    "HIGH_TRANS_FAT", "LOW_FAT",
    # Carbs / fiber / sugar
    "HIGH_FIBER", "CONTAINS_FIBER", "LOW_FIBER",
    "COMPLEX_CARBS", "REFINED_CARBS",
    "LOW_SUGAR", "HIGH_SUGAR", "LOW_CARB",
    # Calories / density / energy
    "HIGH_CALORIES", "LOW_CALORIES", "HIGH_ENERGY",
    "HELPS_QUOTA", "NUTRIENT_DENSE", "EMPTY_CALORIES",
    "HEAVY_MEAL", "LIGHT_MEAL",
    # Salt / cholesterol
    "HIGH_SALT", "LOW_SALT", "HIGH_CHOLESTEROL",
    # Context
    "GOOD_POST_WORKOUT", "GOOD_PRE_WORKOUT", "BREAKFAST_FRIENDLY",
    # Body systems
    "HEART_FRIENDLY", "GUT_FRIENDLY", "BRAIN_FOOD",
    "IMMUNE_BOOST", "BONE_HEALTH",
    # Micronutrients
    "RICH_IN_VITAMINS", "RICH_IN_IRON", "RICH_IN_CALCIUM",
    "RICH_IN_POTASSIUM", "HIGH_ANTIOXIDANTS",
    # Quality / composition
    "BALANCED_MACROS", "WHOLE_FOODS", "ULTRA_PROCESSED",
    "PLANT_BASED", "HYDRATING",
)


# User goal codes used in the client (onboarding_data.goal) → human description
# the model sees in the prompt. Anything else falls back to balanced eating.
_GOAL_DESCRIPTIONS = {
    "lose": "weight loss (calorie deficit, lean protein, fiber, low added sugar)",
    "maintain": "maintenance (balanced macros, steady energy, no extremes)",
    "gain": "muscle gain (calorie surplus, high protein, post-workout fuel)",
}


def _goal_description(goal: str | None) -> str:
    if not goal:
        return "balanced everyday eating (no specific goal selected)"
    return _GOAL_DESCRIPTIONS.get(goal.lower(), "balanced everyday eating")

# BCP-47 / ISO 639-1 language code → full English language name.
# Used to explicitly tell the model which language to respond in.
# Everything the model produces for the user (dish name, ingredient
# names) must be in this language; only the "(N шт.)" piece-count
# marker stays constant across languages so the client-side regex
# (see ai_meal_result_sheet.dart: RegExp(r'\((\d+)\s*шт\.?\)')) still
# matches regardless of UI language.
_LANGUAGE_NAMES = {
    "ru": "Russian",
    "en": "English",
    "de": "German",
    "es": "Spanish",
    "fr": "French",
    "pt": "Portuguese",
}


def _language_name(locale: str | None) -> str:
    if not locale:
        return "Russian"
    code = locale.lower().split("-")[0].split("_")[0]
    return _LANGUAGE_NAMES.get(code, "English")


# Shared rules used by both the image and text prompts.
#
# IMPORTANT — piece-count format:
# For countable ingredients (eggs, sausages, cutlets, meatballs, shrimp,
# dumplings, cookies, slices of bread/pizza, etc.) the client parses
# "(N шт.)" out of the `name` field via regex r'\((\d+)\s*шт\.?\)' and shows
# a +/- stepper so the user can tweak the count. When the stepper is used,
# the client assumes `grams` = total weight for ALL pieces, and computes
# per-unit grams as grams / N.
#
# The "шт." suffix is Cyrillic on purpose and is the ONLY format the
# client asks for in the prompt. The parser also accepts English "pc(s)" /
# "piece(s)" for resilience if the model localises the marker anyway.
_COMMON_RULES_EN = """Recognition and ingredient formatting rules:
- If the user supplied a textual description together with the photo, treat
  explicit facts from that text as authoritative: dish name, weight, count,
  ingredients, "without oil/sauce/sugar", cooking method, etc. Use the image
  to fill missing details, not to override explicit user facts.
- Estimate portion size from visible cues: plate/container size, utensils,
  hand/fork/spoon scale, packaging, cut pieces, and how full the container is.
  If there is no reliable scale reference, use a common serving size for that
  dish and keep the estimate realistic.
- For photos with multiple edible items in the same serving, include all
  visible items. Do not include non-edible items, decorations, packaging, or
  food that is not visible unless the user explicitly mentions it.
- If the photo shows separate foods/products rather than one prepared dish,
  name it as a selection/plate of items and list each visible edible item
  separately. Do not collapse separate packaged snacks and sliced meat into a
  single dish name like "salami with cheese" unless they are actually combined.
- For packaged foods, first read any visible label/brand/product text and use
  that over visual guessing. Preserve readable brand or product names in the
  ingredient name when helpful (for example, a visible candy bar, protein bar,
  glazed cottage cheese bar, yogurt, or packaged snack).
- Do not confidently infer a specific product subtype from package shape alone
  (for example "processed cheese", "cottage cheese bar", "protein bar",
  "candy bar"). Use that subtype only when the label is readable or the visual
  evidence is very strong. If uncertain, use a neutral category such as
  "packaged dairy dessert", "packaged snack bar", or "packaged sweet bar".
- For mixed dishes (soups, salads, pasta, bowls, stews, sandwiches, sauces),
  estimate the main components at a practical level of detail. Do not invent
  many tiny hidden ingredients; include modest amounts of common oil, dressing,
  sauce, or sugar only when visually likely or mentioned.
- Round weights and nutrition to realistic precision. Avoid fake exactness:
  grams are usually rounded to 5-10 g, calories to whole numbers, macros to
  one decimal place when needed.
- `total_grams` must approximately equal the sum of ingredient `grams`.
- For countable ingredients (eggs, sausages, cutlets, meatballs, shrimp,
  dumplings, cookies, slices of bread/pizza, etc.) append "(N шт.)" to
  the `name`, where N is the integer number of pieces. The literal
  characters "шт." (Cyrillic) MUST be used verbatim regardless of the
  response language — the client parses this exact marker to show a
  +/- stepper. Put the TOTAL combined weight of all pieces into
  `grams`. Example: {"name": "Chicken egg (2 шт.)", "grams": 110}.
- For bulk / non-countable ingredients (sauce, oil, grated cheese,
  lettuce, rice, pasta, minced meat, chopped vegetables, etc.) do NOT
  add "(N шт.)" — just use the name and weight in grams.
- Compute protein / fat / carbs / calories for EACH ingredient
  separately so the client can re-total when the user changes piece
  counts.
- `total` must equal the sum across ingredients (within 1–2%).
- `suggestions` is REQUIRED and almost always non-empty. It is a short list
  of 3–6 plausible EXTRA ingredients that COULD have been added to this
  dish but that you cannot see / confirm. They are pure UI hints — the
  user picks ones they actually used. Think "what does a real cook
  commonly add to this dish?" For an omelet that's almost always:
  cheese, bacon, sausage, ham, mushrooms, tomato, onion, herbs, butter.
  For pasta: parmesan, basil, garlic, olive oil, chili flakes, wine.
  For a salad: olive oil, feta, parmesan, croutons, nuts, dressing.
  For a sandwich: mayo, mustard, pickles, tomato, lettuce, cheese. For
  a soup: cream, sour cream, herbs, croutons, sesame oil. Do this for
  the textual recognition path too — even when the user only typed the
  dish name without ingredients, suggest the common companions.
  Return `[]` ONLY when truly nothing makes sense, e.g. a plain apple,
  a glass of water, a single packaged candy bar with a known recipe.
  These suggestions are NOT included in `total`, `total_grams`, or
  `per_100g`. For each suggestion give a sensible default serving size
  (`grams`, usually 10–60 g) and matching protein / fat / carbs /
  calories. Use the same field names as a regular ingredient. Do NOT
  use the "(N шт.)" piece-count marker in suggestions — keep names
  short and bare.
- `health_rating` is an integer 1–10 estimating how well this dish fits a
  normal balanced diet. Anchors: 1 = very unhealthy (deep-fried, sugary,
  ultra-processed); 5 = neutral everyday food; 10 = exceptionally healthy
  (whole, minimally processed, balanced macros). Consider nutrient density,
  macro balance, processing level and calorie density. A protein-rich dish
  with normal saturated fat (eggs and cheese, lean meat) is NOT
  automatically unhealthy — judge it as part of a typical day.
- `health_comment` is one short sentence (≤ 25 words), addressed to the
  user, in the same language as the rest of the response. Explain the
  rating with the most relevant strengths/weaknesses (e.g. high protein,
  added sugar, processed meat, low calorie density). Do not repeat the
  numeric rating inside the comment.
- `health_rating` and `health_comment` are REQUIRED. Always include both
  fields, even when the dish is plain or the photo is ambiguous. Keep
  ingredient names concise so the response fits within the token budget
  and these two fields are never omitted.
- `meal_quote` is REQUIRED. One short sentence (≤ 100 characters), in the
  same language as the rest of the response.
  TONE: playful, friendly, slightly cheeky — like a clever buddy
  commenting on what just landed on the table. The user must smile, not
  feel judged.

  CONTENT — most important rule:
    The quote MUST hook into BOTH the dish AND the user's goal (weight
    loss / maintenance / muscle gain / balanced eating). Don't write
    a generic food joke. Frame the dish as part of the user's journey
    — teammate, temptation, unexpected ally, small sabotage, a flex,
    a meh choice — pick whichever fits.

  REGISTER ROTATION (this is the variety lever):
    Before writing, PICK ONE register from the list below and commit to
    it. Rotate — over multiple recognitions you should hit different
    registers, NOT always the "clever-friend comment". Many quotes
    drift into the same shape ("X did Y, diet/goal Z") — actively
    AVOID that template.
      1. Mock confession FROM the dish, first person.
         "Я бы сошёл за лёгкий, если бы не майонез."
      2. Faux news-ticker headline.
         "Срочно: салат содержит больше колбасы чем надежд на дефицит."
      3. Two-line dish diary, single clause.
         "Дневник салата: пришёл, увидел, забыл про дефицит."
      4. Single playful imperative to the dish.
         "Майонез, отойди два шага."
      5. Mock proverb or rhyme.
         "Где майонез — там и драма."
      6. Hashtag/social-post vibe.
         "#когда_салат_решил_что_он_main_course"
      7. Mock-philosophical observation about one ingredient.
         "Кукуруза в этом салате — единственный пацифист."
      8. Weather-report cadence.
         "Прогноз на тарелку: облачно, с прояснениями из овощей."
      9. One-line dialogue snippet.
         "— Это диетично? — Спроси у майонеза."
     10. Reaction-meme prose.
         "Когда планировал ужин и когда сел за стол — два разных салата."
     11. Soft compliment with a wink (warm angle, for the moments
         when the user "earned" something — borderline-OK dish on a
         long deficit week, sensible portion in maintenance, etc.).
         "Не подвиг, но и не саботаж — ок."
     12. Self-aware overstatement.
         "Эпическая встреча кукурузы и колбасы. Десять из десяти."

  WARM ANGLE — use for borderline dishes:
    If the dish isn't clearly "great" or "bad" for the goal (most
    everyday meals on maintenance, an indulgent-but-modest portion on
    weight loss, a lean meal on muscle gain) lean WARM, not cheeky.
    Don't poke the user about "diet" or "deficit" on every single
    meal — that becomes nagging. Sometimes just smile at the dish.

  ANTI-PATTERNS — DO NOT WRITE quotes shaped like:
    • "X сделал Y, а Z передаёт привет" / "X did Y, Z says hi"
    • "Z пытается, но X" / "Z is trying, but X"
    • "Сейчас Z смотрит на Y" / "Z is watching Y"
    • Anything starting "Кажется,…" / "It seems…"
    • SPORTS metaphors (поле / счёт / финиш / гол / раздевалка / разминка /
      рывок / тренер / matchday / on the field / on the bench / scoreboard /
      final whistle / coach). Even when the goal is muscle gain, do NOT
      reach for football, race, or locker-room framings — they have been
      visibly over-used. Pick a non-sports register.
    • Any sentence that names "диета / дефицит / план / цель / weight
      loss / diet / deficit / goal" directly more than ONCE — pick a
      synonym or imply it (журнал, весы, прогресс, понедельник, джинсы,
      зеркало, scale, the plan, Monday, etc.).

  HARD LIMITS:
    • Tease the FOOD, the situation, the goal — NEVER the eater.
    • No shaming, no moralising, no health lectures, no mean sarcasm.
    • Cheeky ≠ mean. The friend never insults the friend.
    • Plain items (water, an apple): one short playful line, still
      tied to the goal vibe; do NOT pad with food trivia.

  VARIETY: invent a FRESH sentence keyed to THIS specific dish + goal.
  Do NOT reuse, translate, or paraphrase any example above (they
  illustrate REGISTER, not content). Even on a re-recognition of the
  same photo with the same goal, the phrasing AND register must be
  different.
- `complete_macro` is REQUIRED. Numeric values for the WHOLE portion
  (not per 100 g):
    * `sugar_g`           — TOTAL sugars in grams (added + natural)
    * `added_sugar_g`     — refined / added sugars only (white sugar,
                            HFCS, honey added during cooking, syrups in
                            packaged foods). EXCLUDE naturally occurring
                            sugars from whole fruits, plain milk, plain
                            yogurt. A banana smoothie with no added
                            sweetener should have added_sugar_g near 0
                            even when sugar_g is ~25 g.
    * `fiber_g`           — dietary fiber in grams
    * `saturated_fat_g`   — saturated fat in grams
    * `cholesterol_mg`    — cholesterol in milligrams
    * `trans_fat_g`       — industrial trans fats in grams (usually 0)
    * `sodium_mg`         — sodium in milligrams (NOT salt grams)
    * `glycemic_load`     — integer 0–40+ for the whole portion
                            (GI × available_carbs_g / 100)
    * `caloric_density`   — kcal per gram (total.calories / total_grams)
    * `processing_level`  — NOVA classification 1–4:
                            1 = unprocessed / minimally processed,
                            2 = culinary ingredient,
                            3 = processed food,
                            4 = ultra-processed food
  Round grams to one decimal, mg to integers, density to two decimals.

  REFERENCE VALUES (per 100 g of the named ingredient — sum across all
  ingredients in the dish to get the per-portion total). Use these as
  anchors so the per-portion numbers stay realistic:
    Beef (ground / steak)        cholesterol ~80 mg, sat. fat ~7 g, fiber 0 g
    Pork (lean cuts)             cholesterol ~75 mg, sat. fat ~5 g, fiber 0 g
    Chicken breast (skinless)    cholesterol ~85 mg, sat. fat ~1 g, fiber 0 g
    Chicken thigh (skin on)      cholesterol ~95 mg, sat. fat ~3.5 g, fiber 0 g
    Salmon                       cholesterol ~60 mg, sat. fat ~3 g, omega3 ~2 g
    Egg (1 large, ~50 g)         cholesterol ~185 mg, sat. fat ~1.5 g
    Hard cheese (parmesan/cheddar) cholesterol ~95 mg, sat. fat ~18 g, sodium ~700 mg
    Soft cheese (mozzarella)     cholesterol ~55 mg, sat. fat ~10 g, sodium ~400 mg
    Butter                       cholesterol ~215 mg, sat. fat ~50 g
    Whole milk                   cholesterol ~10 mg, sat. fat ~2 g, sugar ~5 g
    Cooked pasta (refined)       fiber ~2 g, sugar ~1 g, sodium ~5 mg
    Cooked pasta (wholegrain)    fiber ~5 g
    Cooked white rice            fiber ~0.5 g
    Cooked brown rice            fiber ~1.8 g
    Bread (white)                fiber ~2.5 g, sodium ~480 mg
    Bread (wholegrain)           fiber ~7 g
    Tomato (raw)                 fiber ~1.2 g, sugar ~2.6 g
    Tomato sauce / passata       fiber ~1.5 g, sugar ~5 g, sodium ~300 mg
    Onion (raw)                  fiber ~1.7 g, sugar ~4 g
    Carrot (raw)                 fiber ~2.8 g, sugar ~5 g
    Lettuce / leafy greens       fiber ~1.3 g, sugar ~1 g
    Cucumber                     fiber ~0.5 g, sugar ~1.7 g
    Radish                       fiber ~1.6 g, sugar ~1.9 g
    Spinach / arugula            fiber ~2.2 g
    Fresh herbs (parsley, dill)  fiber ~3 g
    Mixed salad (greens+veg)     fiber ~2.2 g/100 g — a typical 250 g
                                 bowl already lands above 5 g; do NOT
                                 under-report fiber on visible-green
                                 salads. Fiber is the SUM across every
                                 plant ingredient, not an average by
                                 total dish weight: a Caesar salad with
                                 150 g greens + 30 g croutons + 80 g
                                 chicken is 150 × 1.3/100 + 30 × 2.5/100
                                 + 0 ≈ 2.7 g; a green salad with 200 g
                                 mixed veg + 30 g croutons + 80 g
                                 chicken is 200 × 2.2/100 + 30 × 2.5/100
                                 + 0 ≈ 5.2 g. Plug in the actual
                                 ingredients; do NOT smear fiber down
                                 because the dish also contains meat.
    Avocado                      fiber ~7 g, sat. fat ~2 g
    Apple                        fiber ~2.4 g, sugar ~10 g
    Banana                       fiber ~2.6 g, sugar ~12 g
    Olive oil                    sat. fat ~14 g (per 100 g) — typical use 5–15 g
    Vegetable / sunflower oil    sat. fat ~10 g
  Industrial trans fats: ≈ 0 for home cooking; > 0 only for
  margarine-fried food, packaged baked goods, deep-fried fast food.

- ANTI-BIAS for `complete_macro`: be honest. DO NOT round any field
  toward a value that would land its client-side status in a milder
  bucket. The client picks worse / average / good purely from the
  numbers you return, so a 180 mg cholesterol portion must read 180,
  not 95. Sum reference values per ingredient × grams; do not
  "average it out". A dish with 150 g of ground beef plus 30 g of
  parmesan should NOT report cholesterol under 130 mg.

- REALISTIC INGREDIENT COUNTS for `complete_macro`: don't INFLATE
  ingredient quantities either — that swings the macros the wrong way
  in the other direction. Typical real-world portions, unless the
  photo clearly shows more:
    • salad with eggs       → 1–2 eggs (50–100 g), not 3+
    • leafy salad bowl      → 200–300 g total greens + veg
    • pasta with sauce      → 80–120 g cooked pasta + 80–150 g sauce
    • pizza (1–2 slices)    → 1 slice ≈ 100–130 g, 2 slices ≈ 200–260 g
    • burger                → 1 patty (~110 g), 1 bun (~60 g), 1 slice
                              cheese (~20 g), small sauce (~10 g)
    • sandwich              → 80–120 g bread, 30–60 g protein, 20–40 g
                              cheese; total 150–250 g
    • shaurma / wrap        → 1 wrap (~70 g), 100–150 g meat, sauce
                              (~15 g), veg (~30 g); total 250–350 g
    • bowl of soup          → 250–350 g total
    • cream soup            → 250–300 g total
    • stir-fry portion      → 200–350 g
    • steak with side       → 150–250 g meat + 150–250 g side
    • sushi (6–8 pieces)    → 150–200 g total
    • smoothie (cup)        → 250–350 ml
    • grated cheese on      → 10–30 g, not 60+
      a dish
    • oil / butter visible  → 5–15 g, not 30+
      on a salad / pasta
  Salty staples worth flagging explicitly — they push sodium hard:
    • soy sauce (1 tbsp ~15 g)  → 920 mg sodium
    • ham / bacon / deli meat (30 g)  → 350–450 mg sodium
    • hard cheese (30 g)        → 200–250 mg sodium
    • bread (1 slice ~30 g)     → 140–170 mg sodium
    • bouillon-based broth (250 g) → 500–800 mg sodium
  When you can't tell, lean toward the SMALLER end of the typical
  range — over-estimating ingredient grams pushes cholesterol /
  saturated fat / sodium into "worse" unfairly and the user notices.
  When sodium-heavy items are clearly present (deli meat in a
  sandwich, soy in sushi/poke, packaged broth) DO count them — the
  user expects the row to flag salt for visibly-salty dishes.
- `goal_fit` is REQUIRED. Evaluates the dish against the user's goal,
  which is provided in the user prompt (one of: weight loss / maintenance /
  muscle gain / balanced eating).
  Return up to 5 codes in `positive` and up to 5 in `negative`. Codes MUST
  come from this EXACT list and nothing else:
    HIGH_PROTEIN, CONTAINS_PROTEIN, LOW_PROTEIN, COMPLETE_PROTEIN,
    HEALTHY_FATS, RICH_IN_OMEGA3, HIGH_FAT, HIGH_SAT_FAT, HIGH_TRANS_FAT, LOW_FAT,
    HIGH_FIBER, CONTAINS_FIBER, LOW_FIBER, COMPLEX_CARBS, REFINED_CARBS,
    LOW_SUGAR, HIGH_SUGAR, LOW_CARB,
    HIGH_CALORIES, LOW_CALORIES, HIGH_ENERGY, HELPS_QUOTA,
    NUTRIENT_DENSE, EMPTY_CALORIES, HEAVY_MEAL, LIGHT_MEAL,
    HIGH_SALT, LOW_SALT, HIGH_CHOLESTEROL,
    GOOD_POST_WORKOUT, GOOD_PRE_WORKOUT, BREAKFAST_FRIENDLY,
    HEART_FRIENDLY, GUT_FRIENDLY, BRAIN_FOOD, IMMUNE_BOOST, BONE_HEALTH,
    RICH_IN_VITAMINS, RICH_IN_IRON, RICH_IN_CALCIUM, RICH_IN_POTASSIUM, HIGH_ANTIOXIDANTS,
    BALANCED_MACROS, WHOLE_FOODS, ULTRA_PROCESSED, PLANT_BASED, HYDRATING.
  Same code MUST NOT appear in both arrays.

  MUTUALLY EXCLUSIVE GROUPS — pick AT MOST ONE code per group, across
  both arrays combined. Choosing two opposites from the same group
  produces a self-contradicting card ("Has fiber" + "Low in fiber" at
  the same time) and is a HARD ERROR.
    • Protein level   : HIGH_PROTEIN  / CONTAINS_PROTEIN / LOW_PROTEIN
    • Fiber level     : HIGH_FIBER    / CONTAINS_FIBER  / LOW_FIBER
    • Carbs quality   : COMPLEX_CARBS / REFINED_CARBS
    • Sugar level     : LOW_SUGAR     / HIGH_SUGAR
    • Fat level       : HIGH_FAT      / LOW_FAT
    • Salt level      : HIGH_SALT     / LOW_SALT
    • Calorie level   : HIGH_CALORIES / LOW_CALORIES
    • Meal weight     : HEAVY_MEAL    / LIGHT_MEAL
    • Composition     : NUTRIENT_DENSE / EMPTY_CALORIES
    • Quality         : WHOLE_FOODS   / ULTRA_PROCESSED

  GOAL-DEPENDENT codes — pick the side that actually helps or hurts the
  stated goal. The full polarising list:
    HIGH_CALORIES, LOW_CALORIES, HIGH_ENERGY, LOW_FAT, LOW_CARB,
    HEAVY_MEAL, LIGHT_MEAL, REFINED_CARBS, HIGH_SUGAR, EMPTY_CALORIES,
    ULTRA_PROCESSED.

  Per goal:
    • WEIGHT LOSS  : refined carbs / high sugar / empty calories /
      ultra-processed / high calories / heavy meal all default to the
      `negative` array if they apply.
    • MUSCLE GAIN  : the bar is higher. Bulking diets routinely include
      rice, white pasta, white bread, oats with honey, post-workout
      shakes with sugar — these are FUEL, not flaws. Do NOT put
      REFINED_CARBS, HIGH_SUGAR, HIGH_CALORIES, HEAVY_MEAL, HIGH_ENERGY
      in `negative` for muscle gain unless the dish is genuinely
      junk-food shaped (deep-fried fast food, candy, sugary soda as the
      whole meal). For a normal post-workout meal with white rice or
      oats + honey: omit these codes entirely, or place them in
      `positive` when the dish reads as "fuel for the lift" (HIGH_ENERGY,
      HIGH_CALORIES). Reserve `negative` for things that actively work
      against muscle gain: LOW_PROTEIN, LOW_CALORIES, HIGH_TRANS_FAT,
      ULTRA_PROCESSED.
    • MAINTENANCE  : The polarising codes (HIGH_CALORIES, LOW_CALORIES,
      HIGH_ENERGY, LOW_FAT, LOW_CARB, HEAVY_MEAL, LIGHT_MEAL) should be
      used SPARINGLY. Skip them entirely unless the dish is genuinely
      extreme — e.g. HIGH_CALORIES only when the portion is clearly
      heavy (> ~800 kcal) AND nutrient-poor; LOW_CALORIES only for very
      light snacks (< ~150 kcal). For an everyday dish on a maintenance
      day, prefer composition codes (BALANCED_MACROS, WHOLE_FOODS,
      NUTRIENT_DENSE, HIGH_PROTEIN, RICH_IN_OMEGA3, GUT_FRIENDLY) over
      calorie-direction codes. 1–2 accurate codes beats 4–5 weak ones.
    • BALANCED EATING : same logic as maintenance — composition codes
      over calorie-direction ones.

  REFINED_CARBS THRESHOLD (when used): only flag it when refined-carb
  sources (white bread / white pasta / white rice / sugar-loaded sauces
  / sweet drinks / pastries) supply at least ~50 % of the dish's
  carbohydrate grams, OR contribute ≥ 20 g of refined-source carbs in
  absolute terms. A green salad with 30 g of croutons does NOT meet
  this bar — skip the code instead of clipping it on as negative.

  HIGH_SUGAR THRESHOLD (when used): only flag when added_sugar_g ≥ 15
  for the portion, OR total sugar_g ≥ 25 AND most of it is added /
  refined (sweetened drinks, dessert, candy). Whole fruit, plain milk,
  plain yogurt do NOT trigger this code on their own.

  Pick FEWER but ACCURATE codes — do not stretch to fill 5 slots. Both
  arrays may be empty if nothing applicable.

Respond STRICTLY as JSON (no markdown, no text before or after):
""" + _JSON_SCHEMA

_IMAGE_TASK_EN = """You are a professional dietitian / nutritionist. Analyse the food photograph and determine:
1. Dish name
2. Health rating (1-10) and a one-sentence health comment
3. Ingredient list with approximate weights
4. Protein / fat / carbs / calories for the whole portion and per 100 g"""

_TEXT_TASK_EN = """You are a professional dietitian / nutritionist. From the user's textual description of food, determine:
1. Dish name
2. Health rating (1-10) and a one-sentence health comment
3. Ingredient list with approximate weights
4. Protein / fat / carbs / calories for the whole portion and per 100 g

If the user gave an explicit weight — use it. Otherwise estimate a
standard portion."""


def build_image_prompt(locale: str | None, goal: str | None) -> str:
    lang = _language_name(locale)
    goal_desc = _goal_description(goal)
    return (
        f"{_IMAGE_TASK_EN}\n\n"
        f"Respond entirely in {lang}. All dish names, ingredient names and "
        f"any free-form text you produce (including `meal_quote`) must be "
        f"in {lang}. The only exception is the literal Cyrillic \"шт.\" "
        f"marker described below, which stays the same in every language. "
        f"`goal_fit` codes are language-independent — return them verbatim "
        f"in UPPER_SNAKE_CASE.\n\n"
        f"The user's goal is: {goal_desc}. Tailor `goal_fit` to this goal.\n\n"
        f"{_COMMON_RULES_EN}"
    )


def build_text_prompt(locale: str | None, goal: str | None) -> str:
    lang = _language_name(locale)
    goal_desc = _goal_description(goal)
    return (
        f"{_TEXT_TASK_EN}\n\n"
        f"Respond entirely in {lang}. All dish names, ingredient names and "
        f"any free-form text you produce (including `meal_quote`) must be "
        f"in {lang}. The only exception is the literal Cyrillic \"шт.\" "
        f"marker described below, which stays the same in every language. "
        f"`goal_fit` codes are language-independent — return them verbatim "
        f"in UPPER_SNAKE_CASE.\n\n"
        f"The user's goal is: {goal_desc}. Tailor `goal_fit` to this goal.\n\n"
        f"{_COMMON_RULES_EN}"
    )

MAX_DIMENSION = 768
JPEG_QUALITY = 75
# Output cap. Kept at the long-proven 2800: the Timeweb agent rejected larger
# values (4000) with a 4xx, breaking every recognition, so do NOT raise this
# without first confirming the agent's real max_tokens / context limit.
MAX_TOKENS = 2800

HTTP_TIMEOUT = 60.0
MAX_ATTEMPTS = 3
RETRY_BASE_DELAY = 1.0
# Bad-model-output kinds worth ONE in-process re-roll: the model returned
# HTTP 200 but unparseable / truncated JSON. Because temperature > 0, a second
# attempt often parses fine. We retry these here (cheaply, once) instead of
# letting the client retry the whole request 3× — see _request_and_parse.
_PARSE_ERROR_KINDS = frozenset({"truncated", "parse_error", "no_json", "bad_response"})
MAX_PARSE_REROLLS = 1
PACKAGED_ENRICH_TIMEOUT = 2.0
PACKAGED_ENRICH_MAX_ITEMS = 3

_PACKAGED_KEYWORDS = {
    "packaged", "package", "wrapper", "wrapped", "bar", "snack", "candy",
    "упаков", "батончик", "снэк", "снек", "сырок", "творож", "глазирован",
}

_GENERIC_MATCH_TOKENS = {
    "packaged", "package", "wrapper", "wrapped", "bar", "snack", "sweet",
    "dairy", "dessert", "продукт", "упаковка", "упакованный", "сладкий",
    "молочный", "десерт", "батончик", "сырок",
}


class AIRecognitionError(Exception):
    """Raised when AI recognition fails after retries or returns unparseable output."""

    def __init__(self, message: str, *, kind: str = "unknown", raw: str | None = None):
        super().__init__(message)
        self.kind = kind
        self.raw = raw


def normalize_image(image_bytes: bytes) -> str:
    """Convert any image to JPEG, resize if needed, return base64."""
    img = Image.open(io.BytesIO(image_bytes))
    img = ImageOps.exif_transpose(img)

    if img.mode in ('RGBA', 'P', 'LA'):
        background = Image.new('RGB', img.size, (255, 255, 255))
        if img.mode == 'P':
            img = img.convert('RGBA')
        background.paste(img, mask=img.split()[-1] if 'A' in img.mode else None)
        img = background
    elif img.mode != 'RGB':
        img = img.convert('RGB')

    w, h = img.size
    if max(w, h) > MAX_DIMENSION:
        ratio = MAX_DIMENSION / max(w, h)
        img = img.resize((int(w * ratio), int(h * ratio)), Image.LANCZOS)

    buf = io.BytesIO()
    img.save(buf, format='JPEG', quality=JPEG_QUALITY, optimize=True)
    jpeg_bytes = buf.getvalue()

    logger.info(
        "normalize_image: original=%d bytes, jpeg=%d bytes, size=%dx%d",
        len(image_bytes), len(jpeg_bytes), img.size[0], img.size[1],
    )
    return base64.b64encode(jpeg_bytes).decode('utf-8')


def _ai_url() -> str:
    return f"{settings.timeweb_ai_base_url}/{settings.timeweb_ai_agent_id}/v1/chat/completions"


def _ai_headers() -> dict:
    return {
        "Authorization": f"Bearer {settings.timeweb_ai_token}",
        "Content-Type": "application/json",
    }


_CODE_FENCE_RE = re.compile(r"```(?:json)?\s*(\{.*?\})\s*```", re.DOTALL | re.IGNORECASE)
_TRAILING_COMMA_RE = re.compile(r",(\s*[}\]])")
_LINE_COMMENT_RE = re.compile(r"//[^\n]*")
_BLOCK_COMMENT_RE = re.compile(r"/\*.*?\*/", re.DOTALL)


def _extract_json_candidate(content: str) -> str | None:
    """Try to pull a JSON object out of a noisy LLM response."""
    if not content:
        return None

    fence = _CODE_FENCE_RE.search(content)
    if fence:
        return fence.group(1)

    start = content.find('{')
    if start == -1:
        return None

    depth = 0
    in_string = False
    escape = False
    for i in range(start, len(content)):
        ch = content[i]
        if in_string:
            if escape:
                escape = False
            elif ch == '\\':
                escape = True
            elif ch == '"':
                in_string = False
            continue
        if ch == '"':
            in_string = True
        elif ch == '{':
            depth += 1
        elif ch == '}':
            depth -= 1
            if depth == 0:
                return content[start:i + 1]

    return content[start:]


def _clean_json_text(text: str) -> str:
    text = _BLOCK_COMMENT_RE.sub('', text)
    text = _LINE_COMMENT_RE.sub('', text)
    text = _TRAILING_COMMA_RE.sub(r'\1', text)
    return text.strip()


def _parse_ai_response(data: dict) -> dict:
    # Log the agent's own token accounting (OpenAI-compatible `usage` block).
    # We were discarding this; logging it turns token-cost estimates into
    # exact per-request numbers. Guarded so agents that omit it don't error.
    usage = data.get("usage") if isinstance(data, dict) else None
    if usage:
        logger.info(
            "AI usage: prompt_tokens=%s completion_tokens=%s total_tokens=%s",
            usage.get("prompt_tokens"),
            usage.get("completion_tokens"),
            usage.get("total_tokens"),
        )

    try:
        content = data["choices"][0]["message"]["content"]
    except (KeyError, IndexError, TypeError) as e:
        logger.error("AI response has unexpected shape: %s", json.dumps(data)[:500])
        raise AIRecognitionError(
            "Модель вернула некорректный ответ",
            kind="bad_response",
            raw=json.dumps(data)[:500],
        ) from e

    finish_reason = None
    try:
        finish_reason = data["choices"][0].get("finish_reason")
    except (KeyError, IndexError, TypeError):
        pass

    candidate = _extract_json_candidate(content or "")
    if candidate is None:
        logger.error("AI response has no JSON object. finish_reason=%s content=%r", finish_reason, content[:500])
        raise AIRecognitionError(
            "Модель не вернула JSON",
            kind="no_json",
            raw=content[:500],
        )

    cleaned = _clean_json_text(candidate)

    try:
        parsed = json.loads(cleaned)
        comment = parsed.get("health_comment")
        comment_preview = (comment or "")[:80] if isinstance(comment, str) else comment
        logger.info(
            "AI parsed: ingredients=%d health_rating=%s health_comment=%r "
            "comment_in_raw=%s finish_reason=%s",
            len(parsed.get("ingredients") or []),
            parsed.get("health_rating"),
            comment_preview,
            "health_comment" in (content or ""),
            finish_reason,
        )
        missing = [
            field for field in ("health_rating", "health_comment")
            if field not in parsed or parsed.get(field) in (None, "")
        ]
        if missing:
            logger.warning(
                "AI parsed: missing fields=%s. raw_tail=%r",
                missing, (content or "")[-400:],
            )
        return parsed
    except json.JSONDecodeError as e:
        truncated = finish_reason == "length"
        logger.error(
            "AI JSON decode failed: %s | finish_reason=%s | content=%r",
            e, finish_reason, content[:1000],
        )
        raise AIRecognitionError(
            "Ответ модели не разобрался как JSON"
            + (" (ответ обрезан — превышен лимит токенов)" if truncated else ""),
            kind="truncated" if truncated else "parse_error",
            raw=content[:1000],
        ) from e


_TAG_CODES_SET = frozenset(_TAG_CODES)


def _sanitize_goal_fit(parsed: dict) -> None:
    """Drop unknown/duplicate codes in goal_fit and cap each side at 5.

    The model is told to pick only from a closed list, but it sometimes
    hallucinates new codes or puts the same one in both arrays. The
    client cannot localise unknown codes, so we drop them here.
    """
    goal_fit = parsed.get("goal_fit")
    if not isinstance(goal_fit, dict):
        parsed["goal_fit"] = {"positive": [], "negative": []}
        return

    def _clean(arr) -> list[str]:
        if not isinstance(arr, list):
            return []
        seen: set[str] = set()
        out: list[str] = []
        for item in arr:
            if not isinstance(item, str):
                continue
            code = item.strip().upper()
            if code in _TAG_CODES_SET and code not in seen:
                seen.add(code)
                out.append(code)
        return out[:5]

    positive = _clean(goal_fit.get("positive"))
    negative = _clean(goal_fit.get("negative"))
    # Same code can't be on both sides — keep it on the positive side.
    pos_set = set(positive)
    negative = [c for c in negative if c not in pos_set]
    parsed["goal_fit"] = {"positive": positive, "negative": negative}


def _locale_code(locale: str | None) -> str:
    if not locale:
        return "en"
    return locale.lower().split("-")[0].split("_")[0] or "en"


def _normalise_product_text(value: str) -> str:
    value = re.sub(r"\(\d+\s*(?:шт\.?|pcs?\.?|pieces?)\)", " ", value, flags=re.IGNORECASE)
    value = value.lower()
    value = re.sub(r"[^0-9a-zа-яё]+", " ", value, flags=re.IGNORECASE)
    return re.sub(r"\s+", " ", value).strip()


def _tokens(value: str) -> set[str]:
    return {
        token
        for token in _normalise_product_text(value).split()
        if len(token) >= 3 and token not in _GENERIC_MATCH_TOKENS
    }


def _looks_like_packaged_item(name: str) -> bool:
    normalised = _normalise_product_text(name)
    if any(keyword in normalised for keyword in _PACKAGED_KEYWORDS):
        return True

    # Visible package labels often contain a short latin brand/product token
    # plus a flavour/count token (e.g. "TOM x2 coconut"). Avoid searching for
    # plain unpackaged foods like "salami" or "rice".
    latin_tokens = re.findall(r"\b[a-z0-9]{2,}\b", normalised)
    return len(latin_tokens) >= 2 and any(char.isdigit() for char in normalised)


def _product_match_score(query: str, product: dict) -> float:
    product_text = " ".join(
        str(part or "")
        for part in (
            product.get("brand"),
            product.get("name"),
            product.get("category"),
            product.get("composition"),
        )
    )
    query_tokens = _tokens(query)
    product_tokens = _tokens(product_text)
    if not query_tokens or not product_tokens:
        return 0.0

    overlap = query_tokens & product_tokens
    score = len(overlap) / len(query_tokens)
    query_norm = _normalise_product_text(query)
    product_norm = _normalise_product_text(product_text)
    if query_norm and query_norm in product_norm:
        score += 0.35
    if product.get("brand") and _normalise_product_text(str(product["brand"])) in query_norm:
        score += 0.15
    return score


async def _find_packaged_product(query: str, locale: str | None) -> dict | None:
    try:
        products = await asyncio.wait_for(
            openfoodfacts.search_products(
                query,
                page=1,
                page_size=5,
                locale=_locale_code(locale),
            ),
            timeout=PACKAGED_ENRICH_TIMEOUT,
        )
    except Exception as e:
        logger.info("OFF packaged enrichment skipped for query=%r: %s", query, e)
        return None

    scored = [
        (_product_match_score(query, product), product)
        for product in products
    ]
    scored.sort(key=lambda item: item[0], reverse=True)
    if not scored or scored[0][0] < 0.45:
        return None
    return scored[0][1]


def _apply_product_nutrition(ingredient: dict, product: dict) -> bool:
    calories = product.get("calories_per_100g")
    if calories is None:
        return False

    grams = (ingredient.get("grams") or 0) or product.get("weight_grams") or 100
    try:
        grams = float(grams)
    except (TypeError, ValueError):
        grams = 100.0
    if grams <= 0:
        grams = 100.0

    factor = grams / 100.0
    ingredient["grams"] = round(grams, 1)
    ingredient["calories"] = round(float(calories) * factor)

    for source_key, target_key in (
        ("protein_per_100g", "protein"),
        ("fat_per_100g", "fat"),
        ("carbs_per_100g", "carbs"),
    ):
        value = product.get(source_key)
        if value is not None:
            ingredient[target_key] = round(float(value) * factor, 1)

    product_name = product.get("name")
    brand = product.get("brand")
    if product_name:
        full_name = f"{brand} {product_name}".strip() if brand else product_name
        ingredient["name"] = full_name

    return True


def _recalculate_totals(result: dict) -> None:
    ingredients = result.get("ingredients") or []
    total_grams = sum(float(i.get("grams") or 0) for i in ingredients)
    totals = {
        "protein": sum(float(i.get("protein") or 0) for i in ingredients),
        "fat": sum(float(i.get("fat") or 0) for i in ingredients),
        "carbs": sum(float(i.get("carbs") or 0) for i in ingredients),
        "calories": sum(float(i.get("calories") or 0) for i in ingredients),
    }

    result["total_grams"] = round(total_grams, 1)
    result["total"] = {
        "protein": round(totals["protein"], 1),
        "fat": round(totals["fat"], 1),
        "carbs": round(totals["carbs"], 1),
        "calories": round(totals["calories"]),
    }
    if total_grams > 0:
        result["per_100g"] = {
            "protein": round(totals["protein"] / total_grams * 100, 1),
            "fat": round(totals["fat"] / total_grams * 100, 1),
            "carbs": round(totals["carbs"] / total_grams * 100, 1),
            "calories": round(totals["calories"] / total_grams * 100),
        }


async def _enrich_packaged_items(result: dict, locale: str | None) -> dict:
    ingredients = result.get("ingredients")
    if not isinstance(ingredients, list):
        return result

    candidates = [
        (index, str(item.get("name") or ""))
        for index, item in enumerate(ingredients)
        if isinstance(item, dict) and _looks_like_packaged_item(str(item.get("name") or ""))
    ][:PACKAGED_ENRICH_MAX_ITEMS]
    if not candidates:
        return result

    enriched = copy.deepcopy(result)
    matches = await asyncio.gather(
        *(_find_packaged_product(query, locale) for _, query in candidates),
        return_exceptions=True,
    )

    changed = False
    for (index, query), match in zip(candidates, matches):
        if isinstance(match, Exception) or not match:
            continue
        if _apply_product_nutrition(enriched["ingredients"][index], match):
            changed = True
            logger.info(
                "OFF packaged enrichment matched query=%r to product=%r",
                query,
                match.get("name"),
            )

    if changed:
        _recalculate_totals(enriched)
        return enriched
    return result


async def _post_with_retries(payload: dict) -> dict:
    last_exc: Exception | None = None
    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
                response = await client.post(_ai_url(), headers=_ai_headers(), json=payload)

            if response.status_code >= 500:
                snippet = response.text[:300]
                logger.warning(
                    "Timeweb AI returned %d on attempt %d/%d: %s",
                    response.status_code, attempt, MAX_ATTEMPTS, snippet,
                )
                last_exc = AIRecognitionError(
                    f"AI сервис временно недоступен (HTTP {response.status_code})",
                    kind="upstream_5xx",
                    raw=snippet,
                )
            elif response.status_code == 429:
                snippet = response.text[:300]
                logger.warning(
                    "Timeweb AI rate-limited on attempt %d/%d: %s",
                    attempt, MAX_ATTEMPTS, snippet,
                )
                last_exc = AIRecognitionError(
                    "AI сервис ограничил частоту запросов, попробуйте позже",
                    kind="rate_limited",
                    raw=snippet,
                )
            elif response.status_code >= 400:
                snippet = response.text[:500]
                logger.error(
                    "Timeweb AI returned %d (non-retryable): %s",
                    response.status_code, snippet,
                )
                raise AIRecognitionError(
                    f"AI сервис отклонил запрос (HTTP {response.status_code})",
                    kind="upstream_4xx",
                    raw=snippet,
                )
            else:
                return response.json()
        except (httpx.TimeoutException, httpx.TransportError, httpx.NetworkError) as e:
            logger.warning(
                "Timeweb AI network error on attempt %d/%d: %s: %s",
                attempt, MAX_ATTEMPTS, type(e).__name__, e,
            )
            last_exc = AIRecognitionError(
                "Не удалось связаться с AI сервисом",
                kind="network",
                raw=str(e),
            )

        if attempt < MAX_ATTEMPTS:
            delay = RETRY_BASE_DELAY * (2 ** (attempt - 1))
            await asyncio.sleep(delay)

    assert last_exc is not None
    raise last_exc


async def _request_and_parse(payload: dict) -> dict:
    """POST to the agent and parse the JSON, re-rolling once on bad output.

    `_post_with_retries` already handles transient HTTP failures (5xx / 429 /
    network). This wrapper additionally retries the *whole* call when the agent
    returns HTTP 200 with content we cannot parse (truncated / malformed JSON):
    a fresh sample usually succeeds. We cap this at MAX_PARSE_REROLLS so a
    persistently-broken response fails fast instead of burning tokens, and the
    client is told (via a non-retriable status) not to retry on top of this.
    """
    last_exc: AIRecognitionError | None = None
    for attempt in range(MAX_PARSE_REROLLS + 1):
        data = await _post_with_retries(payload)
        try:
            return _parse_ai_response(data)
        except AIRecognitionError as e:
            if e.kind not in _PARSE_ERROR_KINDS or attempt == MAX_PARSE_REROLLS:
                raise
            last_exc = e
            logger.warning(
                "AI parse failed (kind=%s) on attempt %d/%d — re-rolling",
                e.kind, attempt + 1, MAX_PARSE_REROLLS + 1,
            )
    assert last_exc is not None
    raise last_exc


async def recognize_food(
    image_bytes: bytes,
    *,
    text: str | None = None,
    locale: str | None = None,
    goal: str | None = None,
) -> dict:
    """Отправляет фото еды в Timeweb Cloud AI-агент для распознавания.

    Если передан text, он используется как сопроводительное описание к фото.
    locale — код языка UI (ru/en/de/es/fr/pt); модель должна отвечать именно на нём.
    goal — цель пользователя из онбординга: 'lose' / 'maintain' / 'gain'.
    """
    image_base64 = normalize_image(image_bytes)
    lang = _language_name(locale)
    goal_desc = _goal_description(goal)

    if text:
        user_text = (
            f"Here is a photo of food. User-provided description: \"{text}\". "
            f"Use explicit facts from the description as authoritative. "
            f"Identify the dish and its nutrition. The user's goal is "
            f"{goal_desc} — pick `goal_fit` codes accordingly. "
            f"Reply as JSON, in {lang}."
        )
    else:
        user_text = (
            f"Identify the dish in the photo and its nutrition. "
            f"The user's goal is {goal_desc} — pick `goal_fit` codes "
            f"accordingly. Reply as JSON, in {lang}."
        )

    payload = {
        "messages": [
            {"role": "system", "content": build_image_prompt(locale, goal)},
            {
                "role": "user",
                "content": [
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:image/jpeg;base64,{image_base64}"
                        },
                    },
                    {
                        "type": "text",
                        "text": user_text,
                    },
                ],
            },
        ],
        "temperature": 0.2,
        "max_tokens": MAX_TOKENS,
    }

    result = await _request_and_parse(payload)
    _sanitize_goal_fit(result)
    return await _enrich_packaged_items(result, locale)


async def recognize_food_from_text(
    text: str,
    *,
    locale: str | None = None,
    goal: str | None = None,
) -> dict:
    """Отправляет текстовое описание еды в Timeweb Cloud AI-агент для оценки КБЖУ.

    locale — код языка UI (ru/en/de/es/fr/pt); модель должна отвечать именно на нём.
    goal — цель пользователя из онбординга: 'lose' / 'maintain' / 'gain'.
    """
    lang = _language_name(locale)
    goal_desc = _goal_description(goal)
    user_text = (
        f"User description of the food: \"{text}\".\n"
        f"Identify the dish and its nutrition. The user's goal is "
        f"{goal_desc} — pick `goal_fit` codes accordingly. "
        f"Reply as JSON, in {lang}."
    )
    payload = {
        "messages": [
            {"role": "system", "content": build_text_prompt(locale, goal)},
            {"role": "user", "content": user_text},
        ],
        "temperature": 0.2,
        "max_tokens": MAX_TOKENS,
    }

    result = await _request_and_parse(payload)
    _sanitize_goal_fit(result)
    return result
