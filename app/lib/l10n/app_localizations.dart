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
  /// **'год рождения'**
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

  /// No description provided for @pushNotificationsShortOn.
  ///
  /// In ru, this message translates to:
  /// **'Вкл'**
  String get pushNotificationsShortOn;

  /// No description provided for @pushNotificationsShortOff.
  ///
  /// In ru, this message translates to:
  /// **'Выкл'**
  String get pushNotificationsShortOff;

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

  /// No description provided for @deleteAccount.
  ///
  /// In ru, this message translates to:
  /// **'Удалить аккаунт'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить аккаунт?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmMessage.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт будет удалён навсегда. История питания, рецепты, продукты, избранное и настройки на этом устройстве также будут удалены. Это действие нельзя отменить.'**
  String get deleteAccountConfirmMessage;

  /// No description provided for @deleteAccountFinalConfirmTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вы точно уверены?'**
  String get deleteAccountFinalConfirmTitle;

  /// No description provided for @deleteAccountFinalConfirmMessage.
  ///
  /// In ru, this message translates to:
  /// **'Ваш аккаунт и данные будут удалены без возможности восстановления.'**
  String get deleteAccountFinalConfirmMessage;

  /// No description provided for @deleteAccountSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт удалён.'**
  String get deleteAccountSuccess;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить аккаунт. Проверьте подключение и попробуйте ещё раз.'**
  String get deleteAccountFailed;

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

  /// No description provided for @signInTitle.
  ///
  /// In ru, this message translates to:
  /// **'Войдите в аккаунт'**
  String get signInTitle;

  /// No description provided for @signInGoogle.
  ///
  /// In ru, this message translates to:
  /// **'Войти через Google'**
  String get signInGoogle;

  /// No description provided for @signInApple.
  ///
  /// In ru, this message translates to:
  /// **'Войти через Apple'**
  String get signInApple;

  /// No description provided for @signInEmail.
  ///
  /// In ru, this message translates to:
  /// **'Войти по Email'**
  String get signInEmail;

  /// No description provided for @startOverOnboarding.
  ///
  /// In ru, this message translates to:
  /// **'Начать сначала'**
  String get startOverOnboarding;

  /// No description provided for @startOverOnboardingConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Пройти онбординг сначала?'**
  String get startOverOnboardingConfirm;

  /// No description provided for @startOverOnboardingHint.
  ///
  /// In ru, this message translates to:
  /// **'Ответы в анкете сбросятся. Дневник на устройстве сохранится.'**
  String get startOverOnboardingHint;

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

  /// No description provided for @mergeLocalDataTitle.
  ///
  /// In ru, this message translates to:
  /// **'Хотите перенести последние данные в свой аккаунт?'**
  String get mergeLocalDataTitle;

  /// No description provided for @mergeLocalDataKeep.
  ///
  /// In ru, this message translates to:
  /// **'Перенести'**
  String get mergeLocalDataKeep;

  /// No description provided for @mergeLocalDataReplace.
  ///
  /// In ru, this message translates to:
  /// **'Оставить как есть'**
  String get mergeLocalDataReplace;

  /// No description provided for @loginSyncing.
  ///
  /// In ru, this message translates to:
  /// **'Синхронизация…'**
  String get loginSyncing;

  /// No description provided for @loginSyncFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось синхронизировать данные. Попробуйте позже.'**
  String get loginSyncFailed;

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

  /// No description provided for @forgotPassword.
  ///
  /// In ru, this message translates to:
  /// **'Забыли пароль?'**
  String get forgotPassword;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сброс пароля'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordHint.
  ///
  /// In ru, this message translates to:
  /// **'Введите email, указанный при регистрации. Мы отправим 6-значный код для сброса пароля.'**
  String get resetPasswordHint;

  /// No description provided for @sendResetCode.
  ///
  /// In ru, this message translates to:
  /// **'Отправить код'**
  String get sendResetCode;

  /// No description provided for @enterCodeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Введите код'**
  String get enterCodeTitle;

  /// No description provided for @resetCodeSentTo.
  ///
  /// In ru, this message translates to:
  /// **'Мы отправили 6-значный код на {email}'**
  String resetCodeSentTo(String email);

  /// No description provided for @enterSixDigitCode.
  ///
  /// In ru, this message translates to:
  /// **'Введите 6-значный код'**
  String get enterSixDigitCode;

  /// No description provided for @verifyCode.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get verifyCode;

  /// No description provided for @resendCode.
  ///
  /// In ru, this message translates to:
  /// **'Отправить код повторно'**
  String get resendCode;

  /// No description provided for @resendCodeIn.
  ///
  /// In ru, this message translates to:
  /// **'Повторно через {seconds} с'**
  String resendCodeIn(int seconds);

  /// No description provided for @resetCodeResent.
  ///
  /// In ru, this message translates to:
  /// **'Код отправлен повторно'**
  String get resetCodeResent;

  /// No description provided for @newPasswordTitle.
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль'**
  String get newPasswordTitle;

  /// No description provided for @newPasswordHint.
  ///
  /// In ru, this message translates to:
  /// **'Придумайте новый пароль для вашего аккаунта.'**
  String get newPasswordHint;

  /// No description provided for @newPasswordLabel.
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль'**
  String get newPasswordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите пароль'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In ru, this message translates to:
  /// **'Пароли не совпадают'**
  String get passwordsDoNotMatch;

  /// No description provided for @resetPasswordButton.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить пароль'**
  String get resetPasswordButton;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Пароль успешно сброшен. Войдите с новым паролем.'**
  String get passwordResetSuccess;

  /// No description provided for @emailNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт с таким email не найден'**
  String get emailNotFound;

  /// No description provided for @invalidResetCode.
  ///
  /// In ru, this message translates to:
  /// **'Неверный или просроченный код'**
  String get invalidResetCode;

  /// No description provided for @proTitle.
  ///
  /// In ru, this message translates to:
  /// **'Body Meal Pro'**
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

  /// No description provided for @planYearly.
  ///
  /// In ru, this message translates to:
  /// **'Годовой'**
  String get planYearly;

  /// No description provided for @planLifetime.
  ///
  /// In ru, this message translates to:
  /// **'Бессрочный'**
  String get planLifetime;

  /// No description provided for @planPromo.
  ///
  /// In ru, this message translates to:
  /// **'Промо'**
  String get planPromo;

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

  /// No description provided for @diaryViewLabel.
  ///
  /// In ru, this message translates to:
  /// **'Вид'**
  String get diaryViewLabel;

  /// No description provided for @diaryViewCompact.
  ///
  /// In ru, this message translates to:
  /// **'компактный'**
  String get diaryViewCompact;

  /// No description provided for @diaryViewExpanded.
  ///
  /// In ru, this message translates to:
  /// **'расширенный'**
  String get diaryViewExpanded;

  /// No description provided for @recordsSortNewestFirst.
  ///
  /// In ru, this message translates to:
  /// **'Сначала новые'**
  String get recordsSortNewestFirst;

  /// No description provided for @recordsSortOldestFirst.
  ///
  /// In ru, this message translates to:
  /// **'Сначала старые'**
  String get recordsSortOldestFirst;

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
  /// **'Недавние'**
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

  /// No description provided for @addMenuRecentEntries.
  ///
  /// In ru, this message translates to:
  /// **'Рекомендуемые'**
  String get addMenuRecentEntries;

  /// No description provided for @scanBarcodeAction.
  ///
  /// In ru, this message translates to:
  /// **'Сканировать штрихкод'**
  String get scanBarcodeAction;

  /// No description provided for @attachPhotoAction.
  ///
  /// In ru, this message translates to:
  /// **'Прикрепить фото'**
  String get attachPhotoAction;

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

  /// No description provided for @logEntry.
  ///
  /// In ru, this message translates to:
  /// **'Записать'**
  String get logEntry;

  /// No description provided for @saveMacros.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить макросы'**
  String get saveMacros;

  /// No description provided for @macrosSavedToast.
  ///
  /// In ru, this message translates to:
  /// **'Макросы сохранены'**
  String get macrosSavedToast;

  /// No description provided for @updateDish.
  ///
  /// In ru, this message translates to:
  /// **'Обновить блюдо'**
  String get updateDish;

  /// No description provided for @refineDish.
  ///
  /// In ru, this message translates to:
  /// **'Уточнить блюдо'**
  String get refineDish;

  /// No description provided for @refineDishHint.
  ///
  /// In ru, this message translates to:
  /// **'Уточнить блюдо ...'**
  String get refineDishHint;

  /// No description provided for @activityWalking.
  ///
  /// In ru, this message translates to:
  /// **'Ходьба'**
  String get activityWalking;

  /// No description provided for @activityBicycle.
  ///
  /// In ru, this message translates to:
  /// **'Велосипед'**
  String get activityBicycle;

  /// No description provided for @activityResting.
  ///
  /// In ru, this message translates to:
  /// **'Покой'**
  String get activityResting;

  /// No description provided for @approxHours.
  ///
  /// In ru, this message translates to:
  /// **'~ {count} ч'**
  String approxHours(int count);

  /// No description provided for @approxMinutes.
  ///
  /// In ru, this message translates to:
  /// **'~ {count} мин'**
  String approxMinutes(int count);

  /// No description provided for @healthRatingLabel.
  ///
  /// In ru, this message translates to:
  /// **'Польза'**
  String get healthRatingLabel;

  /// No description provided for @healthRatingValue.
  ///
  /// In ru, this message translates to:
  /// **'{value} / 10'**
  String healthRatingValue(int value);

  /// No description provided for @healthDescPoor.
  ///
  /// In ru, this message translates to:
  /// **'Высокая калорийность, простые углеводы, жиры или соль — лучше как редкое удовольствие.'**
  String get healthDescPoor;

  /// No description provided for @healthDescFair.
  ///
  /// In ru, this message translates to:
  /// **'Вкусно и сытно, но, скорее всего, много калорий, простых углеводов, жиров и соли.'**
  String get healthDescFair;

  /// No description provided for @healthDescGood.
  ///
  /// In ru, this message translates to:
  /// **'Сбалансированный приём пищи с разумным соотношением макроэлементов.'**
  String get healthDescGood;

  /// No description provided for @healthDescGreat.
  ///
  /// In ru, this message translates to:
  /// **'Богато нутриентами и сбалансировано — отличный выбор.'**
  String get healthDescGreat;

  /// No description provided for @healthDescVeggie.
  ///
  /// In ru, this message translates to:
  /// **'Лёгкий и водянистый — много микронутриентов на калорию.'**
  String get healthDescVeggie;

  /// No description provided for @healthDescHighProtein.
  ///
  /// In ru, this message translates to:
  /// **'С перевесом в белок — отлично насыщает и помогает восстановлению.'**
  String get healthDescHighProtein;

  /// No description provided for @healthDescLeanProtein.
  ///
  /// In ru, this message translates to:
  /// **'Нежирный белок — хорошая основа для рациона.'**
  String get healthDescLeanProtein;

  /// No description provided for @healthDescBalanced.
  ///
  /// In ru, this message translates to:
  /// **'Сбалансированные макросы — впишется в большинство планов питания.'**
  String get healthDescBalanced;

  /// No description provided for @healthDescCarbHeavy.
  ///
  /// In ru, this message translates to:
  /// **'Много углеводов — добавь белок или овощи, чтобы насытило надолго.'**
  String get healthDescCarbHeavy;

  /// No description provided for @healthDescFatHeavy.
  ///
  /// In ru, this message translates to:
  /// **'Калорийный из-за жиров — следи за порцией.'**
  String get healthDescFatHeavy;

  /// No description provided for @healthDescSweet.
  ///
  /// In ru, this message translates to:
  /// **'Сладкий и энергоёмкий — лучше как нечастое удовольствие.'**
  String get healthDescSweet;

  /// No description provided for @healthDescUltraProcessed.
  ///
  /// In ru, this message translates to:
  /// **'Калорий много, белка мало — старайся не есть часто.'**
  String get healthDescUltraProcessed;

  /// No description provided for @healthTraitHighProtein.
  ///
  /// In ru, this message translates to:
  /// **'Заметно богат белком.'**
  String get healthTraitHighProtein;

  /// No description provided for @healthTraitLowCalDensity.
  ///
  /// In ru, this message translates to:
  /// **'Легко вписывается в дневную норму.'**
  String get healthTraitLowCalDensity;

  /// No description provided for @healthTraitHighFat.
  ///
  /// In ru, this message translates to:
  /// **'Калорийный за счёт жиров.'**
  String get healthTraitHighFat;

  /// No description provided for @healthTraitHighCarb.
  ///
  /// In ru, this message translates to:
  /// **'Основа — углеводы.'**
  String get healthTraitHighCarb;

  /// No description provided for @healthTraitBalancedMacros.
  ///
  /// In ru, this message translates to:
  /// **'Макросы распределены равномерно.'**
  String get healthTraitBalancedMacros;

  /// No description provided for @healthAdviceGreat.
  ///
  /// In ru, this message translates to:
  /// **'Подходит почти каждый день.'**
  String get healthAdviceGreat;

  /// No description provided for @healthAdviceGood.
  ///
  /// In ru, this message translates to:
  /// **'Удачный выбор для сбалансированного дня.'**
  String get healthAdviceGood;

  /// No description provided for @healthAdviceFair.
  ///
  /// In ru, this message translates to:
  /// **'Ешь умеренно.'**
  String get healthAdviceFair;

  /// No description provided for @healthAdvicePoor.
  ///
  /// In ru, this message translates to:
  /// **'Лучше как редкое удовольствие.'**
  String get healthAdvicePoor;

  /// No description provided for @ofYourDailyCalories.
  ///
  /// In ru, this message translates to:
  /// **'от дневной нормы'**
  String get ofYourDailyCalories;

  /// No description provided for @dailyCaloriesPercent.
  ///
  /// In ru, this message translates to:
  /// **'{percent}%'**
  String dailyCaloriesPercent(int percent);

  /// No description provided for @recognizeDish.
  ///
  /// In ru, this message translates to:
  /// **'Распознать блюдо'**
  String get recognizeDish;

  /// No description provided for @photoDetailsHint.
  ///
  /// In ru, this message translates to:
  /// **'Распишите подробнее, если хотите ...'**
  String get photoDetailsHint;

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

  /// No description provided for @caloriesRemaining.
  ///
  /// In ru, this message translates to:
  /// **'Осталось калорий'**
  String get caloriesRemaining;

  /// No description provided for @dailyEatenLabel.
  ///
  /// In ru, this message translates to:
  /// **'Съедено'**
  String get dailyEatenLabel;

  /// No description provided for @dailyGoalLabel.
  ///
  /// In ru, this message translates to:
  /// **'Цель'**
  String get dailyGoalLabel;

  /// No description provided for @openMore.
  ///
  /// In ru, this message translates to:
  /// **'Развернуть'**
  String get openMore;

  /// No description provided for @goToStatistics.
  ///
  /// In ru, this message translates to:
  /// **'К статистике'**
  String get goToStatistics;

  /// No description provided for @goalsParamGoal.
  ///
  /// In ru, this message translates to:
  /// **'Цель'**
  String get goalsParamGoal;

  /// No description provided for @goalsParamGender.
  ///
  /// In ru, this message translates to:
  /// **'Пол'**
  String get goalsParamGender;

  /// No description provided for @goalsParamAge.
  ///
  /// In ru, this message translates to:
  /// **'Возраст'**
  String get goalsParamAge;

  /// No description provided for @goalsParamHeight.
  ///
  /// In ru, this message translates to:
  /// **'Рост'**
  String get goalsParamHeight;

  /// No description provided for @goalsParamWeight.
  ///
  /// In ru, this message translates to:
  /// **'Вес'**
  String get goalsParamWeight;

  /// No description provided for @goalsParamTargetWeight.
  ///
  /// In ru, this message translates to:
  /// **'Целевой вес'**
  String get goalsParamTargetWeight;

  /// No description provided for @goalsParamActivity.
  ///
  /// In ru, this message translates to:
  /// **'Активность'**
  String get goalsParamActivity;

  /// No description provided for @goalsPlanNote.
  ///
  /// In ru, this message translates to:
  /// **'Рассчитано по вашему плану'**
  String get goalsPlanNote;

  /// No description provided for @goalsCustomNote.
  ///
  /// In ru, this message translates to:
  /// **'Свои значения'**
  String get goalsCustomNote;

  /// No description provided for @goalsEditManually.
  ///
  /// In ru, this message translates to:
  /// **'Изменить самостоятельно'**
  String get goalsEditManually;

  /// No description provided for @goalsUsePlan.
  ///
  /// In ru, this message translates to:
  /// **'Рассчитать по плану'**
  String get goalsUsePlan;

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

  /// No description provided for @onboardingUnitsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Единицы измерения'**
  String get onboardingUnitsTitle;

  /// No description provided for @onboardingUnitsHint.
  ///
  /// In ru, this message translates to:
  /// **'Можно изменить позже в настройках'**
  String get onboardingUnitsHint;

  /// No description provided for @unitsMetricTitle.
  ///
  /// In ru, this message translates to:
  /// **'Метрическая'**
  String get unitsMetricTitle;

  /// No description provided for @unitsMetricExamples.
  ///
  /// In ru, this message translates to:
  /// **'см, кг, мл'**
  String get unitsMetricExamples;

  /// No description provided for @unitsImperialTitle.
  ///
  /// In ru, this message translates to:
  /// **'Имперская'**
  String get unitsImperialTitle;

  /// No description provided for @unitsImperialExamples.
  ///
  /// In ru, this message translates to:
  /// **'ft, lb, fl oz'**
  String get unitsImperialExamples;

  /// No description provided for @onboardingHeightTitle.
  ///
  /// In ru, this message translates to:
  /// **'Какой у вас рост?'**
  String get onboardingHeightTitle;

  /// No description provided for @onboardingHeightHint.
  ///
  /// In ru, this message translates to:
  /// **'Нужен для расчёта базового обмена веществ'**
  String get onboardingHeightHint;

  /// No description provided for @onboardingWeightTitle.
  ///
  /// In ru, this message translates to:
  /// **'Какой у вас вес?'**
  String get onboardingWeightTitle;

  /// No description provided for @onboardingWeightHint.
  ///
  /// In ru, this message translates to:
  /// **'Отправная точка для вашего плана'**
  String get onboardingWeightHint;

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
  /// **'Когда у вас день рождения?'**
  String get onboardingAgeTitle;

  /// No description provided for @onboardingAgeHint.
  ///
  /// In ru, this message translates to:
  /// **'Возраст влияет на скорость метаболизма'**
  String get onboardingAgeHint;

  /// No description provided for @onboardingGoalTitle.
  ///
  /// In ru, this message translates to:
  /// **'Какая у вас цель?'**
  String get onboardingGoalTitle;

  /// No description provided for @onboardingGoalHint.
  ///
  /// In ru, this message translates to:
  /// **'Подберём план питания под вашу задачу'**
  String get onboardingGoalHint;

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

  /// No description provided for @onboardingActivityHint.
  ///
  /// In ru, this message translates to:
  /// **'Активность определяет суточную норму калорий'**
  String get onboardingActivityHint;

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

  /// No description provided for @onboardingTargetWeightHint.
  ///
  /// In ru, this message translates to:
  /// **'Рассчитаем сроки и темп достижения'**
  String get onboardingTargetWeightHint;

  /// No description provided for @onboardingAgeYearsUnit.
  ///
  /// In ru, this message translates to:
  /// **'лет'**
  String get onboardingAgeYearsUnit;

  /// No description provided for @onboardingLoadingCalc.
  ///
  /// In ru, this message translates to:
  /// **'Анализируем ваши ответы...'**
  String get onboardingLoadingCalc;

  /// No description provided for @onboardingLoadingNorm.
  ///
  /// In ru, this message translates to:
  /// **'Настраиваем ежедневные цели...'**
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

  /// No description provided for @resultCongratsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Поздравляем!'**
  String get resultCongratsTitle;

  /// No description provided for @resultCongratsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Ваш персональный план здоровья готов!'**
  String get resultCongratsSubtitle;

  /// No description provided for @resultCanChange.
  ///
  /// In ru, this message translates to:
  /// **'Это можно изменить в любой момент'**
  String get resultCanChange;

  /// No description provided for @resultHowToTitle.
  ///
  /// In ru, this message translates to:
  /// **'Как достигать целей'**
  String get resultHowToTitle;

  /// No description provided for @resultTip1.
  ///
  /// In ru, this message translates to:
  /// **'Ведите учёт еды — сформируйте полезную привычку!'**
  String get resultTip1;

  /// No description provided for @resultTip2.
  ///
  /// In ru, this message translates to:
  /// **'Следуйте дневной рекомендации по калориям'**
  String get resultTip2;

  /// No description provided for @resultTip3.
  ///
  /// In ru, this message translates to:
  /// **'Балансируйте углеводы, белки и жиры'**
  String get resultTip3;

  /// No description provided for @resultImprovementsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Скоро вы заметите улучшения в самочувствии'**
  String get resultImprovementsTitle;

  /// No description provided for @resultImprovementsBody.
  ///
  /// In ru, this message translates to:
  /// **'Ниже риск диабета, ниже давление, лучше уровень холестерина'**
  String get resultImprovementsBody;

  /// No description provided for @resultDisclaimer.
  ///
  /// In ru, this message translates to:
  /// **'Только оценка питания. Не медицинская рекомендация.'**
  String get resultDisclaimer;

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

  /// No description provided for @resultPlanReadyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Ваш персональный план готов'**
  String get resultPlanReadyTitle;

  /// No description provided for @resultHeroSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'На основе ваших ответов'**
  String get resultHeroSubtitle;

  /// No description provided for @resultRingAdjustLine.
  ///
  /// In ru, this message translates to:
  /// **'Цифры можно скорректировать в любой момент'**
  String get resultRingAdjustLine;

  /// No description provided for @resultGoalCardTitle.
  ///
  /// In ru, this message translates to:
  /// **'Ваша цель'**
  String get resultGoalCardTitle;

  /// No description provided for @resultGoalMaintainTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удерживать вес около {weight}'**
  String resultGoalMaintainTitle(String weight);

  /// No description provided for @resultGoalMaintainSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Без жёстких ограничений — баланс на каждый день'**
  String get resultGoalMaintainSubtitle;

  /// No description provided for @resultBridgeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Чтобы план работал — его нужно вести каждый день'**
  String get resultBridgeTitle;

  /// No description provided for @resultBridgeFreeLine.
  ///
  /// In ru, this message translates to:
  /// **'Бесплатно — 3 записи еды, чтобы попробовать'**
  String get resultBridgeFreeLine;

  /// No description provided for @resultBridgePremiumLine.
  ///
  /// In ru, this message translates to:
  /// **'С Premium — без лимита, до самой цели'**
  String get resultBridgePremiumLine;

  /// No description provided for @resultDisclaimerShort.
  ///
  /// In ru, this message translates to:
  /// **'Не заменяет консультацию врача.'**
  String get resultDisclaimerShort;

  /// No description provided for @resultDisclaimerExpand.
  ///
  /// In ru, this message translates to:
  /// **'Подробнее'**
  String get resultDisclaimerExpand;

  /// No description provided for @resultSourcesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Источники'**
  String get resultSourcesTitle;

  /// No description provided for @resultSourceCaloriesLabel.
  ///
  /// In ru, this message translates to:
  /// **'Норма калорий'**
  String get resultSourceCaloriesLabel;

  /// No description provided for @resultSourceMacrosLabel.
  ///
  /// In ru, this message translates to:
  /// **'Распределение БЖУ'**
  String get resultSourceMacrosLabel;

  /// No description provided for @resultSourcesCta.
  ///
  /// In ru, this message translates to:
  /// **'Источники и методика'**
  String get resultSourcesCta;

  /// No description provided for @profileMethodology.
  ///
  /// In ru, this message translates to:
  /// **'Источники и методика питания'**
  String get profileMethodology;

  /// No description provided for @profileMethodologyIntro.
  ///
  /// In ru, this message translates to:
  /// **'Как рассчитываются ваши дневные цели'**
  String get profileMethodologyIntro;

  /// No description provided for @methodologyCaloriesSection.
  ///
  /// In ru, this message translates to:
  /// **'Норма калорий'**
  String get methodologyCaloriesSection;

  /// No description provided for @methodologyMacrosSection.
  ///
  /// In ru, this message translates to:
  /// **'Цели по БЖУ'**
  String get methodologyMacrosSection;

  /// No description provided for @methodologyGeneralSection.
  ///
  /// In ru, this message translates to:
  /// **'Общие рекомендации по питанию'**
  String get methodologyGeneralSection;

  /// No description provided for @methodologySourceMifflinDescription.
  ///
  /// In ru, this message translates to:
  /// **'Формула BMR для оценки калорий.'**
  String get methodologySourceMifflinDescription;

  /// No description provided for @methodologySourceDriDescription.
  ///
  /// In ru, this message translates to:
  /// **'Диапазоны для белков, жиров и углеводов.'**
  String get methodologySourceDriDescription;

  /// No description provided for @methodologySourceUsdaDescription.
  ///
  /// In ru, this message translates to:
  /// **'DRI-референсы по калориям и нутриентам.'**
  String get methodologySourceUsdaDescription;

  /// No description provided for @methodologySourceWhoDescription.
  ///
  /// In ru, this message translates to:
  /// **'Общие рекомендации по здоровому питанию.'**
  String get methodologySourceWhoDescription;

  /// No description provided for @methodologyOpenSourceFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть источник.'**
  String get methodologyOpenSourceFailed;

  /// No description provided for @resultOpenPlan.
  ///
  /// In ru, this message translates to:
  /// **'Открыть мой план'**
  String get resultOpenPlan;

  /// No description provided for @socialProofScaleTitle.
  ///
  /// In ru, this message translates to:
  /// **'Создано для серьёзного учёта'**
  String get socialProofScaleTitle;

  /// No description provided for @socialProofScaleSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Технология, на которой строится ваш план'**
  String get socialProofScaleSubtitle;

  /// No description provided for @socialProofScaleProductsLabel.
  ///
  /// In ru, this message translates to:
  /// **'продуктов в нашей базе'**
  String get socialProofScaleProductsLabel;

  /// No description provided for @socialProofScaleSecondsUnit.
  ///
  /// In ru, this message translates to:
  /// **'сек'**
  String get socialProofScaleSecondsUnit;

  /// No description provided for @socialProofScaleSpeedLabel.
  ///
  /// In ru, this message translates to:
  /// **'Распознавание блюд по фото'**
  String get socialProofScaleSpeedLabel;

  /// No description provided for @socialProofPoweredBy.
  ///
  /// In ru, this message translates to:
  /// **'Работает на'**
  String get socialProofPoweredBy;

  /// No description provided for @socialProofAccuracyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Проверено на точность'**
  String get socialProofAccuracyTitle;

  /// No description provided for @socialProofAccuracySubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Насколько точно AI определяет ваши блюда'**
  String get socialProofAccuracySubtitle;

  /// No description provided for @socialProofAccuracyLabel.
  ///
  /// In ru, this message translates to:
  /// **'Точность AI'**
  String get socialProofAccuracyLabel;

  /// No description provided for @socialProofAccuracyDisclaimer.
  ///
  /// In ru, this message translates to:
  /// **'На основе внутреннего контроля качества на 500+ блюдах из разных кухонь мира.'**
  String get socialProofAccuracyDisclaimer;

  /// No description provided for @socialProofScienceTitle.
  ///
  /// In ru, this message translates to:
  /// **'В основе — нутрициология'**
  String get socialProofScienceTitle;

  /// No description provided for @socialProofScienceSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Ваш план рассчитан по проверенной формуле'**
  String get socialProofScienceSubtitle;

  /// No description provided for @socialProofScienceFormulaCaption.
  ///
  /// In ru, this message translates to:
  /// **'Золотой стандарт нутрициологии с 1990 года'**
  String get socialProofScienceFormulaCaption;

  /// No description provided for @socialProofScienceTrust.
  ///
  /// In ru, this message translates to:
  /// **'Используется дипломированными диетологами и клиническими нутрициологами по всему миру.'**
  String get socialProofScienceTrust;

  /// No description provided for @paywallTitle.
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте Pro\nбесплатно'**
  String get paywallTitle;

  /// No description provided for @paywallWeeklyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Откройте Pro\nсегодня'**
  String get paywallWeeklyTitle;

  /// No description provided for @paywallWeeklyTimelineTodayTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня — откройте Pro'**
  String get paywallWeeklyTimelineTodayTitle;

  /// No description provided for @paywallWeeklyTimelineTodayDesc.
  ///
  /// In ru, this message translates to:
  /// **'AI-сканирование, дневник питания и аналитика без ограничений.'**
  String get paywallWeeklyTimelineTodayDesc;

  /// No description provided for @paywallWeeklyTimelineRenewTitle.
  ///
  /// In ru, this message translates to:
  /// **'Еженедельно — прогресс'**
  String get paywallWeeklyTimelineRenewTitle;

  /// No description provided for @paywallWeeklyTimelineRenewDesc.
  ///
  /// In ru, this message translates to:
  /// **'План продлевается еженедельно, чтобы доступ не прерывался.'**
  String get paywallWeeklyTimelineRenewDesc;

  /// No description provided for @paywallWeeklyTimelineCancelTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отмена в любой момент'**
  String get paywallWeeklyTimelineCancelTitle;

  /// No description provided for @paywallWeeklyTimelineCancelDesc.
  ///
  /// In ru, this message translates to:
  /// **'Отменяйте подписку в настройках аккаунта магазина.'**
  String get paywallWeeklyTimelineCancelDesc;

  /// No description provided for @paywallTimelineTodayTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня — откройте Pro'**
  String get paywallTimelineTodayTitle;

  /// No description provided for @paywallTimelineTodayDesc.
  ///
  /// In ru, this message translates to:
  /// **'AI-сканирование, дневник питания и аналитика без ограничений.'**
  String get paywallTimelineTodayDesc;

  /// No description provided for @paywallTimelineReminderTitle.
  ///
  /// In ru, this message translates to:
  /// **'Через 2 дня — напомним'**
  String get paywallTimelineReminderTitle;

  /// No description provided for @paywallTimelineReminderDesc.
  ///
  /// In ru, this message translates to:
  /// **'Мы напомним, что пробный период скоро закончится'**
  String get paywallTimelineReminderDesc;

  /// No description provided for @paywallTimelinePayTitle.
  ///
  /// In ru, this message translates to:
  /// **'Через 3 дня — оплата'**
  String get paywallTimelinePayTitle;

  /// No description provided for @paywallTimelinePayDesc.
  ///
  /// In ru, this message translates to:
  /// **'Списание будет {date}, если вы не отмените подписку'**
  String paywallTimelinePayDesc(String date);

  /// No description provided for @paywallMonthly.
  ///
  /// In ru, this message translates to:
  /// **'Еженедельно'**
  String get paywallMonthly;

  /// No description provided for @paywallMonthlyPrice.
  ///
  /// In ru, this message translates to:
  /// **'\$4.99 / нед'**
  String get paywallMonthlyPrice;

  /// No description provided for @paywallYearly.
  ///
  /// In ru, this message translates to:
  /// **'Ежегодно'**
  String get paywallYearly;

  /// No description provided for @paywallYearlyPrice.
  ///
  /// In ru, this message translates to:
  /// **'\$39.99 / год'**
  String get paywallYearlyPrice;

  /// No description provided for @paywallPerWeek.
  ///
  /// In ru, this message translates to:
  /// **'нед'**
  String get paywallPerWeek;

  /// No description provided for @paywallPerYear.
  ///
  /// In ru, this message translates to:
  /// **'год'**
  String get paywallPerYear;

  /// No description provided for @paywallTrialBadge.
  ///
  /// In ru, this message translates to:
  /// **'3 дня бесплатно'**
  String get paywallTrialBadge;

  /// No description provided for @paywallYearlyDiscount.
  ///
  /// In ru, this message translates to:
  /// **'-85%'**
  String get paywallYearlyDiscount;

  /// No description provided for @paywallSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Максимум возможностей и эксклюзивные функции с подпиской BodyMeal Pro'**
  String get paywallSubtitle;

  /// No description provided for @paywallFeatureAiTitle.
  ///
  /// In ru, this message translates to:
  /// **'ИИ-распознование'**
  String get paywallFeatureAiTitle;

  /// No description provided for @paywallFeatureAiDesc.
  ///
  /// In ru, this message translates to:
  /// **'Сфотографируй — ИИ определит калории и нутриенты за секунду.'**
  String get paywallFeatureAiDesc;

  /// No description provided for @paywallFeatureDiaryTitle.
  ///
  /// In ru, this message translates to:
  /// **'Дневник питания'**
  String get paywallFeatureDiaryTitle;

  /// No description provided for @paywallFeatureDiaryDesc.
  ///
  /// In ru, this message translates to:
  /// **'Записывайте все приёмы пищи без ограничений, каждый день.'**
  String get paywallFeatureDiaryDesc;

  /// No description provided for @paywallFeatureAnalyticsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Детальная аналитика'**
  String get paywallFeatureAnalyticsTitle;

  /// No description provided for @paywallFeatureAnalyticsDesc.
  ///
  /// In ru, this message translates to:
  /// **'Графики калорий, БЖУ и прогресс по вашим целям за любой период.'**
  String get paywallFeatureAnalyticsDesc;

  /// No description provided for @paywallFeatureBarcodeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сканер штрихкодов'**
  String get paywallFeatureBarcodeTitle;

  /// No description provided for @paywallFeatureBarcodeDesc.
  ///
  /// In ru, this message translates to:
  /// **'Наведите камеру на упаковку — данные подтянутся сами.'**
  String get paywallFeatureBarcodeDesc;

  /// No description provided for @paywallNoPaymentNow.
  ///
  /// In ru, this message translates to:
  /// **'Платёж сейчас не требуется'**
  String get paywallNoPaymentNow;

  /// No description provided for @paywallStartTrial.
  ///
  /// In ru, this message translates to:
  /// **'Начать пробный период'**
  String get paywallStartTrial;

  /// No description provided for @paywallTrialDisclaimer.
  ///
  /// In ru, this message translates to:
  /// **'3 дня бесплатно, затем \$39.99/год'**
  String get paywallTrialDisclaimer;

  /// No description provided for @paywallWeeklyDisclaimer.
  ///
  /// In ru, this message translates to:
  /// **'Списание сегодня. Отмена в любой момент.'**
  String get paywallWeeklyDisclaimer;

  /// No description provided for @paywallTrialDisclaimerFmt.
  ///
  /// In ru, this message translates to:
  /// **'3 дня бесплатно, затем {price}/год'**
  String paywallTrialDisclaimerFmt(String price);

  /// No description provided for @paywallRestore.
  ///
  /// In ru, this message translates to:
  /// **'Восстановить'**
  String get paywallRestore;

  /// No description provided for @paywallTerms.
  ///
  /// In ru, this message translates to:
  /// **'Условия'**
  String get paywallTerms;

  /// No description provided for @paywallPrivacy.
  ///
  /// In ru, this message translates to:
  /// **'Конфиденциальность'**
  String get paywallPrivacy;

  /// No description provided for @paywallHaveCode.
  ///
  /// In ru, this message translates to:
  /// **'Есть код?'**
  String get paywallHaveCode;

  /// No description provided for @promoCodeApply.
  ///
  /// In ru, this message translates to:
  /// **'Применить'**
  String get promoCodeApply;

  /// No description provided for @promoCodeInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Неверный код'**
  String get promoCodeInvalid;

  /// No description provided for @paywallSkip.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить'**
  String get paywallSkip;

  /// No description provided for @paywallRestoreSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Подписка восстановлена'**
  String get paywallRestoreSuccess;

  /// No description provided for @paywallRestoreNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Активных подписок не найдено'**
  String get paywallRestoreNotFound;

  /// No description provided for @paywallSubscriptionError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить подписки. Попробуйте позже.'**
  String get paywallSubscriptionError;

  /// No description provided for @paywallLoadingPrice.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка…'**
  String get paywallLoadingPrice;

  /// No description provided for @paywallErrorTitle.
  ///
  /// In ru, this message translates to:
  /// **'Подписка недоступна'**
  String get paywallErrorTitle;

  /// No description provided for @paywallTryAgain.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get paywallTryAgain;

  /// No description provided for @paywallErrorStoreUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'App Store сейчас недоступен. Убедитесь, что вы вошли в App Store, и попробуйте ещё раз.'**
  String get paywallErrorStoreUnavailable;

  /// No description provided for @paywallErrorProductsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить варианты подписки. Проверьте соединение и попробуйте ещё раз.'**
  String get paywallErrorProductsEmpty;

  /// No description provided for @paywallErrorSelectedProductUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Этот вариант подписки сейчас недоступен. Выберите другой тариф или попробуйте ещё раз.'**
  String get paywallErrorSelectedProductUnavailable;

  /// No description provided for @paywallErrorQueryFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удаётся связаться с App Store. Попробуйте через минуту.'**
  String get paywallErrorQueryFailed;

  /// No description provided for @paywallErrorPurchaseFailed.
  ///
  /// In ru, this message translates to:
  /// **'Покупку не удалось завершить. Попробуйте ещё раз.'**
  String get paywallErrorPurchaseFailed;

  /// No description provided for @paywallErrorRestoreFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось восстановить покупки. Попробуйте ещё раз.'**
  String get paywallErrorRestoreFailed;

  /// No description provided for @paywallErrorPaymentPending.
  ///
  /// In ru, this message translates to:
  /// **'Оплата обрабатывается. Мы откроем Pro сразу после подтверждения.'**
  String get paywallErrorPaymentPending;

  /// No description provided for @restartOnboarding.
  ///
  /// In ru, this message translates to:
  /// **'Начать заново'**
  String get restartOnboarding;

  /// No description provided for @proActive.
  ///
  /// In ru, this message translates to:
  /// **'Активна'**
  String get proActive;

  /// No description provided for @signInToSaveData.
  ///
  /// In ru, this message translates to:
  /// **'Войдите для сохранения данных'**
  String get signInToSaveData;

  /// No description provided for @dataStoredLocally.
  ///
  /// In ru, this message translates to:
  /// **'Ваши данные хранятся только на этом устройстве'**
  String get dataStoredLocally;

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

  /// No description provided for @paywallSubscribeNow.
  ///
  /// In ru, this message translates to:
  /// **'Оформить подписку'**
  String get paywallSubscribeNow;

  /// No description provided for @paywallGo.
  ///
  /// In ru, this message translates to:
  /// **'Начать'**
  String get paywallGo;

  /// No description provided for @paywallHardDisclaimer.
  ///
  /// In ru, this message translates to:
  /// **'Автопродление. Отмена в любой момент.'**
  String get paywallHardDisclaimer;

  /// No description provided for @paywallHardTitle.
  ///
  /// In ru, this message translates to:
  /// **'Продолжайте\nс Pro'**
  String get paywallHardTitle;

  /// No description provided for @freeEntriesRemaining.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, =1{Осталась 1 бесплатная запись} few{Осталось {count} бесплатные записи} many{Осталось {count} бесплатных записей} other{Осталось {count} бесплатных записей}}'**
  String freeEntriesRemaining(int count);

  /// No description provided for @getPro.
  ///
  /// In ru, this message translates to:
  /// **'Получить Pro'**
  String get getPro;

  /// No description provided for @freeLimitReached.
  ///
  /// In ru, this message translates to:
  /// **'Бесплатные записи закончились'**
  String get freeLimitReached;

  /// No description provided for @analyticsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Аналитика'**
  String get analyticsTitle;

  /// No description provided for @summarySection.
  ///
  /// In ru, this message translates to:
  /// **'Сводка'**
  String get summarySection;

  /// No description provided for @trendsSection.
  ///
  /// In ru, this message translates to:
  /// **'Тренды'**
  String get trendsSection;

  /// No description provided for @highlightsSection.
  ///
  /// In ru, this message translates to:
  /// **'Главное'**
  String get highlightsSection;

  /// No description provided for @dayStreak.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, =0{Дней подряд} =1{День подряд} few{Дня подряд} many{Дней подряд} other{Дней подряд}}'**
  String dayStreak(int count);

  /// No description provided for @averageADay.
  ///
  /// In ru, this message translates to:
  /// **'в среднем за день'**
  String get averageADay;

  /// No description provided for @calDifferenceCount.
  ///
  /// In ru, this message translates to:
  /// **'Разница {count} ккал'**
  String calDifferenceCount(int count);

  /// No description provided for @percentAverage.
  ///
  /// In ru, this message translates to:
  /// **'{count}/100% среднего'**
  String percentAverage(int count);

  /// No description provided for @analyticsHighlightHigher.
  ///
  /// In ru, this message translates to:
  /// **'Среднее потребление {metric} за день на этой неделе выше, чем на прошлой.'**
  String analyticsHighlightHigher(String metric);

  /// No description provided for @analyticsHighlightLower.
  ///
  /// In ru, this message translates to:
  /// **'Среднее потребление {metric} за день на этой неделе ниже, чем на прошлой.'**
  String analyticsHighlightLower(String metric);

  /// No description provided for @analyticsHighlightSimilar.
  ///
  /// In ru, this message translates to:
  /// **'Среднее потребление {metric} за день примерно такое же, как на прошлой неделе.'**
  String analyticsHighlightSimilar(String metric);

  /// No description provided for @analyticsPeriod1W.
  ///
  /// In ru, this message translates to:
  /// **'1 Н'**
  String get analyticsPeriod1W;

  /// No description provided for @analyticsPeriod2W.
  ///
  /// In ru, this message translates to:
  /// **'2 Н'**
  String get analyticsPeriod2W;

  /// No description provided for @analyticsPeriod1M.
  ///
  /// In ru, this message translates to:
  /// **'1 М'**
  String get analyticsPeriod1M;

  /// No description provided for @analyticsPeriod3M.
  ///
  /// In ru, this message translates to:
  /// **'3 М'**
  String get analyticsPeriod3M;

  /// No description provided for @analyticsPeriod6M.
  ///
  /// In ru, this message translates to:
  /// **'6 М'**
  String get analyticsPeriod6M;

  /// No description provided for @analyticsPeriod1Y.
  ///
  /// In ru, this message translates to:
  /// **'1 Г'**
  String get analyticsPeriod1Y;

  /// No description provided for @analyticsMetricCal.
  ///
  /// In ru, this message translates to:
  /// **'Ккал'**
  String get analyticsMetricCal;

  /// No description provided for @analyticsMetricProtein.
  ///
  /// In ru, this message translates to:
  /// **'Белки'**
  String get analyticsMetricProtein;

  /// No description provided for @analyticsMetricFat.
  ///
  /// In ru, this message translates to:
  /// **'Жиры'**
  String get analyticsMetricFat;

  /// No description provided for @analyticsMetricCarbs.
  ///
  /// In ru, this message translates to:
  /// **'Углев'**
  String get analyticsMetricCarbs;

  /// No description provided for @quantityLabel.
  ///
  /// In ru, this message translates to:
  /// **'Количество'**
  String get quantityLabel;

  /// No description provided for @addSuggestionsLabel.
  ///
  /// In ru, this message translates to:
  /// **'Добавить ингредиент'**
  String get addSuggestionsLabel;

  /// No description provided for @suggestionSomethingElse.
  ///
  /// In ru, this message translates to:
  /// **'Другое'**
  String get suggestionSomethingElse;

  /// No description provided for @untitledIngredientName.
  ///
  /// In ru, this message translates to:
  /// **'Без названия'**
  String get untitledIngredientName;

  /// No description provided for @onbObstaclesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Что мешало вам раньше?'**
  String get onbObstaclesTitle;

  /// No description provided for @onbObstaclesHint.
  ///
  /// In ru, this message translates to:
  /// **'Выберите всё, что относится к вам'**
  String get onbObstaclesHint;

  /// No description provided for @obstacleConsistency.
  ///
  /// In ru, this message translates to:
  /// **'Не получается быть последовательным'**
  String get obstacleConsistency;

  /// No description provided for @obstacleKnowledge.
  ///
  /// In ru, this message translates to:
  /// **'Не знаю, что есть'**
  String get obstacleKnowledge;

  /// No description provided for @obstacleBusy.
  ///
  /// In ru, this message translates to:
  /// **'Загруженный график'**
  String get obstacleBusy;

  /// No description provided for @obstacleCravings.
  ///
  /// In ru, this message translates to:
  /// **'Сильная тяга к сладкому/мучному'**
  String get obstacleCravings;

  /// No description provided for @obstacleSupport.
  ///
  /// In ru, this message translates to:
  /// **'Нет поддержки'**
  String get obstacleSupport;

  /// No description provided for @obstacleEatingOut.
  ///
  /// In ru, this message translates to:
  /// **'Часто ем вне дома'**
  String get obstacleEatingOut;

  /// No description provided for @obstacleMotivation.
  ///
  /// In ru, this message translates to:
  /// **'Не хватает мотивации'**
  String get obstacleMotivation;

  /// No description provided for @obstacleTracking.
  ///
  /// In ru, this message translates to:
  /// **'Сложно считать калории'**
  String get obstacleTracking;

  /// No description provided for @onbSpeedTitleLose.
  ///
  /// In ru, this message translates to:
  /// **'Как быстро хотите похудеть?'**
  String get onbSpeedTitleLose;

  /// No description provided for @onbSpeedTitleGain.
  ///
  /// In ru, this message translates to:
  /// **'Как быстро хотите набрать массу?'**
  String get onbSpeedTitleGain;

  /// No description provided for @onbSpeedHintKg.
  ///
  /// In ru, this message translates to:
  /// **'Рекомендуемый темп — {rate} кг/неделю'**
  String onbSpeedHintKg(String rate);

  /// No description provided for @onbSpeedHintLb.
  ///
  /// In ru, this message translates to:
  /// **'Рекомендуемый темп — {rate} фнт/неделю'**
  String onbSpeedHintLb(String rate);

  /// No description provided for @onbSpeedKgPerWeek.
  ///
  /// In ru, this message translates to:
  /// **'{value} кг/неделю'**
  String onbSpeedKgPerWeek(String value);

  /// No description provided for @onbSpeedLbPerWeek.
  ///
  /// In ru, this message translates to:
  /// **'{value} фнт/неделю'**
  String onbSpeedLbPerWeek(String value);

  /// No description provided for @onbSpeedBadgeGentle.
  ///
  /// In ru, this message translates to:
  /// **'Мягкий темп ✅'**
  String get onbSpeedBadgeGentle;

  /// No description provided for @onbSpeedBadgeRecommended.
  ///
  /// In ru, this message translates to:
  /// **'Рекомендуемый темп ⭐'**
  String get onbSpeedBadgeRecommended;

  /// No description provided for @onbSpeedBadgeAmbitious.
  ///
  /// In ru, this message translates to:
  /// **'Амбициозно 🔥'**
  String get onbSpeedBadgeAmbitious;

  /// No description provided for @onbSpeedBadgeAggressive.
  ///
  /// In ru, this message translates to:
  /// **'Очень агрессивно ⚠️'**
  String get onbSpeedBadgeAggressive;

  /// No description provided for @onbSpeedTargetByPrefix.
  ///
  /// In ru, this message translates to:
  /// **'Вы достигнете {weight} к'**
  String onbSpeedTargetByPrefix(String weight);

  /// No description provided for @onbQuizTitle.
  ///
  /// In ru, this message translates to:
  /// **'Расскажите о ваших привычках'**
  String get onbQuizTitle;

  /// No description provided for @onbQuizHint.
  ///
  /// In ru, this message translates to:
  /// **'Это поможет персонализировать ваш план'**
  String get onbQuizHint;

  /// No description provided for @quizStressEatingLeft.
  ///
  /// In ru, this message translates to:
  /// **'Часто ем от стресса'**
  String get quizStressEatingLeft;

  /// No description provided for @quizStressEatingRight.
  ///
  /// In ru, this message translates to:
  /// **'Ем только для энергии'**
  String get quizStressEatingRight;

  /// No description provided for @quizSweetPreferenceLeft.
  ///
  /// In ru, this message translates to:
  /// **'Люблю сладкое'**
  String get quizSweetPreferenceLeft;

  /// No description provided for @quizSweetPreferenceRight.
  ///
  /// In ru, this message translates to:
  /// **'Предпочитаю солёное/острое'**
  String get quizSweetPreferenceRight;

  /// No description provided for @quizExerciseConsistencyLeft.
  ///
  /// In ru, this message translates to:
  /// **'Тренируюсь постоянно'**
  String get quizExerciseConsistencyLeft;

  /// No description provided for @quizExerciseConsistencyRight.
  ///
  /// In ru, this message translates to:
  /// **'Не получается заниматься регулярно'**
  String get quizExerciseConsistencyRight;

  /// No description provided for @quizMealPlanningLeft.
  ///
  /// In ru, this message translates to:
  /// **'Планирую приёмы пищи'**
  String get quizMealPlanningLeft;

  /// No description provided for @quizMealPlanningRight.
  ///
  /// In ru, this message translates to:
  /// **'Ем что под рукой'**
  String get quizMealPlanningRight;

  /// No description provided for @quizMotivationTypeLeft.
  ///
  /// In ru, this message translates to:
  /// **'Меня двигают результаты'**
  String get quizMotivationTypeLeft;

  /// No description provided for @quizMotivationTypeRight.
  ///
  /// In ru, this message translates to:
  /// **'Меня двигают ощущения'**
  String get quizMotivationTypeRight;

  /// No description provided for @onbRateTitle.
  ///
  /// In ru, this message translates to:
  /// **'Нравится ваш план?'**
  String get onbRateTitle;

  /// No description provided for @onbRateSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Оцените Body Meal — это поможет нам стать лучше'**
  String get onbRateSubtitle;

  /// No description provided for @onbRateButton.
  ///
  /// In ru, this message translates to:
  /// **'Оценить'**
  String get onbRateButton;

  /// No description provided for @onbRateSkip.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить'**
  String get onbRateSkip;

  /// No description provided for @onbRateFeedbackTitle.
  ///
  /// In ru, this message translates to:
  /// **'Что мы можем улучшить?'**
  String get onbRateFeedbackTitle;

  /// No description provided for @onbRateFeedbackHint.
  ///
  /// In ru, this message translates to:
  /// **'Расскажите, что не понравилось'**
  String get onbRateFeedbackHint;

  /// No description provided for @onbRateFeedbackSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get onbRateFeedbackSubmit;

  /// No description provided for @resultAnchorPrefix.
  ///
  /// In ru, this message translates to:
  /// **'Вы достигнете {weight} к'**
  String resultAnchorPrefix(String weight);

  /// No description provided for @resultAnchorWeeksSuffix.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, =1{(через 1 неделю)} few{(через {count} недели)} many{(через {count} недель)} other{(через {count} недель)}}'**
  String resultAnchorWeeksSuffix(int count);

  /// No description provided for @resultMaintainCard.
  ///
  /// In ru, this message translates to:
  /// **'Мы поможем удержать вес на {weight}'**
  String resultMaintainCard(String weight);

  /// No description provided for @resultDailyNormLabel.
  ///
  /// In ru, this message translates to:
  /// **'ВАША ДНЕВНАЯ НОРМА'**
  String get resultDailyNormLabel;

  /// No description provided for @resultPsychotypeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Ваш тип питания: {title}'**
  String resultPsychotypeLabel(String title);

  /// No description provided for @resultObstaclesHeader.
  ///
  /// In ru, this message translates to:
  /// **'Ваш план учитывает:'**
  String get resultObstaclesHeader;

  /// No description provided for @resultMilestonesHeader.
  ///
  /// In ru, this message translates to:
  /// **'Ваш прогресс по неделям:'**
  String get resultMilestonesHeader;

  /// No description provided for @resultGoalRow.
  ///
  /// In ru, this message translates to:
  /// **'Цель'**
  String get resultGoalRow;

  /// No description provided for @resultWeekRow.
  ///
  /// In ru, this message translates to:
  /// **'Неделя {week}'**
  String resultWeekRow(int week);

  /// No description provided for @resultGoalReachLine.
  ///
  /// In ru, this message translates to:
  /// **'Вы достигнете {weight}'**
  String resultGoalReachLine(String weight);

  /// No description provided for @resultGoalByDateLine.
  ///
  /// In ru, this message translates to:
  /// **'к {date}'**
  String resultGoalByDateLine(String date);

  /// No description provided for @resultGoalInWeeks.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, =1{через 1 неделю} few{через {count} недели} many{через {count} недель} other{через {count} недель}}'**
  String resultGoalInWeeks(int count);

  /// No description provided for @resultBenefit5MinDay.
  ///
  /// In ru, this message translates to:
  /// **'Занимает 5 минут в день'**
  String get resultBenefit5MinDay;

  /// No description provided for @resultBenefitSmartTracking.
  ///
  /// In ru, this message translates to:
  /// **'Умный трекинг без усилий'**
  String get resultBenefitSmartTracking;

  /// No description provided for @resultBenefitTailored.
  ///
  /// In ru, this message translates to:
  /// **'Меню под ваш образ жизни'**
  String get resultBenefitTailored;

  /// No description provided for @resultBenefitSustainable.
  ///
  /// In ru, this message translates to:
  /// **'Устойчивый результат, а не диета'**
  String get resultBenefitSustainable;

  /// No description provided for @resultFaqHeader.
  ///
  /// In ru, this message translates to:
  /// **'FAQ'**
  String get resultFaqHeader;

  /// No description provided for @resultFaqCancelQ.
  ///
  /// In ru, this message translates to:
  /// **'Как отменить подписку?'**
  String get resultFaqCancelQ;

  /// No description provided for @resultFaqCancelAIos.
  ///
  /// In ru, this message translates to:
  /// **'Откройте Настройки → ваше имя → Подписки на iPhone, найдите Body Meal и нажмите «Отменить подписку».'**
  String get resultFaqCancelAIos;

  /// No description provided for @resultFaqCancelAAndroid.
  ///
  /// In ru, this message translates to:
  /// **'Откройте Google Play → профиль → Платежи и подписки → Подписки, найдите Body Meal и нажмите «Отменить».'**
  String get resultFaqCancelAAndroid;

  /// No description provided for @resultFaqSecurityQ.
  ///
  /// In ru, this message translates to:
  /// **'Безопасны ли мои данные?'**
  String get resultFaqSecurityQ;

  /// No description provided for @resultFaqSecurityA.
  ///
  /// In ru, this message translates to:
  /// **'Данные шифруются при передаче и хранении. Мы не передаём их рекламодателям, а аккаунт можно удалить в настройках в любой момент.'**
  String get resultFaqSecurityA;

  /// No description provided for @resultFaqTrialQ.
  ///
  /// In ru, this message translates to:
  /// **'Есть ли бесплатный пробный период?'**
  String get resultFaqTrialQ;

  /// No description provided for @resultFaqTrialA.
  ///
  /// In ru, this message translates to:
  /// **'Да — пробный период доступен в годовом тарифе. Деньги не списываются до его окончания, отменить можно в любой момент до этого.'**
  String get resultFaqTrialA;

  /// No description provided for @loadingMetabolism.
  ///
  /// In ru, this message translates to:
  /// **'Анализируем ваш метаболизм...'**
  String get loadingMetabolism;

  /// No description provided for @loadingCalories.
  ///
  /// In ru, this message translates to:
  /// **'Рассчитываем дневную норму калорий...'**
  String get loadingCalories;

  /// No description provided for @loadingMacros.
  ///
  /// In ru, this message translates to:
  /// **'Подбираем баланс белков / жиров / углеводов...'**
  String get loadingMacros;

  /// No description provided for @loadingPsychotype.
  ///
  /// In ru, this message translates to:
  /// **'Анализируем ваш психотип и привычки...'**
  String get loadingPsychotype;

  /// No description provided for @loadingPlanCreate.
  ///
  /// In ru, this message translates to:
  /// **'Создаём персональный план...'**
  String get loadingPlanCreate;

  /// No description provided for @psyStressEaterTitle.
  ///
  /// In ru, this message translates to:
  /// **'Эмоциональный едок'**
  String get psyStressEaterTitle;

  /// No description provided for @psyStressEaterDesc.
  ///
  /// In ru, this message translates to:
  /// **'Вы едите от эмоций. Мы поможем найти альтернативы.'**
  String get psyStressEaterDesc;

  /// No description provided for @psyFuelFocusedTitle.
  ///
  /// In ru, this message translates to:
  /// **'Рациональный едок'**
  String get psyFuelFocusedTitle;

  /// No description provided for @psyFuelFocusedDesc.
  ///
  /// In ru, this message translates to:
  /// **'Вы рациональны в питании. Останется только точно посчитать.'**
  String get psyFuelFocusedDesc;

  /// No description provided for @psySweetLoverTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сладкоежка'**
  String get psySweetLoverTitle;

  /// No description provided for @psySweetLoverDesc.
  ///
  /// In ru, this message translates to:
  /// **'Мы научим заменять сладкое без срывов.'**
  String get psySweetLoverDesc;

  /// No description provided for @psySavoryLoverTitle.
  ///
  /// In ru, this message translates to:
  /// **'Любитель острого'**
  String get psySavoryLoverTitle;

  /// No description provided for @psySavoryLoverDesc.
  ///
  /// In ru, this message translates to:
  /// **'Острое и солёное — ваш стиль. Найдём баланс по натрию.'**
  String get psySavoryLoverDesc;

  /// No description provided for @psyConsistentAthleteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Спортивный профи'**
  String get psyConsistentAthleteTitle;

  /// No description provided for @psyConsistentAthleteDesc.
  ///
  /// In ru, this message translates to:
  /// **'У вас сильная база. Точная диета умножит результат.'**
  String get psyConsistentAthleteDesc;

  /// No description provided for @psyInconsistentTitle.
  ///
  /// In ru, this message translates to:
  /// **'Герой рестарта'**
  String get psyInconsistentTitle;

  /// No description provided for @psyInconsistentDesc.
  ///
  /// In ru, this message translates to:
  /// **'Главное — начать снова. Мы упростим возврат.'**
  String get psyInconsistentDesc;

  /// No description provided for @psyPlannerTitle.
  ///
  /// In ru, this message translates to:
  /// **'Планировщик'**
  String get psyPlannerTitle;

  /// No description provided for @psyPlannerDesc.
  ///
  /// In ru, this message translates to:
  /// **'Вы любите контроль. Дайте AI просчитать всё за вас.'**
  String get psyPlannerDesc;

  /// No description provided for @psyConvenienceEaterTitle.
  ///
  /// In ru, this message translates to:
  /// **'Едок на бегу'**
  String get psyConvenienceEaterTitle;

  /// No description provided for @psyConvenienceEaterDesc.
  ///
  /// In ru, this message translates to:
  /// **'Времени мало — поможем выбирать быстро и правильно.'**
  String get psyConvenienceEaterDesc;

  /// No description provided for @psyResultsDrivenTitle.
  ///
  /// In ru, this message translates to:
  /// **'Целеустремлённый'**
  String get psyResultsDrivenTitle;

  /// No description provided for @psyResultsDrivenDesc.
  ///
  /// In ru, this message translates to:
  /// **'Вас двигают цифры. Покажем прогресс наглядно.'**
  String get psyResultsDrivenDesc;

  /// No description provided for @psyFeelingsDrivenTitle.
  ///
  /// In ru, this message translates to:
  /// **'Интуитивный едок'**
  String get psyFeelingsDrivenTitle;

  /// No description provided for @psyFeelingsDrivenDesc.
  ///
  /// In ru, this message translates to:
  /// **'Вы слушаете себя. Мы дополним это данными.'**
  String get psyFeelingsDrivenDesc;

  /// No description provided for @psyBalancedTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сбалансированный подход'**
  String get psyBalancedTitle;

  /// No description provided for @psyBalancedDesc.
  ///
  /// In ru, this message translates to:
  /// **'У вас здоровый подход к питанию. Усилим его данными.'**
  String get psyBalancedDesc;

  /// No description provided for @onbWelcomeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Составим план для вашей цели'**
  String get onbWelcomeTitle;

  /// No description provided for @onbWelcomeSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Считайте калории и БЖУ быстро и точно — без ручного ввода!'**
  String get onbWelcomeSubtitle;

  /// No description provided for @onbWelcomeCta.
  ///
  /// In ru, this message translates to:
  /// **'Начать'**
  String get onbWelcomeCta;

  /// No description provided for @onbLanguageSheetTitle.
  ///
  /// In ru, this message translates to:
  /// **'Выберите язык'**
  String get onbLanguageSheetTitle;

  /// No description provided for @langShortEn.
  ///
  /// In ru, this message translates to:
  /// **'Eng'**
  String get langShortEn;

  /// No description provided for @langShortRu.
  ///
  /// In ru, this message translates to:
  /// **'Рус'**
  String get langShortRu;

  /// No description provided for @langShortDe.
  ///
  /// In ru, this message translates to:
  /// **'Нем'**
  String get langShortDe;

  /// No description provided for @langShortEs.
  ///
  /// In ru, this message translates to:
  /// **'Исп'**
  String get langShortEs;

  /// No description provided for @langShortFr.
  ///
  /// In ru, this message translates to:
  /// **'Фра'**
  String get langShortFr;

  /// No description provided for @langShortPt.
  ///
  /// In ru, this message translates to:
  /// **'Пор'**
  String get langShortPt;

  /// No description provided for @onbConfidentTitle.
  ///
  /// In ru, this message translates to:
  /// **'Спасибо, что доверяете'**
  String get onbConfidentTitle;

  /// No description provided for @onbConfidentSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Мы персонализируем Body Meal специально под ваши цели'**
  String get onbConfidentSubtitle;

  /// No description provided for @onbConfidentPrivacyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Ваша конфиденциальность важна'**
  String get onbConfidentPrivacyTitle;

  /// No description provided for @onbConfidentPrivacyBody.
  ///
  /// In ru, this message translates to:
  /// **'Мы обещаем хранить вашу личную информацию в секрете'**
  String get onbConfidentPrivacyBody;

  /// No description provided for @onbKeepResultTitle.
  ///
  /// In ru, this message translates to:
  /// **'Body Meal помогает удерживать результат'**
  String get onbKeepResultTitle;

  /// No description provided for @onbKeepResultSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Сохраняйте стабильный прогресс даже через 6 месяцев!'**
  String get onbKeepResultSubtitle;

  /// No description provided for @onbCalorieHistoryTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вы когда-нибудь считали калории?'**
  String get onbCalorieHistoryTitle;

  /// No description provided for @onbCalorieHistoryYes.
  ///
  /// In ru, this message translates to:
  /// **'Да, и продолжаю'**
  String get onbCalorieHistoryYes;

  /// No description provided for @onbCalorieHistoryTried.
  ///
  /// In ru, this message translates to:
  /// **'{gender, select, male{Пробовал, но бросил} female{Пробовала, но бросила} other{Пробовал(а), но бросил(а)}}'**
  String onbCalorieHistoryTried(String gender);

  /// No description provided for @onbCalorieHistoryNever.
  ///
  /// In ru, this message translates to:
  /// **'Нет, никогда'**
  String get onbCalorieHistoryNever;

  /// No description provided for @onbImproveTitle.
  ///
  /// In ru, this message translates to:
  /// **'Что вы хотите улучшить?'**
  String get onbImproveTitle;

  /// No description provided for @onbImproveLookBetter.
  ///
  /// In ru, this message translates to:
  /// **'Выглядеть лучше'**
  String get onbImproveLookBetter;

  /// No description provided for @onbImproveFeelConfident.
  ///
  /// In ru, this message translates to:
  /// **'Чувствовать себя увереннее'**
  String get onbImproveFeelConfident;

  /// No description provided for @onbImproveHealth.
  ///
  /// In ru, this message translates to:
  /// **'Улучшить здоровье'**
  String get onbImproveHealth;

  /// No description provided for @onbImproveMoreEnergy.
  ///
  /// In ru, this message translates to:
  /// **'Больше энергии'**
  String get onbImproveMoreEnergy;

  /// No description provided for @onbImproveLessStress.
  ///
  /// In ru, this message translates to:
  /// **'Меньше стресса'**
  String get onbImproveLessStress;

  /// No description provided for @onbImproveImmunity.
  ///
  /// In ru, this message translates to:
  /// **'Поддержать иммунитет'**
  String get onbImproveImmunity;

  /// No description provided for @onbImproveFocus.
  ///
  /// In ru, this message translates to:
  /// **'Лучше фокусироваться'**
  String get onbImproveFocus;

  /// No description provided for @onbImproveSleep.
  ///
  /// In ru, this message translates to:
  /// **'Лучше спать'**
  String get onbImproveSleep;

  /// No description provided for @onbEatingObstacleTitle.
  ///
  /// In ru, this message translates to:
  /// **'Что мешает вам питаться полезнее?'**
  String get onbEatingObstacleTitle;

  /// No description provided for @onbEatingObstacleCravings.
  ///
  /// In ru, this message translates to:
  /// **'Тяга к сладкому или вредному'**
  String get onbEatingObstacleCravings;

  /// No description provided for @onbEatingObstacleLateSnacks.
  ///
  /// In ru, this message translates to:
  /// **'Поздние перекусы'**
  String get onbEatingObstacleLateSnacks;

  /// No description provided for @onbEatingObstacleBadHabits.
  ///
  /// In ru, this message translates to:
  /// **'Неполезные привычки'**
  String get onbEatingObstacleBadHabits;

  /// No description provided for @onbHardestTitle.
  ///
  /// In ru, this message translates to:
  /// **'Что сложнее всего — не срываться и держать режим?'**
  String get onbHardestTitle;

  /// No description provided for @onbHardestBusy.
  ///
  /// In ru, this message translates to:
  /// **'Плотный график'**
  String get onbHardestBusy;

  /// No description provided for @onbHardestRestrictive.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много ограничений'**
  String get onbHardestRestrictive;

  /// No description provided for @onbHardestNoSupport.
  ///
  /// In ru, this message translates to:
  /// **'Не хватает поддержки'**
  String get onbHardestNoSupport;

  /// No description provided for @onbSupportTitle.
  ///
  /// In ru, this message translates to:
  /// **'Мы будем рядом!'**
  String get onbSupportTitle;

  /// No description provided for @onbSupportSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Путь к цели бывает непростым, но мы будем поддерживать вас на каждом шаге.'**
  String get onbSupportSubtitle;

  /// No description provided for @onbSocialProofTitle.
  ///
  /// In ru, this message translates to:
  /// **'С поддержкой люди теряют вес больше и быстрее'**
  String get onbSocialProofTitle;

  /// No description provided for @onbSocialProofSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Приложение может помочь вам достичь устойчивых результатов в снижении веса.'**
  String get onbSocialProofSubtitle;

  /// No description provided for @onbSpeedSlow.
  ///
  /// In ru, this message translates to:
  /// **'Медленно'**
  String get onbSpeedSlow;

  /// No description provided for @onbSpeedBalanced.
  ///
  /// In ru, this message translates to:
  /// **'Сбалансированно'**
  String get onbSpeedBalanced;

  /// No description provided for @onbSpeedFast.
  ///
  /// In ru, this message translates to:
  /// **'Быстро'**
  String get onbSpeedFast;

  /// No description provided for @onbSpeedGoodTitle.
  ///
  /// In ru, this message translates to:
  /// **'Цель: {date}'**
  String onbSpeedGoodTitle(String date);

  /// No description provided for @onbSpeedGoodBody.
  ///
  /// In ru, this message translates to:
  /// **'Разумный план — устойчивый результат без срывов и плато.'**
  String get onbSpeedGoodBody;

  /// No description provided for @onbSpeedAlertTitle.
  ///
  /// In ru, this message translates to:
  /// **'Слишком быстро — высок риск срыва'**
  String get onbSpeedAlertTitle;

  /// No description provided for @onbSpeedAlertBody.
  ///
  /// In ru, this message translates to:
  /// **'Выберите более устойчивый темп, чтобы дойти до цели без срывов.'**
  String get onbSpeedAlertBody;

  /// No description provided for @onbTrialReminderTitle.
  ///
  /// In ru, this message translates to:
  /// **'Мы пришлём напоминание,\nчто пробный период\nскоро закончится.'**
  String get onbTrialReminderTitle;

  /// No description provided for @onbTrialReminderNoPaymentNow.
  ///
  /// In ru, this message translates to:
  /// **'Платёж сейчас не требуется'**
  String get onbTrialReminderNoPaymentNow;

  /// No description provided for @onbTrialReminderCta.
  ///
  /// In ru, this message translates to:
  /// **'Попробовать за {price}'**
  String onbTrialReminderCta(String price);

  /// No description provided for @onbTrialReminderSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Всего {yearly} в год ({monthly} / мес)'**
  String onbTrialReminderSubtitle(String yearly, String monthly);

  /// No description provided for @tagHighProtein.
  ///
  /// In ru, this message translates to:
  /// **'Много белка'**
  String get tagHighProtein;

  /// No description provided for @tagContainsProtein.
  ///
  /// In ru, this message translates to:
  /// **'Есть белок'**
  String get tagContainsProtein;

  /// No description provided for @tagLowProtein.
  ///
  /// In ru, this message translates to:
  /// **'Мало белка'**
  String get tagLowProtein;

  /// No description provided for @tagCompleteProtein.
  ///
  /// In ru, this message translates to:
  /// **'Полноценный белок'**
  String get tagCompleteProtein;

  /// No description provided for @tagHealthyFats.
  ///
  /// In ru, this message translates to:
  /// **'Полезные жиры'**
  String get tagHealthyFats;

  /// No description provided for @tagRichInOmega3.
  ///
  /// In ru, this message translates to:
  /// **'Омега-3'**
  String get tagRichInOmega3;

  /// No description provided for @tagHighFat.
  ///
  /// In ru, this message translates to:
  /// **'Много жиров'**
  String get tagHighFat;

  /// No description provided for @tagHighSatFat.
  ///
  /// In ru, this message translates to:
  /// **'Насыщенные жиры'**
  String get tagHighSatFat;

  /// No description provided for @tagHighTransFat.
  ///
  /// In ru, this message translates to:
  /// **'Транс-жиры'**
  String get tagHighTransFat;

  /// No description provided for @tagLowFat.
  ///
  /// In ru, this message translates to:
  /// **'Мало жиров'**
  String get tagLowFat;

  /// No description provided for @tagHighFiber.
  ///
  /// In ru, this message translates to:
  /// **'Много клетчатки'**
  String get tagHighFiber;

  /// No description provided for @tagContainsFiber.
  ///
  /// In ru, this message translates to:
  /// **'Есть клетчатка'**
  String get tagContainsFiber;

  /// No description provided for @tagLowFiber.
  ///
  /// In ru, this message translates to:
  /// **'Мало клетчатки'**
  String get tagLowFiber;

  /// No description provided for @tagComplexCarbs.
  ///
  /// In ru, this message translates to:
  /// **'Сложные углеводы'**
  String get tagComplexCarbs;

  /// No description provided for @tagRefinedCarbs.
  ///
  /// In ru, this message translates to:
  /// **'Быстрые углеводы'**
  String get tagRefinedCarbs;

  /// No description provided for @tagLowSugar.
  ///
  /// In ru, this message translates to:
  /// **'Мало сахара'**
  String get tagLowSugar;

  /// No description provided for @tagHighSugar.
  ///
  /// In ru, this message translates to:
  /// **'Много сахара'**
  String get tagHighSugar;

  /// No description provided for @tagLowCarb.
  ///
  /// In ru, this message translates to:
  /// **'Низкоуглеводное'**
  String get tagLowCarb;

  /// No description provided for @tagHighCalories.
  ///
  /// In ru, this message translates to:
  /// **'Калорийное'**
  String get tagHighCalories;

  /// No description provided for @tagLowCalories.
  ///
  /// In ru, this message translates to:
  /// **'Низкокалорийное'**
  String get tagLowCalories;

  /// No description provided for @tagHighEnergy.
  ///
  /// In ru, this message translates to:
  /// **'Много энергии'**
  String get tagHighEnergy;

  /// No description provided for @tagHelpsQuota.
  ///
  /// In ru, this message translates to:
  /// **'Добивает норму'**
  String get tagHelpsQuota;

  /// No description provided for @tagNutrientDense.
  ///
  /// In ru, this message translates to:
  /// **'Питательное'**
  String get tagNutrientDense;

  /// No description provided for @tagEmptyCalories.
  ///
  /// In ru, this message translates to:
  /// **'Пустые калории'**
  String get tagEmptyCalories;

  /// No description provided for @tagHeavyMeal.
  ///
  /// In ru, this message translates to:
  /// **'Тяжёлое блюдо'**
  String get tagHeavyMeal;

  /// No description provided for @tagLightMeal.
  ///
  /// In ru, this message translates to:
  /// **'Лёгкое блюдо'**
  String get tagLightMeal;

  /// No description provided for @tagHighSalt.
  ///
  /// In ru, this message translates to:
  /// **'Много соли'**
  String get tagHighSalt;

  /// No description provided for @tagLowSalt.
  ///
  /// In ru, this message translates to:
  /// **'Мало соли'**
  String get tagLowSalt;

  /// No description provided for @tagHighCholesterol.
  ///
  /// In ru, this message translates to:
  /// **'Много холестерина'**
  String get tagHighCholesterol;

  /// No description provided for @tagGoodPostWorkout.
  ///
  /// In ru, this message translates to:
  /// **'После тренировки'**
  String get tagGoodPostWorkout;

  /// No description provided for @tagGoodPreWorkout.
  ///
  /// In ru, this message translates to:
  /// **'Перед тренировкой'**
  String get tagGoodPreWorkout;

  /// No description provided for @tagBreakfastFriendly.
  ///
  /// In ru, this message translates to:
  /// **'Хороший завтрак'**
  String get tagBreakfastFriendly;

  /// No description provided for @tagHeartFriendly.
  ///
  /// In ru, this message translates to:
  /// **'Для сердца'**
  String get tagHeartFriendly;

  /// No description provided for @tagGutFriendly.
  ///
  /// In ru, this message translates to:
  /// **'Для ЖКТ'**
  String get tagGutFriendly;

  /// No description provided for @tagBrainFood.
  ///
  /// In ru, this message translates to:
  /// **'Для мозга'**
  String get tagBrainFood;

  /// No description provided for @tagImmuneBoost.
  ///
  /// In ru, this message translates to:
  /// **'Для иммунитета'**
  String get tagImmuneBoost;

  /// No description provided for @tagBoneHealth.
  ///
  /// In ru, this message translates to:
  /// **'Для костей'**
  String get tagBoneHealth;

  /// No description provided for @tagRichInVitamins.
  ///
  /// In ru, this message translates to:
  /// **'Много витаминов'**
  String get tagRichInVitamins;

  /// No description provided for @tagRichInIron.
  ///
  /// In ru, this message translates to:
  /// **'Богато железом'**
  String get tagRichInIron;

  /// No description provided for @tagRichInCalcium.
  ///
  /// In ru, this message translates to:
  /// **'Богато кальцием'**
  String get tagRichInCalcium;

  /// No description provided for @tagRichInPotassium.
  ///
  /// In ru, this message translates to:
  /// **'Богато калием'**
  String get tagRichInPotassium;

  /// No description provided for @tagHighAntioxidants.
  ///
  /// In ru, this message translates to:
  /// **'Антиоксиданты'**
  String get tagHighAntioxidants;

  /// No description provided for @tagBalancedMacros.
  ///
  /// In ru, this message translates to:
  /// **'Баланс БЖУ'**
  String get tagBalancedMacros;

  /// No description provided for @tagWholeFoods.
  ///
  /// In ru, this message translates to:
  /// **'Натуральные продукты'**
  String get tagWholeFoods;

  /// No description provided for @tagUltraProcessed.
  ///
  /// In ru, this message translates to:
  /// **'Переработанное'**
  String get tagUltraProcessed;

  /// No description provided for @tagPlantBased.
  ///
  /// In ru, this message translates to:
  /// **'Растительное'**
  String get tagPlantBased;

  /// No description provided for @tagHydrating.
  ///
  /// In ru, this message translates to:
  /// **'Увлажняющее'**
  String get tagHydrating;

  /// No description provided for @forYourGoalLose.
  ///
  /// In ru, this message translates to:
  /// **'Цель: Похудеть'**
  String get forYourGoalLose;

  /// No description provided for @forYourGoalMaintain.
  ///
  /// In ru, this message translates to:
  /// **'Цель: Поддержание'**
  String get forYourGoalMaintain;

  /// No description provided for @forYourGoalGain.
  ///
  /// In ru, this message translates to:
  /// **'Цель: Набор массы'**
  String get forYourGoalGain;

  /// No description provided for @completeMacroSection.
  ///
  /// In ru, this message translates to:
  /// **'Полные показатели'**
  String get completeMacroSection;

  /// No description provided for @macroSugar.
  ///
  /// In ru, this message translates to:
  /// **'Сахар'**
  String get macroSugar;

  /// No description provided for @macroFiber.
  ///
  /// In ru, this message translates to:
  /// **'Клетчатка'**
  String get macroFiber;

  /// No description provided for @macroSaturatedFat.
  ///
  /// In ru, this message translates to:
  /// **'Насыщенные жиры'**
  String get macroSaturatedFat;

  /// No description provided for @macroCholesterol.
  ///
  /// In ru, this message translates to:
  /// **'Холестерин'**
  String get macroCholesterol;

  /// No description provided for @macroTransFat.
  ///
  /// In ru, this message translates to:
  /// **'Транс-жиры'**
  String get macroTransFat;

  /// No description provided for @macroGlycemicLoad.
  ///
  /// In ru, this message translates to:
  /// **'Гликем. нагрузка'**
  String get macroGlycemicLoad;

  /// No description provided for @macroCaloricDensity.
  ///
  /// In ru, this message translates to:
  /// **'Плотность калорий'**
  String get macroCaloricDensity;

  /// No description provided for @macroProcessing.
  ///
  /// In ru, this message translates to:
  /// **'Степень обработки'**
  String get macroProcessing;

  /// No description provided for @macroVitamins.
  ///
  /// In ru, this message translates to:
  /// **'Витамины и минералы'**
  String get macroVitamins;

  /// No description provided for @macroStatusWorse.
  ///
  /// In ru, this message translates to:
  /// **'Хуже среднего'**
  String get macroStatusWorse;

  /// No description provided for @macroStatusAverage.
  ///
  /// In ru, this message translates to:
  /// **'Средне'**
  String get macroStatusAverage;

  /// No description provided for @macroStatusGood.
  ///
  /// In ru, this message translates to:
  /// **'Хорошо'**
  String get macroStatusGood;

  /// No description provided for @dishWeightLabel.
  ///
  /// In ru, this message translates to:
  /// **'Вес блюда'**
  String get dishWeightLabel;

  /// No description provided for @macroSalt.
  ///
  /// In ru, this message translates to:
  /// **'Соль'**
  String get macroSalt;

  /// No description provided for @burnSectionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Как сжечь калории?'**
  String get burnSectionTitle;

  /// No description provided for @burnWalking.
  ///
  /// In ru, this message translates to:
  /// **'Ходьба'**
  String get burnWalking;

  /// No description provided for @burnRunning.
  ///
  /// In ru, this message translates to:
  /// **'Бег'**
  String get burnRunning;

  /// No description provided for @burnGym.
  ///
  /// In ru, this message translates to:
  /// **'Тренировка'**
  String get burnGym;

  /// No description provided for @burnCycling.
  ///
  /// In ru, this message translates to:
  /// **'Велосипед'**
  String get burnCycling;

  /// No description provided for @burnResting.
  ///
  /// In ru, this message translates to:
  /// **'Покой'**
  String get burnResting;

  /// No description provided for @burnOr.
  ///
  /// In ru, this message translates to:
  /// **'или'**
  String get burnOr;

  /// No description provided for @burnApproxSteps.
  ///
  /// In ru, this message translates to:
  /// **'~ {count} шагов'**
  String burnApproxSteps(String count);

  /// No description provided for @burnApproxKm.
  ///
  /// In ru, this message translates to:
  /// **'~ {count} км'**
  String burnApproxKm(String count);

  /// No description provided for @burnApproxHoursMinutes.
  ///
  /// In ru, this message translates to:
  /// **'~ {hours} ч {minutes} мин'**
  String burnApproxHoursMinutes(int hours, int minutes);

  /// No description provided for @aiLoadingPhrase01.
  ///
  /// In ru, this message translates to:
  /// **'Хм… выглядит подозрительно вкусно.'**
  String get aiLoadingPhrase01;

  /// No description provided for @aiLoadingPhrase02.
  ///
  /// In ru, this message translates to:
  /// **'Секунду, мне нужно изучить эту красоту.'**
  String get aiLoadingPhrase02;

  /// No description provided for @aiLoadingPhrase03.
  ///
  /// In ru, this message translates to:
  /// **'Посмотрим, что прячет тарелка.'**
  String get aiLoadingPhrase03;

  /// No description provided for @aiLoadingPhrase04.
  ///
  /// In ru, this message translates to:
  /// **'Еда обнаружена. Любопытство активировано.'**
  String get aiLoadingPhrase04;

  /// No description provided for @aiLoadingPhrase05.
  ///
  /// In ru, this message translates to:
  /// **'Подожди, у этого блюда есть секреты.'**
  String get aiLoadingPhrase05;

  /// No description provided for @aiLoadingPhrase06.
  ///
  /// In ru, this message translates to:
  /// **'Анализирую аппетитную ситуацию…'**
  String get aiLoadingPhrase06;

  /// No description provided for @aiLoadingPhrase07.
  ///
  /// In ru, this message translates to:
  /// **'Дай-ка я разгадаю эту вкусную загадку.'**
  String get aiLoadingPhrase07;

  /// No description provided for @aiLoadingPhrase08.
  ///
  /// In ru, this message translates to:
  /// **'Маленький детектив еды на деле.'**
  String get aiLoadingPhrase08;

  /// No description provided for @aiLoadingPhrase09.
  ///
  /// In ru, this message translates to:
  /// **'Выглядит хорошо. Подозрительно хорошо.'**
  String get aiLoadingPhrase09;

  /// No description provided for @aiLoadingPhrase10.
  ///
  /// In ru, this message translates to:
  /// **'Сканирую тарелку как улику.'**
  String get aiLoadingPhrase10;

  /// No description provided for @aiLoadingPhrase11.
  ///
  /// In ru, this message translates to:
  /// **'Минутку, расследую эту вкуснотищу.'**
  String get aiLoadingPhrase11;

  /// No description provided for @aiLoadingPhrase12.
  ///
  /// In ru, this message translates to:
  /// **'Выясним, что тут на самом деле.'**
  String get aiLoadingPhrase12;

  /// No description provided for @aiLoadingPhrase13.
  ///
  /// In ru, this message translates to:
  /// **'Вилка подождёт. Сначала наука.'**
  String get aiLoadingPhrase13;

  /// No description provided for @aiLoadingPhrase14.
  ///
  /// In ru, this message translates to:
  /// **'Проверю, такое ли оно невинное.'**
  String get aiLoadingPhrase14;

  /// No description provided for @aiLoadingPhrase15.
  ///
  /// In ru, this message translates to:
  /// **'Происходит что-то вкусное…'**
  String get aiLoadingPhrase15;

  /// No description provided for @aiLoadingPhrase16.
  ///
  /// In ru, this message translates to:
  /// **'Приближаюсь к аппетитным уликам.'**
  String get aiLoadingPhrase16;

  /// No description provided for @aiLoadingPhrase17.
  ///
  /// In ru, this message translates to:
  /// **'Веду полное расследование закуски.'**
  String get aiLoadingPhrase17;

  /// No description provided for @aiLoadingPhrase18.
  ///
  /// In ru, this message translates to:
  /// **'Чую калории. Метафорически.'**
  String get aiLoadingPhrase18;

  /// No description provided for @aiLoadingPhrase19.
  ///
  /// In ru, this message translates to:
  /// **'Тарелка вошла в режим анализа.'**
  String get aiLoadingPhrase19;

  /// No description provided for @aiLoadingPhrase20.
  ///
  /// In ru, this message translates to:
  /// **'Секунду, читаю гастрономические сплетни.'**
  String get aiLoadingPhrase20;

  /// No description provided for @aiLoadingPhrase21.
  ///
  /// In ru, this message translates to:
  /// **'Ищу макросы за этой магией.'**
  String get aiLoadingPhrase21;

  /// No description provided for @aiLoadingPhrase22.
  ///
  /// In ru, this message translates to:
  /// **'Хм… тарелка — главный герой.'**
  String get aiLoadingPhrase22;

  /// No description provided for @aiLoadingPhrase23.
  ///
  /// In ru, this message translates to:
  /// **'Посмотрим, из чего сделан этот мини-пир.'**
  String get aiLoadingPhrase23;

  /// No description provided for @aiLoadingPhrase24.
  ///
  /// In ru, this message translates to:
  /// **'Считаю цифры, а не твоё блюдо.'**
  String get aiLoadingPhrase24;

  /// No description provided for @aiLoadingPhrase25.
  ///
  /// In ru, this message translates to:
  /// **'Вайбы еды обнаружены. Считаем…'**
  String get aiLoadingPhrase25;
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
