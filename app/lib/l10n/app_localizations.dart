import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('pt'),
    Locale('ru'),
  ];

  /// No description provided for @mealBreakfast.
  ///
  /// In ru, this message translates to:
  /// **'Завтрак'**
  String get mealBreakfast;

  /// No description provided for @mealLunch.
  ///
  /// In ru, this message translates to:
  /// **'Обед'**
  String get mealLunch;

  /// No description provided for @mealDinner.
  ///
  /// In ru, this message translates to:
  /// **'Ужин'**
  String get mealDinner;

  /// No description provided for @mealSnack.
  ///
  /// In ru, this message translates to:
  /// **'Перекус'**
  String get mealSnack;

  /// No description provided for @kcalUnit.
  ///
  /// In ru, this message translates to:
  /// **'ккал'**
  String get kcalUnit;

  /// No description provided for @gramsUnit.
  ///
  /// In ru, this message translates to:
  /// **'г'**
  String get gramsUnit;

  /// No description provided for @gramsUnitDot.
  ///
  /// In ru, this message translates to:
  /// **'г.'**
  String get gramsUnitDot;

  /// No description provided for @kgUnit.
  ///
  /// In ru, this message translates to:
  /// **'кг'**
  String get kgUnit;

  /// No description provided for @cmUnit.
  ///
  /// In ru, this message translates to:
  /// **'см'**
  String get cmUnit;

  /// No description provided for @yearsUnit.
  ///
  /// In ru, this message translates to:
  /// **'лет'**
  String get yearsUnit;

  /// No description provided for @kcalValue.
  ///
  /// In ru, this message translates to:
  /// **'{count} ккал'**
  String kcalValue(String count);

  /// No description provided for @kcalValueInt.
  ///
  /// In ru, this message translates to:
  /// **'{count} Ккал'**
  String kcalValueInt(int count);

  /// No description provided for @gramsValue.
  ///
  /// In ru, this message translates to:
  /// **'{count} г.'**
  String gramsValue(int count);

  /// No description provided for @kcalPer100g.
  ///
  /// In ru, this message translates to:
  /// **'{count} ккал/100г'**
  String kcalPer100g(String count);

  /// No description provided for @per100gInfo.
  ///
  /// In ru, this message translates to:
  /// **'На 100 г: {cal} ккал  Б{prot} Ж{fat} У{carbs}'**
  String per100gInfo(int cal, String prot, String fat, String carbs);

  /// No description provided for @proteinShort.
  ///
  /// In ru, this message translates to:
  /// **'б'**
  String get proteinShort;

  /// No description provided for @fatShort.
  ///
  /// In ru, this message translates to:
  /// **'ж'**
  String get fatShort;

  /// No description provided for @carbsShort.
  ///
  /// In ru, this message translates to:
  /// **'у'**
  String get carbsShort;

  /// No description provided for @proteinLabel.
  ///
  /// In ru, this message translates to:
  /// **'Белки'**
  String get proteinLabel;

  /// No description provided for @fatLabel.
  ///
  /// In ru, this message translates to:
  /// **'Жиры'**
  String get fatLabel;

  /// No description provided for @carbsLabel.
  ///
  /// In ru, this message translates to:
  /// **'Углеводы'**
  String get carbsLabel;

  /// No description provided for @carbsLabelShort.
  ///
  /// In ru, this message translates to:
  /// **'Углев.'**
  String get carbsLabelShort;

  /// No description provided for @caloriesLabel.
  ///
  /// In ru, this message translates to:
  /// **'Калории'**
  String get caloriesLabel;

  /// No description provided for @caloriesKcalLabel.
  ///
  /// In ru, this message translates to:
  /// **'Калории, ккал'**
  String get caloriesKcalLabel;

  /// No description provided for @proteinGramsLabel.
  ///
  /// In ru, this message translates to:
  /// **'Белки, г'**
  String get proteinGramsLabel;

  /// No description provided for @fatGramsLabel.
  ///
  /// In ru, this message translates to:
  /// **'Жиры, г'**
  String get fatGramsLabel;

  /// No description provided for @carbsGramsLabel.
  ///
  /// In ru, this message translates to:
  /// **'Углеводы, г'**
  String get carbsGramsLabel;

  /// No description provided for @caloriesKcalInputLabel.
  ///
  /// In ru, this message translates to:
  /// **'Калории (ккал)'**
  String get caloriesKcalInputLabel;

  /// No description provided for @proteinGoalLabel.
  ///
  /// In ru, this message translates to:
  /// **'{count} белки'**
  String proteinGoalLabel(int count);

  /// No description provided for @fatGoalLabel.
  ///
  /// In ru, this message translates to:
  /// **'{count} жиры'**
  String fatGoalLabel(int count);

  /// No description provided for @carbsGoalLabel.
  ///
  /// In ru, this message translates to:
  /// **'{count} углеводы'**
  String carbsGoalLabel(int count);

  /// No description provided for @profileTitle.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profileTitle;

  /// No description provided for @myProfile.
  ///
  /// In ru, this message translates to:
  /// **'Мой профиль'**
  String get myProfile;

  /// No description provided for @subscription.
  ///
  /// In ru, this message translates to:
  /// **'Подписка'**
  String get subscription;

  /// No description provided for @myGoals.
  ///
  /// In ru, this message translates to:
  /// **'Мои цели'**
  String get myGoals;

  /// No description provided for @myProducts.
  ///
  /// In ru, this message translates to:
  /// **'Мои продукты'**
  String get myProducts;

  /// No description provided for @settings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settings;

  /// No description provided for @productsList.
  ///
  /// In ru, this message translates to:
  /// **'Список продуктов'**
  String get productsList;

  /// No description provided for @allProducts.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get allProducts;

  /// No description provided for @appTheme.
  ///
  /// In ru, this message translates to:
  /// **'Тема приложения'**
  String get appTheme;

  /// No description provided for @languageSelector.
  ///
  /// In ru, this message translates to:
  /// **'Язык интерфейса'**
  String get languageSelector;

  /// No description provided for @pushNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Push-уведомления'**
  String get pushNotifications;

  /// No description provided for @themeSystem.
  ///
  /// In ru, this message translates to:
  /// **'Системная'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get themeDark;

  /// No description provided for @signOut.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из аккаунта?'**
  String get signOutConfirm;

  /// No description provided for @signOutLocalDataKept.
  ///
  /// In ru, this message translates to:
  /// **'Локальные данные сохранятся на устройстве.'**
  String get signOutLocalDataKept;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get save;

  /// No description provided for @add.
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get add;

  /// No description provided for @close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get close;

  /// No description provided for @edit.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
  String get edit;

  /// No description provided for @guestMode.
  ///
  /// In ru, this message translates to:
  /// **'Гостевой режим'**
  String get guestMode;

  /// No description provided for @defaultUserName.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь'**
  String get defaultUserName;

  /// No description provided for @signedInSnackbar.
  ///
  /// In ru, this message translates to:
  /// **'Вы вошли в аккаунт'**
  String get signedInSnackbar;

  /// No description provided for @signInGoogle.
  ///
  /// In ru, this message translates to:
  /// **'Войти через Google'**
  String get signInGoogle;

  /// No description provided for @signInEmail.
  ///
  /// In ru, this message translates to:
  /// **'Войти по Email'**
  String get signInEmail;

  /// No description provided for @skipLogin.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить без входа'**
  String get skipLogin;

  /// No description provided for @signInSyncHint.
  ///
  /// In ru, this message translates to:
  /// **'Вход позволяет синхронизировать данные\nмежду устройствами'**
  String get signInSyncHint;

  /// No description provided for @calorieTracking.
  ///
  /// In ru, this message translates to:
  /// **'Учёт питания и калорий'**
  String get calorieTracking;

  /// No description provided for @loginTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вход'**
  String get loginTitle;

  /// No description provided for @registerTitle.
  ///
  /// In ru, this message translates to:
  /// **'Регистрация'**
  String get registerTitle;

  /// No description provided for @nameOptional.
  ///
  /// In ru, this message translates to:
  /// **'Имя (необязательно)'**
  String get nameOptional;

  /// No description provided for @enterEmail.
  ///
  /// In ru, this message translates to:
  /// **'Введите email'**
  String get enterEmail;

  /// No description provided for @invalidEmail.
  ///
  /// In ru, this message translates to:
  /// **'Некорректный email'**
  String get invalidEmail;

  /// No description provided for @passwordLabel.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get passwordLabel;

  /// No description provided for @enterPassword.
  ///
  /// In ru, this message translates to:
  /// **'Введите пароль'**
  String get enterPassword;

  /// No description provided for @minPasswordLength.
  ///
  /// In ru, this message translates to:
  /// **'Минимум 6 символов'**
  String get minPasswordLength;

  /// No description provided for @signInButton.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get signInButton;

  /// No description provided for @registerButton.
  ///
  /// In ru, this message translates to:
  /// **'Зарегистрироваться'**
  String get registerButton;

  /// No description provided for @switchToLogin.
  ///
  /// In ru, this message translates to:
  /// **'Войти в аккаунт'**
  String get switchToLogin;

  /// No description provided for @wrongCredentials.
  ///
  /// In ru, this message translates to:
  /// **'Неверный email или пароль'**
  String get wrongCredentials;

  /// No description provided for @signInError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка входа: {error}'**
  String signInError(String error);

  /// No description provided for @emailAlreadyRegistered.
  ///
  /// In ru, this message translates to:
  /// **'Этот email уже зарегистрирован'**
  String get emailAlreadyRegistered;

  /// No description provided for @registerError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка регистрации: {error}'**
  String registerError(String error);

  /// No description provided for @proTitle.
  ///
  /// In ru, this message translates to:
  /// **'MealTracker Pro'**
  String get proTitle;

  /// No description provided for @proUnlockFeatures.
  ///
  /// In ru, this message translates to:
  /// **'Разблокируйте все возможности:'**
  String get proUnlockFeatures;

  /// No description provided for @proAiUnlimited.
  ///
  /// In ru, this message translates to:
  /// **'ИИ-распознавание без лимитов'**
  String get proAiUnlimited;

  /// No description provided for @proExtendedStats.
  ///
  /// In ru, this message translates to:
  /// **'Расширенная статистика'**
  String get proExtendedStats;

  /// No description provided for @proPersonalRecommendations.
  ///
  /// In ru, this message translates to:
  /// **'Персональные рекомендации'**
  String get proPersonalRecommendations;

  /// No description provided for @proTryFree.
  ///
  /// In ru, this message translates to:
  /// **'Попробовать бесплатно'**
  String get proTryFree;

  /// No description provided for @planLabel.
  ///
  /// In ru, this message translates to:
  /// **'План:'**
  String get planLabel;

  /// No description provided for @planWeekly.
  ///
  /// In ru, this message translates to:
  /// **'Еженедельный'**
  String get planWeekly;

  /// No description provided for @billingLabel.
  ///
  /// In ru, this message translates to:
  /// **'Списание:'**
  String get billingLabel;

  /// No description provided for @manageSubscription.
  ///
  /// In ru, this message translates to:
  /// **'Управление подпиской'**
  String get manageSubscription;

  /// No description provided for @goalCaloriesKcal.
  ///
  /// In ru, this message translates to:
  /// **'Калории, ккал'**
  String get goalCaloriesKcal;

  /// No description provided for @goalProteinG.
  ///
  /// In ru, this message translates to:
  /// **'Белки, г'**
  String get goalProteinG;

  /// No description provided for @goalFatG.
  ///
  /// In ru, this message translates to:
  /// **'Жиры, г'**
  String get goalFatG;

  /// No description provided for @goalCarbsG.
  ///
  /// In ru, this message translates to:
  /// **'Углеводы, г'**
  String get goalCarbsG;

  /// No description provided for @remindersTitle.
  ///
  /// In ru, this message translates to:
  /// **'Напоминания'**
  String get remindersTitle;

  /// No description provided for @reminderOff.
  ///
  /// In ru, this message translates to:
  /// **'Выключено'**
  String get reminderOff;

  /// No description provided for @remindersDescription.
  ///
  /// In ru, this message translates to:
  /// **'Напоминания будут приходить ежедневно в указанное время, чтобы вы не забыли записать приемы пищи.'**
  String get remindersDescription;

  /// No description provided for @notifBreakfastBody.
  ///
  /// In ru, this message translates to:
  /// **'Время записать завтрак'**
  String get notifBreakfastBody;

  /// No description provided for @notifLunchBody.
  ///
  /// In ru, this message translates to:
  /// **'Время записать обед'**
  String get notifLunchBody;

  /// No description provided for @notifDinnerBody.
  ///
  /// In ru, this message translates to:
  /// **'Время записать ужин'**
  String get notifDinnerBody;

  /// No description provided for @notifSnackBody.
  ///
  /// In ru, this message translates to:
  /// **'Не забудьте записать перекус'**
  String get notifSnackBody;

  /// No description provided for @notifChannelName.
  ///
  /// In ru, this message translates to:
  /// **'Напоминания о приемах пищи'**
  String get notifChannelName;

  /// No description provided for @notifChannelDesc.
  ///
  /// In ru, this message translates to:
  /// **'Напоминания записать приемы пищи'**
  String get notifChannelDesc;

  /// No description provided for @diaryRecordsForDay.
  ///
  /// In ru, this message translates to:
  /// **'Записи за день'**
  String get diaryRecordsForDay;

  /// No description provided for @diaryEmptyDay.
  ///
  /// In ru, this message translates to:
  /// **'Ещё нет записей за этот день'**
  String get diaryEmptyDay;

  /// No description provided for @addMealTitle.
  ///
  /// In ru, this message translates to:
  /// **'Добавить приём пищи'**
  String get addMealTitle;

  /// No description provided for @mealTypeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Приём пищи'**
  String get mealTypeLabel;

  /// No description provided for @searchInDb.
  ///
  /// In ru, this message translates to:
  /// **'Найти в базе'**
  String get searchInDb;

  /// No description provided for @fromGallery.
  ///
  /// In ru, this message translates to:
  /// **'Из галереи'**
  String get fromGallery;

  /// No description provided for @recognizeByPhoto.
  ///
  /// In ru, this message translates to:
  /// **'Распознать по фото'**
  String get recognizeByPhoto;

  /// No description provided for @productNameOrDish.
  ///
  /// In ru, this message translates to:
  /// **'Название продукта или блюда'**
  String get productNameOrDish;

  /// No description provided for @addEntry.
  ///
  /// In ru, this message translates to:
  /// **'Добавить запись'**
  String get addEntry;

  /// No description provided for @recognizingViaAi.
  ///
  /// In ru, this message translates to:
  /// **'Распознаю через ИИ...'**
  String get recognizingViaAi;

  /// No description provided for @notFoundInDb.
  ///
  /// In ru, this message translates to:
  /// **'Не найдено в базе\nНажмите  ➜  чтобы распознать через ИИ'**
  String get notFoundInDb;

  /// No description provided for @historyTab.
  ///
  /// In ru, this message translates to:
  /// **'История'**
  String get historyTab;

  /// No description provided for @favoritesTab.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get favoritesTab;

  /// No description provided for @noRecentRecords.
  ///
  /// In ru, this message translates to:
  /// **'Нет недавних записей'**
  String get noRecentRecords;

  /// No description provided for @noFavoriteProducts.
  ///
  /// In ru, this message translates to:
  /// **'Нет избранных продуктов'**
  String get noFavoriteProducts;

  /// No description provided for @gramsDialogLabel.
  ///
  /// In ru, this message translates to:
  /// **'Граммы'**
  String get gramsDialogLabel;

  /// No description provided for @favoriteUpdated.
  ///
  /// In ru, this message translates to:
  /// **'Избранное обновлено'**
  String get favoriteUpdated;

  /// No description provided for @addToFavorite.
  ///
  /// In ru, this message translates to:
  /// **'В избранное'**
  String get addToFavorite;

  /// No description provided for @dayNotYet.
  ///
  /// In ru, this message translates to:
  /// **'Этот день ещё не наступил!'**
  String get dayNotYet;

  /// No description provided for @voiceUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Голосовой ввод недоступен. Проверьте разрешения микрофона.'**
  String get voiceUnavailable;

  /// No description provided for @holdToRecord.
  ///
  /// In ru, this message translates to:
  /// **'Удерживайте для записи голоса'**
  String get holdToRecord;

  /// No description provided for @copyMealTo.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать {meal} в…'**
  String copyMealTo(String meal);

  /// No description provided for @copiedRecords.
  ///
  /// In ru, this message translates to:
  /// **'Скопировано {count} записей в {date}'**
  String copiedRecords(int count, String date);

  /// No description provided for @dayMon.
  ///
  /// In ru, this message translates to:
  /// **'ПН'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In ru, this message translates to:
  /// **'ВТ'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In ru, this message translates to:
  /// **'СР'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In ru, this message translates to:
  /// **'ЧТ'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In ru, this message translates to:
  /// **'ПТ'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In ru, this message translates to:
  /// **'СБ'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In ru, this message translates to:
  /// **'ВС'**
  String get daySun;

  /// No description provided for @aiAnalyzingPhoto.
  ///
  /// In ru, this message translates to:
  /// **'Анализируем фото...'**
  String get aiAnalyzingPhoto;

  /// No description provided for @aiRecognizingIngredients.
  ///
  /// In ru, this message translates to:
  /// **'Распознаём ингредиенты...'**
  String get aiRecognizingIngredients;

  /// No description provided for @aiCountingCalories.
  ///
  /// In ru, this message translates to:
  /// **'Считаем калории...'**
  String get aiCountingCalories;

  /// No description provided for @aiDeterminingMacros.
  ///
  /// In ru, this message translates to:
  /// **'Определяем БЖУ...'**
  String get aiDeterminingMacros;

  /// No description provided for @aiAlmostDone.
  ///
  /// In ru, this message translates to:
  /// **'Почти готово...'**
  String get aiAlmostDone;

  /// No description provided for @aiAnalyzingData.
  ///
  /// In ru, this message translates to:
  /// **'Анализируем данные...'**
  String get aiAnalyzingData;

  /// No description provided for @aiRecognitionFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось распознать блюдо'**
  String get aiRecognitionFailed;

  /// No description provided for @aiRecognizingDish.
  ///
  /// In ru, this message translates to:
  /// **'Распознаём блюдо'**
  String get aiRecognizingDish;

  /// No description provided for @addDish.
  ///
  /// In ru, this message translates to:
  /// **'Добавить блюдо'**
  String get addDish;

  /// No description provided for @dishNameLabel.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get dishNameLabel;

  /// No description provided for @dishParameters.
  ///
  /// In ru, this message translates to:
  /// **'Параметры блюда'**
  String get dishParameters;

  /// No description provided for @ingredientsLabel.
  ///
  /// In ru, this message translates to:
  /// **'Ингредиенты'**
  String get ingredientsLabel;

  /// No description provided for @unknownDish.
  ///
  /// In ru, this message translates to:
  /// **'Неизвестное блюдо'**
  String get unknownDish;

  /// No description provided for @defaultDishName.
  ///
  /// In ru, this message translates to:
  /// **'Блюдо'**
  String get defaultDishName;

  /// No description provided for @saveEntry.
  ///
  /// In ru, this message translates to:
  /// **'Добавить запись'**
  String get saveEntry;

  /// No description provided for @saveChanges.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get saveChanges;

  /// No description provided for @recognizeDish.
  ///
  /// In ru, this message translates to:
  /// **'Распознать блюдо'**
  String get recognizeDish;

  /// No description provided for @cameraLabel.
  ///
  /// In ru, this message translates to:
  /// **'Камера'**
  String get cameraLabel;

  /// No description provided for @searchTitle.
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск продуктов...'**
  String get searchHint;

  /// No description provided for @nothingFound.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get nothingFound;

  /// No description provided for @recognizeViaAi.
  ///
  /// In ru, this message translates to:
  /// **'Распознать через ИИ'**
  String get recognizeViaAi;

  /// No description provided for @createProduct.
  ///
  /// In ru, this message translates to:
  /// **'Создать продукт'**
  String get createProduct;

  /// No description provided for @newProduct.
  ///
  /// In ru, this message translates to:
  /// **'Новый продукт'**
  String get newProduct;

  /// No description provided for @basicInfo.
  ///
  /// In ru, this message translates to:
  /// **'Основное'**
  String get basicInfo;

  /// No description provided for @productNameRequired.
  ///
  /// In ru, this message translates to:
  /// **'Название *'**
  String get productNameRequired;

  /// No description provided for @enterName.
  ///
  /// In ru, this message translates to:
  /// **'Введите название'**
  String get enterName;

  /// No description provided for @brandOptional.
  ///
  /// In ru, this message translates to:
  /// **'Бренд (необязательно)'**
  String get brandOptional;

  /// No description provided for @servingWeightG.
  ///
  /// In ru, this message translates to:
  /// **'Вес порции (г)'**
  String get servingWeightG;

  /// No description provided for @macrosPer100g.
  ///
  /// In ru, this message translates to:
  /// **'БЖУ на 100 г'**
  String get macrosPer100g;

  /// No description provided for @caloriesAutoCalc.
  ///
  /// In ru, this message translates to:
  /// **'Рассчитается автоматически из БЖУ'**
  String get caloriesAutoCalc;

  /// No description provided for @productAdded.
  ///
  /// In ru, this message translates to:
  /// **'Продукт добавлен'**
  String get productAdded;

  /// No description provided for @saveProduct.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить продукт'**
  String get saveProduct;

  /// No description provided for @myProductsCategory.
  ///
  /// In ru, this message translates to:
  /// **'Мои продукты'**
  String get myProductsCategory;

  /// No description provided for @newRecipe.
  ///
  /// In ru, this message translates to:
  /// **'Новый рецепт'**
  String get newRecipe;

  /// No description provided for @recipeNameRequired.
  ///
  /// In ru, this message translates to:
  /// **'Название рецепта *'**
  String get recipeNameRequired;

  /// No description provided for @servingsCount.
  ///
  /// In ru, this message translates to:
  /// **'Количество порций'**
  String get servingsCount;

  /// No description provided for @enterRecipeName.
  ///
  /// In ru, this message translates to:
  /// **'Введите название рецепта'**
  String get enterRecipeName;

  /// No description provided for @addAtLeastOneIngredient.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте хотя бы один ингредиент'**
  String get addAtLeastOneIngredient;

  /// No description provided for @recipeSaved.
  ///
  /// In ru, this message translates to:
  /// **'Рецепт сохранён'**
  String get recipeSaved;

  /// No description provided for @totalForRecipe.
  ///
  /// In ru, this message translates to:
  /// **'Итого на весь рецепт'**
  String get totalForRecipe;

  /// No description provided for @per100g.
  ///
  /// In ru, this message translates to:
  /// **'На 100 г:'**
  String get per100g;

  /// No description provided for @perServing.
  ///
  /// In ru, this message translates to:
  /// **'На порцию ({grams} г):'**
  String perServing(int grams);

  /// No description provided for @ingredientSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск ингредиента...'**
  String get ingredientSearchHint;

  /// No description provided for @startTypingName.
  ///
  /// In ru, this message translates to:
  /// **'Начните вводить название'**
  String get startTypingName;

  /// No description provided for @tapAddToSelect.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите «Добавить» чтобы\nвыбрать продукты'**
  String get tapAddToSelect;

  /// No description provided for @ingredientsCount.
  ///
  /// In ru, this message translates to:
  /// **'Ингредиенты ({count})'**
  String ingredientsCount(int count);

  /// No description provided for @weightLabel.
  ///
  /// In ru, this message translates to:
  /// **'Вес'**
  String get weightLabel;

  /// No description provided for @favoritesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get favoritesTitle;

  /// No description provided for @productAddedToMeal.
  ///
  /// In ru, this message translates to:
  /// **'{name} добавлен'**
  String productAddedToMeal(String name);

  /// No description provided for @historyTitle.
  ///
  /// In ru, this message translates to:
  /// **'История'**
  String get historyTitle;

  /// No description provided for @noRecords.
  ///
  /// In ru, this message translates to:
  /// **'Нет записей'**
  String get noRecords;

  /// No description provided for @today.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In ru, this message translates to:
  /// **'Вчера'**
  String get yesterday;

  /// No description provided for @statsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Статистика'**
  String get statsTitle;

  /// No description provided for @averageLabel.
  ///
  /// In ru, this message translates to:
  /// **'Среднее'**
  String get averageLabel;

  /// No description provided for @byDays.
  ///
  /// In ru, this message translates to:
  /// **'По дням'**
  String get byDays;

  /// No description provided for @periodWeek.
  ///
  /// In ru, this message translates to:
  /// **'Неделя'**
  String get periodWeek;

  /// No description provided for @period2Weeks.
  ///
  /// In ru, this message translates to:
  /// **'2 недели'**
  String get period2Weeks;

  /// No description provided for @periodMonth.
  ///
  /// In ru, this message translates to:
  /// **'Месяц'**
  String get periodMonth;

  /// No description provided for @totalGrams.
  ///
  /// In ru, this message translates to:
  /// **'Всего {count} г.'**
  String totalGrams(int count);

  /// No description provided for @noOwnProducts.
  ///
  /// In ru, this message translates to:
  /// **'Нет своих продуктов'**
  String get noOwnProducts;

  /// No description provided for @createProductWithMacros.
  ///
  /// In ru, this message translates to:
  /// **'Создайте продукт с указанием БЖУ'**
  String get createProductWithMacros;

  /// No description provided for @productLabel.
  ///
  /// In ru, this message translates to:
  /// **'Продукт'**
  String get productLabel;

  /// No description provided for @deleteConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Удалить?'**
  String get deleteConfirm;

  /// No description provided for @deleteWhat.
  ///
  /// In ru, this message translates to:
  /// **'Удалить {what}?'**
  String deleteWhat(String what);

  /// No description provided for @customizeView.
  ///
  /// In ru, this message translates to:
  /// **'Настроить вид'**
  String get customizeView;

  /// No description provided for @primaryMetric.
  ///
  /// In ru, this message translates to:
  /// **'Главная метрика'**
  String get primaryMetric;

  /// No description provided for @otherMetrics.
  ///
  /// In ru, this message translates to:
  /// **'Остальные метрики'**
  String get otherMetrics;

  /// No description provided for @showMore.
  ///
  /// In ru, this message translates to:
  /// **'Подробнее'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть'**
  String get showLess;

  /// No description provided for @networkTimeout.
  ///
  /// In ru, this message translates to:
  /// **'Сервер не отвечает. Проверьте подключение к интернету.'**
  String get networkTimeout;

  /// No description provided for @networkSslError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка SSL-соединения. Попробуйте позже.'**
  String get networkSslError;

  /// No description provided for @networkConnectionError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка соединения: {message}'**
  String networkConnectionError(String message);

  /// No description provided for @networkRetryFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось связаться с сервером.'**
  String get networkRetryFailed;

  /// No description provided for @networkHostLookup.
  ///
  /// In ru, this message translates to:
  /// **'Сервер временно недоступен. Проверьте интернет или попробуйте через минуту.'**
  String get networkHostLookup;

  /// No description provided for @networkConnectionRefused.
  ///
  /// In ru, this message translates to:
  /// **'Сервер не принимает соединения. Попробуйте позже.'**
  String get networkConnectionRefused;

  /// No description provided for @networkConnectionReset.
  ///
  /// In ru, this message translates to:
  /// **'Соединение разорвано. Попробуйте ещё раз.'**
  String get networkConnectionReset;

  /// No description provided for @networkGenericError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сети. Проверьте подключение к интернету.'**
  String get networkGenericError;

  /// No description provided for @onboardingGenderTitle.
  ///
  /// In ru, this message translates to:
  /// **'Укажите ваш пол'**
  String get onboardingGenderTitle;

  /// No description provided for @onboardingGenderHint.
  ///
  /// In ru, this message translates to:
  /// **'Нужен для точного расчёта нормы калорий'**
  String get onboardingGenderHint;

  /// No description provided for @genderMale.
  ///
  /// In ru, this message translates to:
  /// **'Мужской'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In ru, this message translates to:
  /// **'Женский'**
  String get genderFemale;

  /// No description provided for @onboardingMeasurementsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Ваши параметры'**
  String get onboardingMeasurementsTitle;

  /// No description provided for @heightLabel.
  ///
  /// In ru, this message translates to:
  /// **'Рост'**
  String get heightLabel;

  /// No description provided for @currentWeightLabel.
  ///
  /// In ru, this message translates to:
  /// **'Текущий вес'**
  String get currentWeightLabel;

  /// No description provided for @onboardingAgeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сколько вам лет?'**
  String get onboardingAgeTitle;

  /// No description provided for @onboardingGoalTitle.
  ///
  /// In ru, this message translates to:
  /// **'Какая у вас цель?'**
  String get onboardingGoalTitle;

  /// No description provided for @goalLoseWeight.
  ///
  /// In ru, this message translates to:
  /// **'Похудеть'**
  String get goalLoseWeight;

  /// No description provided for @goalMaintainWeight.
  ///
  /// In ru, this message translates to:
  /// **'Поддерживать вес'**
  String get goalMaintainWeight;

  /// No description provided for @goalGainWeight.
  ///
  /// In ru, this message translates to:
  /// **'Набрать массу'**
  String get goalGainWeight;

  /// No description provided for @onboardingActivityTitle.
  ///
  /// In ru, this message translates to:
  /// **'Насколько вы активны?'**
  String get onboardingActivityTitle;

  /// No description provided for @activitySedentary.
  ///
  /// In ru, this message translates to:
  /// **'Малоподвижный'**
  String get activitySedentary;

  /// No description provided for @activitySedentaryDesc.
  ///
  /// In ru, this message translates to:
  /// **'Сидячая работа, мало ходьбы'**
  String get activitySedentaryDesc;

  /// No description provided for @activityLight.
  ///
  /// In ru, this message translates to:
  /// **'Слегка активный'**
  String get activityLight;

  /// No description provided for @activityLightDesc.
  ///
  /// In ru, this message translates to:
  /// **'Лёгкие тренировки 1-3 раза в неделю'**
  String get activityLightDesc;

  /// No description provided for @activityModerate.
  ///
  /// In ru, this message translates to:
  /// **'Умеренно активный'**
  String get activityModerate;

  /// No description provided for @activityModerateDesc.
  ///
  /// In ru, this message translates to:
  /// **'Тренировки 3-5 раз в неделю'**
  String get activityModerateDesc;

  /// No description provided for @activityHigh.
  ///
  /// In ru, this message translates to:
  /// **'Очень активный'**
  String get activityHigh;

  /// No description provided for @activityHighDesc.
  ///
  /// In ru, this message translates to:
  /// **'Тяжёлые тренировки 6-7 раз в неделю'**
  String get activityHighDesc;

  /// No description provided for @onboardingTargetWeightTitle.
  ///
  /// In ru, this message translates to:
  /// **'Какой вес — ваша цель?'**
  String get onboardingTargetWeightTitle;

  /// No description provided for @safeWeightLossPace.
  ///
  /// In ru, this message translates to:
  /// **'Безопасный темп — 0.5 кг в неделю'**
  String get safeWeightLossPace;

  /// No description provided for @recommendedWeightGainPace.
  ///
  /// In ru, this message translates to:
  /// **'Рекомендуемый темп — 0.25 кг в неделю'**
  String get recommendedWeightGainPace;

  /// No description provided for @onboardingLoadingCalc.
  ///
  /// In ru, this message translates to:
  /// **'Рассчитываем метаболизм...'**
  String get onboardingLoadingCalc;

  /// No description provided for @onboardingLoadingNorm.
  ///
  /// In ru, this message translates to:
  /// **'Подбираем норму калорий...'**
  String get onboardingLoadingNorm;

  /// No description provided for @onboardingLoadingPlan.
  ///
  /// In ru, this message translates to:
  /// **'Создаём персональный план...'**
  String get onboardingLoadingPlan;

  /// No description provided for @onboardingResultTitle.
  ///
  /// In ru, this message translates to:
  /// **'Ваш персональный план'**
  String get onboardingResultTitle;

  /// No description provided for @kcalPerDay.
  ///
  /// In ru, this message translates to:
  /// **'ккал/день'**
  String get kcalPerDay;

  /// No description provided for @weightLossGoalText.
  ///
  /// In ru, this message translates to:
  /// **'похудения'**
  String get weightLossGoalText;

  /// No description provided for @weightGainGoalText.
  ///
  /// In ru, this message translates to:
  /// **'набора массы'**
  String get weightGainGoalText;

  /// No description provided for @achievableGoal.
  ///
  /// In ru, this message translates to:
  /// **'Достижимая цель {goalText}'**
  String achievableGoal(String goalText);

  /// No description provided for @weeksToGoal.
  ///
  /// In ru, this message translates to:
  /// **'{weeks} нед. до цели — к {date}'**
  String weeksToGoal(int weeks, String date);

  /// No description provided for @maintainWeightHint.
  ///
  /// In ru, this message translates to:
  /// **'Мы поможем вам поддерживать вес\nна уровне {weight} кг'**
  String maintainWeightHint(String weight);

  /// No description provided for @weightWithUnit.
  ///
  /// In ru, this message translates to:
  /// **'{value} кг'**
  String weightWithUnit(String value);

  /// No description provided for @onboardingNext.
  ///
  /// In ru, this message translates to:
  /// **'Далее'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In ru, this message translates to:
  /// **'Начать'**
  String get onboardingStart;

  /// No description provided for @paywallTitle.
  ///
  /// In ru, this message translates to:
  /// **'Начните свой путь\nк результату'**
  String get paywallTitle;

  /// No description provided for @paywallAiRecognition.
  ///
  /// In ru, this message translates to:
  /// **'ИИ-распознавание еды'**
  String get paywallAiRecognition;

  /// No description provided for @paywallAiRecognitionDesc.
  ///
  /// In ru, this message translates to:
  /// **'Сфотографируй блюдо и узнай калории за секунду'**
  String get paywallAiRecognitionDesc;

  /// No description provided for @paywallPersonalGoals.
  ///
  /// In ru, this message translates to:
  /// **'Персональные цели'**
  String get paywallPersonalGoals;

  /// No description provided for @paywallPersonalGoalsDesc.
  ///
  /// In ru, this message translates to:
  /// **'Норма рассчитана под ваше тело и цель'**
  String get paywallPersonalGoalsDesc;

  /// No description provided for @paywallProgressTracking.
  ///
  /// In ru, this message translates to:
  /// **'Отслеживание прогресса'**
  String get paywallProgressTracking;

  /// No description provided for @paywallProgressTrackingDesc.
  ///
  /// In ru, this message translates to:
  /// **'Наглядная статистика по дням и неделям'**
  String get paywallProgressTrackingDesc;

  /// No description provided for @paywallWeekly.
  ///
  /// In ru, this message translates to:
  /// **'Еженедельно'**
  String get paywallWeekly;

  /// No description provided for @paywallWeeklyPrice.
  ///
  /// In ru, this message translates to:
  /// **'299 ₽/неделю'**
  String get paywallWeeklyPrice;

  /// No description provided for @paywallWeeklyTrial.
  ///
  /// In ru, this message translates to:
  /// **'Первые 3 дня — бесплатно'**
  String get paywallWeeklyTrial;

  /// No description provided for @paywallPopular.
  ///
  /// In ru, this message translates to:
  /// **'Популярный'**
  String get paywallPopular;

  /// No description provided for @paywallYearly.
  ///
  /// In ru, this message translates to:
  /// **'На год'**
  String get paywallYearly;

  /// No description provided for @paywallYearlyPrice.
  ///
  /// In ru, this message translates to:
  /// **'1 990 ₽/год'**
  String get paywallYearlyPrice;

  /// No description provided for @paywallYearlySavings.
  ///
  /// In ru, this message translates to:
  /// **'≈ 5 ₽/день · Экономия 85%'**
  String get paywallYearlySavings;

  /// No description provided for @paywallRating.
  ///
  /// In ru, this message translates to:
  /// **'4.8 · Более 10 000 пользователей'**
  String get paywallRating;

  /// No description provided for @paywallToday.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get paywallToday;

  /// No description provided for @paywallFullAccess.
  ///
  /// In ru, this message translates to:
  /// **'Полный доступ'**
  String get paywallFullAccess;

  /// No description provided for @paywallDay2.
  ///
  /// In ru, this message translates to:
  /// **'День 2'**
  String get paywallDay2;

  /// No description provided for @paywallReminder.
  ///
  /// In ru, this message translates to:
  /// **'Напомним'**
  String get paywallReminder;

  /// No description provided for @paywallDay3.
  ///
  /// In ru, this message translates to:
  /// **'День 3'**
  String get paywallDay3;

  /// No description provided for @paywallDay3Price.
  ///
  /// In ru, this message translates to:
  /// **'299 ₽'**
  String get paywallDay3Price;

  /// No description provided for @paywallContinue.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get paywallContinue;

  /// No description provided for @paywallDisclaimer.
  ///
  /// In ru, this message translates to:
  /// **'Отмена в любое время. Оплата не списывается\nв течение пробного периода.'**
  String get paywallDisclaimer;

  /// No description provided for @paywallSkip.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить'**
  String get paywallSkip;

  /// No description provided for @barcodeScannerTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сканер штрих-кода'**
  String get barcodeScannerTitle;

  /// No description provided for @barcodeScanHint.
  ///
  /// In ru, this message translates to:
  /// **'Наведите камеру на штрих-код'**
  String get barcodeScanHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'pt',
    'ru',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
