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
  String get mergeLocalDataTitle =>
      'Хотите перенести последние данные в свой аккаунт?';

  @override
  String get mergeLocalDataKeep => 'Перенести';

  @override
  String get mergeLocalDataReplace => 'Оставить как есть';

  @override
  String get loginSyncing => 'Синхронизация…';

  @override
  String get loginSyncFailed =>
      'Не удалось синхронизировать данные. Попробуйте позже.';

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
  String get proTitle => 'Body Meal Pro';

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
  String get planLifetime => 'Бессрочный';

  @override
  String get planPromo => 'Промо';

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
  String get historyTab => 'Недавние';

  @override
  String get favoritesTab => 'Избранное';

  @override
  String get noRecentRecords => 'Нет недавних записей';

  @override
  String get addMenuRecentEntries => 'Рекомендуемые';

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
  String get logEntry => 'Записать';

  @override
  String get saveMacros => 'Сохранить макросы';

  @override
  String get macrosSavedToast => 'Макросы сохранены';

  @override
  String get updateDish => 'Обновить блюдо';

  @override
  String get refineDish => 'Уточнить блюдо';

  @override
  String get refineDishHint => 'Уточнить блюдо ...';

  @override
  String get activityWalking => 'Ходьба';

  @override
  String get activityBicycle => 'Велосипед';

  @override
  String get activityResting => 'Покой';

  @override
  String approxHours(int count) {
    return '~ $count ч';
  }

  @override
  String approxMinutes(int count) {
    return '~ $count мин';
  }

  @override
  String get healthRatingLabel => 'Польза';

  @override
  String healthRatingValue(int value) {
    return '$value / 10';
  }

  @override
  String get healthDescPoor =>
      'Высокая калорийность, простые углеводы, жиры или соль — лучше как редкое удовольствие.';

  @override
  String get healthDescFair =>
      'Вкусно и сытно, но, скорее всего, много калорий, простых углеводов, жиров и соли.';

  @override
  String get healthDescGood =>
      'Сбалансированный приём пищи с разумным соотношением макроэлементов.';

  @override
  String get healthDescGreat =>
      'Богато нутриентами и сбалансировано — отличный выбор.';

  @override
  String get healthDescVeggie =>
      'Лёгкий и водянистый — много микронутриентов на калорию.';

  @override
  String get healthDescHighProtein =>
      'С перевесом в белок — отлично насыщает и помогает восстановлению.';

  @override
  String get healthDescLeanProtein =>
      'Нежирный белок — хорошая основа для рациона.';

  @override
  String get healthDescBalanced =>
      'Сбалансированные макросы — впишется в большинство планов питания.';

  @override
  String get healthDescCarbHeavy =>
      'Много углеводов — добавь белок или овощи, чтобы насытило надолго.';

  @override
  String get healthDescFatHeavy => 'Калорийный из-за жиров — следи за порцией.';

  @override
  String get healthDescSweet =>
      'Сладкий и энергоёмкий — лучше как нечастое удовольствие.';

  @override
  String get healthDescUltraProcessed =>
      'Калорий много, белка мало — старайся не есть часто.';

  @override
  String get healthTraitHighProtein => 'Заметно богат белком.';

  @override
  String get healthTraitLowCalDensity => 'Легко вписывается в дневную норму.';

  @override
  String get healthTraitHighFat => 'Калорийный за счёт жиров.';

  @override
  String get healthTraitHighCarb => 'Основа — углеводы.';

  @override
  String get healthTraitBalancedMacros => 'Макросы распределены равномерно.';

  @override
  String get healthAdviceGreat => 'Подходит почти каждый день.';

  @override
  String get healthAdviceGood => 'Удачный выбор для сбалансированного дня.';

  @override
  String get healthAdviceFair => 'Ешь умеренно.';

  @override
  String get healthAdvicePoor => 'Лучше как редкое удовольствие.';

  @override
  String get ofYourDailyCalories => 'от дневной нормы';

  @override
  String dailyCaloriesPercent(int percent) {
    return '$percent%';
  }

  @override
  String get recognizeDish => 'Распознать блюдо';

  @override
  String get photoDetailsHint => 'Распишите подробнее, если хотите ...';

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
  String get caloriesRemaining => 'Осталось калорий';

  @override
  String get dailyEatenLabel => 'Съедено';

  @override
  String get dailyGoalLabel => 'Цель';

  @override
  String get openMore => 'Развернуть';

  @override
  String get goToStatistics => 'К статистике';

  @override
  String get goalsParamGoal => 'Цель';

  @override
  String get goalsParamGender => 'Пол';

  @override
  String get goalsParamAge => 'Возраст';

  @override
  String get goalsParamHeight => 'Рост';

  @override
  String get goalsParamWeight => 'Вес';

  @override
  String get goalsParamTargetWeight => 'Целевой вес';

  @override
  String get goalsParamActivity => 'Активность';

  @override
  String get goalsPlanNote => 'Рассчитано по вашему плану';

  @override
  String get goalsCustomNote => 'Свои значения';

  @override
  String get goalsEditManually => 'Изменить самостоятельно';

  @override
  String get goalsUsePlan => 'Рассчитать по плану';

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
  String get onboardingAgeYearsUnit => 'лет';

  @override
  String get onboardingLoadingCalc => 'Анализируем ваши ответы...';

  @override
  String get onboardingLoadingNorm => 'Настраиваем ежедневные цели...';

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
      'Только оценка питания. Не медицинская рекомендация.';

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
  String get resultPlanReadyTitle => 'Ваш персональный план готов';

  @override
  String get resultHeroSubtitle => 'На основе ваших ответов';

  @override
  String get resultRingAdjustLine =>
      'Цифры можно скорректировать в любой момент';

  @override
  String get resultGoalCardTitle => 'Ваша цель';

  @override
  String resultGoalMaintainTitle(String weight) {
    return 'Удерживать вес около $weight';
  }

  @override
  String get resultGoalMaintainSubtitle =>
      'Без жёстких ограничений — баланс на каждый день';

  @override
  String get resultBridgeTitle =>
      'Чтобы план работал — его нужно вести каждый день';

  @override
  String get resultBridgeFreeLine =>
      'Бесплатно — 3 записи еды, чтобы попробовать';

  @override
  String get resultBridgePremiumLine => 'С Premium — без лимита, до самой цели';

  @override
  String get resultDisclaimerShort => 'Не заменяет консультацию врача.';

  @override
  String get resultDisclaimerExpand => 'Подробнее';

  @override
  String get resultSourcesTitle => 'Источники';

  @override
  String get resultSourceCaloriesLabel => 'Норма калорий';

  @override
  String get resultSourceMacrosLabel => 'Распределение БЖУ';

  @override
  String get resultSourcesCta => 'Источники и методика';

  @override
  String get profileMethodology => 'Источники и методика питания';

  @override
  String get profileMethodologyIntro => 'Как рассчитываются ваши дневные цели';

  @override
  String get methodologyCaloriesSection => 'Норма калорий';

  @override
  String get methodologyMacrosSection => 'Цели по БЖУ';

  @override
  String get methodologyGeneralSection => 'Общие рекомендации по питанию';

  @override
  String get methodologySourceMifflinDescription =>
      'Формула BMR для оценки калорий.';

  @override
  String get methodologySourceDriDescription =>
      'Диапазоны для белков, жиров и углеводов.';

  @override
  String get methodologySourceUsdaDescription =>
      'DRI-референсы по калориям и нутриентам.';

  @override
  String get methodologySourceWhoDescription =>
      'Общие рекомендации по здоровому питанию.';

  @override
  String get methodologyOpenSourceFailed => 'Не удалось открыть источник.';

  @override
  String get resultOpenPlan => 'Открыть мой план';

  @override
  String get socialProofScaleTitle => 'Создано для серьёзного учёта';

  @override
  String get socialProofScaleSubtitle =>
      'Технология, на которой строится ваш план';

  @override
  String get socialProofScaleProductsLabel => 'продуктов в нашей базе';

  @override
  String get socialProofScaleSecondsUnit => 'сек';

  @override
  String get socialProofScaleSpeedLabel => 'Распознавание блюд по фото';

  @override
  String get socialProofPoweredBy => 'Работает на';

  @override
  String get socialProofAccuracyTitle => 'Проверено на точность';

  @override
  String get socialProofAccuracySubtitle =>
      'Насколько точно AI определяет ваши блюда';

  @override
  String get socialProofAccuracyLabel => 'Точность AI';

  @override
  String get socialProofAccuracyDisclaimer =>
      'На основе внутреннего контроля качества на 500+ блюдах из разных кухонь мира.';

  @override
  String get socialProofScienceTitle => 'В основе — нутрициология';

  @override
  String get socialProofScienceSubtitle =>
      'Ваш план рассчитан по проверенной формуле';

  @override
  String get socialProofScienceFormulaCaption =>
      'Золотой стандарт нутрициологии с 1990 года';

  @override
  String get socialProofScienceTrust =>
      'Используется дипломированными диетологами и клиническими нутрициологами по всему миру.';

  @override
  String get paywallTitle => 'Попробуйте Pro\nбесплатно';

  @override
  String get paywallWeeklyTitle => 'Откройте Pro\nсегодня';

  @override
  String get paywallWeeklyTimelineTodayTitle => 'Сегодня — откройте Pro';

  @override
  String get paywallWeeklyTimelineTodayDesc =>
      'AI-сканирование, дневник питания и аналитика без ограничений.';

  @override
  String get paywallWeeklyTimelineRenewTitle => 'Еженедельно — прогресс';

  @override
  String get paywallWeeklyTimelineRenewDesc =>
      'План продлевается еженедельно, чтобы доступ не прерывался.';

  @override
  String get paywallWeeklyTimelineCancelTitle => 'Отмена в любой момент';

  @override
  String get paywallWeeklyTimelineCancelDesc =>
      'Отменяйте подписку в настройках аккаунта магазина.';

  @override
  String get paywallTimelineTodayTitle => 'Сегодня — откройте Pro';

  @override
  String get paywallTimelineTodayDesc =>
      'AI-сканирование, дневник питания и аналитика без ограничений.';

  @override
  String get paywallTimelineReminderTitle => 'Через 2 дня — напомним';

  @override
  String get paywallTimelineReminderDesc =>
      'Мы напомним, что пробный период скоро закончится';

  @override
  String get paywallTimelinePayTitle => 'Через 3 дня — оплата';

  @override
  String paywallTimelinePayDesc(String date) {
    return 'Списание будет $date, если вы не отмените подписку';
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
  String get paywallTrialBadge => '3 дня бесплатно';

  @override
  String get paywallYearlyDiscount => '-85%';

  @override
  String get paywallSubtitle =>
      'Максимум возможностей и эксклюзивные функции с подпиской BodyMeal Pro';

  @override
  String get paywallFeatureAiTitle => 'ИИ-распознование';

  @override
  String get paywallFeatureAiDesc =>
      'Сфотографируй — ИИ определит калории и нутриенты за секунду.';

  @override
  String get paywallFeatureDiaryTitle => 'Дневник питания';

  @override
  String get paywallFeatureDiaryDesc =>
      'Записывайте все приёмы пищи без ограничений, каждый день.';

  @override
  String get paywallFeatureAnalyticsTitle => 'Детальная аналитика';

  @override
  String get paywallFeatureAnalyticsDesc =>
      'Графики калорий, БЖУ и прогресс по вашим целям за любой период.';

  @override
  String get paywallFeatureBarcodeTitle => 'Сканер штрихкодов';

  @override
  String get paywallFeatureBarcodeDesc =>
      'Наведите камеру на упаковку — данные подтянутся сами.';

  @override
  String get paywallNoPaymentNow => 'Платёж сейчас не требуется';

  @override
  String get paywallStartTrial => 'Начать пробный период';

  @override
  String get paywallTrialDisclaimer => '3 дня бесплатно, затем \$39.99/год';

  @override
  String get paywallWeeklyDisclaimer =>
      'Списание сегодня. Отмена в любой момент.';

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
  String get paywallErrorSelectedProductUnavailable =>
      'Этот вариант подписки сейчас недоступен. Выберите другой тариф или попробуйте ещё раз.';

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
  String get paywallGo => 'Начать';

  @override
  String get paywallHardDisclaimer => 'Автопродление. Отмена в любой момент.';

  @override
  String get paywallHardTitle => 'Продолжайте\nс Pro';

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

  @override
  String get analyticsTitle => 'Аналитика';

  @override
  String get summarySection => 'Сводка';

  @override
  String get trendsSection => 'Тренды';

  @override
  String get highlightsSection => 'Главное';

  @override
  String dayStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Дней подряд',
      many: 'Дней подряд',
      few: 'Дня подряд',
      one: 'День подряд',
      zero: 'Дней подряд',
    );
    return '$_temp0';
  }

  @override
  String get averageADay => 'в среднем за день';

  @override
  String calDifferenceCount(int count) {
    return 'Разница $count ккал';
  }

  @override
  String percentAverage(int count) {
    return '$count/100% среднего';
  }

  @override
  String analyticsHighlightHigher(String metric) {
    return 'Среднее потребление $metric за день на этой неделе выше, чем на прошлой.';
  }

  @override
  String analyticsHighlightLower(String metric) {
    return 'Среднее потребление $metric за день на этой неделе ниже, чем на прошлой.';
  }

  @override
  String analyticsHighlightSimilar(String metric) {
    return 'Среднее потребление $metric за день примерно такое же, как на прошлой неделе.';
  }

  @override
  String get analyticsPeriod1W => '1 Н';

  @override
  String get analyticsPeriod2W => '2 Н';

  @override
  String get analyticsPeriod1M => '1 М';

  @override
  String get analyticsPeriod3M => '3 М';

  @override
  String get analyticsPeriod6M => '6 М';

  @override
  String get analyticsPeriod1Y => '1 Г';

  @override
  String get analyticsMetricCal => 'Ккал';

  @override
  String get analyticsMetricProtein => 'Белки';

  @override
  String get analyticsMetricFat => 'Жиры';

  @override
  String get analyticsMetricCarbs => 'Углев';

  @override
  String get quantityLabel => 'Количество';

  @override
  String get addSuggestionsLabel => 'Добавить ингредиент';

  @override
  String get suggestionSomethingElse => 'Другое';

  @override
  String get untitledIngredientName => 'Без названия';

  @override
  String get onbObstaclesTitle => 'Что мешало вам раньше?';

  @override
  String get onbObstaclesHint => 'Выберите всё, что относится к вам';

  @override
  String get obstacleConsistency => 'Не получается быть последовательным';

  @override
  String get obstacleKnowledge => 'Не знаю, что есть';

  @override
  String get obstacleBusy => 'Загруженный график';

  @override
  String get obstacleCravings => 'Сильная тяга к сладкому/мучному';

  @override
  String get obstacleSupport => 'Нет поддержки';

  @override
  String get obstacleEatingOut => 'Часто ем вне дома';

  @override
  String get obstacleMotivation => 'Не хватает мотивации';

  @override
  String get obstacleTracking => 'Сложно считать калории';

  @override
  String get onbSpeedTitleLose => 'Как быстро хотите похудеть?';

  @override
  String get onbSpeedTitleGain => 'Как быстро хотите набрать массу?';

  @override
  String onbSpeedHintKg(String rate) {
    return 'Рекомендуемый темп — $rate кг/неделю';
  }

  @override
  String onbSpeedHintLb(String rate) {
    return 'Рекомендуемый темп — $rate фнт/неделю';
  }

  @override
  String onbSpeedKgPerWeek(String value) {
    return '$value кг/неделю';
  }

  @override
  String onbSpeedLbPerWeek(String value) {
    return '$value фнт/неделю';
  }

  @override
  String get onbSpeedBadgeGentle => 'Мягкий темп ✅';

  @override
  String get onbSpeedBadgeRecommended => 'Рекомендуемый темп ⭐';

  @override
  String get onbSpeedBadgeAmbitious => 'Амбициозно 🔥';

  @override
  String get onbSpeedBadgeAggressive => 'Очень агрессивно ⚠️';

  @override
  String onbSpeedTargetByPrefix(String weight) {
    return 'Вы достигнете $weight к';
  }

  @override
  String get onbQuizTitle => 'Расскажите о ваших привычках';

  @override
  String get onbQuizHint => 'Это поможет персонализировать ваш план';

  @override
  String get quizStressEatingLeft => 'Часто ем от стресса';

  @override
  String get quizStressEatingRight => 'Ем только для энергии';

  @override
  String get quizSweetPreferenceLeft => 'Люблю сладкое';

  @override
  String get quizSweetPreferenceRight => 'Предпочитаю солёное/острое';

  @override
  String get quizExerciseConsistencyLeft => 'Тренируюсь постоянно';

  @override
  String get quizExerciseConsistencyRight =>
      'Не получается заниматься регулярно';

  @override
  String get quizMealPlanningLeft => 'Планирую приёмы пищи';

  @override
  String get quizMealPlanningRight => 'Ем что под рукой';

  @override
  String get quizMotivationTypeLeft => 'Меня двигают результаты';

  @override
  String get quizMotivationTypeRight => 'Меня двигают ощущения';

  @override
  String get onbRateTitle => 'Нравится ваш план?';

  @override
  String get onbRateSubtitle =>
      'Оцените Body Meal — это поможет нам стать лучше';

  @override
  String get onbRateButton => 'Оценить';

  @override
  String get onbRateSkip => 'Пропустить';

  @override
  String get onbRateFeedbackTitle => 'Что мы можем улучшить?';

  @override
  String get onbRateFeedbackHint => 'Расскажите, что не понравилось';

  @override
  String get onbRateFeedbackSubmit => 'Отправить';

  @override
  String resultAnchorPrefix(String weight) {
    return 'Вы достигнете $weight к';
  }

  @override
  String resultAnchorWeeksSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '(через $count недель)',
      many: '(через $count недель)',
      few: '(через $count недели)',
      one: '(через 1 неделю)',
    );
    return '$_temp0';
  }

  @override
  String resultMaintainCard(String weight) {
    return 'Мы поможем удержать вес на $weight';
  }

  @override
  String get resultDailyNormLabel => 'ВАША ДНЕВНАЯ НОРМА';

  @override
  String resultPsychotypeLabel(String title) {
    return 'Ваш тип питания: $title';
  }

  @override
  String get resultObstaclesHeader => 'Ваш план учитывает:';

  @override
  String get resultMilestonesHeader => 'Ваш прогресс по неделям:';

  @override
  String get resultGoalRow => 'Цель';

  @override
  String resultWeekRow(int week) {
    return 'Неделя $week';
  }

  @override
  String resultGoalReachLine(String weight) {
    return 'Вы достигнете $weight';
  }

  @override
  String resultGoalByDateLine(String date) {
    return 'к $date';
  }

  @override
  String resultGoalInWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'через $count недель',
      many: 'через $count недель',
      few: 'через $count недели',
      one: 'через 1 неделю',
    );
    return '$_temp0';
  }

  @override
  String get resultBenefit5MinDay => 'Занимает 5 минут в день';

  @override
  String get resultBenefitSmartTracking => 'Умный трекинг без усилий';

  @override
  String get resultBenefitTailored => 'Меню под ваш образ жизни';

  @override
  String get resultBenefitSustainable => 'Устойчивый результат, а не диета';

  @override
  String get resultFaqHeader => 'FAQ';

  @override
  String get resultFaqCancelQ => 'Как отменить подписку?';

  @override
  String get resultFaqCancelAIos =>
      'Откройте Настройки → ваше имя → Подписки на iPhone, найдите Body Meal и нажмите «Отменить подписку».';

  @override
  String get resultFaqCancelAAndroid =>
      'Откройте Google Play → профиль → Платежи и подписки → Подписки, найдите Body Meal и нажмите «Отменить».';

  @override
  String get resultFaqSecurityQ => 'Безопасны ли мои данные?';

  @override
  String get resultFaqSecurityA =>
      'Данные шифруются при передаче и хранении. Мы не передаём их рекламодателям, а аккаунт можно удалить в настройках в любой момент.';

  @override
  String get resultFaqTrialQ => 'Есть ли бесплатный пробный период?';

  @override
  String get resultFaqTrialA =>
      'Да — пробный период доступен в годовом тарифе. Деньги не списываются до его окончания, отменить можно в любой момент до этого.';

  @override
  String get loadingMetabolism => 'Анализируем ваш метаболизм...';

  @override
  String get loadingCalories => 'Рассчитываем дневную норму калорий...';

  @override
  String get loadingMacros => 'Подбираем баланс белков / жиров / углеводов...';

  @override
  String get loadingPsychotype => 'Анализируем ваш психотип и привычки...';

  @override
  String get loadingPlanCreate => 'Создаём персональный план...';

  @override
  String get psyStressEaterTitle => 'Эмоциональный едок';

  @override
  String get psyStressEaterDesc =>
      'Вы едите от эмоций. Мы поможем найти альтернативы.';

  @override
  String get psyFuelFocusedTitle => 'Рациональный едок';

  @override
  String get psyFuelFocusedDesc =>
      'Вы рациональны в питании. Останется только точно посчитать.';

  @override
  String get psySweetLoverTitle => 'Сладкоежка';

  @override
  String get psySweetLoverDesc => 'Мы научим заменять сладкое без срывов.';

  @override
  String get psySavoryLoverTitle => 'Любитель острого';

  @override
  String get psySavoryLoverDesc =>
      'Острое и солёное — ваш стиль. Найдём баланс по натрию.';

  @override
  String get psyConsistentAthleteTitle => 'Спортивный профи';

  @override
  String get psyConsistentAthleteDesc =>
      'У вас сильная база. Точная диета умножит результат.';

  @override
  String get psyInconsistentTitle => 'Герой рестарта';

  @override
  String get psyInconsistentDesc =>
      'Главное — начать снова. Мы упростим возврат.';

  @override
  String get psyPlannerTitle => 'Планировщик';

  @override
  String get psyPlannerDesc =>
      'Вы любите контроль. Дайте AI просчитать всё за вас.';

  @override
  String get psyConvenienceEaterTitle => 'Едок на бегу';

  @override
  String get psyConvenienceEaterDesc =>
      'Времени мало — поможем выбирать быстро и правильно.';

  @override
  String get psyResultsDrivenTitle => 'Целеустремлённый';

  @override
  String get psyResultsDrivenDesc =>
      'Вас двигают цифры. Покажем прогресс наглядно.';

  @override
  String get psyFeelingsDrivenTitle => 'Интуитивный едок';

  @override
  String get psyFeelingsDrivenDesc =>
      'Вы слушаете себя. Мы дополним это данными.';

  @override
  String get psyBalancedTitle => 'Сбалансированный подход';

  @override
  String get psyBalancedDesc =>
      'У вас здоровый подход к питанию. Усилим его данными.';

  @override
  String get onbWelcomeTitle => 'Составим план для вашей цели';

  @override
  String get onbWelcomeSubtitle =>
      'Считайте калории и БЖУ быстро и точно — без ручного ввода!';

  @override
  String get onbWelcomeCta => 'Начать';

  @override
  String get onbLanguageSheetTitle => 'Выберите язык';

  @override
  String get langShortEn => 'Eng';

  @override
  String get langShortRu => 'Рус';

  @override
  String get langShortDe => 'Нем';

  @override
  String get langShortEs => 'Исп';

  @override
  String get langShortFr => 'Фра';

  @override
  String get langShortPt => 'Пор';

  @override
  String get onbConfidentTitle => 'Спасибо, что доверяете';

  @override
  String get onbConfidentSubtitle =>
      'Мы персонализируем Body Meal специально под ваши цели';

  @override
  String get onbConfidentPrivacyTitle => 'Ваша конфиденциальность важна';

  @override
  String get onbConfidentPrivacyBody =>
      'Мы обещаем хранить вашу личную информацию в секрете';

  @override
  String get onbKeepResultTitle => 'Body Meal помогает удерживать результат';

  @override
  String get onbKeepResultSubtitle =>
      'Сохраняйте стабильный прогресс даже через 6 месяцев!';

  @override
  String get onbCalorieHistoryTitle => 'Вы когда-нибудь считали калории?';

  @override
  String get onbCalorieHistoryYes => 'Да, и продолжаю';

  @override
  String onbCalorieHistoryTried(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Пробовал, но бросил',
      'female': 'Пробовала, но бросила',
      'other': 'Пробовал(а), но бросил(а)',
    });
    return '$_temp0';
  }

  @override
  String get onbCalorieHistoryNever => 'Нет, никогда';

  @override
  String get onbImproveTitle => 'Что вы хотите улучшить?';

  @override
  String get onbImproveLookBetter => 'Выглядеть лучше';

  @override
  String get onbImproveFeelConfident => 'Чувствовать себя увереннее';

  @override
  String get onbImproveHealth => 'Улучшить здоровье';

  @override
  String get onbImproveMoreEnergy => 'Больше энергии';

  @override
  String get onbImproveLessStress => 'Меньше стресса';

  @override
  String get onbImproveImmunity => 'Поддержать иммунитет';

  @override
  String get onbImproveFocus => 'Лучше фокусироваться';

  @override
  String get onbImproveSleep => 'Лучше спать';

  @override
  String get onbEatingObstacleTitle => 'Что мешает вам питаться полезнее?';

  @override
  String get onbEatingObstacleCravings => 'Тяга к сладкому или вредному';

  @override
  String get onbEatingObstacleLateSnacks => 'Поздние перекусы';

  @override
  String get onbEatingObstacleBadHabits => 'Неполезные привычки';

  @override
  String get onbHardestTitle =>
      'Что сложнее всего — не срываться и держать режим?';

  @override
  String get onbHardestBusy => 'Плотный график';

  @override
  String get onbHardestRestrictive => 'Слишком много ограничений';

  @override
  String get onbHardestNoSupport => 'Не хватает поддержки';

  @override
  String get onbSupportTitle => 'Мы будем рядом!';

  @override
  String get onbSupportSubtitle =>
      'Путь к цели бывает непростым, но мы будем поддерживать вас на каждом шаге.';

  @override
  String get onbSocialProofTitle =>
      'С поддержкой люди теряют вес больше и быстрее';

  @override
  String get onbSocialProofSubtitle =>
      'Приложение может помочь вам достичь устойчивых результатов в снижении веса.';

  @override
  String get onbSpeedSlow => 'Медленно';

  @override
  String get onbSpeedBalanced => 'Сбалансированно';

  @override
  String get onbSpeedFast => 'Быстро';

  @override
  String onbSpeedGoodTitle(String date) {
    return 'Цель: $date';
  }

  @override
  String get onbSpeedGoodBody =>
      'Разумный план — устойчивый результат без срывов и плато.';

  @override
  String get onbSpeedAlertTitle => 'Слишком быстро — высок риск срыва';

  @override
  String get onbSpeedAlertBody =>
      'Выберите более устойчивый темп, чтобы дойти до цели без срывов.';

  @override
  String get onbTrialReminderTitle =>
      'Мы пришлём напоминание,\nчто пробный период\nскоро закончится.';

  @override
  String get onbTrialReminderNoPaymentNow => 'Платёж сейчас не требуется';

  @override
  String onbTrialReminderCta(String price) {
    return 'Попробовать за $price';
  }

  @override
  String onbTrialReminderSubtitle(String yearly, String monthly) {
    return 'Всего $yearly в год ($monthly / мес)';
  }

  @override
  String get tagHighProtein => 'Много белка';

  @override
  String get tagContainsProtein => 'Есть белок';

  @override
  String get tagLowProtein => 'Мало белка';

  @override
  String get tagCompleteProtein => 'Полноценный белок';

  @override
  String get tagHealthyFats => 'Полезные жиры';

  @override
  String get tagRichInOmega3 => 'Омега-3';

  @override
  String get tagHighFat => 'Много жиров';

  @override
  String get tagHighSatFat => 'Насыщенные жиры';

  @override
  String get tagHighTransFat => 'Транс-жиры';

  @override
  String get tagLowFat => 'Мало жиров';

  @override
  String get tagHighFiber => 'Много клетчатки';

  @override
  String get tagContainsFiber => 'Есть клетчатка';

  @override
  String get tagLowFiber => 'Мало клетчатки';

  @override
  String get tagComplexCarbs => 'Сложные углеводы';

  @override
  String get tagRefinedCarbs => 'Быстрые углеводы';

  @override
  String get tagLowSugar => 'Мало сахара';

  @override
  String get tagHighSugar => 'Много сахара';

  @override
  String get tagLowCarb => 'Низкоуглеводное';

  @override
  String get tagHighCalories => 'Калорийное';

  @override
  String get tagLowCalories => 'Низкокалорийное';

  @override
  String get tagHighEnergy => 'Много энергии';

  @override
  String get tagHelpsQuota => 'Добивает норму';

  @override
  String get tagNutrientDense => 'Питательное';

  @override
  String get tagEmptyCalories => 'Пустые калории';

  @override
  String get tagHeavyMeal => 'Тяжёлое блюдо';

  @override
  String get tagLightMeal => 'Лёгкое блюдо';

  @override
  String get tagHighSalt => 'Много соли';

  @override
  String get tagLowSalt => 'Мало соли';

  @override
  String get tagHighCholesterol => 'Много холестерина';

  @override
  String get tagGoodPostWorkout => 'После тренировки';

  @override
  String get tagGoodPreWorkout => 'Перед тренировкой';

  @override
  String get tagBreakfastFriendly => 'Хороший завтрак';

  @override
  String get tagHeartFriendly => 'Для сердца';

  @override
  String get tagGutFriendly => 'Для ЖКТ';

  @override
  String get tagBrainFood => 'Для мозга';

  @override
  String get tagImmuneBoost => 'Для иммунитета';

  @override
  String get tagBoneHealth => 'Для костей';

  @override
  String get tagRichInVitamins => 'Много витаминов';

  @override
  String get tagRichInIron => 'Богато железом';

  @override
  String get tagRichInCalcium => 'Богато кальцием';

  @override
  String get tagRichInPotassium => 'Богато калием';

  @override
  String get tagHighAntioxidants => 'Антиоксиданты';

  @override
  String get tagBalancedMacros => 'Баланс БЖУ';

  @override
  String get tagWholeFoods => 'Натуральные продукты';

  @override
  String get tagUltraProcessed => 'Переработанное';

  @override
  String get tagPlantBased => 'Растительное';

  @override
  String get tagHydrating => 'Увлажняющее';

  @override
  String get forYourGoalLose => 'Цель: Похудеть';

  @override
  String get forYourGoalMaintain => 'Цель: Поддержание';

  @override
  String get forYourGoalGain => 'Цель: Набор массы';

  @override
  String get completeMacroSection => 'Полные показатели';

  @override
  String get macroSugar => 'Сахар';

  @override
  String get macroFiber => 'Клетчатка';

  @override
  String get macroSaturatedFat => 'Насыщенные жиры';

  @override
  String get macroCholesterol => 'Холестерин';

  @override
  String get macroTransFat => 'Транс-жиры';

  @override
  String get macroGlycemicLoad => 'Гликем. нагрузка';

  @override
  String get macroCaloricDensity => 'Плотность калорий';

  @override
  String get macroProcessing => 'Степень обработки';

  @override
  String get macroVitamins => 'Витамины и минералы';

  @override
  String get macroStatusWorse => 'Хуже среднего';

  @override
  String get macroStatusAverage => 'Средне';

  @override
  String get macroStatusGood => 'Хорошо';

  @override
  String get dishWeightLabel => 'Вес блюда';

  @override
  String get macroSalt => 'Соль';

  @override
  String get burnSectionTitle => 'Как сжечь калории?';

  @override
  String get burnWalking => 'Ходьба';

  @override
  String get burnRunning => 'Бег';

  @override
  String get burnGym => 'Тренировка';

  @override
  String get burnCycling => 'Велосипед';

  @override
  String get burnResting => 'Покой';

  @override
  String get burnOr => 'или';

  @override
  String burnApproxSteps(String count) {
    return '~ $count шагов';
  }

  @override
  String burnApproxKm(String count) {
    return '~ $count км';
  }

  @override
  String burnApproxHoursMinutes(int hours, int minutes) {
    return '~ $hours ч $minutes мин';
  }

  @override
  String get aiLoadingPhrase01 => 'Хм… выглядит подозрительно вкусно.';

  @override
  String get aiLoadingPhrase02 => 'Секунду, мне нужно изучить эту красоту.';

  @override
  String get aiLoadingPhrase03 => 'Посмотрим, что прячет тарелка.';

  @override
  String get aiLoadingPhrase04 => 'Еда обнаружена. Любопытство активировано.';

  @override
  String get aiLoadingPhrase05 => 'Подожди, у этого блюда есть секреты.';

  @override
  String get aiLoadingPhrase06 => 'Анализирую аппетитную ситуацию…';

  @override
  String get aiLoadingPhrase07 => 'Дай-ка я разгадаю эту вкусную загадку.';

  @override
  String get aiLoadingPhrase08 => 'Маленький детектив еды на деле.';

  @override
  String get aiLoadingPhrase09 => 'Выглядит хорошо. Подозрительно хорошо.';

  @override
  String get aiLoadingPhrase10 => 'Сканирую тарелку как улику.';

  @override
  String get aiLoadingPhrase11 => 'Минутку, расследую эту вкуснотищу.';

  @override
  String get aiLoadingPhrase12 => 'Выясним, что тут на самом деле.';

  @override
  String get aiLoadingPhrase13 => 'Вилка подождёт. Сначала наука.';

  @override
  String get aiLoadingPhrase14 => 'Проверю, такое ли оно невинное.';

  @override
  String get aiLoadingPhrase15 => 'Происходит что-то вкусное…';

  @override
  String get aiLoadingPhrase16 => 'Приближаюсь к аппетитным уликам.';

  @override
  String get aiLoadingPhrase17 => 'Веду полное расследование закуски.';

  @override
  String get aiLoadingPhrase18 => 'Чую калории. Метафорически.';

  @override
  String get aiLoadingPhrase19 => 'Тарелка вошла в режим анализа.';

  @override
  String get aiLoadingPhrase20 => 'Секунду, читаю гастрономические сплетни.';

  @override
  String get aiLoadingPhrase21 => 'Ищу макросы за этой магией.';

  @override
  String get aiLoadingPhrase22 => 'Хм… тарелка — главный герой.';

  @override
  String get aiLoadingPhrase23 => 'Посмотрим, из чего сделан этот мини-пир.';

  @override
  String get aiLoadingPhrase24 => 'Считаю цифры, а не твоё блюдо.';

  @override
  String get aiLoadingPhrase25 => 'Вайбы еды обнаружены. Считаем…';
}
