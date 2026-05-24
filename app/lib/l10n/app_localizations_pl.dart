// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get mealBreakfast => 'Śniadanie';

  @override
  String get mealLunch => 'Obiad';

  @override
  String get mealDinner => 'Kolacja';

  @override
  String get mealSnack => 'Przekąska';

  @override
  String get kcalUnit => 'kcal';

  @override
  String get gramsUnit => 'g';

  @override
  String get gramsUnitDot => 'g';

  @override
  String get kgUnit => 'kg';

  @override
  String get cmUnit => 'cm';

  @override
  String get yearsUnit => 'rok urodzenia';

  @override
  String kcalValue(String count) {
    return '$count kcal';
  }

  @override
  String kcalValueInt(int count) {
    return '$count kcal';
  }

  @override
  String gramsValue(int count) {
    return '$count g';
  }

  @override
  String kcalPer100g(String count) {
    return '$count kcal/100g';
  }

  @override
  String per100gInfo(int cal, String prot, String fat, String carbs) {
    return 'Na 100 g: $cal kcal  B$prot T$fat W$carbs';
  }

  @override
  String get proteinShort => 'B';

  @override
  String get fatShort => 'T';

  @override
  String get carbsShort => 'W';

  @override
  String get proteinLabel => 'Białko';

  @override
  String get fatLabel => 'Tłuszcze';

  @override
  String get carbsLabel => 'Węglowodany';

  @override
  String get carbsLabelShort => 'Węgl.';

  @override
  String get caloriesLabel => 'Kalorie';

  @override
  String get caloriesKcalLabel => 'Kalorie, kcal';

  @override
  String get proteinGramsLabel => 'Białko, g';

  @override
  String get fatGramsLabel => 'Tłuszcze, g';

  @override
  String get carbsGramsLabel => 'Węglowodany, g';

  @override
  String get caloriesKcalInputLabel => 'Kalorie (kcal)';

  @override
  String proteinGoalLabel(int count) {
    return '$count białko';
  }

  @override
  String fatGoalLabel(int count) {
    return '$count tłuszcze';
  }

  @override
  String carbsGoalLabel(int count) {
    return '$count węglowodany';
  }

  @override
  String get profileTitle => 'Profil';

  @override
  String get myProfile => 'Mój profil';

  @override
  String get subscription => 'Subskrypcja';

  @override
  String get myGoals => 'Moje cele';

  @override
  String get myProducts => 'Moje produkty';

  @override
  String get settings => 'Ustawienia';

  @override
  String get productsList => 'Lista produktów';

  @override
  String get allProducts => 'Wszystkie';

  @override
  String get appTheme => 'Motyw aplikacji';

  @override
  String get languageSelector => 'Język interfejsu';

  @override
  String get pushNotifications => 'Powiadomienia push';

  @override
  String get pushNotificationsShortOn => 'Wł';

  @override
  String get pushNotificationsShortOff => 'Wył';

  @override
  String get themeSystem => 'Systemowy';

  @override
  String get themeLight => 'Jasny';

  @override
  String get themeDark => 'Ciemny';

  @override
  String get signOut => 'Wyloguj się';

  @override
  String get signOutConfirm => 'Wylogować się z konta?';

  @override
  String get signOutLocalDataKept => 'Dane lokalne pozostaną na urządzeniu.';

  @override
  String get deleteAccount => 'Usuń konto';

  @override
  String get deleteAccountConfirmTitle => 'Usunąć konto?';

  @override
  String get deleteAccountConfirmMessage =>
      'Konto zostanie trwale usunięte. Historia posiłków, przepisy, produkty, ulubione i ustawienia na tym urządzeniu również zostaną usunięte. Tej operacji nie można cofnąć.';

  @override
  String get deleteAccountFinalConfirmTitle => 'Czy na pewno?';

  @override
  String get deleteAccountFinalConfirmMessage =>
      'Twoje konto i dane zostaną usunięte bez możliwości odzyskania.';

  @override
  String get deleteAccountSuccess => 'Konto zostało usunięte.';

  @override
  String get deleteAccountFailed =>
      'Nie udało się usunąć konta. Sprawdź połączenie i spróbuj ponownie.';

  @override
  String get cancel => 'Anuluj';

  @override
  String get delete => 'Usuń';

  @override
  String get save => 'Zapisz';

  @override
  String get add => 'Dodaj';

  @override
  String get close => 'Zamknij';

  @override
  String get edit => 'Edytuj';

  @override
  String get guestMode => 'Tryb gościa';

  @override
  String get defaultUserName => 'Użytkownik';

  @override
  String get signedInSnackbar => 'Zalogowano pomyślnie';

  @override
  String get signInTitle => 'Zaloguj się na konto';

  @override
  String get signInGoogle => 'Zaloguj się przez Google';

  @override
  String get signInApple => 'Zaloguj się przez Apple';

  @override
  String get signInEmail => 'Zaloguj się przez e-mail';

  @override
  String get startOverOnboarding => 'Zacznij od nowa';

  @override
  String get startOverOnboardingConfirm => 'Rozpocząć onboarding od nowa?';

  @override
  String get startOverOnboardingHint =>
      'Odpowiedzi w ankiecie zostaną zresetowane. Dziennik na urządzeniu pozostanie.';

  @override
  String get skipLogin => 'Kontynuuj bez logowania';

  @override
  String get signInSyncHint =>
      'Logowanie pozwala synchronizować dane\nmiędzy urządzeniami';

  @override
  String get calorieTracking => 'Monitorowanie posiłków i kalorii';

  @override
  String get mergeLocalDataTitle =>
      'Chcesz przenieść ostatnie dane na swoje konto?';

  @override
  String get mergeLocalDataKeep => 'Przenieś';

  @override
  String get mergeLocalDataReplace => 'Pozostaw bez zmian';

  @override
  String get loginSyncing => 'Synchronizacja…';

  @override
  String get loginSyncFailed =>
      'Nie udało się zsynchronizować danych. Spróbuj później.';

  @override
  String get loginTitle => 'Logowanie';

  @override
  String get registerTitle => 'Rejestracja';

  @override
  String get nameOptional => 'Imię (opcjonalnie)';

  @override
  String get enterEmail => 'Wpisz e-mail';

  @override
  String get invalidEmail => 'Nieprawidłowy e-mail';

  @override
  String get passwordLabel => 'Hasło';

  @override
  String get enterPassword => 'Wpisz hasło';

  @override
  String get minPasswordLength => 'Minimum 6 znaków';

  @override
  String get signInButton => 'Zaloguj się';

  @override
  String get registerButton => 'Zarejestruj się';

  @override
  String get switchToLogin => 'Zaloguj się na konto';

  @override
  String get wrongCredentials => 'Nieprawidłowy e-mail lub hasło';

  @override
  String signInError(String error) {
    return 'Błąd logowania: $error';
  }

  @override
  String get emailAlreadyRegistered => 'Ten e-mail jest już zarejestrowany';

  @override
  String registerError(String error) {
    return 'Błąd rejestracji: $error';
  }

  @override
  String get forgotPassword => 'Nie pamiętasz hasła?';

  @override
  String get resetPasswordTitle => 'Resetowanie hasła';

  @override
  String get resetPasswordHint =>
      'Wpisz e-mail podany przy rejestracji. Wyślemy 6-cyfrowy kod do resetowania hasła.';

  @override
  String get sendResetCode => 'Wyślij kod';

  @override
  String get enterCodeTitle => 'Wpisz kod';

  @override
  String resetCodeSentTo(String email) {
    return 'Wysłaliśmy 6-cyfrowy kod na $email';
  }

  @override
  String get enterSixDigitCode => 'Wpisz 6-cyfrowy kod';

  @override
  String get verifyCode => 'Potwierdź';

  @override
  String get resendCode => 'Wyślij kod ponownie';

  @override
  String resendCodeIn(int seconds) {
    return 'Ponownie za $seconds s';
  }

  @override
  String get resetCodeResent => 'Kod wysłany ponownie';

  @override
  String get newPasswordTitle => 'Nowe hasło';

  @override
  String get newPasswordHint => 'Utwórz nowe hasło do swojego konta.';

  @override
  String get newPasswordLabel => 'Nowe hasło';

  @override
  String get confirmPasswordLabel => 'Potwierdź hasło';

  @override
  String get passwordsDoNotMatch => 'Hasła nie są zgodne';

  @override
  String get resetPasswordButton => 'Zresetuj hasło';

  @override
  String get passwordResetSuccess =>
      'Hasło pomyślnie zresetowane. Zaloguj się z nowym hasłem.';

  @override
  String get emailNotFound => 'Nie znaleziono konta z takim e-mailem';

  @override
  String get invalidResetCode => 'Nieprawidłowy lub wygasły kod';

  @override
  String get proTitle => 'Body Meal Pro';

  @override
  String get proUnlockFeatures => 'Odblokuj wszystkie funkcje:';

  @override
  String get proAiUnlimited => 'Rozpoznawanie AI bez limitów';

  @override
  String get proExtendedStats => 'Rozszerzone statystyki';

  @override
  String get proPersonalRecommendations => 'Spersonalizowane rekomendacje';

  @override
  String get proTryFree => 'Wypróbuj za darmo';

  @override
  String get planLabel => 'Plan:';

  @override
  String get planWeekly => 'Tygodniowy';

  @override
  String get planYearly => 'Roczny';

  @override
  String get planLifetime => 'Dożywotni';

  @override
  String get planPromo => 'Promo';

  @override
  String get billingLabel => 'Następne pobranie:';

  @override
  String get manageSubscription => 'Zarządzaj subskrypcją';

  @override
  String get goalCaloriesKcal => 'Kalorie, kcal';

  @override
  String get goalProteinG => 'Białko, g';

  @override
  String get goalFatG => 'Tłuszcze, g';

  @override
  String get goalCarbsG => 'Węglowodany, g';

  @override
  String get remindersTitle => 'Przypomnienia';

  @override
  String get reminderOff => 'Wyłączone';

  @override
  String get remindersDescription =>
      'Przypomnienia będą przychodzić codziennie o wskazanej porze, abyś nie zapomniał zapisać posiłków.';

  @override
  String get notifBreakfastBody => 'Czas zapisać śniadanie';

  @override
  String get notifLunchBody => 'Czas zapisać obiad';

  @override
  String get notifDinnerBody => 'Czas zapisać kolację';

  @override
  String get notifSnackBody => 'Nie zapomnij zapisać przekąski';

  @override
  String get notifChannelName => 'Przypomnienia o posiłkach';

  @override
  String get notifChannelDesc => 'Przypomnienia, aby zapisać posiłki';

  @override
  String get diaryRecordsForDay => 'Wpisy z dnia';

  @override
  String get diaryViewLabel => 'Widok';

  @override
  String get diaryViewCompact => 'kompaktowy';

  @override
  String get diaryViewExpanded => 'rozszerzony';

  @override
  String get recordsSortNewestFirst => 'Najnowsze najpierw';

  @override
  String get recordsSortOldestFirst => 'Najstarsze najpierw';

  @override
  String get diaryEmptyDay => 'Brak wpisów na ten dzień';

  @override
  String get addMealTitle => 'Dodaj posiłek';

  @override
  String get mealTypeLabel => 'Typ posiłku';

  @override
  String get searchInDb => 'Szukaj w bazie';

  @override
  String get fromGallery => 'Z galerii';

  @override
  String get recognizeByPhoto => 'Rozpoznaj ze zdjęcia';

  @override
  String get productNameOrDish => 'Nazwa produktu lub dania';

  @override
  String get addEntry => 'Dodaj wpis';

  @override
  String get recognizingViaAi => 'Rozpoznaję przez AI...';

  @override
  String get notFoundInDb =>
      'Nie znaleziono w bazie\nNaciśnij ➜ aby rozpoznać przez AI';

  @override
  String get historyTab => 'Ostatnie';

  @override
  String get favoritesTab => 'Ulubione';

  @override
  String get noRecentRecords => 'Brak ostatnich wpisów';

  @override
  String get addMenuRecentEntries => 'Polecane';

  @override
  String get scanBarcodeAction => 'Skanuj kod kreskowy';

  @override
  String get attachPhotoAction => 'Dołącz zdjęcie';

  @override
  String get noFavoriteProducts => 'Brak ulubionych produktów';

  @override
  String get gramsDialogLabel => 'Gramy';

  @override
  String get favoriteUpdated => 'Ulubione zaktualizowane';

  @override
  String get addToFavorite => 'Do ulubionych';

  @override
  String get dayNotYet => 'Ten dzień jeszcze nie nadszedł!';

  @override
  String copyMealTo(String meal) {
    return 'Skopiuj $meal do…';
  }

  @override
  String copiedRecords(int count, String date) {
    return 'Skopiowano $count wpisów do $date';
  }

  @override
  String get dayMon => 'PN';

  @override
  String get dayTue => 'WT';

  @override
  String get dayWed => 'ŚR';

  @override
  String get dayThu => 'CZ';

  @override
  String get dayFri => 'PT';

  @override
  String get daySat => 'SB';

  @override
  String get daySun => 'ND';

  @override
  String get aiAnalyzingPhoto => 'Analizujemy zdjęcie...';

  @override
  String get aiRecognizingIngredients => 'Rozpoznajemy składniki...';

  @override
  String get aiCountingCalories => 'Liczymy kalorie...';

  @override
  String get aiDeterminingMacros => 'Ustalamy makroskładniki...';

  @override
  String get aiAlmostDone => 'Prawie gotowe...';

  @override
  String get aiAnalyzingData => 'Analizujemy dane...';

  @override
  String get aiRecognitionFailed => 'Nie udało się rozpoznać dania';

  @override
  String get aiRecognizingDish => 'Rozpoznajemy danie';

  @override
  String get addDish => 'Dodaj danie';

  @override
  String get dishNameLabel => 'Nazwa';

  @override
  String get dishParameters => 'Parametry dania';

  @override
  String get ingredientsLabel => 'Składniki';

  @override
  String get unknownDish => 'Nieznane danie';

  @override
  String get defaultDishName => 'Danie';

  @override
  String get saveEntry => 'Dodaj wpis';

  @override
  String get saveChanges => 'Zapisz';

  @override
  String get duplicate => 'Duplikuj';

  @override
  String get logEntry => 'Zapisz';

  @override
  String get saveMacros => 'Zapisz makro';

  @override
  String get macrosSavedToast => 'Makroskładniki zapisane';

  @override
  String get updateDish => 'Zaktualizuj danie';

  @override
  String get refineDish => 'Doprecyzuj danie';

  @override
  String get refineDishHint => 'Doprecyzuj danie ...';

  @override
  String get activityWalking => 'Chodzenie';

  @override
  String get activityBicycle => 'Rower';

  @override
  String get activityResting => 'Spoczynek';

  @override
  String approxHours(int count) {
    return '~ $count godz.';
  }

  @override
  String approxMinutes(int count) {
    return '~ $count min';
  }

  @override
  String get healthRatingLabel => 'Wartość zdrowotna';

  @override
  String healthRatingValue(int value) {
    return '$value / 10';
  }

  @override
  String get healthDescPoor =>
      'Dużo kalorii, prostych węglowodanów, tłuszczu lub soli — lepiej jako rzadka przyjemność.';

  @override
  String get healthDescFair =>
      'Smaczne i sycące, ale prawdopodobnie sporo kalorii, prostych węglowodanów, tłuszczu i soli.';

  @override
  String get healthDescGood =>
      'Zbilansowany posiłek z rozsądnymi proporcjami makroskładników.';

  @override
  String get healthDescGreat =>
      'Bogate w składniki odżywcze i zbilansowane — świetny wybór.';

  @override
  String get healthDescVeggie =>
      'Lekkie i pełne wody — dużo mikroelementów na kalorię.';

  @override
  String get healthDescHighProtein =>
      'Z przewagą białka — świetnie syci i wspiera regenerację.';

  @override
  String get healthDescLeanProtein => 'Chude białko — dobra podstawa diety.';

  @override
  String get healthDescBalanced =>
      'Zbilansowane makro — pasuje do większości planów żywieniowych.';

  @override
  String get healthDescCarbHeavy =>
      'Dużo węglowodanów — dodaj białko lub warzywa, by syciło dłużej.';

  @override
  String get healthDescFatHeavy =>
      'Kaloryczne z powodu tłuszczu — pilnuj porcji.';

  @override
  String get healthDescSweet =>
      'Słodkie i kaloryczne — lepiej jako rzadka przyjemność.';

  @override
  String get healthDescUltraProcessed =>
      'Sporo kalorii, mało białka — staraj się nie jeść tego często.';

  @override
  String get healthTraitHighProtein => 'Wyraźnie bogate w białko.';

  @override
  String get healthTraitLowCalDensity => 'Łatwo mieści się w dziennej normie.';

  @override
  String get healthTraitHighFat => 'Kaloryczne za sprawą tłuszczu.';

  @override
  String get healthTraitHighCarb => 'Podstawa to węglowodany.';

  @override
  String get healthTraitBalancedMacros =>
      'Makroskładniki równomiernie rozłożone.';

  @override
  String get healthAdviceGreat => 'Pasuje niemal każdego dnia.';

  @override
  String get healthAdviceGood => 'Trafny wybór na zbilansowany dzień.';

  @override
  String get healthAdviceFair => 'Jedz z umiarem.';

  @override
  String get healthAdvicePoor => 'Lepiej jako rzadka przyjemność.';

  @override
  String get ofYourDailyCalories => 'dziennej normy';

  @override
  String dailyCaloriesPercent(int percent) {
    return '$percent%';
  }

  @override
  String get recognizeDish => 'Rozpoznaj danie';

  @override
  String get photoDetailsHint => 'Opisz dokładniej, jeśli chcesz ...';

  @override
  String get cameraLabel => 'Aparat';

  @override
  String get searchTitle => 'Wyszukiwanie';

  @override
  String get searchHint => 'Szukaj produktów...';

  @override
  String get nothingFound => 'Nic nie znaleziono';

  @override
  String get recognizeViaAi => 'Rozpoznaj przez AI';

  @override
  String get createProduct => 'Utwórz produkt';

  @override
  String get newProduct => 'Nowy produkt';

  @override
  String get basicInfo => 'Podstawowe';

  @override
  String get productNameRequired => 'Nazwa *';

  @override
  String get enterName => 'Wpisz nazwę';

  @override
  String get brandOptional => 'Marka (opcjonalnie)';

  @override
  String get servingWeightG => 'Waga porcji (g)';

  @override
  String get macrosPer100g => 'Makro na 100 g';

  @override
  String get caloriesAutoCalc => 'Obliczy się automatycznie z makro';

  @override
  String get productAdded => 'Produkt dodany';

  @override
  String get saveProduct => 'Zapisz produkt';

  @override
  String get myProductsCategory => 'Moje produkty';

  @override
  String get newRecipe => 'Nowy przepis';

  @override
  String get recipeNameRequired => 'Nazwa przepisu *';

  @override
  String get servingsCount => 'Liczba porcji';

  @override
  String get enterRecipeName => 'Wpisz nazwę przepisu';

  @override
  String get addAtLeastOneIngredient => 'Dodaj co najmniej jeden składnik';

  @override
  String get recipeSaved => 'Przepis zapisany';

  @override
  String get totalForRecipe => 'Razem na cały przepis';

  @override
  String get per100g => 'Na 100 g:';

  @override
  String perServing(int grams) {
    return 'Na porcję ($grams g):';
  }

  @override
  String get ingredientSearchHint => 'Szukaj składnika...';

  @override
  String get startTypingName => 'Zacznij wpisywać nazwę';

  @override
  String get tapAddToSelect => 'Naciśnij „Dodaj”, aby\nwybrać produkty';

  @override
  String ingredientsCount(int count) {
    return 'Składniki ($count)';
  }

  @override
  String get weightLabel => 'Waga';

  @override
  String get favoritesTitle => 'Ulubione';

  @override
  String productAddedToMeal(String name) {
    return '$name dodany';
  }

  @override
  String get historyTitle => 'Historia';

  @override
  String get noRecords => 'Brak wpisów';

  @override
  String get today => 'Dzisiaj';

  @override
  String get yesterday => 'Wczoraj';

  @override
  String get statsTitle => 'Statystyki';

  @override
  String get averageLabel => 'Średnia';

  @override
  String get byDays => 'Dziennie';

  @override
  String get periodWeek => 'Tydzień';

  @override
  String get period2Weeks => '2 tygodnie';

  @override
  String get periodMonth => 'Miesiąc';

  @override
  String totalGrams(int count) {
    return 'Razem $count g';
  }

  @override
  String get noOwnProducts => 'Brak własnych produktów';

  @override
  String get createProductWithMacros => 'Utwórz produkt z podanym makro';

  @override
  String get productLabel => 'Produkt';

  @override
  String get deleteConfirm => 'Usunąć?';

  @override
  String deleteWhat(String what) {
    return 'Usunąć $what?';
  }

  @override
  String get customizeView => 'Dostosuj widok';

  @override
  String get primaryMetric => 'Główna metryka';

  @override
  String get otherMetrics => 'Pozostałe metryki';

  @override
  String get showMore => 'Więcej';

  @override
  String get showLess => 'Ukryj';

  @override
  String get caloriesRemaining => 'Pozostało kalorii';

  @override
  String get dailyEatenLabel => 'Zjedzone';

  @override
  String get dailyGoalLabel => 'Cel';

  @override
  String get openMore => 'Rozwiń';

  @override
  String get goToStatistics => 'Do statystyk';

  @override
  String get goalsParamGoal => 'Cel';

  @override
  String get goalsParamGender => 'Płeć';

  @override
  String get goalsParamAge => 'Wiek';

  @override
  String get goalsParamHeight => 'Wzrost';

  @override
  String get goalsParamWeight => 'Waga';

  @override
  String get goalsParamTargetWeight => 'Waga docelowa';

  @override
  String get goalsParamActivity => 'Aktywność';

  @override
  String get goalsPlanNote => 'Obliczone według Twojego planu';

  @override
  String get goalsCustomNote => 'Własne wartości';

  @override
  String get goalsEditManually => 'Zmień samodzielnie';

  @override
  String get goalsUsePlan => 'Oblicz według planu';

  @override
  String get networkTimeout =>
      'Serwer nie odpowiada. Sprawdź połączenie z internetem.';

  @override
  String get networkSslError => 'Błąd połączenia SSL. Spróbuj później.';

  @override
  String networkConnectionError(String message) {
    return 'Błąd połączenia: $message';
  }

  @override
  String get networkRetryFailed => 'Nie udało się połączyć z serwerem.';

  @override
  String get networkHostLookup =>
      'Serwer chwilowo niedostępny. Sprawdź internet lub spróbuj za chwilę.';

  @override
  String get networkConnectionRefused =>
      'Serwer nie przyjmuje połączeń. Spróbuj później.';

  @override
  String get networkConnectionReset =>
      'Połączenie przerwane. Spróbuj jeszcze raz.';

  @override
  String get networkGenericError =>
      'Błąd sieci. Sprawdź połączenie z internetem.';

  @override
  String get onboardingGenderTitle => 'Wskaż swoją płeć';

  @override
  String get onboardingGenderHint =>
      'Potrzebne do dokładnego obliczenia kalorii';

  @override
  String get genderMale => 'Mężczyzna';

  @override
  String get genderFemale => 'Kobieta';

  @override
  String get onboardingMeasurementsTitle => 'Twoje parametry';

  @override
  String get onboardingUnitsTitle => 'Jednostki miary';

  @override
  String get onboardingUnitsHint => 'Można zmienić później w ustawieniach';

  @override
  String get unitsMetricTitle => 'Metryczne';

  @override
  String get unitsMetricExamples => 'cm, kg, ml';

  @override
  String get unitsImperialTitle => 'Imperialne';

  @override
  String get unitsImperialExamples => 'ft, lb, fl oz';

  @override
  String get onboardingHeightTitle => 'Jaki masz wzrost?';

  @override
  String get onboardingHeightHint =>
      'Potrzebne do obliczenia podstawowej przemiany materii';

  @override
  String get onboardingWeightTitle => 'Ile ważysz?';

  @override
  String get onboardingWeightHint => 'Punkt wyjścia dla Twojego planu';

  @override
  String get heightLabel => 'Wzrost';

  @override
  String get currentWeightLabel => 'Aktualna waga';

  @override
  String get onboardingAgeTitle => 'Kiedy masz urodziny?';

  @override
  String get onboardingAgeHint => 'Wiek wpływa na tempo metabolizmu';

  @override
  String get onboardingGoalTitle => 'Jaki masz cel?';

  @override
  String get onboardingGoalHint => 'Dobierzemy plan żywieniowy do Twojego celu';

  @override
  String get goalLoseWeight => 'Schudnąć';

  @override
  String get goalMaintainWeight => 'Utrzymać wagę';

  @override
  String get goalGainWeight => 'Przybrać na masie';

  @override
  String get onboardingActivityTitle => 'Jak aktywny jesteś?';

  @override
  String get onboardingActivityHint =>
      'Aktywność określa dzienną normę kalorii';

  @override
  String get activitySedentary => 'Mało aktywny';

  @override
  String get activitySedentaryDesc => 'Praca siedząca, mało ruchu';

  @override
  String get activityLight => 'Lekko aktywny';

  @override
  String get activityLightDesc => 'Lekkie treningi 1-3 razy w tygodniu';

  @override
  String get activityModerate => 'Umiarkowanie aktywny';

  @override
  String get activityModerateDesc => 'Treningi 3-5 razy w tygodniu';

  @override
  String get activityHigh => 'Bardzo aktywny';

  @override
  String get activityHighDesc => 'Intensywne treningi 6-7 razy w tygodniu';

  @override
  String get onboardingTargetWeightTitle => 'Jaka waga to Twój cel?';

  @override
  String get onboardingTargetWeightHint =>
      'Obliczymy termin i tempo osiągnięcia';

  @override
  String get onboardingAgeYearsUnit => 'lat';

  @override
  String get onboardingLoadingCalc => 'Analizujemy Twoje odpowiedzi...';

  @override
  String get onboardingLoadingNorm => 'Dostrajamy dzienne cele...';

  @override
  String get onboardingLoadingPlan => 'Tworzymy spersonalizowany plan...';

  @override
  String get onboardingResultTitle => 'Twój spersonalizowany plan';

  @override
  String get resultCongratsTitle => 'Gratulacje!';

  @override
  String get resultCongratsSubtitle =>
      'Twój spersonalizowany plan zdrowotny jest gotowy!';

  @override
  String get resultCanChange => 'To można zmienić w dowolnej chwili';

  @override
  String resultTailoredFromAnswers(int count) {
    return 'Dopasowane na podstawie $count Twoich odpowiedzi';
  }

  @override
  String get resultHowToTitle => 'Jak osiągać cele';

  @override
  String get resultTip1 => 'Zapisuj posiłki — zbuduj zdrowy nawyk!';

  @override
  String get resultTip2 => 'Trzymaj się dziennej rekomendacji kalorii';

  @override
  String get resultTip3 => 'Balansuj węglowodany, białko i tłuszcze';

  @override
  String get resultImprovementsTitle =>
      'Wkrótce zauważysz poprawę samopoczucia';

  @override
  String get resultImprovementsBody =>
      'Niższe ryzyko cukrzycy, niższe ciśnienie, lepszy poziom cholesterolu';

  @override
  String get resultDisclaimer =>
      'Tylko szacunek żywieniowy. To nie porada medyczna.';

  @override
  String get kcalPerDay => 'kcal/dzień';

  @override
  String get weightLossGoalText => 'schudnięcia';

  @override
  String get weightGainGoalText => 'przybrania na masie';

  @override
  String achievableGoal(String goalText) {
    return 'Osiągalny cel $goalText';
  }

  @override
  String weeksToGoal(int weeks, String date) {
    return '$weeks tyg. do celu — do $date';
  }

  @override
  String maintainWeightHint(String weight) {
    return 'Pomożemy Ci utrzymać wagę\nna poziomie $weight kg';
  }

  @override
  String weightWithUnit(String value) {
    return '$value kg';
  }

  @override
  String get onboardingNext => 'Dalej';

  @override
  String get onboardingStart => 'Rozpocznij';

  @override
  String get resultPlanReadyTitle => 'Twój spersonalizowany plan jest gotowy';

  @override
  String get resultHeroSubtitle => 'Na podstawie Twoich odpowiedzi';

  @override
  String get resultRingAdjustLine => 'Liczby można zmienić w dowolnej chwili';

  @override
  String get resultGoalCardTitle => 'Twój cel';

  @override
  String resultGoalMaintainTitle(String weight) {
    return 'Utrzymać wagę około $weight';
  }

  @override
  String get resultGoalMaintainSubtitle =>
      'Bez surowych ograniczeń — codzienna równowaga';

  @override
  String get resultBridgeTitle =>
      'Aby plan działał — trzeba go prowadzić codziennie';

  @override
  String get resultBridgeFreeLine => 'Bezpłatnie — 3 wpisy posiłków na próbę';

  @override
  String get resultBridgePremiumLine => 'Z Premium — bez limitu, aż do celu';

  @override
  String get resultDisclaimerShort => 'Nie zastępuje konsultacji lekarskiej.';

  @override
  String get resultDisclaimerExpand => 'Więcej';

  @override
  String get resultSourcesTitle => 'Źródła';

  @override
  String get resultSourceCaloriesLabel => 'Norma kalorii';

  @override
  String get resultSourceMacrosLabel => 'Rozkład makroskładników';

  @override
  String get resultSourcesCta => 'Źródła i metodologia';

  @override
  String get profileMethodology => 'Źródła i metodologia żywienia';

  @override
  String get profileMethodologyIntro => 'Jak obliczane są Twoje dzienne cele';

  @override
  String get methodologyCaloriesSection => 'Norma kalorii';

  @override
  String get methodologyMacrosSection => 'Cele makroskładników';

  @override
  String get methodologyGeneralSection => 'Ogólne zalecenia żywieniowe';

  @override
  String get methodologySourceMifflinDescription =>
      'Wzór BMR do oszacowania kalorii.';

  @override
  String get methodologySourceDriDescription =>
      'Zakresy referencyjne dla białka, tłuszczu i węglowodanów.';

  @override
  String get methodologySourceUsdaDescription =>
      'Referencje DRI dla kalorii i składników odżywczych.';

  @override
  String get methodologySourceWhoDescription =>
      'Ogólne zalecenia zdrowego odżywiania.';

  @override
  String get methodologyOpenSourceFailed => 'Nie udało się otworzyć źródła.';

  @override
  String get resultOpenPlan => 'Otwórz mój plan';

  @override
  String get socialProofScaleTitle => 'Stworzone do poważnego śledzenia';

  @override
  String get socialProofScaleSubtitle =>
      'Technologia, na której opiera się Twój plan';

  @override
  String get socialProofScaleProductsLabel => 'produktów w naszej bazie';

  @override
  String get socialProofScaleSecondsUnit => 'sek';

  @override
  String get socialProofScaleSpeedLabel => 'Rozpoznawanie dań ze zdjęć';

  @override
  String get socialProofPoweredBy => 'Napędzane przez';

  @override
  String get socialProofAccuracyTitle => 'Zweryfikowane pod kątem dokładności';

  @override
  String get socialProofAccuracySubtitle =>
      'Jak dokładnie AI rozpoznaje Twoje dania';

  @override
  String get socialProofAccuracyLabel => 'Dokładność AI';

  @override
  String get socialProofAccuracyDisclaimer =>
      'Na podstawie wewnętrznej kontroli jakości na 500+ daniach z różnych kuchni świata.';

  @override
  String get socialProofScienceTitle => 'Oparte na nauce o żywieniu';

  @override
  String get socialProofScienceSubtitle =>
      'Twój plan obliczono według sprawdzonego wzoru';

  @override
  String get socialProofScienceFormulaCaption =>
      'Złoty standard żywienia od 1990 roku';

  @override
  String get socialProofScienceTrust =>
      'Używany przez dyplomowanych dietetyków i klinicznych specjalistów żywienia na całym świecie.';

  @override
  String get paywallTitle => 'Wypróbuj Pro\nza darmo';

  @override
  String get paywallWeeklyTitle => 'Odblokuj Pro\njuż dziś';

  @override
  String get paywallWeeklyTimelineTodayTitle => 'Dziś — odblokuj Pro';

  @override
  String get paywallWeeklyTimelineTodayDesc =>
      'Skanowanie AI, dziennik posiłków i analityka bez ograniczeń.';

  @override
  String get paywallWeeklyTimelineRenewTitle => 'Co tydzień — postęp';

  @override
  String get paywallWeeklyTimelineRenewDesc =>
      'Plan odnawia się co tydzień, aby dostęp był nieprzerwany.';

  @override
  String get paywallWeeklyTimelineCancelTitle => 'Anuluj w dowolnej chwili';

  @override
  String get paywallWeeklyTimelineCancelDesc =>
      'Anuluj subskrypcję w ustawieniach konta sklepu.';

  @override
  String get paywallTimelineTodayTitle => 'Dziś — odblokuj Pro';

  @override
  String get paywallTimelineTodayDesc =>
      'Skanowanie AI, dziennik posiłków i analityka bez ograniczeń.';

  @override
  String get paywallTimelineReminderTitle => 'Za 2 dni — przypomnimy';

  @override
  String get paywallTimelineReminderDesc =>
      'Przypomnimy, gdy okres próbny będzie się kończył';

  @override
  String get paywallTimelinePayTitle => 'Za 3 dni — płatność';

  @override
  String paywallTimelinePayDesc(String date) {
    return 'Pobranie nastąpi $date, chyba że anulujesz subskrypcję';
  }

  @override
  String get paywallMonthly => 'Tygodniowo';

  @override
  String get paywallMonthlyPrice => '\$4.99 / tydz.';

  @override
  String get paywallYearly => 'Rocznie';

  @override
  String get paywallYearlyPrice => '\$39.99 / rok';

  @override
  String get paywallPerWeek => 'tydz.';

  @override
  String get paywallPerYear => 'rok';

  @override
  String get paywallTrialBadge => '3 dni za darmo';

  @override
  String get paywallYearlyDiscount => '-85%';

  @override
  String get paywallSubtitle =>
      'Maksimum możliwości i ekskluzywne funkcje z subskrypcją BodyMeal Pro';

  @override
  String get paywallFeatureAiTitle => 'Rozpoznawanie AI';

  @override
  String get paywallFeatureAiDesc =>
      'Zrób zdjęcie — AI w sekundę określi kalorie i składniki.';

  @override
  String get paywallFeatureDiaryTitle => 'Dziennik posiłków';

  @override
  String get paywallFeatureDiaryDesc =>
      'Zapisuj wszystkie posiłki bez ograniczeń, każdego dnia.';

  @override
  String get paywallFeatureAnalyticsTitle => 'Szczegółowa analityka';

  @override
  String get paywallFeatureAnalyticsDesc =>
      'Wykresy kalorii, makro i postępu do Twoich celów za dowolny okres.';

  @override
  String get paywallFeatureBarcodeTitle => 'Skaner kodów kreskowych';

  @override
  String get paywallFeatureBarcodeDesc =>
      'Skieruj aparat na opakowanie — dane pojawią się same.';

  @override
  String get paywallNoPaymentNow => 'Dziś bez płatności';

  @override
  String get paywallStartTrial => 'Rozpocznij okres próbny';

  @override
  String get paywallContinuePro => 'Kontynuuj z Pro';

  @override
  String get paywallSave85 => 'Oszczędność 85%';

  @override
  String paywallDayPrefix(int n) {
    return 'Dzień $n';
  }

  @override
  String get paywallTrialStarts => 'Start okresu próbnego';

  @override
  String get paywallTrialRemindYou => 'Przypomnimy Ci';

  @override
  String get paywallTrialPlanBegins => 'Start planu';

  @override
  String get paywallFeatureSnap => 'Zdjęcie — AI liczy kalorie';

  @override
  String get paywallFeatureScore => 'Ocena zdrowotna każdego dania';

  @override
  String get paywallFeatureTags => 'Tagi dopasowane do Twojego celu';

  @override
  String get paywallFeaturePrivacy =>
      'Szyfrowanie · Bez reklam · Bez sprzedaży danych';

  @override
  String get paywallTrialDisclaimer => '3 dni za darmo, potem \$39.99/rok';

  @override
  String get paywallWeeklyDisclaimer =>
      'Pobranie dzisiaj. Anuluj w dowolnej chwili.';

  @override
  String paywallTrialDisclaimerFmt(String price) {
    return '3 dni za darmo, potem $price/rok';
  }

  @override
  String get paywallRestore => 'Przywróć';

  @override
  String get paywallTerms => 'Warunki';

  @override
  String get paywallPrivacy => 'Prywatność';

  @override
  String get paywallHaveCode => 'Masz kod?';

  @override
  String get promoCodeApply => 'Zastosuj';

  @override
  String get promoCodeInvalid => 'Nieprawidłowy kod';

  @override
  String get paywallSkip => 'Pomiń';

  @override
  String get paywallRestoreSuccess => 'Subskrypcja przywrócona';

  @override
  String get paywallRestoreNotFound => 'Nie znaleziono aktywnych subskrypcji';

  @override
  String get paywallSubscriptionError =>
      'Nie udało się załadować subskrypcji. Spróbuj później.';

  @override
  String get paywallLoadingPrice => 'Ładowanie…';

  @override
  String get paywallErrorTitle => 'Subskrypcja niedostępna';

  @override
  String get paywallTryAgain => 'Spróbuj ponownie';

  @override
  String get paywallErrorStoreUnavailable =>
      'App Store jest obecnie niedostępny. Upewnij się, że jesteś zalogowany w App Store i spróbuj ponownie.';

  @override
  String get paywallErrorProductsEmpty =>
      'Nie udało się załadować wariantów subskrypcji. Sprawdź połączenie i spróbuj ponownie.';

  @override
  String get paywallErrorSelectedProductUnavailable =>
      'Ten wariant subskrypcji jest obecnie niedostępny. Wybierz inny plan lub spróbuj ponownie.';

  @override
  String get paywallErrorQueryFailed =>
      'Nie można połączyć się z App Store. Spróbuj za chwilę.';

  @override
  String get paywallErrorPurchaseFailed =>
      'Nie udało się dokończyć zakupu. Spróbuj ponownie.';

  @override
  String get paywallErrorRestoreFailed =>
      'Nie udało się przywrócić zakupów. Spróbuj ponownie.';

  @override
  String get paywallErrorPaymentPending =>
      'Płatność jest przetwarzana. Otworzymy Pro zaraz po potwierdzeniu.';

  @override
  String get restartOnboarding => 'Zacznij od nowa';

  @override
  String get proActive => 'Aktywna';

  @override
  String get signInToSaveData => 'Zaloguj się, aby zapisać dane';

  @override
  String get dataStoredLocally =>
      'Twoje dane są zapisane tylko na tym urządzeniu';

  @override
  String get barcodeScannerTitle => 'Skaner kodów kreskowych';

  @override
  String get barcodeScanHint => 'Skieruj aparat na kod kreskowy';

  @override
  String get paywallSubscribeNow => 'Wykup subskrypcję';

  @override
  String get paywallGo => 'Rozpocznij';

  @override
  String get paywallHardDisclaimer =>
      'Automatyczne odnawianie. Anuluj w dowolnej chwili.';

  @override
  String get paywallHardTitle => 'Kontynuuj\nz Pro';

  @override
  String freeEntriesRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zostało $count darmowych wpisów',
      many: 'Zostało $count darmowych wpisów',
      few: 'Zostały $count darmowe wpisy',
      one: 'Został 1 darmowy wpis',
    );
    return '$_temp0';
  }

  @override
  String get getPro => 'Odbierz Pro';

  @override
  String get freeLimitReached => 'Darmowe wpisy się skończyły';

  @override
  String get analyticsTitle => 'Analityka';

  @override
  String get summarySection => 'Podsumowanie';

  @override
  String get trendsSection => 'Trendy';

  @override
  String get highlightsSection => 'Najważniejsze';

  @override
  String dayStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dni z rzędu',
      many: 'Dni z rzędu',
      few: 'Dni z rzędu',
      one: 'Dzień z rzędu',
      zero: 'Dni z rzędu',
    );
    return '$_temp0';
  }

  @override
  String get averageADay => 'średnio na dzień';

  @override
  String calDifferenceCount(int count) {
    return 'Różnica $count kcal';
  }

  @override
  String percentAverage(int count) {
    return '$count/100% średniej';
  }

  @override
  String analyticsHighlightHigher(String metric) {
    return 'Średnie dzienne spożycie $metric w tym tygodniu jest wyższe niż w poprzednim.';
  }

  @override
  String analyticsHighlightLower(String metric) {
    return 'Średnie dzienne spożycie $metric w tym tygodniu jest niższe niż w poprzednim.';
  }

  @override
  String analyticsHighlightSimilar(String metric) {
    return 'Średnie dzienne spożycie $metric jest mniej więcej takie samo jak w poprzednim tygodniu.';
  }

  @override
  String get analyticsPeriod1W => '1 T';

  @override
  String get analyticsPeriod2W => '2 T';

  @override
  String get analyticsPeriod1M => '1 M';

  @override
  String get analyticsPeriod3M => '3 M';

  @override
  String get analyticsPeriod6M => '6 M';

  @override
  String get analyticsPeriod1Y => '1 R';

  @override
  String get analyticsMetricCal => 'Kcal';

  @override
  String get analyticsMetricProtein => 'Białko';

  @override
  String get analyticsMetricFat => 'Tłuszcze';

  @override
  String get analyticsMetricCarbs => 'Węgl';

  @override
  String get quantityLabel => 'Ilość';

  @override
  String get addSuggestionsLabel => 'Dodaj składnik';

  @override
  String get suggestionSomethingElse => 'Inne';

  @override
  String get untitledIngredientName => 'Bez nazwy';

  @override
  String get onbObstaclesTitle => 'Co jest dla Ciebie najtrudniejsze?';

  @override
  String get onbObstaclesHint =>
      'Wybierz wszystko, co pasuje — im więcej wiemy, tym dokładniejszy plan.';

  @override
  String onbObstaclesContinue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kontynuuj · wybrano $count',
      zero: 'Wybierz co najmniej jedną opcję',
    );
    return '$_temp0';
  }

  @override
  String get obstacleConsistency => 'Trudno trzymać się planu';

  @override
  String get obstacleKnowledge => 'Nie wiem, co jeść';

  @override
  String get obstacleBusy => 'Zawsze w biegu';

  @override
  String get obstacleCravings => 'Ochota na słodkie i mączne';

  @override
  String get obstacleSupport => 'Bez wsparcia';

  @override
  String get obstacleEatingOut => 'Często jem poza domem';

  @override
  String get obstacleMotivation => 'Brakuje motywacji';

  @override
  String get obstacleTracking => 'Trudno liczyć kalorie';

  @override
  String get obstacleTagConsistency => 'Serie';

  @override
  String get obstacleTagKnowledge => 'Tagi celu';

  @override
  String get obstacleTagBusy => 'Szybko';

  @override
  String get obstacleTagCravings => 'Cukier-alert';

  @override
  String get obstacleTagSupport => 'Przewodnik AI';

  @override
  String get obstacleTagEatingOut => 'Wszędzie';

  @override
  String get obstacleTagMotivation => 'Postęp';

  @override
  String get obstacleTagTracking => 'Bez wpisywania';

  @override
  String get onbSpeedTitleLose => 'Jak szybko chcesz schudnąć?';

  @override
  String get onbSpeedTitleGain => 'Jak szybko chcesz przybrać na masie?';

  @override
  String onbSpeedHintKg(String rate) {
    return 'Zalecane tempo — $rate kg/tydzień';
  }

  @override
  String onbSpeedHintLb(String rate) {
    return 'Zalecane tempo — $rate funtów/tydzień';
  }

  @override
  String onbSpeedKgPerWeek(String value) {
    return '$value kg/tydzień';
  }

  @override
  String onbSpeedLbPerWeek(String value) {
    return '$value funtów/tydzień';
  }

  @override
  String get onbSpeedBadgeGentle => 'Łagodne tempo ✅';

  @override
  String get onbSpeedBadgeRecommended => 'Zalecane tempo ⭐';

  @override
  String get onbSpeedBadgeAmbitious => 'Ambitnie 🔥';

  @override
  String get onbSpeedBadgeAggressive => 'Bardzo agresywnie ⚠️';

  @override
  String onbSpeedTargetByPrefix(String weight) {
    return 'Osiągniesz $weight do';
  }

  @override
  String get onbQuizTitle => 'Opowiedz o swoich nawykach';

  @override
  String get onbQuizHint => 'To pomoże spersonalizować Twój plan';

  @override
  String get quizStressEatingLeft => 'Często jem z powodu stresu';

  @override
  String get quizStressEatingRight => 'Jem tylko dla energii';

  @override
  String get quizSweetPreferenceLeft => 'Lubię słodkie';

  @override
  String get quizSweetPreferenceRight => 'Wolę słone/ostre';

  @override
  String get quizExerciseConsistencyLeft => 'Trenuję regularnie';

  @override
  String get quizExerciseConsistencyRight =>
      'Nie wychodzi mi regularne ćwiczenie';

  @override
  String get quizMealPlanningLeft => 'Planuję posiłki';

  @override
  String get quizMealPlanningRight => 'Jem to, co jest pod ręką';

  @override
  String get quizMotivationTypeLeft => 'Napędzają mnie wyniki';

  @override
  String get quizMotivationTypeRight => 'Napędzają mnie odczucia';

  @override
  String get onbRateTitle => 'Podoba Ci się Twój plan?';

  @override
  String get onbRateSubtitle => 'Oceń Body Meal — to pomoże nam być lepszymi';

  @override
  String get onbRateButton => 'Oceń';

  @override
  String get onbRateSkip => 'Pomiń';

  @override
  String get onbRateFeedbackTitle => 'Co możemy poprawić?';

  @override
  String get onbRateFeedbackHint => 'Powiedz, co się nie podobało';

  @override
  String get onbRateFeedbackSubmit => 'Wyślij';

  @override
  String resultAnchorPrefix(String weight) {
    return 'Osiągniesz $weight do';
  }

  @override
  String resultAnchorWeeksSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '(za $count tygodni)',
      many: '(za $count tygodni)',
      few: '(za $count tygodnie)',
      one: '(za 1 tydzień)',
    );
    return '$_temp0';
  }

  @override
  String resultMaintainCard(String weight) {
    return 'Pomożemy utrzymać wagę na poziomie $weight';
  }

  @override
  String get resultDailyNormLabel => 'TWOJA DZIENNA NORMA';

  @override
  String resultPsychotypeLabel(String title) {
    return 'Twój styl żywienia: $title';
  }

  @override
  String get resultObstaclesHeader => 'Twój plan uwzględnia:';

  @override
  String get resultMilestonesHeader => 'Twój postęp tydzień po tygodniu:';

  @override
  String get resultGoalRow => 'Cel';

  @override
  String resultWeekRow(int week) {
    return 'Tydzień $week';
  }

  @override
  String get resultStartLabel => 'Start';

  @override
  String resultGoalReachLine(String weight) {
    return 'Osiągniesz $weight';
  }

  @override
  String resultGoalByDateLine(String date) {
    return 'do $date';
  }

  @override
  String resultGoalInWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'za $count tygodni',
      many: 'za $count tygodni',
      few: 'za $count tygodnie',
      one: 'za 1 tydzień',
    );
    return '$_temp0';
  }

  @override
  String get resultBenefit5MinDay => 'Zajmuje 5 minut dziennie';

  @override
  String get resultBenefitSmartTracking => 'Inteligentne śledzenie bez wysiłku';

  @override
  String get resultBenefitTailored => 'Menu dopasowane do Twojego stylu życia';

  @override
  String get resultBenefitSustainable => 'Trwały rezultat, a nie dieta';

  @override
  String get resultFaqHeader => 'FAQ';

  @override
  String get resultFaqCancelQ => 'Jak anulować subskrypcję?';

  @override
  String get resultFaqCancelAIos =>
      'Otwórz Ustawienia → Twoje imię → Subskrypcje na iPhone, znajdź Body Meal i naciśnij „Anuluj subskrypcję”.';

  @override
  String get resultFaqCancelAAndroid =>
      'Otwórz Google Play → profil → Płatności i subskrypcje → Subskrypcje, znajdź Body Meal i naciśnij „Anuluj”.';

  @override
  String get resultFaqSecurityQ => 'Czy moje dane są bezpieczne?';

  @override
  String get resultFaqSecurityA =>
      'Dane są szyfrowane podczas przesyłania i przechowywania. Nie przekazujemy ich reklamodawcom, a konto można usunąć w ustawieniach w dowolnej chwili.';

  @override
  String get resultFaqTrialQ => 'Czy jest darmowy okres próbny?';

  @override
  String get resultFaqTrialA =>
      'Tak — okres próbny dostępny jest w planie rocznym. Pobranie nie nastąpi do jego zakończenia, anulować można w dowolnej chwili wcześniej.';

  @override
  String get loadingMetabolism => 'Analizujemy Twój metabolizm...';

  @override
  String get loadingCalories => 'Obliczamy dzienną normę kalorii...';

  @override
  String get loadingMacros =>
      'Dobieramy balans białka / tłuszczu / węglowodanów...';

  @override
  String get loadingPsychotype => 'Analizujemy Twój styl żywienia i nawyki...';

  @override
  String get loadingPlanCreate => 'Tworzymy spersonalizowany plan...';

  @override
  String get psyStressEaterTitle => 'Emocjonalny Smakosz';

  @override
  String get psyStressEaterDesc =>
      'Jesz pod wpływem emocji. Pomożemy znaleźć alternatywy.';

  @override
  String get psyFuelFocusedTitle => 'Racjonalny Smakosz';

  @override
  String get psyFuelFocusedDesc =>
      'Jesteś racjonalny w jedzeniu. Wystarczy precyzyjnie policzyć.';

  @override
  String get psySweetLoverTitle => 'Łasuch';

  @override
  String get psySweetLoverDesc => 'Nauczymy zamieniać słodkie bez wpadek.';

  @override
  String get psySavoryLoverTitle => 'Miłośnik Pikantnego';

  @override
  String get psySavoryLoverDesc =>
      'Ostre i słone — Twój styl. Znajdziemy balans sodu.';

  @override
  String get psyConsistentAthleteTitle => 'Sportowy Profesjonalista';

  @override
  String get psyConsistentAthleteDesc =>
      'Masz mocną bazę. Precyzyjna dieta zwielokrotni wynik.';

  @override
  String get psyInconsistentTitle => 'Bohater Restartu';

  @override
  String get psyInconsistentDesc =>
      'Najważniejsze to zacząć od nowa. Ułatwimy powrót.';

  @override
  String get psyPlannerTitle => 'Planista';

  @override
  String get psyPlannerDesc =>
      'Lubisz kontrolę. Pozwól AI policzyć wszystko za Ciebie.';

  @override
  String get psyConvenienceEaterTitle => 'Smakosz w Biegu';

  @override
  String get psyConvenienceEaterDesc =>
      'Mało czasu — pomożemy wybierać szybko i dobrze.';

  @override
  String get psyResultsDrivenTitle => 'Zorientowany na Cel';

  @override
  String get psyResultsDrivenDesc =>
      'Napędzają Cię liczby. Pokażemy postęp wyraziście.';

  @override
  String get psyFeelingsDrivenTitle => 'Intuicyjny Smakosz';

  @override
  String get psyFeelingsDrivenDesc => 'Słuchasz siebie. Uzupełnimy to danymi.';

  @override
  String get psyBalancedTitle => 'Zrównoważone Podejście';

  @override
  String get psyBalancedDesc =>
      'Masz zdrowe podejście do jedzenia. Wzmocnimy je danymi.';

  @override
  String get onbWelcomeTitle => 'Sfotografuj jedzenie.\nOsiągnij cel.';

  @override
  String get onbWelcomeSubtitle =>
      'AI liczy kalorie, białko, węglowodany i tłuszcze — bez ręcznego wpisywania.';

  @override
  String get onbWelcomeCta => 'Rozpocznij';

  @override
  String get onbWelcomeLabelSalmon => 'Łosoś';

  @override
  String get onbWelcomeLabelEggs => 'Jajka';

  @override
  String get onbWelcomeLabelAvocado => 'Awokado';

  @override
  String get onbWelcomeLabelBread => 'Chleb';

  @override
  String get onbLanguageSheetTitle => 'Wybierz język';

  @override
  String get langShortEn => 'Ang';

  @override
  String get langShortRu => 'Ros';

  @override
  String get langShortDe => 'Niem';

  @override
  String get langShortEs => 'Hisz';

  @override
  String get langShortFr => 'Fr';

  @override
  String get langShortPt => 'Por';

  @override
  String get langShortPl => 'Pol';

  @override
  String get onbConfidentTitle => 'Dziękujemy za zaufanie';

  @override
  String get onbConfidentSubtitle =>
      'Personalizujemy Body Meal specjalnie pod Twoje cele';

  @override
  String get onbConfidentPrivacyTitle => 'Twoja prywatność jest ważna';

  @override
  String get onbConfidentPrivacyBody =>
      'Obiecujemy zachować Twoje dane osobowe w tajemnicy';

  @override
  String get onbKeepResultTitle => 'Schudnij i nie odbij.';

  @override
  String get onbKeepResultSubtitle => 'Dopasowane do Ciebie. Na trwałe.';

  @override
  String get onbCalorieHistoryTitle => 'Czy kiedykolwiek liczyłeś kalorie?';

  @override
  String get onbCalorieHistoryYes => 'Tak, i nadal to robię';

  @override
  String onbCalorieHistoryTried(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Próbowałem, ale zrezygnowałem',
      'female': 'Próbowałam, ale zrezygnowałam',
      'other': 'Próbowałem(am), ale zrezygnowałem(am)',
    });
    return '$_temp0';
  }

  @override
  String get onbCalorieHistoryNever => 'Nie, nigdy';

  @override
  String get onbImproveTitle => 'Co chcesz poprawić?';

  @override
  String get onbImproveLookBetter => 'Wyglądać lepiej';

  @override
  String get onbImproveFeelConfident => 'Czuć się pewniej';

  @override
  String get onbImproveHealth => 'Poprawić zdrowie';

  @override
  String get onbImproveMoreEnergy => 'Więcej energii';

  @override
  String get onbImproveLessStress => 'Mniej stresu';

  @override
  String get onbImproveImmunity => 'Wzmocnić odporność';

  @override
  String get onbImproveFocus => 'Lepsza koncentracja';

  @override
  String get onbImproveSleep => 'Lepszy sen';

  @override
  String get onbEatingObstacleTitle =>
      'Co przeszkadza Ci w zdrowszym jedzeniu?';

  @override
  String get onbEatingObstacleCravings => 'Ochota na słodkie lub niezdrowe';

  @override
  String get onbEatingObstacleLateSnacks => 'Późne przekąski';

  @override
  String get onbEatingObstacleBadHabits => 'Niezdrowe nawyki';

  @override
  String get onbHardestTitle =>
      'Co jest najtrudniejsze — nie poddać się i utrzymać reżim?';

  @override
  String get onbHardestBusy => 'Napięty grafik';

  @override
  String get onbHardestRestrictive => 'Za dużo ograniczeń';

  @override
  String get onbHardestNoSupport => 'Brak wsparcia';

  @override
  String get onbSupportTitle => 'Będziemy z Tobą!';

  @override
  String get onbSupportSubtitle =>
      'Droga do celu bywa trudna, ale będziemy wspierać Cię na każdym kroku.';

  @override
  String get onbSocialProofTitle =>
      'Ze wsparciem ludzie tracą więcej kilogramów i szybciej';

  @override
  String get onbSocialProofSubtitle =>
      'Aplikacja może pomóc Ci osiągnąć trwałe rezultaty w odchudzaniu.';

  @override
  String get onbSpeedSlow => 'Wolno';

  @override
  String get onbSpeedBalanced => 'Zrównoważenie';

  @override
  String get onbSpeedFast => 'Szybko';

  @override
  String onbSpeedGoodTitle(String date) {
    return 'Cel: $date';
  }

  @override
  String get onbSpeedGoodBody =>
      'Rozsądny plan — trwały wynik bez wpadek i plateau.';

  @override
  String get onbSpeedAlertTitle => 'Za szybko — wysokie ryzyko wpadki';

  @override
  String get onbSpeedAlertBody =>
      'Wybierz bardziej zrównoważone tempo, aby dojść do celu bez wpadek.';

  @override
  String get onbTrialReminderTitle =>
      'Wyślemy przypomnienie,\nże okres próbny\nwkrótce się kończy.';

  @override
  String get onbTrialReminderNoPaymentNow => 'Płatność teraz nie jest wymagana';

  @override
  String onbTrialReminderCta(String price) {
    return 'Wypróbuj za $price';
  }

  @override
  String onbTrialReminderSubtitle(String yearly, String monthly) {
    return 'Tylko $yearly rocznie ($monthly / mies.)';
  }

  @override
  String get tagHighProtein => 'Dużo białka';

  @override
  String get tagContainsProtein => 'Zawiera białko';

  @override
  String get tagLowProtein => 'Mało białka';

  @override
  String get tagCompleteProtein => 'Pełnowartościowe białko';

  @override
  String get tagHealthyFats => 'Zdrowe tłuszcze';

  @override
  String get tagRichInOmega3 => 'Omega-3';

  @override
  String get tagHighFat => 'Dużo tłuszczu';

  @override
  String get tagHighSatFat => 'Tłuszcze nasycone';

  @override
  String get tagHighTransFat => 'Tłuszcze trans';

  @override
  String get tagLowFat => 'Mało tłuszczu';

  @override
  String get tagHighFiber => 'Dużo błonnika';

  @override
  String get tagContainsFiber => 'Zawiera błonnik';

  @override
  String get tagLowFiber => 'Mało błonnika';

  @override
  String get tagComplexCarbs => 'Złożone węglowodany';

  @override
  String get tagRefinedCarbs => 'Szybkie węglowodany';

  @override
  String get tagLowSugar => 'Mało cukru';

  @override
  String get tagHighSugar => 'Dużo cukru';

  @override
  String get tagLowCarb => 'Niskowęglowodanowe';

  @override
  String get tagHighCalories => 'Kaloryczne';

  @override
  String get tagLowCalories => 'Niskokaloryczne';

  @override
  String get tagHighEnergy => 'Dużo energii';

  @override
  String get tagHelpsQuota => 'Dopełnia normę';

  @override
  String get tagNutrientDense => 'Odżywcze';

  @override
  String get tagEmptyCalories => 'Puste kalorie';

  @override
  String get tagHeavyMeal => 'Ciężki posiłek';

  @override
  String get tagLightMeal => 'Lekki posiłek';

  @override
  String get tagHighSalt => 'Dużo soli';

  @override
  String get tagLowSalt => 'Mało soli';

  @override
  String get tagHighCholesterol => 'Dużo cholesterolu';

  @override
  String get tagGoodPostWorkout => 'Po treningu';

  @override
  String get tagGoodPreWorkout => 'Przed treningiem';

  @override
  String get tagBreakfastFriendly => 'Dobre na śniadanie';

  @override
  String get tagHeartFriendly => 'Dla serca';

  @override
  String get tagGutFriendly => 'Dla jelit';

  @override
  String get tagBrainFood => 'Dla mózgu';

  @override
  String get tagImmuneBoost => 'Dla odporności';

  @override
  String get tagBoneHealth => 'Dla kości';

  @override
  String get tagRichInVitamins => 'Dużo witamin';

  @override
  String get tagRichInIron => 'Bogate w żelazo';

  @override
  String get tagRichInCalcium => 'Bogate w wapń';

  @override
  String get tagRichInPotassium => 'Bogate w potas';

  @override
  String get tagHighAntioxidants => 'Antyoksydanty';

  @override
  String get tagBalancedMacros => 'Balans makro';

  @override
  String get tagWholeFoods => 'Naturalne produkty';

  @override
  String get tagUltraProcessed => 'Przetworzone';

  @override
  String get tagPlantBased => 'Roślinne';

  @override
  String get tagHydrating => 'Nawadniające';

  @override
  String get forYourGoalLose => 'Cel: Schudnąć';

  @override
  String get forYourGoalMaintain => 'Cel: Utrzymanie';

  @override
  String get forYourGoalGain => 'Cel: Przybranie na masie';

  @override
  String get completeMacroSection => 'Pełne wskaźniki';

  @override
  String get macroSugar => 'Cukier';

  @override
  String get macroFiber => 'Błonnik';

  @override
  String get macroSaturatedFat => 'Tłuszcze nasycone';

  @override
  String get macroCholesterol => 'Cholesterol';

  @override
  String get macroTransFat => 'Tłuszcze trans';

  @override
  String get macroGlycemicLoad => 'Ładunek glikem.';

  @override
  String get macroCaloricDensity => 'Gęstość kalorii';

  @override
  String get macroProcessing => 'Stopień przetworzenia';

  @override
  String get macroVitamins => 'Witaminy i minerały';

  @override
  String get macroStatusWorse => 'Gorzej niż średnio';

  @override
  String get macroStatusAverage => 'Średnio';

  @override
  String get macroStatusGood => 'Świetnie';

  @override
  String macroValueOfDaily(String value, int percent) {
    return '$value · $percent%';
  }

  @override
  String get macroLevelLow => 'Niska';

  @override
  String get macroLevelModerate => 'Średnia';

  @override
  String get macroLevelModerateHigh => 'Średnio-wysoka';

  @override
  String get macroLevelHigh => 'Wysoka';

  @override
  String get macroLevelVeryHigh => 'Bardzo wysoka';

  @override
  String get macroProcessingUnprocessed => 'Nieprzetworzone';

  @override
  String get macroProcessingMinimal => 'Minimalnie';

  @override
  String get macroProcessingProcessed => 'Umiarkowanie';

  @override
  String get macroProcessingUltra => 'Ultra';

  @override
  String get macroMgUnit => 'mg';

  @override
  String get dishWeightLabel => 'Waga dania';

  @override
  String get macroSalt => 'Sól';

  @override
  String get burnSectionTitle => 'Jak spalić kalorie?';

  @override
  String get burnWalking => 'Chodzenie';

  @override
  String get burnRunning => 'Bieg';

  @override
  String get burnGym => 'Trening';

  @override
  String get burnCycling => 'Rower';

  @override
  String get burnResting => 'Spoczynek';

  @override
  String get burnOr => 'lub';

  @override
  String burnApproxSteps(String count) {
    return '~ $count kroków';
  }

  @override
  String burnApproxKm(String count) {
    return '~ $count km';
  }

  @override
  String burnApproxHoursMinutes(int hours, int minutes) {
    return '~ $hours godz. $minutes min';
  }

  @override
  String get aiLoadingPhrase01 => 'Hmm… podejrzanie smaczne.';

  @override
  String get aiLoadingPhrase02 => 'Chwilę, zbadam tę pyszność.';

  @override
  String get aiLoadingPhrase03 => 'Zobaczmy, co kryje talerz.';

  @override
  String get aiLoadingPhrase04 => 'Jedzenie wykryte. Ciekawość włączona.';

  @override
  String get aiLoadingPhrase05 => 'To danie ma tajemnice.';

  @override
  String get aiLoadingPhrase06 => 'Analizuję apetyczną sytuację…';

  @override
  String get aiLoadingPhrase07 => 'Rozwiążę tę pyszną zagadkę.';

  @override
  String get aiLoadingPhrase08 => 'Mały detektyw jedzenia w akcji.';

  @override
  String get aiLoadingPhrase09 => 'Wygląda dobrze. Zbyt dobrze.';

  @override
  String get aiLoadingPhrase10 => 'Skanuję talerz jak dowód.';

  @override
  String get aiLoadingPhrase11 => 'Chwila, śledzę pyszności.';

  @override
  String get aiLoadingPhrase12 => 'Dowiemy się, co tu się dzieje.';

  @override
  String get aiLoadingPhrase13 => 'Widelec poczeka. Najpierw nauka.';

  @override
  String get aiLoadingPhrase14 => 'Sprawdzę, czy jest takie niewinne.';

  @override
  String get aiLoadingPhrase15 => 'Dzieje się coś smacznego…';

  @override
  String get aiLoadingPhrase16 => 'Przybliżam się do apetycznych dowodów.';

  @override
  String get aiLoadingPhrase17 => 'Pełne śledztwo w sprawie przekąski.';

  @override
  String get aiLoadingPhrase18 => 'Czuję kalorie. Metaforycznie.';

  @override
  String get aiLoadingPhrase19 => 'Talerz wszedł w tryb analizy.';

  @override
  String get aiLoadingPhrase20 => 'Czytam gastronomiczne plotki.';

  @override
  String get aiLoadingPhrase21 => 'Szukam makro za tą magią.';

  @override
  String get aiLoadingPhrase22 => 'Hmm… talerz to główny bohater.';

  @override
  String get aiLoadingPhrase23 => 'Z czego zrobiona ta mini-uczta?';

  @override
  String get aiLoadingPhrase24 => 'Liczę cyfry, a nie Twoje danie.';

  @override
  String get aiLoadingPhrase25 => 'Wibracje jedzenia wykryte. Liczymy…';
}
