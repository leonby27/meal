// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get mealBreakfast => 'Завтрак';

  @override
  String get mealLunch => 'Обед';

  @override
  String get mealDinner => 'Ужин';

  @override
  String get mealSnack => 'Перекус';

  @override
  String get kcalUnit => 'ккал';

  @override
  String get gramsUnit => 'г';

  @override
  String get gramsUnitDot => 'г.';

  @override
  String get kgUnit => 'кг';

  @override
  String get cmUnit => 'см';

  @override
  String get yearsUnit => 'год рождения';

  @override
  String kcalValue(String count) {
    return '$count ккал';
  }

  @override
  String kcalValueInt(int count) {
    return '$count Ккал';
  }

  @override
  String gramsValue(int count) {
    return '$count г.';
  }

  @override
  String kcalPer100g(String count) {
    return '$count ккал/100г';
  }

  @override
  String per100gInfo(int cal, String prot, String fat, String carbs) {
    return 'На 100 г: $cal ккал  Б$prot Ж$fat У$carbs';
  }

  @override
  String get proteinShort => 'б';

  @override
  String get fatShort => 'ж';

  @override
  String get carbsShort => 'у';

  @override
  String get proteinLabel => 'Белки';

  @override
  String get fatLabel => 'Жиры';

  @override
  String get carbsLabel => 'Углеводы';

  @override
  String get carbsLabelShort => 'Углев.';

  @override
  String get caloriesLabel => 'Калории';

  @override
  String get caloriesKcalLabel => 'Калории, ккал';

  @override
  String get proteinGramsLabel => 'Белки, г';

  @override
  String get fatGramsLabel => 'Жиры, г';

  @override
  String get carbsGramsLabel => 'Углеводы, г';

  @override
  String get caloriesKcalInputLabel => 'Калории (ккал)';

  @override
  String proteinGoalLabel(int count) {
    return '$count белки';
  }

  @override
  String fatGoalLabel(int count) {
    return '$count жиры';
  }

  @override
  String carbsGoalLabel(int count) {
    return '$count углеводы';
  }

  @override
  String get profileTitle => 'Профиль';

  @override
  String get myProfile => 'Мой профиль';

  @override
  String get subscription => 'Подписка';

  @override
  String get myGoals => 'Мои цели';

  @override
  String get myProducts => 'Мои продукты';

  @override
  String get settings => 'Настройки';

  @override
  String get productsList => 'Список продуктов';

  @override
  String get allProducts => 'Все';

  @override
  String get appTheme => 'Тема приложения';

  @override
  String get languageSelector => 'Язык интерфейса';

  @override
  String get pushNotifications => 'Push-уведомления';

  @override
  String get pushNotificationsShortOn => 'Вкл';

  @override
  String get pushNotificationsShortOff => 'Выкл';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get signOut => 'Выйти';

  @override
  String get signOutConfirm => 'Выйти из аккаунта?';

  @override
  String get signOutLocalDataKept =>
      'Локальные данные сохранятся на устройстве.';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get deleteAccountConfirmTitle => 'Удалить аккаунт?';

  @override
  String get deleteAccountConfirmMessage =>
      'Аккаунт будет удалён навсегда. История питания, рецепты, продукты, избранное и настройки на этом устройстве также будут удалены. Это действие нельзя отменить.';

  @override
  String get deleteAccountFinalConfirmTitle => 'Вы точно уверены?';

  @override
  String get deleteAccountFinalConfirmMessage =>
      'Ваш аккаунт и данные будут удалены без возможности восстановления.';

  @override
  String get deleteAccountSuccess => 'Аккаунт удалён.';

  @override
  String get deleteAccountFailed =>
      'Не удалось удалить аккаунт. Проверьте подключение и попробуйте ещё раз.';

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String get save => 'Сохранить';

  @override
  String get add => 'Добавить';

  @override
  String get close => 'Закрыть';

  @override
  String get edit => 'Редактировать';

  @override
  String get guestMode => 'Гостевой режим';

  @override
  String get defaultUserName => 'Пользователь';

  @override
  String get signedInSnackbar => 'Вы вошли в аккаунт';

  @override
  String get signInTitle => 'Войдите в аккаунт';

  @override
  String get signInGoogle => 'Войти через Google';

  @override
  String get signInApple => 'Войти через Apple';

  @override
  String get signInEmail => 'Войти по Email';

  @override
  String get startOverOnboarding => 'Начать сначала';

  @override
  String get startOverOnboardingConfirm => 'Пройти онбординг сначала?';

  @override
  String get startOverOnboardingHint =>
      'Ответы в анкете сбросятся. Дневник на устройстве сохранится.';

  @override
  String get skipLogin => 'Продолжить без входа';

  @override
  String get signInSyncHint =>
      'Вход позволяет синхронизировать данные\nмежду устройствами';

  @override
  String get calorieTracking => 'Учёт питания и калорий';

  @override
  String get loginTitle => 'Вход';

  @override
  String get registerTitle => 'Регистрация';

  @override
  String get nameOptional => 'Имя (необязательно)';

  @override
  String get enterEmail => 'Введите email';

  @override
  String get invalidEmail => 'Некорректный email';

  @override
  String get passwordLabel => 'Пароль';

  @override
  String get enterPassword => 'Введите пароль';

  @override
  String get minPasswordLength => 'Минимум 6 символов';

  @override
  String get signInButton => 'Войти';

  @override
  String get registerButton => 'Зарегистрироваться';

  @override
  String get switchToLogin => 'Войти в аккаунт';

  @override
  String get wrongCredentials => 'Неверный email или пароль';

  @override
  String signInError(String error) {
    return 'Ошибка входа: $error';
  }

  @override
  String get emailAlreadyRegistered => 'Этот email уже зарегистрирован';

  @override
  String registerError(String error) {
    return 'Ошибка регистрации: $error';
  }

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get resetPasswordTitle => 'Сброс пароля';

  @override
  String get resetPasswordHint =>
      'Введите email, указанный при регистрации. Мы отправим 6-значный код для сброса пароля.';

  @override
  String get sendResetCode => 'Отправить код';

  @override
  String get enterCodeTitle => 'Введите код';

  @override
  String resetCodeSentTo(String email) {
    return 'Мы отправили 6-значный код на $email';
  }

  @override
  String get enterSixDigitCode => 'Введите 6-значный код';

  @override
  String get verifyCode => 'Подтвердить';

  @override
  String get resendCode => 'Отправить код повторно';

  @override
  String resendCodeIn(int seconds) {
    return 'Повторно через $seconds с';
  }

  @override
  String get resetCodeResent => 'Код отправлен повторно';

  @override
  String get newPasswordTitle => 'Новый пароль';

  @override
  String get newPasswordHint => 'Придумайте новый пароль для вашего аккаунта.';

  @override
  String get newPasswordLabel => 'Новый пароль';

  @override
  String get confirmPasswordLabel => 'Подтвердите пароль';

  @override
  String get passwordsDoNotMatch => 'Пароли не совпадают';

  @override
  String get resetPasswordButton => 'Сбросить пароль';

  @override
  String get passwordResetSuccess =>
      'Пароль успешно сброшен. Войдите с новым паролем.';

  @override
  String get emailNotFound => 'Аккаунт с таким email не найден';

  @override
  String get invalidResetCode => 'Неверный или просроченный код';

  @override
  String get proTitle => 'MealTracker Pro';

  @override
  String get proUnlockFeatures => 'Разблокируйте все возможности:';

  @override
  String get proAiUnlimited => 'ИИ-распознавание без лимитов';

  @override
  String get proExtendedStats => 'Расширенная статистика';

  @override
  String get proPersonalRecommendations => 'Персональные рекомендации';

  @override
  String get proTryFree => 'Попробовать бесплатно';

  @override
  String get planLabel => 'План:';

  @override
  String get planWeekly => 'Еженедельный';

  @override
  String get planYearly => 'Годовой';

  @override
  String get billingLabel => 'Списание:';

  @override
  String get manageSubscription => 'Управление подпиской';

  @override
  String get goalCaloriesKcal => 'Калории, ккал';

  @override
  String get goalProteinG => 'Белки, г';

  @override
  String get goalFatG => 'Жиры, г';

  @override
  String get goalCarbsG => 'Углеводы, г';

  @override
  String get remindersTitle => 'Напоминания';

  @override
  String get reminderOff => 'Выключено';

  @override
  String get remindersDescription =>
      'Напоминания будут приходить ежедневно в указанное время, чтобы вы не забыли записать приемы пищи.';

  @override
  String get notifBreakfastBody => 'Время записать завтрак';

  @override
  String get notifLunchBody => 'Время записать обед';

  @override
  String get notifDinnerBody => 'Время записать ужин';

  @override
  String get notifSnackBody => 'Не забудьте записать перекус';

  @override
  String get notifChannelName => 'Напоминания о приемах пищи';

  @override
  String get notifChannelDesc => 'Напоминания записать приемы пищи';

  @override
  String get diaryRecordsForDay => 'Записи за день';

  @override
  String get diaryViewLabel => 'Вид';

  @override
  String get diaryViewCompact => 'компактный';

  @override
  String get diaryViewExpanded => 'расширенный';

  @override
  String get recordsSortNewestFirst => 'Сначала новые';

  @override
  String get recordsSortOldestFirst => 'Сначала старые';

  @override
  String get diaryEmptyDay => 'Ещё нет записей за этот день';

  @override
  String get addMealTitle => 'Добавить приём пищи';

  @override
  String get mealTypeLabel => 'Приём пищи';

  @override
  String get searchInDb => 'Найти в базе';

  @override
  String get fromGallery => 'Из галереи';

  @override
  String get recognizeByPhoto => 'Распознать по фото';

  @override
  String get productNameOrDish => 'Название продукта или блюда';

  @override
  String get addEntry => 'Добавить запись';

  @override
  String get recognizingViaAi => 'Распознаю через ИИ...';

  @override
  String get notFoundInDb =>
      'Не найдено в базе\nНажмите  ➜  чтобы распознать через ИИ';

  @override
  String get historyTab => 'История';

  @override
  String get favoritesTab => 'Избранное';

  @override
  String get noRecentRecords => 'Нет недавних записей';

  @override
  String get addMenuRecentEntries => 'Последние записи';

  @override
  String get scanBarcodeAction => 'Сканировать штрихкод';

  @override
  String get attachPhotoAction => 'Прикрепить фото';

  @override
  String get noFavoriteProducts => 'Нет избранных продуктов';

  @override
  String get gramsDialogLabel => 'Граммы';

  @override
  String get favoriteUpdated => 'Избранное обновлено';

  @override
  String get addToFavorite => 'В избранное';

  @override
  String get dayNotYet => 'Этот день ещё не наступил!';

  @override
  String copyMealTo(String meal) {
    return 'Скопировать $meal в…';
  }

  @override
  String copiedRecords(int count, String date) {
    return 'Скопировано $count записей в $date';
  }

  @override
  String get dayMon => 'ПН';

  @override
  String get dayTue => 'ВТ';

  @override
  String get dayWed => 'СР';

  @override
  String get dayThu => 'ЧТ';

  @override
  String get dayFri => 'ПТ';

  @override
  String get daySat => 'СБ';

  @override
  String get daySun => 'ВС';

  @override
  String get aiAnalyzingPhoto => 'Анализируем фото...';

  @override
  String get aiRecognizingIngredients => 'Распознаём ингредиенты...';

  @override
  String get aiCountingCalories => 'Считаем калории...';

  @override
  String get aiDeterminingMacros => 'Определяем БЖУ...';

  @override
  String get aiAlmostDone => 'Почти готово...';

  @override
  String get aiAnalyzingData => 'Анализируем данные...';

  @override
  String get aiRecognitionFailed => 'Не удалось распознать блюдо';

  @override
  String get aiRecognizingDish => 'Распознаём блюдо';

  @override
  String get addDish => 'Добавить блюдо';

  @override
  String get dishNameLabel => 'Название';

  @override
  String get dishParameters => 'Параметры блюда';

  @override
  String get ingredientsLabel => 'Ингредиенты';

  @override
  String get unknownDish => 'Неизвестное блюдо';

  @override
  String get defaultDishName => 'Блюдо';

  @override
  String get saveEntry => 'Добавить запись';

  @override
  String get saveChanges => 'Сохранить';

  @override
  String get recognizeDish => 'Распознать блюдо';

  @override
  String get cameraLabel => 'Камера';

  @override
  String get searchTitle => 'Поиск';

  @override
  String get searchHint => 'Поиск продуктов...';

  @override
  String get nothingFound => 'Ничего не найдено';

  @override
  String get recognizeViaAi => 'Распознать через ИИ';

  @override
  String get createProduct => 'Создать продукт';

  @override
  String get newProduct => 'Новый продукт';

  @override
  String get basicInfo => 'Основное';

  @override
  String get productNameRequired => 'Название *';

  @override
  String get enterName => 'Введите название';

  @override
  String get brandOptional => 'Бренд (необязательно)';

  @override
  String get servingWeightG => 'Вес порции (г)';

  @override
  String get macrosPer100g => 'БЖУ на 100 г';

  @override
  String get caloriesAutoCalc => 'Рассчитается автоматически из БЖУ';

  @override
  String get productAdded => 'Продукт добавлен';

  @override
  String get saveProduct => 'Сохранить продукт';

  @override
  String get myProductsCategory => 'Мои продукты';

  @override
  String get newRecipe => 'Новый рецепт';

  @override
  String get recipeNameRequired => 'Название рецепта *';

  @override
  String get servingsCount => 'Количество порций';

  @override
  String get enterRecipeName => 'Введите название рецепта';

  @override
  String get addAtLeastOneIngredient => 'Добавьте хотя бы один ингредиент';

  @override
  String get recipeSaved => 'Рецепт сохранён';

  @override
  String get totalForRecipe => 'Итого на весь рецепт';

  @override
  String get per100g => 'На 100 г:';

  @override
  String perServing(int grams) {
    return 'На порцию ($grams г):';
  }

  @override
  String get ingredientSearchHint => 'Поиск ингредиента...';

  @override
  String get startTypingName => 'Начните вводить название';

  @override
  String get tapAddToSelect => 'Нажмите «Добавить» чтобы\nвыбрать продукты';

  @override
  String ingredientsCount(int count) {
    return 'Ингредиенты ($count)';
  }

  @override
  String get weightLabel => 'Вес';

  @override
  String get favoritesTitle => 'Избранное';

  @override
  String productAddedToMeal(String name) {
    return '$name добавлен';
  }

  @override
  String get historyTitle => 'История';

  @override
  String get noRecords => 'Нет записей';

  @override
  String get today => 'Сегодня';

  @override
  String get yesterday => 'Вчера';

  @override
  String get statsTitle => 'Статистика';

  @override
  String get averageLabel => 'Среднее';

  @override
  String get byDays => 'По дням';

  @override
  String get periodWeek => 'Неделя';

  @override
  String get period2Weeks => '2 недели';

  @override
  String get periodMonth => 'Месяц';

  @override
  String totalGrams(int count) {
    return 'Всего $count г.';
  }

  @override
  String get noOwnProducts => 'Нет своих продуктов';

  @override
  String get createProductWithMacros => 'Создайте продукт с указанием БЖУ';

  @override
  String get productLabel => 'Продукт';

  @override
  String get deleteConfirm => 'Удалить?';

  @override
  String deleteWhat(String what) {
    return 'Удалить $what?';
  }

  @override
  String get customizeView => 'Настроить вид';

  @override
  String get primaryMetric => 'Главная метрика';

  @override
  String get otherMetrics => 'Остальные метрики';

  @override
  String get showMore => 'Подробнее';

  @override
  String get showLess => 'Скрыть';

  @override
  String get networkTimeout =>
      'Сервер не отвечает. Проверьте подключение к интернету.';

  @override
  String get networkSslError => 'Ошибка SSL-соединения. Попробуйте позже.';

  @override
  String networkConnectionError(String message) {
    return 'Ошибка соединения: $message';
  }

  @override
  String get networkRetryFailed => 'Не удалось связаться с сервером.';

  @override
  String get networkHostLookup =>
      'Сервер временно недоступен. Проверьте интернет или попробуйте через минуту.';

  @override
  String get networkConnectionRefused =>
      'Сервер не принимает соединения. Попробуйте позже.';

  @override
  String get networkConnectionReset =>
      'Соединение разорвано. Попробуйте ещё раз.';

  @override
  String get networkGenericError =>
      'Ошибка сети. Проверьте подключение к интернету.';

  @override
  String get onboardingGenderTitle => 'Укажите ваш пол';

  @override
  String get onboardingGenderHint => 'Нужен для точного расчёта нормы калорий';

  @override
  String get genderMale => 'Мужской';

  @override
  String get genderFemale => 'Женский';

  @override
  String get onboardingMeasurementsTitle => 'Ваши параметры';

  @override
  String get onboardingUnitsTitle => 'Единицы измерения';

  @override
  String get onboardingUnitsHint => 'Можно изменить позже в настройках';

  @override
  String get unitsMetricTitle => 'Метрическая';

  @override
  String get unitsMetricExamples => 'см, кг, мл';

  @override
  String get unitsImperialTitle => 'Имперская';

  @override
  String get unitsImperialExamples => 'ft, lb, fl oz';

  @override
  String get onboardingHeightTitle => 'Какой у вас рост?';

  @override
  String get onboardingHeightHint =>
      'Нужен для расчёта базового обмена веществ';

  @override
  String get onboardingWeightTitle => 'Какой у вас вес?';

  @override
  String get onboardingWeightHint => 'Отправная точка для вашего плана';

  @override
  String get heightLabel => 'Рост';

  @override
  String get currentWeightLabel => 'Текущий вес';

  @override
  String get onboardingAgeTitle => 'Когда у вас день рождения?';

  @override
  String get onboardingAgeHint => 'Возраст влияет на скорость метаболизма';

  @override
  String get onboardingGoalTitle => 'Какая у вас цель?';

  @override
  String get onboardingGoalHint => 'Подберём план питания под вашу задачу';

  @override
  String get goalLoseWeight => 'Похудеть';

  @override
  String get goalMaintainWeight => 'Поддерживать вес';

  @override
  String get goalGainWeight => 'Набрать массу';

  @override
  String get onboardingActivityTitle => 'Насколько вы активны?';

  @override
  String get onboardingActivityHint =>
      'Активность определяет суточную норму калорий';

  @override
  String get activitySedentary => 'Малоподвижный';

  @override
  String get activitySedentaryDesc => 'Сидячая работа, мало ходьбы';

  @override
  String get activityLight => 'Слегка активный';

  @override
  String get activityLightDesc => 'Лёгкие тренировки 1-3 раза в неделю';

  @override
  String get activityModerate => 'Умеренно активный';

  @override
  String get activityModerateDesc => 'Тренировки 3-5 раз в неделю';

  @override
  String get activityHigh => 'Очень активный';

  @override
  String get activityHighDesc => 'Тяжёлые тренировки 6-7 раз в неделю';

  @override
  String get onboardingTargetWeightTitle => 'Какой вес — ваша цель?';

  @override
  String get onboardingTargetWeightHint => 'Рассчитаем сроки и темп достижения';

  @override
  String get safeWeightLossPace => 'Безопасный темп — 0.5 кг в неделю';

  @override
  String get recommendedWeightGainPace =>
      'Рекомендуемый темп — 0.25 кг в неделю';

  @override
  String get onboardingLoadingCalc => 'Рассчитываем метаболизм...';

  @override
  String get onboardingLoadingNorm => 'Подбираем норму калорий...';

  @override
  String get onboardingLoadingPlan => 'Создаём персональный план...';

  @override
  String get onboardingResultTitle => 'Ваш персональный план';

  @override
  String get resultCongratsTitle => 'Поздравляем!';

  @override
  String get resultCongratsSubtitle => 'Ваш персональный план здоровья готов!';

  @override
  String get resultCanChange => 'Это можно изменить в любой момент';

  @override
  String get resultHowToTitle => 'Как достигать целей';

  @override
  String get resultTip1 => 'Ведите учёт еды — сформируйте полезную привычку!';

  @override
  String get resultTip2 => 'Следуйте дневной рекомендации по калориям';

  @override
  String get resultTip3 => 'Балансируйте углеводы, белки и жиры';

  @override
  String get resultImprovementsTitle =>
      'Скоро вы заметите улучшения в самочувствии';

  @override
  String get resultImprovementsBody =>
      'Ниже риск диабета, ниже давление, лучше уровень холестерина';

  @override
  String get resultDisclaimer =>
      'Приложение предоставляет информацию о питании, но не предназначено для диагностики, лечения или профилактики заболеваний. Оно не заменяет консультацию врача. При проблемах со здоровьем обращайтесь к специалисту.';

  @override
  String get kcalPerDay => 'ккал/день';

  @override
  String get weightLossGoalText => 'похудения';

  @override
  String get weightGainGoalText => 'набора массы';

  @override
  String achievableGoal(String goalText) {
    return 'Достижимая цель $goalText';
  }

  @override
  String weeksToGoal(int weeks, String date) {
    return '$weeks нед. до цели — к $date';
  }

  @override
  String maintainWeightHint(String weight) {
    return 'Мы поможем вам поддерживать вес\nна уровне $weight кг';
  }

  @override
  String weightWithUnit(String value) {
    return '$value кг';
  }

  @override
  String get onboardingNext => 'Далее';

  @override
  String get onboardingStart => 'Начать';

  @override
  String get paywallTitle =>
      'Чтобы продолжить, начните 3-дневный БЕСПЛАТНЫЙ пробный период';

  @override
  String get paywallTimelineTodayTitle => 'Сегодня';

  @override
  String get paywallTimelineTodayDesc =>
      'Откройте все функции приложения — например, AI-сканирование калорий и многое другое';

  @override
  String get paywallTimelineReminderTitle => 'Через 2 дня — напоминание';

  @override
  String get paywallTimelineReminderDesc =>
      'Мы напомним, что пробный период скоро закончится';

  @override
  String get paywallTimelinePayTitle => 'Через 3 дня — начнётся оплата';

  @override
  String paywallTimelinePayDesc(String date) {
    return 'Списание будет $date, если вы не отмените подписку до этого';
  }

  @override
  String get paywallMonthly => 'Еженедельно';

  @override
  String get paywallMonthlyPrice => '\$4.99 / нед';

  @override
  String get paywallYearly => 'Ежегодно';

  @override
  String get paywallYearlyPrice => '\$39.99 / год';

  @override
  String get paywallPerWeek => 'нед';

  @override
  String get paywallPerYear => 'год';

  @override
  String get paywallTrialBadge => '3 ДНЯ БЕСПЛАТНО';

  @override
  String get paywallNoPaymentNow => 'Платёж сейчас не требуется';

  @override
  String get paywallStartTrial => 'Начать 3-дневный бесплатный пробный период';

  @override
  String get paywallTrialDisclaimer => '3 дня бесплатно, затем \$39.99/год';

  @override
  String paywallTrialDisclaimerFmt(String price) {
    return '3 дня бесплатно, затем $price/год';
  }

  @override
  String get paywallRestore => 'Восстановить';

  @override
  String get paywallTerms => 'Условия';

  @override
  String get paywallPrivacy => 'Конфиденциальность';

  @override
  String get paywallHaveCode => 'Есть код?';

  @override
  String get promoCodeApply => 'Применить';

  @override
  String get promoCodeInvalid => 'Неверный код';

  @override
  String get paywallSkip => 'Пропустить';

  @override
  String get paywallRestoreSuccess => 'Подписка восстановлена';

  @override
  String get paywallRestoreNotFound => 'Активных подписок не найдено';

  @override
  String get paywallSubscriptionError =>
      'Не удалось загрузить подписки. Попробуйте позже.';

  @override
  String get paywallLoadingPrice => 'Загрузка…';

  @override
  String get paywallErrorTitle => 'Подписка недоступна';

  @override
  String get paywallTryAgain => 'Повторить';

  @override
  String get paywallErrorStoreUnavailable =>
      'App Store сейчас недоступен. Убедитесь, что вы вошли в App Store, и попробуйте ещё раз.';

  @override
  String get paywallErrorProductsEmpty =>
      'Не удалось загрузить варианты подписки. Проверьте соединение и попробуйте ещё раз.';

  @override
  String get paywallErrorQueryFailed =>
      'Не удаётся связаться с App Store. Попробуйте через минуту.';

  @override
  String get paywallErrorPurchaseFailed =>
      'Покупку не удалось завершить. Попробуйте ещё раз.';

  @override
  String get paywallErrorRestoreFailed =>
      'Не удалось восстановить покупки. Попробуйте ещё раз.';

  @override
  String get paywallErrorPaymentPending =>
      'Оплата обрабатывается. Мы откроем Pro сразу после подтверждения.';

  @override
  String get restartOnboarding => 'Начать заново';

  @override
  String get proActive => 'Активна';

  @override
  String get signInToSaveData => 'Войдите для сохранения данных';

  @override
  String get dataStoredLocally =>
      'Ваши данные хранятся только на этом устройстве';

  @override
  String get barcodeScannerTitle => 'Сканер штрих-кода';

  @override
  String get barcodeScanHint => 'Наведите камеру на штрих-код';

  @override
  String get paywallSubscribeNow => 'Оформить подписку';

  @override
  String get paywallHardDisclaimer => 'Автопродление. Отмена в любой момент.';

  @override
  String get paywallHardTitle => 'Понравилось?\nПродолжите с Pro';

  @override
  String freeEntriesRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Осталось $count бесплатных записей',
      many: 'Осталось $count бесплатных записей',
      few: 'Осталось $count бесплатные записи',
      one: 'Осталась 1 бесплатная запись',
    );
    return '$_temp0';
  }

  @override
  String get getPro => 'Получить Pro';

  @override
  String get freeLimitReached => 'Бесплатные записи закончились';
}
