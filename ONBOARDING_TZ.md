# ТЗ: Онбординг + Paywall для MealTracker

## Контекст

Приложение MealTracker — трекер калорий и БЖУ на Flutter. Сейчас при первом запуске пользователь попадает на экран логина (`LoginScreen`), авторизуется через Google или гостевой режим и сразу попадает в дневник. Нужно добавить онбординг-флоу с персонализацией и paywall между авторизацией и основным приложением.

**Цель:** максимизировать конверсию в подписку через персонализированный онбординг.

**Язык интерфейса:** русский (позже будет добавлена локализация на английский, но сейчас всё на русском).

---

## Архитектура

### Новые файлы

```
app/lib/features/onboarding/
├── models/
│   └── onboarding_data.dart          # Модель данных онбординга
├── services/
│   └── tdee_calculator.dart          # Расчёт TDEE по Mifflin-St Jeor
├── widgets/
│   ├── onboarding_flow.dart          # Главный контроллер флоу (PageView)
│   ├── steps/
│   │   ├── goal_step.dart            # Экран 1: Цель
│   │   ├── gender_step.dart          # Экран 2: Пол
│   │   ├── age_step.dart             # Экран 3: Возраст
│   │   ├── measurements_step.dart    # Экран 4: Рост + Вес
│   │   ├── target_weight_step.dart   # Экран 5: Желаемый вес
│   │   ├── activity_step.dart        # Экран 6: Уровень активности
│   │   ├── loading_step.dart         # Экран 7: "Создаём план"
│   │   └── result_step.dart          # Экран 8: Персональный план
│   └── paywall_screen.dart           # Экран 9: Paywall
```

### Изменения в существующих файлах

- **`app/lib/app/router.dart`** — добавить роут `/onboarding` и `/paywall`, обновить redirect-логику
- **`app/lib/core/database/app_database.dart`** — данные онбординга сохраняются в таблицу `UserSettings` (ключи: `onboarding_completed`, `user_gender`, `user_age`, `user_height`, `user_weight`, `user_target_weight`, `user_activity_level`, `user_goal`)
- **`app/lib/features/profile/widgets/profile_screen.dart`** — цели калорий и БЖУ должны автоматически заполняться из результатов онбординга (а не хардкод 2000)

### Навигация

```
Первый запуск:
  LoginScreen → OnboardingFlow (экраны 1-8) → PaywallScreen → DiaryScreen

Повторный запуск (onboarding_completed == 'true'):
  LoginScreen → DiaryScreen (минуя онбординг)
```

Проверка в `router.dart`: после успешной авторизации проверить `UserSettings` ключ `onboarding_completed`. Если не `'true'` — редирект на `/onboarding`.

---

## Общие требования к дизайну всех экранов онбординга

- Фон: `scaffoldBackgroundColor` из текущей темы (поддержка светлой и тёмной тем)
- Вверху: **линейный прогресс-бар** (цвет `AppColors.primary`, 8 шагов). Показывает прогресс от 1/8 до 8/8. На экране paywall прогресс-бар не показывать
- Кнопка "Назад" (стрелка) в левом верхнем углу на всех экранах кроме первого. На первом экране — нет кнопки назад
- Переход между экранами: горизонтальный свайп через `PageView` + кнопка "Далее" внизу
- Кнопка "Далее": закруглённая (`borderRadius: 16`), цвет `AppColors.primary`, белый текст, ширина на всю ширину с отступами 24px по бокам, высота 56px
- Кнопка "Далее" **заблокирована** (серая, `AppColors.lightDisabledBg` / `AppColors.darkDisabledBg`), пока пользователь не выбрал ответ
- Анимация перехода: плавный slide влево (300ms, `Curves.easeInOut`)
- Все данные хранятся в `OnboardingData` модели в памяти и сохраняются в `UserSettings` при завершении онбординга

---

## Экран 1: Цель (`goal_step.dart`)

**Заголовок:** "Какая у вас цель?"

**Варианты ответов** (вертикальный список карточек, одиночный выбор):

| Вариант | Иконка | Значение |
|---|---|---|
| Похудеть | `Icons.trending_down` | `lose` |
| Поддерживать вес | `Icons.balance` | `maintain` |
| Набрать массу | `Icons.trending_up` | `gain` |

**Дизайн карточек:**
- Высота ~72px, скруглённые углы 16px
- Неактивная: фон `surface`, бордер `outline`
- Активная: фон `primaryContainer`, бордер `primary` (2px)
- Иконка слева (40x40, скруглённый контейнер), текст по центру вертикально

**Кнопка:** "Далее" → переход к экрану 2

---

## Экран 2: Пол (`gender_step.dart`)

**Заголовок:** "Укажите ваш пол"
**Подзаголовок:** "Нужен для точного расчёта нормы калорий" (мелкий текст, цвет `onSurfaceVariant`)

**Варианты** (две карточки в ряд, горизонтально):

| Вариант | Иконка | Значение |
|---|---|---|
| Мужской | `Icons.male` | `male` |
| Женский | `Icons.female` | `female` |

**Дизайн:** квадратные карточки ~150x150px, иконка сверху (48x48), текст снизу. Стиль выделения как в экране 1.

**Кнопка:** "Далее" → переход к экрану 3

---

## Экран 3: Возраст (`age_step.dart`)

**Заголовок:** "Сколько вам лет?"

**Ввод:** Scroll wheel picker (как `CupertinoPicker`) по центру экрана.
- Диапазон: 14 — 90
- Значение по умолчанию: 25
- Крупный шрифт выбранного значения (48sp, `FontWeight.w700`)
- Подпись "лет" под пикером (цвет `onSurfaceVariant`)

**Кнопка:** "Далее" → переход к экрану 4

---

## Экран 4: Рост и вес (`measurements_step.dart`)

**Заголовок:** "Ваши параметры"

**Два поля на одном экране:**

**Рост:**
- Подпись: "Рост"
- Scroll wheel picker, диапазон 120-220 см, шаг 1
- Значение по умолчанию: 170
- Подпись единиц: "см"

**Вес:**
- Подпись: "Текущий вес"
- Scroll wheel picker, диапазон 30.0 — 200.0 кг, шаг 0.5
- Значение по умолчанию: 70.0
- Подпись единиц: "кг"

Оба пикера расположены вертикально один под другим с разделителем.

**Кнопка:** "Далее" → переход к экрану 5

---

## Экран 5: Желаемый вес (`target_weight_step.dart`)

**Заголовок:** "Какой вес — ваша цель?"

**Ввод:** Scroll wheel picker
- Диапазон: 30.0 — 200.0 кг, шаг 0.5
- Значение по умолчанию: зависит от цели
  - `lose`: текущий вес - 5 кг
  - `maintain`: текущий вес
  - `gain`: текущий вес + 5 кг

**Подсказка** под пикером (мелкий текст, `onSurfaceVariant`):
- Если `lose`: "Безопасный темп — 0.5 кг в неделю"
- Если `gain`: "Рекомендуемый темп — 0.25 кг в неделю"
- Если `maintain`: не показывать

**Кнопка:** "Далее" → переход к экрану 6

---

## Экран 6: Уровень активности (`activity_step.dart`)

**Заголовок:** "Насколько вы активны?"

**Варианты** (вертикальный список карточек, одиночный выбор):

| Вариант | Описание | Множитель |
|---|---|---|
| Малоподвижный | Сидячая работа, мало ходьбы | 1.2 |
| Слегка активный | Лёгкие тренировки 1-3 раза в неделю | 1.375 |
| Умеренно активный | Тренировки 3-5 раз в неделю | 1.55 |
| Очень активный | Тяжёлые тренировки 6-7 раз в неделю | 1.725 |

**Дизайн карточек:** как в экране 1 (название жирным, описание — мелким текстом под названием, цвет `onSurfaceVariant`)

**Кнопка:** "Далее" → запуск расчёта и переход к экрану 7

---

## Экран 7: Расчёт плана (`loading_step.dart`)

**Не интерактивный. Автоматический переход через 3.5 секунды.**

**Дизайн:**
- По центру экрана: круговой индикатор прогресса с анимацией заполнения 0% → 100% за 3.5 сек
- Под индикатором — текст, который меняется каждую секунду:
  1. "Рассчитываем метаболизм..." (0-1 сек)
  2. "Подбираем норму калорий..." (1-2 сек)
  3. "Создаём персональный план..." (2-3.5 сек)
- Кнопок "Далее" и "Назад" **нет**
- Прогресс-бар вверху: 7/8
- После завершения анимации — автоматический переход к экрану 8

**Расчёт в фоне** (пока идёт анимация):

```dart
// Mifflin-St Jeor
double bmr;
if (gender == 'male') {
  bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
} else {
  bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
}

double tdee = bmr * activityMultiplier;

double calorieGoal;
switch (goal) {
  case 'lose': calorieGoal = tdee - 500;
  case 'gain': calorieGoal = tdee + 300;
  case 'maintain': calorieGoal = tdee;
}

// Не ниже 1200 ккал
calorieGoal = calorieGoal.clamp(1200, 5000);

// Макросы (стандартное распределение)
double proteinGrams = (calorieGoal * 0.30) / 4;  // 30% от калорий
double fatGrams = (calorieGoal * 0.25) / 9;       // 25% от калорий
double carbsGrams = (calorieGoal * 0.45) / 4;     // 45% от калорий
```

Прогноз даты достижения цели:
```dart
double weightDiff = (currentWeight - targetWeight).abs();
double weeklyRate = goal == 'lose' ? 0.5 : goal == 'gain' ? 0.25 : 0;
int weeksNeeded = weeklyRate > 0 ? (weightDiff / weeklyRate).ceil() : 0;
DateTime targetDate = DateTime.now().add(Duration(days: weeksNeeded * 7));
```

---

## Экран 8: Персональный план (`result_step.dart`)

**Заголовок:** "Ваш персональный план"

**Содержание (сверху вниз):**

1. **Блок калорий** (крупно):
   - "Ваша дневная норма"
   - Число калорий крупным шрифтом (32sp, `FontWeight.w700`, цвет `primary`): например "1 850 ккал"

2. **Блок макросов** (три колонки в ряд):
   - Белки: [число] г (цвет: `AppColors.blue`)
   - Жиры: [число] г (цвет: `AppColors.orange`)
   - Углеводы: [число] г (цвет: `AppColors.green`)
   - Каждый столбец: число жирным (20sp), подпись мелким текстом

3. **График прогноза** (если цель ≠ maintain):
   - Карточка (`Card`) со скруглёнными углами
   - Внутри: простой линейный график через `CustomPaint` (не подключать тяжёлые пакеты типа fl_chart)
   - Ось X: текущая дата → дата достижения цели (подписи: "Сегодня" и дата "дд.мм.yyyy")
   - Ось Y: текущий вес → целевой вес
   - Линия: плавная кривая, цвет `AppColors.primary`, толщина 2.5px
   - Точки: начальная и конечная — кружки 8px, цвет `primary`
   - Подписи у точек: "[текущий вес] кг" и "[целевой вес] кг"
   - Под графиком текст: "Вы достигнете цели к [дата]" (цвет `onSurfaceVariant`)

4. **Если цель == maintain:**
   - Вместо графика: карточка с текстом "Мы поможем вам поддерживать вес на уровне [текущий вес] кг" и иконка `Icons.check_circle` зелёного цвета

**Кнопка:** "Начать" (вместо "Далее") → сохранение данных в `UserSettings` + переход к PaywallScreen

**Сохранение при нажатии "Начать":**
```
UserSettings: onboarding_completed = 'true'
UserSettings: user_goal = 'lose' / 'maintain' / 'gain'
UserSettings: user_gender = 'male' / 'female'
UserSettings: user_age = '25'
UserSettings: user_height = '170'
UserSettings: user_weight = '70.0'
UserSettings: user_target_weight = '65.0'
UserSettings: user_activity_level = '1.55'
UserSettings: calorie_goal = '1850'
UserSettings: protein_goal = '139'
UserSettings: fat_goal = '51'
UserSettings: carbs_goal = '208'
```

---

## Экран 9: Paywall (`paywall_screen.dart`)

**Отдельный экран, без прогресс-бара.**

**Дизайн (сверху вниз):**

1. **Заголовок:** "Начните свой путь к результату" (24sp, `FontWeight.w700`)

2. **Список преимуществ** (3 пункта с иконками):
   - 📸 **ИИ-распознавание еды** — сфотографируй блюдо и узнай калории за секунду
   - 📊 **Персональные цели** — норма рассчитана под ваше тело и цель
   - 📈 **Отслеживание прогресса** — наглядная статистика по дням и неделям

   Каждый пункт: иконка (24px, цвет `primary`) слева, заголовок жирным, описание мелким текстом под заголовком.

3. **Блок выбора плана** (переключение между двумя вариантами):

   **Вариант 1 (выделен по умолчанию):**
   - Карточка с бордером `primary`
   - Бейдж сверху: "Популярный" (фон `primary`, белый текст, скруглённые углы)
   - "Еженедельно"
   - "299 ₽/неделю"
   - "Пробный период — 3 дня бесплатно"

   **Вариант 2:**
   - Карточка с бордером `outline`
   - "На год"
   - "1 990 ₽/год"
   - Мелкий текст: "Экономия 85%"

4. **Кнопка CTA:** "Попробовать бесплатно" (стиль как кнопки "Далее", но текст другой)

5. **Мелкий текст под кнопкой** (10sp, цвет `onSurfaceVariant`):
   - "Отмена в любое время. Оплата не списывается в течение пробного периода."

6. **Ссылка "Пропустить"** (текстовая кнопка без фона, мелкий шрифт, цвет `onSurfaceVariant`):
   - Позиция: внизу экрана, по центру
   - При нажатии: переход к `DiaryScreen` без подписки

**Поведение кнопки "Попробовать бесплатно":**
- В текущей версии (без реального биллинга): **работает так же, как "Пропустить"** — переводит в `DiaryScreen`
- В коде оставить TODO-метку для подключения реального биллинга:
  ```dart
  // TODO: Подключить реальный биллинг (RevenueCat / Google Play Billing)
  ```

---

## Модель данных (`onboarding_data.dart`)

```dart
class OnboardingData {
  String? goal;           // 'lose', 'maintain', 'gain'
  String? gender;         // 'male', 'female'
  int age = 25;
  double heightCm = 170;
  double weightKg = 70.0;
  double targetWeightKg = 65.0;
  double activityMultiplier = 1.55;

  // Рассчитанные значения
  double? calorieGoal;
  double? proteinGoal;
  double? fatGoal;
  double? carbsGoal;
  DateTime? targetDate;
}
```

---

## Сервис расчёта (`tdee_calculator.dart`)

```dart
class TdeeCalculator {
  static Map<String, double> calculate({
    required String gender,
    required int age,
    required double heightCm,
    required double weightKg,
    required double activityMultiplier,
    required String goal,
  }) {
    double bmr;
    if (gender == 'male') {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }

    double tdee = bmr * activityMultiplier;

    double calorieGoal;
    switch (goal) {
      case 'lose':
        calorieGoal = tdee - 500;
      case 'gain':
        calorieGoal = tdee + 300;
      default:
        calorieGoal = tdee;
    }

    calorieGoal = calorieGoal.clamp(1200, 5000);

    return {
      'calories': calorieGoal.roundToDouble(),
      'protein': ((calorieGoal * 0.30) / 4).roundToDouble(),
      'fat': ((calorieGoal * 0.25) / 9).roundToDouble(),
      'carbs': ((calorieGoal * 0.45) / 4).roundToDouble(),
    };
  }

  static DateTime estimateTargetDate({
    required double currentWeight,
    required double targetWeight,
    required String goal,
  }) {
    double diff = (currentWeight - targetWeight).abs();
    double weeklyRate = goal == 'lose' ? 0.5 : goal == 'gain' ? 0.25 : 0;
    int weeks = weeklyRate > 0 ? (diff / weeklyRate).ceil() : 0;
    return DateTime.now().add(Duration(days: weeks * 7));
  }
}
```

---

## Изменения в роутере (`router.dart`)

Добавить роуты:

```dart
GoRoute(
  path: '/onboarding',
  parentNavigatorKey: _rootNavigatorKey,
  builder: (context, state) => const OnboardingFlow(),
),
GoRoute(
  path: '/paywall',
  parentNavigatorKey: _rootNavigatorKey,
  builder: (context, state) => const PaywallScreen(),
),
```

Обновить redirect-логику: после логина проверять флаг `onboarding_completed` в `UserSettings`. Если флаг отсутствует или не равен `'true'` — редирект на `/onboarding`.

**Важно:** redirect должен быть асинхронным (нужен доступ к БД). Если GoRouter не поддерживает async redirect нативно — использовать FutureBuilder на уровне ShellScreen или проверять флаг при инициализации AuthService.

---

## Firebase Analytics Events

| Событие | Когда | Параметры |
|---|---|---|
| `onboarding_started` | Открытие экрана 1 | — |
| `onboarding_step_completed` | Нажатие "Далее" на каждом экране | `step: 1-8`, `step_name: 'goal'/'gender'/...` |
| `onboarding_completed` | Нажатие "Начать" на экране результата | `calorie_goal`, `goal_type` |
| `paywall_shown` | Показ paywall | — |
| `paywall_subscribe_tapped` | Нажатие "Попробовать бесплатно" | `plan: 'weekly'/'yearly'` |
| `paywall_skipped` | Нажатие "Пропустить" | — |

**Если `firebase_analytics` ещё не подключён** — добавить в `pubspec.yaml` и инициализировать в `main.dart`.

---

## Требования к качеству

1. **Тёмная тема:** все экраны должны корректно выглядеть в тёмной теме. Использовать цвета из `Theme.of(context).colorScheme`, а не хардкодить
2. **Адаптивность:** корректное отображение на экранах от 320px до 428px ширины
3. **Не добавлять лишних зависимостей.** Для графика на экране результата использовать `CustomPaint`, не подключать fl_chart или syncfusion
4. **Все строки на русском языке** (в будущем будет вынесено в локализацию, но сейчас хардкод ок)
5. **Не ломать существующую функциональность.** Авторизация, дневник, поиск и всё остальное должно работать как раньше
6. **Автоматическое заполнение целей:** после онбординга `calorie_goal`, `protein_goal`, `fat_goal`, `carbs_goal` в `UserSettings` должны быть заполнены рассчитанными значениями. ProfileScreen должен их подхватить
