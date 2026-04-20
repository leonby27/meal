# ТЗ: Hard Paywall + Google Play Billing для MealTracker MVP

## Контекст

Приложение MealTracker — Flutter-трекер калорий с AI-распознаванием еды. Онбординг из 8 экранов и paywall-экран **уже реализованы** (`app/lib/features/onboarding/`). Сейчас paywall — soft (есть кнопка "Пропустить"), подписка фейковая (кнопка ведёт в diary без оплаты). В `AuthService` уже есть поля `isPremium`, `planName`, `nextBillingDate`.

**Цель:** превратить soft paywall в hard paywall с реальной оплатой через Google Play Billing. Минимально необходимый объём для MVP — без серверной верификации, без сложной логики восстановления.

**Платформа:** только Android (Google Play). iOS не в скоупе.

---

## Принципиальное решение: логин ПОСЛЕ paywall

Топовые calorie-трекеры (YAZIO, Cal AI, Fastic) показывают логин **после** оплаты, а не до. Причина: каждый экран до paywall — это барьер, который убивает конверсию. Логин до paywall заставляет пользователя принять решение ("доверить email") ещё до того, как он увидел ценность. При этом для оплаты через Google Play логин в приложении вообще не нужен — Google Play использует аккаунт устройства.

**Наш флоу:**
```
Онбординг (8 экранов) → Paywall → Оплата → Diary
                                              ↓
                                   Профиль: "Войти чтобы сохранить данные"
```

Логин (Google/Email) становится **опциональным действием из профиля**, а не обязательным шагом при запуске. Пользователь до момента оплаты работает как анонимный гость.

---

## Что уже есть (не нужно делать заново)

- Онбординг 8 экранов (`onboarding_flow.dart`, `steps/*.dart`)
- Paywall-экран с UI (`paywall_screen.dart`) — два плана, timeline, CTA-кнопка
- `AuthService` с полями `isPremium`, `planName`, `nextBillingDate` в `SharedPreferences`
- `LoginScreen` с Google/Email/Guest — переиспользуем в профиле
- Роутер с redirect-логикой для онбординга (`router.dart`)
- Локализация через `.arb` файлы

---

## Что нужно сделать

### 1. Paywall: добавить "Восстановить покупки", кнопку "Пропустить" пока оставить

**Файл:** `app/lib/features/onboarding/widgets/paywall_screen.dart`

Кнопка "Пропустить" (`_skip`) **остаётся на время разработки** — чтобы не блокировать доступ в приложение пока нет аккаунта Google Play и реальных подписок. Убрать её перед релизом — это отдельная задача (см. раздел "Перед релизом").

Сейчас добавить ссылку "Восстановить покупки" (мелкий текст, `onSurfaceVariant`) рядом с "Пропустить".

Итоговая структура CTA-блока внизу (на время разработки):
```
[  Попробовать бесплатно  ]       ← основная кнопка (подписка)
Отмена в любое время...           ← мелкий disclaimer
Восстановить покупки              ← текстовая кнопка
Пропустить                        ← ВРЕМЕННО, убрать перед релизом
```

---

### 2. Подключить Google Play Billing

**Пакет:** `in_app_purchase: ^3.2.0` (официальный Flutter-пакет, работает без посредников)

Добавить в `pubspec.yaml`:
```yaml
in_app_purchase: ^3.2.0
```

---

### 3. Создать `SubscriptionService`

**Новый файл:** `app/lib/core/services/subscription_service.dart`

Синглтон-сервис, отвечающий за:
- Инициализация `InAppPurchase`
- Загрузка доступных продуктов из Google Play
- Покупка подписки
- Проверка статуса подписки при запуске
- Восстановление покупок
- Обновление `AuthService.isPremium`

```dart
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._();
  factory SubscriptionService() => _instance;
  SubscriptionService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // ID продуктов — должны совпадать с созданными в Google Play Console
  static const String weeklyId = 'weekly_premium';
  static const String yearlyId = 'yearly_premium';
  static const Set<String> _productIds = {weeklyId, yearlyId};

  List<ProductDetails> products = [];
  bool isAvailable = false;

  Future<void> init() async {
    isAvailable = await _iap.isAvailable();
    if (!isAvailable) return;

    // Слушать обновления покупок
    _subscription = _iap.purchaseStream.listen(_onPurchaseUpdate);

    // Загрузить продукты
    final response = await _iap.queryProductDetails(_productIds);
    products = response.productDetails;

    // Проверить существующие покупки при запуске
    await _iap.restorePurchases();
  }

  Future<bool> buy(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restore() async {
    await _iap.restorePurchases();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      _handlePurchase(purchase);
    }
  }

  void _handlePurchase(PurchaseDetails purchase) {
    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      // Активировать premium
      _activatePremium(purchase);
    }

    if (purchase.pendingCompletePurchase) {
      _iap.completePurchase(purchase);
    }
  }

  void _activatePremium(PurchaseDetails purchase) {
    final auth = AuthService();
    auth.setPremium(
      isPremium: true,
      planName: purchase.productID == weeklyId ? 'weekly' : 'yearly',
    );
  }

  void dispose() {
    _subscription?.cancel();
  }
}
```

**Важно для MVP:** верификация чека на сервере НЕ делается. Проверка только локальная через `in_app_purchase`. Это допустимо для MVP — серверная верификация добавляется позже, когда появится значимый объём подписок.

**Примечание:** аккаунт разработчика Google Play ещё не создан. Это значит:
- Подписки `weekly_premium` / `yearly_premium` пока не существуют в Google Play Console
- `_iap.isAvailable()` будет `false`, `products` будет пустым
- Код должен корректно обрабатывать этот случай: paywall показывается, при нажатии "Подписаться" — SnackBar с ошибкой "Не удалось загрузить подписки"
- После создания аккаунта и подписок в консоли — всё заработает без изменений в коде

---

### 4. Обновить `AuthService`

**Файл:** `app/lib/core/services/auth_service.dart`

Добавить метод `setPremium`:
```dart
Future<void> setPremium({
  required bool isPremium,
  String? planName,
}) async {
  _isPremium = isPremium;
  _planName = planName;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_isPremiumKey, isPremium);
  if (planName != null) {
    await prefs.setString(_planNameKey, planName);
  }
  notifyListeners();
}
```

---

### 4.1. Developer bypass (бесплатный premium для разработчика)

**Файл:** `app/lib/core/services/auth_service.dart`

```dart
static const Set<String> _devEmails = {
  'sergey.gridyushko@gmail.com',
};

bool get isPremium => _isPremium || _devEmails.contains(_userEmail);
```

**Как это работает:**
- На этапе разработки: "Пропустить" на paywall → diary → Профиль → Войти с `sergey.gridyushko@gmail.com` → bypass активен
- В release: после первой оплаты (или тестовой) → логин → bypass навсегда, даже если подписка истечёт
- Для обычных пользователей: email не в списке → обычный hard paywall

---

### 5. Переделать роутер: убрать Login из обязательной цепочки

**Файл:** `app/lib/app/router.dart`

Текущая логика (СТАРАЯ):
```
не залогинен → /login
залогинен + не прошёл онбординг → /onboarding
```

Новая логика — **логин НЕ обязателен для входа в приложение**:
```
не прошёл онбординг → /onboarding
прошёл онбординг + не premium → /paywall
прошёл онбординг + premium → /diary
```

**Ключевое изменение:** убираем проверку `isLoggedIn` из основной цепочки redirect. Вместо этого при первом запуске **автоматически** создаём анонимную сессию (тихий guest), и пользователь сразу попадает в онбординг.

Полная цепочка:
```dart
redirect: (context, state) {
  final auth = AuthService();
  final location = state.matchedLocation;
  final isAuthRoute = location == '/login';
  final isOnboardingRoute = location == '/onboarding';
  final isPaywallRoute = location == '/paywall';

  // 1. Онбординг не пройден → туда (кроме paywall, куда онбординг сам направит)
  if (!auth.onboardingCompleted && !isOnboardingRoute && !isPaywallRoute) {
    return '/onboarding';
  }

  // 2. Онбординг пройден, но нет подписки → paywall
  if (auth.onboardingCompleted && !auth.isPremium && !isPaywallRoute) {
    return '/paywall';
  }

  // 3. Всё ок — пускаем
  return null;
}
```

Маршрут `/login` **остаётся** в списке routes, но теперь он не в redirect-цепочке. Он доступен только по явному вызову из профиля (`context.push('/login')`).

**Файл:** `app/lib/main.dart`

Убрать вызов `LoginScreen` из начального запуска. При первом запуске автоматически устанавливать гостевую сессию:

```dart
await AuthService().init();
if (!AuthService().isLoggedIn) {
  await AuthService().skipLogin(); // тихий guest — без UI
}
await SubscriptionService().init();
```

Таким образом: пользователь открывает приложение → сразу видит первый экран онбординга. Никакого логина.

---

### 6. Обновить paywall: подключить реальную покупку

**Файл:** `app/lib/features/onboarding/widgets/paywall_screen.dart`

Заменить метод `_subscribe()`:

```dart
void _subscribe() async {
  final sub = SubscriptionService();
  if (sub.products.isEmpty) {
    // Продукты не загрузились — показать ошибку
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Не удалось загрузить подписки. Попробуйте позже.')),
    );
    return;
  }

  final productId = _selectedPlan == 0
      ? SubscriptionService.weeklyId
      : SubscriptionService.yearlyId;

  final product = sub.products.firstWhere(
    (p) => p.id == productId,
    orElse: () => sub.products.first,
  );

  await sub.buy(product);
  // Навигация произойдёт автоматически через AuthService.notifyListeners → router refresh
}
```

Добавить метод `_restore()`:
```dart
void _restore() async {
  await SubscriptionService().restore();
  // Если покупка найдена — AuthService обновится, роутер перенаправит в diary
}
```

---

### 7. Инициализация при запуске

**Файл:** `app/lib/main.dart`

Добавить инициализацию `SubscriptionService` после `AuthService`:
```dart
await AuthService().init();
await SubscriptionService().init();  // ← добавить
```

---

### 8. Карточка подписки + вход в профиле

**Файл:** `app/lib/features/profile/widgets/profile_screen.dart`

Теперь профиль содержит **два блока**, которых раньше не было:

#### 8a. Блок "Войти для сохранения данных" (если пользователь — гость)

Показывать если `AuthService().userEmail == null`:

```
┌─────────────────────────────────────┐
│  👤 Войти для сохранения данных     │
│  Ваши данные хранятся только на     │
│  этом устройстве                    │
│                                     │
│  [Войти через Google]               │
│  [Войти через Email]                │
└─────────────────────────────────────┘
```

Кнопки вызывают те же методы что были на `LoginScreen` (`AuthService().signInWithGoogle()`, открытие `EmailAuthSheet`). Код уже есть в `profile_screen.dart` (методы `_signInFromGuest`, `_signInWithEmailFromGuest`).

**Не показывать** этот блок если пользователь уже залогинен (email != null).

#### 8b. Карточка подписки

Заменить текущий блок "Разблокируй возможности" на:

```
⭐ MealTracker Pro                    Активна
План: Еженедельный
Управление подпиской →
```

"Управление подпиской" → deeplink в Google Play subscriptions:
```dart
launchUrl(Uri.parse('https://play.google.com/store/account/subscriptions'));
```

Пакет `url_launcher` уже может быть в зависимостях (проверить), иначе добавить.

---

## Создание подписок в Google Play Console

В Google Play Console → Monetize → Subscriptions создать:

### Подписка 1: `weekly_premium`
- Название: MealTracker Pro Weekly
- Billing period: Weekly
- Цена: $4.99/week
- Free trial: 3 дня
- Grace period: 3 дня (для недельной подписки больше не нужно)

### Подписка 2: `yearly_premium`
- Название: MealTracker Pro Yearly
- Billing period: Yearly
- Цена: $29.99/year
- Free trial: 7 дней
- Grace period: 7 дней

**Важно:** ID продуктов (`weekly_premium`, `yearly_premium`) должны точно совпадать с константами в `SubscriptionService`.

---

## Флоу пользователя (финальный)

```
┌─────────────────────────────────────────────────────┐
│                  ПЕРВЫЙ ЗАПУСК                       │
│                                                     │
│  [Автоматический guest — без UI]                    │
│  → Онбординг (8 экранов)                            │
│  → Paywall (HARD — нет "Пропустить", нет "Назад")  │
│  → Google Play покупка (триал 3 дня)                │
│  → Diary                                            │
│  → (опционально) Профиль → Войти через Google/Email │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                ПОВТОРНЫЙ ЗАПУСК                      │
│                                                     │
│  SubscriptionService.init → restorePurchases        │
│  → Подписка активна → Diary                         │
│  → Подписка истекла → Paywall (HARD)                │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                 ОТМЕНА ПОДПИСКИ                      │
│                                                     │
│  Пользователь отменяет в Google Play настройках     │
│  → Доступ сохраняется до конца оплаченного периода  │
│  → После истечения: при запуске → Paywall            │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                DEVELOPER BYPASS                      │
│                                                     │
│  Онбординг → Paywall → оплата → Diary               │
│  → Профиль → Войти (sergey.gridyushko@gmail.com)    │
│  → isPremium = true навсегда                        │
│  → При следующих запусках: сразу Diary              │
└─────────────────────────────────────────────────────┘
```

**Важно:** `LoginScreen` больше НЕ показывается при первом запуске. Экран логина доступен только из Профиля (кнопка "Войти"). Маршрут `/login` остаётся в routes, но используется через `context.push('/login')`, а не через redirect.

---

## Что НЕ делать (MVP scope)

| Не делать | Почему |
|---|---|
| Серверная верификация чеков | Overkill для MVP. Добавить когда будет >100 подписчиков |
| Свой экран отмены подписки | Google Play это делает сам, и требует чтобы делал он |
| Промокоды / скидки | Нет инфраструктуры, добавить позже |
| Fallback paywall со скидкой | Нет данных для оптимизации, добавить после первых 500 показов |
| Отдельные лимиты для бесплатных | Hard paywall = всё закрыто, лимиты не нужны |
| Apple/iOS биллинг | Только Android на этом этапе |
| RevenueCat | Лишняя зависимость для MVP. `in_app_purchase` достаточно |
| A/B тестирование paywall | Нет трафика для статзначимости. Один вариант, итерации руками |

---

## Жизненный цикл подписки (что происходит с аккаунтом)

### Принцип: данные НИКОГДА не удаляются. Закрывается только доступ к UI.

| Состояние | Что видит пользователь | Что в коде |
|---|---|---|
| Подписка активна | Diary, всё работает | `isPremium = true` |
| Отменил, но период не истёк | Diary, всё работает (до конца оплаченного срока) | `isPremium = true` (Google Play ещё возвращает подписку как активную) |
| Период истёк | Paywall. Нет доступа к дневнику, статистике, камере | `isPremium = false`, роутер → `/paywall` |
| Переподписался | Diary, все старые данные на месте | `isPremium = true`, SQLite база не тронута |
| Нет интернета + был premium | Diary (кэш из SharedPreferences) | `isPremium = true` из кэша |
| Нет интернета + подписка истекла | Diary (кэш не обновился) — до следующего онлайн-запуска | `isPremium = true` из устаревшего кэша |

### Когда `isPremium` обновляется на `false`:

Только при вызове `SubscriptionService.init()` → `restorePurchases()`, если Google Play не возвращает активную подписку. Это происходит:
- При каждом запуске приложения (в `main.dart`)
- При ручном вызове "Восстановить покупки"

### Что НЕ нужно делать при истечении подписки:

- Не удалять данные пользователя из SQLite
- Не удалять аккаунт (email, настройки)
- Не показывать страшные предупреждения
- Не менять онбординг-данные (цели, вес, калории)

Всё сохраняется. Пользователь просто видит paywall вместо diary. Подписался заново → всё как было.

---

## Тестирование перед публикацией

### Тестовые покупки в Google Play

1. В Google Play Console → Settings → License testing → добавить email-адреса тестировщиков
2. Тестировщики могут "покупать" подписки без реального списания
3. Тестовые подписки обновляются быстрее: недельная = 5 мин, годовая = 30 мин
4. Проверить:
   - Покупка недельной подписки с триалом
   - Покупка годовой подписки
   - Восстановление покупки
   - Отмена → истечение → показ paywall заново
   - Приложение без интернета (должно использовать кэш isPremium из SharedPreferences)

### Оффлайн-поведение

Если нет интернета — опираться на `SharedPreferences` кэш `isPremium`. Это значит:
- Если пользователь был premium и потерял интернет — доступ сохраняется
- Если подписка истекла, но интернета нет — доступ сохраняется до следующего онлайн-запуска
- Это допустимый компромисс для MVP

---

## Файлы для изменения (полный список)

| Файл | Действие |
|---|---|
| `pubspec.yaml` | Добавить `in_app_purchase`, `url_launcher` (если нет) |
| `core/services/subscription_service.dart` | **Создать** — весь биллинг |
| `core/services/auth_service.dart` | Добавить `setPremium()`, developer bypass в `isPremium` |
| `app/router.dart` | Убрать login из redirect, добавить проверку isPremium |
| `main.dart` | Автоматический guest + `SubscriptionService().init()` |
| `onboarding/widgets/paywall_screen.dart` | Убрать "Пропустить", добавить "Восстановить", подключить реальную покупку |
| `profile/widgets/profile_screen.dart` | Добавить блок "Войти" для гостей + карточка подписки |
| `l10n/app_en.arb` | Добавить строки: restore purchases, sign in prompt, subscription status |
| `l10n/app_ru.arb` | Добавить строки: восстановить покупки, вход, статус подписки |

---

## Цены

Для глобальной аудитории (US/EU) — цены в USD:

| План | Цена | Триал | Эквивалент в год |
|---|---|---|---|
| Недельный | $4.99/нед | 3 дня бесплатно | ~$260/год |
| Годовой | $29.99/год | 7 дней бесплатно | $29.99/год |

Недельный план стоит по умолчанию, как основной — именно он окупает рекламу быстрее всего (Journable и Cal AI тоже используют недельные планы как основные).

Google Play сам конвертирует цены для других стран. Можно вручную скорректировать цены для отдельных регионов позже в консоли.

---

## Перед релизом (отдельная задача, НЕ делать сейчас)

Когда аккаунт Google Play готов, подписки созданы и протестированы:

1. **Убрать кнопку "Пропустить"** из paywall (`paywall_screen.dart` → удалить `TextButton` с `_skip`)
2. **Добавить `PopScope(canPop: false)`** на paywall — заблокировать системную кнопку "Назад"
3. Убрать локализацию `paywallSkip` из `.arb` файлов
4. Прогнать полный флоу: онбординг → paywall → покупка → diary
