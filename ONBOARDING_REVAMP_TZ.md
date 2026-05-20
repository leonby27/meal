# ТЗ: Переработка онбординга MealTracker для повышения конверсии в trial

## Контекст

MealTracker — Flutter-приложение для учёта питания с AI-распознаванием блюд по фото (Gemini API). Hard paywall между онбордингом и основным приложением. Цены: $4.99/нед (3-day trial), $39.99/год (7-day trial). Платформы: Android и iOS, приложение уже опубликовано.

**Текущее состояние** (см. `ONBOARDING_TZ.md` для базовой архитектуры): онбординг 8 экранов → paywall. Структура реализована в `app/lib/features/onboarding/`.

**Цель этого ТЗ**: переработать онбординг с 8 на 12 экранов с добавлением высоко-конверсионных элементов из плейбуков топ-апп (Cal AI, Noom, BetterMe). Ожидаемый эффект — рост конверсии «онбординг → trial start» в 2-3 раза.

**Что НЕ в скоупе этого ТЗ:**
- Paywall (`paywall_screen.dart`) — структурно одобрен Apple, не меняем
- Биллинг / RevenueCat / `in_app_purchase` — оставляем как есть
- Цены и продукты в App Store Connect — не трогаем
- Локализация на новые языки — отдельной задачей
- Аналитика / атрибуция / AppsFlyer — отдельной задачей

---

## Новая структура флоу (12 шагов + paywall)

| # | Шаг | Файл | Статус |
|---|---|---|---|
| 1 | Цель (Lose / Maintain / Gain) | `goal_step.dart` | **Без изменений** |
| 2 | Препятствия (multi-select) | `obstacles_step.dart` | **НОВЫЙ** |
| 3 | Пол | `gender_step.dart` | Без изменений |
| 4 | Возраст | `age_step.dart` | Без изменений |
| 5 | Рост + Вес | `measurements_step.dart` | Без изменений |
| 6 | Целевой вес | `target_weight_step.dart` | Без изменений |
| 7 | Скорость похудения (ползунок) | `weight_loss_speed_step.dart` | **НОВЫЙ** (только для lose/gain) |
| 8 | Уровень активности | `activity_step.dart` | Без изменений |
| 9 | Поведенческий мини-квиз | `behavioral_quiz_step.dart` | **НОВЫЙ** |
| 10 | Экран загрузки (8-12 сек) | `loading_step.dart` | **Переработать** (с 3.5 сек) |
| 11 | Персональный план | `result_step.dart` | **Переработать** (4 новых блока) |
| 12 | Запрос оценки в App Store | `rate_prompt_step.dart` | **НОВЫЙ** (опционально, можно делать вторым этапом) |
| — | Paywall | `paywall_screen.dart` | Без изменений (отдельная задача) |

**Прогресс-бар вверху**: 12 шагов (была 8). Шаг 7 показывается только если `goal == 'lose'` или `goal == 'gain'` — для `maintain` пропускается, прогресс-бар адаптируется (11 шагов).

**Логика навигации**: `PageView` с горизонтальным свайпом, анимация slide 300ms `Curves.easeInOut`. Кнопка «Назад» (стрелка) на всех шагах кроме первого. На шагах 10 и 12 кнопки «Назад» нет (см. ниже).

---

## Изменения в data-модели `OnboardingData`

**Файл**: `app/lib/features/onboarding/models/onboarding_data.dart`

Добавить поля:

```dart
class OnboardingData {
  // Существующие поля (без изменений)
  String? goal;
  String? gender;
  int age = 25;
  double heightCm = 170;
  double weightKg = 70.0;
  double targetWeightKg = 65.0;
  double activityMultiplier = 1.55;

  // НОВЫЕ поля
  Set<String> obstacles = {};           // Шаг 2: множественный выбор
  double weightLossKgPerWeek = 0.7;     // Шаг 7: ползунок 0.2-1.5
  Map<String, int> behavioralScores = {}; // Шаг 9: 5 ползунков, ключ → значение 0-100
  String? psychotype;                    // Вычисляется после шага 9

  // Существующие рассчитанные поля
  double? calorieGoal;
  double? proteinGoal;
  double? fatGoal;
  double? carbsGoal;
  DateTime? targetDate;
}
```

---

## Шаг 2: Препятствия (НОВЫЙ)

**Файл**: `app/lib/features/onboarding/widgets/steps/obstacles_step.dart`

### Дизайн

- **Заголовок**: «Что мешало вам раньше?»
- **Подзаголовок**: «Выберите всё, что относится к вам» (мелкий, `onSurfaceVariant`)
- **Список карточек** (множественный выбор, минимум 1 для активации «Далее»):

| Значение (key) | Текст карточки | Иконка |
|---|---|---|
| `consistency` | Не получается быть последовательным | `Icons.repeat` |
| `knowledge` | Не знаю, что есть | `Icons.help_outline` |
| `busy` | Загруженный график | `Icons.schedule` |
| `cravings` | Сильная тяга к сладкому/мучному | `Icons.cake_outlined` |
| `support` | Нет поддержки | `Icons.group_outlined` |
| `eating_out` | Часто ем вне дома | `Icons.restaurant` |
| `motivation` | Не хватает мотивации | `Icons.bolt_outlined` |
| `tracking` | Сложно считать калории | `Icons.calculate_outlined` |

### Поведение

- Карточки: высота ~72px, скруглённые углы 16px
- Неактивная: фон `surface`, бордер `outline`
- Активная (выбрана): фон `primaryContainer`, бордер `primary` (2px), галочка `Icons.check_circle` справа цветом `primary`
- Можно тапать несколько раз — toggle on/off
- Сохранять в `onboardingData.obstacles` как `Set<String>`
- Кнопка «Далее» активна только если выбран хотя бы 1 пункт

### Аналитика-эвент

`onboarding_obstacles_selected` с параметром `count: int`, `selected: List<String>`.

---

## Шаг 7: Скорость похудения (НОВЫЙ, показывается только для lose/gain)

**Файл**: `app/lib/features/onboarding/widgets/steps/weight_loss_speed_step.dart`

### Условие отображения

В `onboarding_flow.dart` — пропускать этот шаг если `onboardingData.goal == 'maintain'`. Прогресс-бар адаптировать: при `maintain` показывать 11 шагов, при `lose/gain` — 12.

### Дизайн

- **Заголовок** (зависит от goal):
  - `lose`: «Как быстро хотите похудеть?»
  - `gain`: «Как быстро хотите набрать массу?»
- **Подзаголовок**: «Рекомендуемый темп — 0.5 кг/неделю» (мелкий, `onSurfaceVariant`)

- **Ползунок** по центру экрана:
  - Диапазон: 0.2 — 1.5 кг/нед, шаг 0.1
  - Значение по умолчанию: 0.5
  - Над ползунком — крупная подпись с текущим значением: «0.5 кг/неделю» (32sp, `FontWeight.w700`)
  - Под ползунком — **live-feedback бейдж**, меняется в зависимости от значения:

| Значение | Текст бейджа | Цвет фона |
|---|---|---|
| 0.2 — 0.4 | «Мягкий темп ✅» | `AppColors.green` |
| 0.5 — 0.7 | «Рекомендуемый темп ⭐» | `AppColors.primary` |
| 0.8 — 1.0 | «Амбициозно 🔥» | `AppColors.orange` |
| 1.1 — 1.5 | «Очень агрессивно ⚠️» | `AppColors.red` |

- **Под бейджем** — live-расчёт даты достижения цели:
  ```
  Вы достигнете 65 кг к [рассчитанная_дата]
  ```
  Дата пересчитывается мгновенно при движении ползунка. Формула:
  ```dart
  double weightDiff = (currentWeight - targetWeight).abs();
  int weeksNeeded = (weightDiff / weightLossKgPerWeek).ceil();
  DateTime targetDate = DateTime.now().add(Duration(days: weeksNeeded * 7));
  ```

### Поведение

- Сохранять выбранное значение в `onboardingData.weightLossKgPerWeek`
- Кнопка «Далее» активна сразу (есть значение по умолчанию 0.5)
- HapticFeedback.selectionClick() на каждое изменение значения

### Аналитика-эвент

`onboarding_weight_loss_speed_selected` с параметром `kg_per_week: double`.

### Влияние на расчёт калорий

В `tdee_calculator.dart` обновить формулу — использовать `weightLossKgPerWeek` вместо фиксированного дефицита 500/300 ккал.

Логика: 1 кг жира ≈ 7700 ккал. Поэтому при потере 0.5 кг/нед дефицит = 0.5 × 7700 / 7 = ~550 ккал/день.

```dart
// В TdeeCalculator.calculate():
double weeklyKgChange = goal == 'lose' ? -weightLossKgPerWeek : 
                       goal == 'gain' ? weightLossKgPerWeek : 0;
double dailyKcalDelta = (weeklyKgChange * 7700) / 7;
double calorieGoal = tdee + dailyKcalDelta;
calorieGoal = calorieGoal.clamp(1200, 5000);
```

---

## Шаг 9: Поведенческий мини-квиз (НОВЫЙ)

**Файл**: `app/lib/features/onboarding/widgets/steps/behavioral_quiz_step.dart`

### Дизайн

- **Заголовок**: «Расскажите о ваших привычках»
- **Подзаголовок**: «Это поможет персонализировать ваш план» (мелкий, `onSurfaceVariant`)

- **5 ползунков** вертикально, каждый между двумя утверждениями:

| Ключ | Левый текст (0) | Правый текст (100) |
|---|---|---|
| `stress_eating` | Часто ем от стресса | Ем только для энергии |
| `sweet_preference` | Люблю сладкое | Предпочитаю солёное/острое |
| `exercise_consistency` | Тренируюсь постоянно | Не получается заниматься регулярно |
| `meal_planning` | Планирую приёмы пищи | Ем что под рукой |
| `motivation_type` | Меня двигают результаты | Меня двигают ощущения |

### Дизайн ползунка

- Ползунок горизонтальный, цвет трека: linear gradient от `AppColors.blue` к `AppColors.orange`
- Под ползунком — левый текст слева, правый справа (мелкий, `onSurfaceVariant`)
- Значение по умолчанию: 50 (центр)
- Шаг: 1
- Высота элемента: ~96px (текст сверху + ползунок + подписи снизу)

### Поведение

- Все 5 ползунков на одном экране (скролл если не помещается)
- Сохранять в `onboardingData.behavioralScores` как `Map<String, int>`
- Кнопка «Далее» активна сразу (все ползунки имеют дефолт 50)
- HapticFeedback.selectionClick() на каждое изменение

### Логика расчёта психотипа

При нажатии «Далее» — вычислить `psychotype` и сохранить в `onboardingData.psychotype`:

```dart
String computePsychotype(Map<String, int> scores) {
  // Найти ползунок с наибольшим отклонением от центра 50
  String? extremeKey;
  int maxDeviation = 0;
  scores.forEach((key, value) {
    int deviation = (value - 50).abs();
    if (deviation > maxDeviation) {
      maxDeviation = deviation;
      extremeKey = key;
    }
  });

  // Если все ползунки около центра (отклонение < 25) — Balanced
  if (maxDeviation < 25) return 'balanced';

  // Иначе — психотип по ключу и стороне
  final value = scores[extremeKey]!;
  switch (extremeKey) {
    case 'stress_eating':
      return value < 50 ? 'stress_eater' : 'fuel_focused';
    case 'sweet_preference':
      return value < 50 ? 'sweet_lover' : 'savory_lover';
    case 'exercise_consistency':
      return value < 50 ? 'consistent_athlete' : 'inconsistent';
    case 'meal_planning':
      return value < 50 ? 'planner' : 'convenience_eater';
    case 'motivation_type':
      return value < 50 ? 'results_driven' : 'feelings_driven';
    default:
      return 'balanced';
  }
}
```

### Таблица психотипов (для отображения на экране плана)

| Значение `psychotype` | Заголовок на экране плана | Описание |
|---|---|---|
| `stress_eater` | The Stress Eater | «Вы едите от эмоций. Мы поможем найти альтернативы» |
| `fuel_focused` | The Fuel Master | «Вы рациональны в питании. Останется только точно посчитать» |
| `sweet_lover` | The Sweet Tooth | «Мы научим заменять сладкое без срывов» |
| `savory_lover` | The Savory Seeker | «Острое и солёное — ваш стиль. Найдём баланс по натрию» |
| `consistent_athlete` | The Consistent One | «У вас сильная база. Точная диета умножит результат» |
| `inconsistent` | The Restart Hero | «Главное — начать снова. Мы упростим возврат» |
| `planner` | The Planner | «Вы любите контроль. Дайте AI просчитать всё за вас» |
| `convenience_eater` | The Convenience Eater | «Времени мало — поможем выбирать быстро и правильно» |
| `results_driven` | The Achiever | «Вас двигают цифры. Покажем прогресс наглядно» |
| `feelings_driven` | The Mindful Eater | «Вы слушаете себя. Мы дополним это данными» |
| `balanced` | The Balanced Approach | «У вас здоровый подход к питанию. Усилим его данными» |

### Аналитика-эвент

`onboarding_behavioral_quiz_completed` с параметрами `psychotype: String` и `scores: Map`.

---

## Шаг 10: Экран загрузки (переработать)

**Файл**: `app/lib/features/onboarding/widgets/steps/loading_step.dart`

### Изменения

Длительность: было **3.5 секунды**, стало **10 секунд** (5 подписей по 2 секунды).

Подписи (меняются каждые 2 секунды):
1. 0-2с: «Анализируем ваш метаболизм...»
2. 2-4с: «Рассчитываем дневную норму калорий...»
3. 4-6с: «Подбираем баланс белков / жиров / углеводов...»
4. 6-8с: «Анализируем ваш психотип и привычки...»
5. 8-10с: «Создаём персональный план...»

Каждая подпись — fade-in 300ms, fade-out 300ms при смене.

Круговой прогресс-бар по центру — анимация 0% → 100% за 10 секунд линейно.

### Дизайн

- Кнопок «Далее» и «Назад» НЕТ (`Scaffold` с `AppBar` без `leading`)
- `WillPopScope` / `PopScope` блокирует системную кнопку «Назад»
- После 10 секунд — автоматический переход на шаг 11 (Result)
- Прогресс-бар онбординга вверху показывает «10/12» (или 9/11 для maintain)

### Логика

Расчёт калорий и макросов из `TdeeCalculator.calculate()` выполняется в фоне в первые 100мс после монтирования экрана. Псевдо-задержка — чисто UX-приём для создания ощущения «AI работает над тобой».

---

## Шаг 11: Персональный план (переработать)

**Файл**: `app/lib/features/onboarding/widgets/steps/result_step.dart`

Сейчас экран содержит: дневную норму калорий (32sp), макросы 3 колонки, простой график прогноза. Менять на структуру ниже.

### Новая структура (сверху вниз)

#### Блок 1: Hero-заголовок

```
🎉 Ваш план готов!
```
- 24sp, `FontWeight.w700`, цвет `onSurface`
- По центру, 32px от верха

#### Блок 2: Якорная дата (САМЫЙ ВАЖНЫЙ элемент экрана)

Карточка по центру с большим скруглением (24px), фон `primaryContainer`:

```
Вы достигнете 65 кг к
─────────────────────
   14 августа 2026
─────────────────────
        (через 14 недель)
```

- Текст «Вы достигнете X кг к» — 14sp, `onSurfaceVariant`
- Дата — **32sp, FontWeight.w800, цвет `primary`**
- Подпись «(через X недель)» — 12sp, `onSurfaceVariant`

Для `goal == 'maintain'`: вместо этой карточки — карточка «Мы поможем удержать вес на 70 кг» с иконкой `Icons.check_circle` зелёного цвета.

#### Блок 3: Дневная норма калорий

```
ВАША ДНЕВНАЯ НОРМА
   1 850 ккал
```

- Подпись сверху — 11sp, `letterSpacing: 1.5`, `onSurfaceVariant`, UPPERCASE
- Цифра калорий — **48sp** (было 32sp), `FontWeight.w800`, цвет `primary`
- По центру экрана

#### Блок 4: Макросы (3 колонки)

Как в текущем дизайне, но крупнее:
- Каждая колонка: число 24sp (было 20sp), `FontWeight.w700`
- Подпись «г» сразу после числа, 14sp, тот же цвет
- Под цифрой подпись «Белки» / «Жиры» / «Углеводы» 12sp, `onSurfaceVariant`
- Над цифрой — иконка `Icons.fitness_center` / `Icons.opacity` / `Icons.grain` соответствующего цвета (`AppColors.blue` / `AppColors.orange` / `AppColors.green`)

#### Блок 5: Психотип

Карточка с фоном `surfaceContainerLow`, скругление 16px, отступ от макросов 24px:

```
┌─────────────────────────────────────┐
│  Ваш тип питания: The Stress Eater  │
│  Вы едите от эмоций. Мы поможем     │
│  найти альтернативы.                │
└─────────────────────────────────────┘
```

- Заголовок «Ваш тип питания: [psychotype_title]» — 16sp, `FontWeight.w600`
- Описание — 13sp, `onSurfaceVariant`, leading 18px
- Текст психотипа подтягивается из таблицы выше (шаг 9)

#### Блок 6: «Ваш план учитывает»

Только если `onboardingData.obstacles.isNotEmpty`. Список выбранных препятствий с иконкой `Icons.check` слева:

```
Ваш план учитывает:
✓ Загруженный график
✓ Сильная тяга к сладкому/мучному
✓ Не знаю, что есть
```

- Заголовок — 14sp, `FontWeight.w600`
- Каждый пункт — 13sp, иконка check цветом `primary`

#### Блок 7: Milestone preview (только для lose/gain)

Только если `goal != 'maintain'`. Карточка со скруглёнными углами:

```
Ваш прогресс по неделям:
─────────────────────────
Неделя 1:  ████████ 69.5 кг
Неделя 2:  ███████  69.0 кг
Неделя 3:  ██████   68.5 кг
Неделя 4:  █████    68.0 кг
Неделя 5:  ████     67.5 кг
...        ...
Цель:      █        65.0 кг
─────────────────────────
```

Простая визуализация: горизонтальные полосы убывающей/возрастающей длины, рядом цифры весов. Показывать минимум 5 недель + последнюю (финальную).

Реализация — через `CustomPaint` или просто `Row` с `Container` фиксированной ширины.

#### Блок 8: Кнопка «Начать»

- В самом низу, ширина на всю ширину с отступами 24px
- Текст: «Начать мой план»
- Стиль — как «Далее», но текст другой
- При нажатии: сохранение в `UserSettings` (логика как в текущем `result_step.dart`) + переход на шаг 12 (Rate prompt) или сразу на paywall (если шаг 12 не реализован)

### Сохранение в UserSettings (без изменений + новые ключи)

В дополнение к существующим ключам добавить:
```
user_obstacles = 'consistency,busy,cravings'  (CSV выбранных)
user_weight_loss_speed = '0.7'
user_psychotype = 'stress_eater'
```

---

## Шаг 12: Запрос оценки в App Store (НОВЫЙ, опционально вторым этапом)

**Файл**: `app/lib/features/onboarding/widgets/steps/rate_prompt_step.dart`

### Зачем

Поймать 5★ в момент peak excitement (после показа плана, до того как юзер увидит цену). Cal AI и SnapCalorie делают именно так — это в 5-10 раз эффективнее по конверсии в оценку, чем стандартное «после 7-го дня использования».

### Дизайн

- **Заголовок**: «Нравится ваш план?»
- **Подзаголовок**: «Оцените MealTracker — это поможет нам стать лучше»
- По центру: **5 звёздочек** (Material `Icons.star_border` / `Icons.star`), которые можно тапать по очереди или сразу выбрать число от 1 до 5
- Под звёздочками: кнопка «Оценить» (активируется после выбора рейтинга)
- Кнопка «Пропустить» мелким текстом снизу

### Поведение

При нажатии «Оценить»:
- Если рейтинг **4-5★**: вызвать `InAppReview.requestReview()` (пакет `in_app_review: ^2.0.10`), затем перейти на paywall
- Если рейтинг **1-3★**: НЕ вызывать `InAppReview` (нельзя гнать негатив в App Store). Вместо этого показать BottomSheet с TextField «Что мы можем улучшить?» → submit (можно просто логировать в Firebase Analytics + email/Slack) → перейти на paywall
- При «Пропустить» — сразу перейти на paywall

### Аналитика-эвент

`onboarding_rate_prompted` с `rating: int? (null если скип)`, `submitted_review: bool`.

### Альтернатива

Если реализация `in_app_review` сейчас тяжела — можно отложить шаг 12 и **переходить с шага 11 (Result) прямо на paywall**. Прогресс-бар тогда показывать 11/11 на шаге Result.

---

## Изменения в `OnboardingFlow` контроллере

**Файл**: `app/lib/features/onboarding/widgets/onboarding_flow.dart`

### Список шагов

Заменить статический список 8 шагов на динамический в зависимости от `onboardingData.goal`:

```dart
List<Widget> _buildSteps() {
  final steps = <Widget>[
    GoalStep(...),
    ObstaclesStep(...),       // НОВЫЙ
    GenderStep(...),
    AgeStep(...),
    MeasurementsStep(...),
    TargetWeightStep(...),
    if (onboardingData.goal != 'maintain')
      WeightLossSpeedStep(...),  // НОВЫЙ, только lose/gain
    ActivityStep(...),
    BehavioralQuizStep(...),     // НОВЫЙ
    LoadingStep(...),
    ResultStep(...),
    // RatePromptStep(...),      // НОВЫЙ, опционально
  ];
  return steps;
}
```

### Прогресс-бар

Адаптивный: `totalSteps = steps.length`, `currentStep = pageController.page + 1`. На шагах Loading и RatePrompt — прогресс-бар показывать как раньше (не скрывать), но кнопка «Назад» отсутствует.

### Анимация перехода

Без изменений — `Curves.easeInOut`, 300ms.

---

## Обновления в `TdeeCalculator`

**Файл**: `app/lib/features/onboarding/services/tdee_calculator.dart`

### Обновлённый расчёт калорий

Заменить фиксированные дефициты (500/300) на расчёт от `weightLossKgPerWeek`:

```dart
static Map<String, double> calculate({
  required String gender,
  required int age,
  required double heightCm,
  required double weightKg,
  required double activityMultiplier,
  required String goal,
  required double weightLossKgPerWeek,  // НОВЫЙ параметр
}) {
  double bmr;
  if (gender == 'male') {
    bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
  } else {
    bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
  }
  double tdee = bmr * activityMultiplier;

  // НОВАЯ логика: дефицит/профицит зависит от скорости
  double dailyKcalDelta;
  switch (goal) {
    case 'lose':
      dailyKcalDelta = -(weightLossKgPerWeek * 7700 / 7);  // ~550 ккал при 0.5 кг/нед
    case 'gain':
      dailyKcalDelta = (weightLossKgPerWeek * 7700 / 7) * 0.6;  // 60% от расчёта для безопасного набора
    default:
      dailyKcalDelta = 0;
  }

  double calorieGoal = (tdee + dailyKcalDelta).clamp(1200, 5000);

  return {
    'calories': calorieGoal.roundToDouble(),
    'protein': ((calorieGoal * 0.30) / 4).roundToDouble(),
    'fat': ((calorieGoal * 0.25) / 9).roundToDouble(),
    'carbs': ((calorieGoal * 0.45) / 4).roundToDouble(),
  };
}
```

### Обновлённый расчёт даты

```dart
static DateTime estimateTargetDate({
  required double currentWeight,
  required double targetWeight,
  required String goal,
  required double weightLossKgPerWeek,
}) {
  double diff = (currentWeight - targetWeight).abs();
  if (weightLossKgPerWeek <= 0 || goal == 'maintain') return DateTime.now();
  int weeks = (diff / weightLossKgPerWeek).ceil();
  return DateTime.now().add(Duration(days: weeks * 7));
}
```

### Новый метод: расчёт milestone weeks

```dart
static List<({int week, double weight, DateTime date})> generateMilestones({
  required double currentWeight,
  required double targetWeight,
  required double weightLossKgPerWeek,
  required String goal,
  int maxWeeks = 6,
}) {
  if (goal == 'maintain') return [];
  
  final direction = goal == 'lose' ? -1 : 1;
  final totalWeeks = ((currentWeight - targetWeight).abs() / weightLossKgPerWeek).ceil();
  final stepsToShow = totalWeeks < maxWeeks ? totalWeeks : maxWeeks - 1;
  
  final milestones = <({int week, double weight, DateTime date})>[];
  for (int i = 1; i <= stepsToShow; i++) {
    final weight = currentWeight + (direction * weightLossKgPerWeek * i);
    final date = DateTime.now().add(Duration(days: i * 7));
    milestones.add((week: i, weight: weight, date: date));
  }
  
  // Финальная milestone — цель
  if (totalWeeks > maxWeeks - 1) {
    final finalDate = DateTime.now().add(Duration(days: totalWeeks * 7));
    milestones.add((week: totalWeeks, weight: targetWeight, date: finalDate));
  }
  
  return milestones;
}
```

---

## Аналитика-эвенты (обновлённый список)

В `firebase_analytics` (если уже подключён, иначе подключить):

| Событие | Когда | Параметры |
|---|---|---|
| `onboarding_started` | Открытие шага 1 | — |
| `onboarding_step_completed` | Нажатие «Далее» на каждом шаге | `step: 1-12`, `step_name: String` |
| `onboarding_obstacles_selected` | После шага 2 | `count: int`, `selected: String (csv)` |
| `onboarding_weight_loss_speed_selected` | После шага 7 | `kg_per_week: double` |
| `onboarding_behavioral_quiz_completed` | После шага 9 | `psychotype: String`, `scores: String (json)` |
| `onboarding_plan_revealed` | Открытие шага 11 | `calorie_goal: int`, `target_date_weeks: int`, `psychotype: String` |
| `onboarding_rate_prompted` | На шаге 12 (если реализован) | `rating: int?`, `submitted: bool` |
| `onboarding_completed` | Нажатие «Начать мой план» | `calorie_goal: int`, `goal: String`, `psychotype: String` |

---

## Acceptance criteria (что должно работать после реализации)

1. ✅ Юзер с целью `lose` или `gain` проходит **12 экранов** до paywall (11 для `maintain`)
2. ✅ Ползунок скорости похудения **скрывается** для `maintain`-юзеров
3. ✅ На шаге 7 при движении ползунка дата достижения цели **обновляется в реальном времени**
4. ✅ На шаге 11 показывается **якорная дата** крупным шрифтом — главный визуальный элемент
5. ✅ Психотип на шаге 11 **подтягивается** из ответов шага 9 по таблице маппинга
6. ✅ Выбранные на шаге 2 препятствия **отображаются** на шаге 11 в блоке «Ваш план учитывает»
7. ✅ Milestone preview на шаге 11 показывает **5-6 недель прогресса** + финальную цель
8. ✅ Экран загрузки длится **10 секунд** с 5 сменяющимися подписями
9. ✅ Расчёт калорий **зависит от выбранной скорости** похудения (не фиксированные 500 ккал)
10. ✅ Все новые данные **сохраняются в UserSettings** через `app_database.dart`
11. ✅ Прогресс-бар вверху **адаптируется** под количество шагов (11 или 12)
12. ✅ Тёмная тема **корректно работает** на всех новых экранах
13. ✅ Назад-кнопка работает на всех шагах кроме 1, 10 и 12
14. ✅ Все строки **на русском** (локализация — отдельной задачей)
15. ✅ Существующий paywall (`paywall_screen.dart`) **не сломан** и открывается после шага 11/12
16. ✅ Существующая авторизация, дневник, поиск, сканер еды **работают как раньше**

---

## Edge cases

1. **Юзер ничего не выбрал на шаге 2** — кнопка «Далее» неактивна (серая)
2. **Юзер выбрал target weight == current weight для lose/gain** — показать SnackBar «Целевой вес должен отличаться от текущего», вернуть на шаг 6
3. **Юзер выбрал psychotype со score == 50 на всех ползунках** — assign `balanced`
4. **Юзер свайпает назад с шага 10 (Loading)** — заблокировать через `PopScope(canPop: false)`
5. **Юзер фоном свернул приложение на шаге 10** — при возврате таймер продолжается с момента сворачивания (не сбрасывается)
6. **Прыжок назад с шага 11 на шаг 9** — все промежуточные шаги остаются заполненными (`OnboardingData` хранится в state OnboardingFlow)
7. **Адаптивность** — на маленьких экранах (320-360px ширина) шаг 11 должен скроллиться вертикально
8. **Юзер выбрал weight loss speed 1.5 кг/нед** — расчёт калорий даёт <1200 → clamp срабатывает, показывается 1200 + предупреждение «Минимальная безопасная норма» в блоке калорий

---

## Что НЕ менять в этом ТЗ

- `paywall_screen.dart` — структурно одобрен Apple, изменения паузы
- Файлы вне `app/lib/features/onboarding/` — НЕ трогаем
- Биллинг, RevenueCat, `in_app_purchase` — отдельная задача
- Цены, App Store Connect конфигурация — отдельная задача
- Существующие тарифы $4.99/нед и $39.99/год — оставить как есть
- Триал 3 дня на недельной — оставить как есть (изменение на 7-дневный — отдельная задача)
- Локализация на новые языки — отдельной задачей
- Сложные анимации, lottie — не нужны, обычные fade/slide достаточно

---

## Этапы реализации (порядок работы)

Если разбивать на этапы, оптимальный порядок:

**Этап 1 (база, 1-2 дня):**
- Обновить `OnboardingData` модель (новые поля)
- Создать `ObstaclesStep` (шаг 2)
- Создать `WeightLossSpeedStep` (шаг 7)
- Обновить `TdeeCalculator` (новая формула + milestone метод)
- Обновить `OnboardingFlow` (динамический список шагов)

**Этап 2 (психология, 1-2 дня):**
- Создать `BehavioralQuizStep` (шаг 9)
- Маппинг психотипов
- Переработать `LoadingStep` (10 сек)

**Этап 3 (Plan reveal redesign, 1.5-2 дня):**
- Переработать `ResultStep` со всеми 8 блоками
- Якорная дата как главный элемент
- Milestone visualization (CustomPaint или простой Row)
- Блок психотипа + блок препятствий

**Этап 4 (опционально, 0.5 дня):**
- `RatePromptStep` с `in_app_review`

**Итого: ~5 дней работы для опытного Flutter-разработчика.**

---

## Зависимости

В `pubspec.yaml` могут потребоваться:
- `in_app_review: ^2.0.10` — для шага 12 (опционально)
- `flutter_haptic_feedback` или встроенный `HapticFeedback` из `services.dart` — для тактильной обратной связи

Остальное уже должно быть в проекте (`firebase_analytics`, `flutter_riverpod` или используемый state management).
