// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get mealBreakfast => 'Frühstück';

  @override
  String get mealLunch => 'Mittagessen';

  @override
  String get mealDinner => 'Abendessen';

  @override
  String get mealSnack => 'Snack';

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
  String get yearsUnit => 'Geburtsjahr';

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
    return 'Pro 100 g: $cal kcal  E$prot F$fat K$carbs';
  }

  @override
  String get proteinShort => 'E';

  @override
  String get fatShort => 'F';

  @override
  String get carbsShort => 'K';

  @override
  String get proteinLabel => 'Eiweiß';

  @override
  String get fatLabel => 'Fett';

  @override
  String get carbsLabel => 'Kohlenhydrate';

  @override
  String get carbsLabelShort => 'Kohlenh.';

  @override
  String get caloriesLabel => 'Kalorien';

  @override
  String get caloriesKcalLabel => 'Kalorien, kcal';

  @override
  String get proteinGramsLabel => 'Eiweiß, g';

  @override
  String get fatGramsLabel => 'Fett, g';

  @override
  String get carbsGramsLabel => 'Kohlenhydrate, g';

  @override
  String get caloriesKcalInputLabel => 'Kalorien (kcal)';

  @override
  String proteinGoalLabel(int count) {
    return '$count Eiweiß';
  }

  @override
  String fatGoalLabel(int count) {
    return '$count Fett';
  }

  @override
  String carbsGoalLabel(int count) {
    return '$count Kohlenh.';
  }

  @override
  String get profileTitle => 'Profil';

  @override
  String get myProfile => 'Mein Profil';

  @override
  String get subscription => 'Abonnement';

  @override
  String get myGoals => 'Meine Ziele';

  @override
  String get myProducts => 'Meine Produkte';

  @override
  String get settings => 'Einstellungen';

  @override
  String get productsList => 'Produktliste';

  @override
  String get allProducts => 'Alle';

  @override
  String get appTheme => 'App-Design';

  @override
  String get languageSelector => 'Sprache der Benutzeroberfläche';

  @override
  String get pushNotifications => 'Push-Benachrichtigungen';

  @override
  String get pushNotificationsShortOn => 'An';

  @override
  String get pushNotificationsShortOff => 'Aus';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get signOut => 'Abmelden';

  @override
  String get signOutConfirm => 'Vom Konto abmelden?';

  @override
  String get signOutLocalDataKept =>
      'Lokale Daten bleiben auf dem Gerät gespeichert.';

  @override
  String get deleteAccount => 'Account löschen';

  @override
  String get deleteAccountConfirmTitle => 'Account löschen?';

  @override
  String get deleteAccountConfirmMessage =>
      'Dadurch wird Ihr Account dauerhaft gelöscht. Mahlzeitenverlauf, Rezepte, Produkte, Favoriten und Einstellungen werden von diesem Gerät entfernt. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get deleteAccountFinalConfirmTitle => 'Sind Sie absolut sicher?';

  @override
  String get deleteAccountFinalConfirmMessage =>
      'Ihr Account und Ihre Daten werden dauerhaft gelöscht.';

  @override
  String get deleteAccountSuccess => 'Ihr Account wurde gelöscht.';

  @override
  String get deleteAccountFailed =>
      'Der Account konnte nicht gelöscht werden. Bitte prüfen Sie Ihre Verbindung und versuchen Sie es erneut.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get save => 'Speichern';

  @override
  String get add => 'Hinzufügen';

  @override
  String get close => 'Schließen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get guestMode => 'Gastmodus';

  @override
  String get defaultUserName => 'Benutzer';

  @override
  String get signedInSnackbar => 'Erfolgreich angemeldet';

  @override
  String get signInTitle => 'In Konto einloggen';

  @override
  String get signInGoogle => 'Mit Google anmelden';

  @override
  String get signInApple => 'Mit Apple anmelden';

  @override
  String get signInEmail => 'Mit E-Mail anmelden';

  @override
  String get startOverOnboarding => 'Von vorne beginnen';

  @override
  String get startOverOnboardingConfirm => 'Onboarding von Anfang an starten?';

  @override
  String get startOverOnboardingHint =>
      'Ihre Angaben im Fragebogen werden zurückgesetzt. Tagebuchdaten auf diesem Gerät bleiben erhalten.';

  @override
  String get skipLogin => 'Ohne Anmeldung fortfahren';

  @override
  String get signInSyncHint =>
      'Mit Anmeldung können Sie Daten\nzwischen Geräten synchronisieren';

  @override
  String get calorieTracking => 'Ernährungs- & Kalorienverfolgung';

  @override
  String get mergeLocalDataTitle => 'Aktuelle Daten in dein Konto übertragen?';

  @override
  String get mergeLocalDataKeep => 'Übertragen';

  @override
  String get mergeLocalDataReplace => 'So lassen';

  @override
  String get loginSyncing => 'Synchronisiere…';

  @override
  String get loginSyncFailed =>
      'Daten konnten nicht synchronisiert werden. Bitte später erneut versuchen.';

  @override
  String get loginTitle => 'Anmelden';

  @override
  String get registerTitle => 'Registrieren';

  @override
  String get nameOptional => 'Name (optional)';

  @override
  String get enterEmail => 'E-Mail eingeben';

  @override
  String get invalidEmail => 'Ungültige E-Mail';

  @override
  String get passwordLabel => 'Passwort';

  @override
  String get enterPassword => 'Passwort eingeben';

  @override
  String get minPasswordLength => 'Mindestens 6 Zeichen';

  @override
  String get signInButton => 'Anmelden';

  @override
  String get registerButton => 'Registrieren';

  @override
  String get switchToLogin => 'Beim Konto anmelden';

  @override
  String get wrongCredentials => 'Falsche E-Mail oder Passwort';

  @override
  String signInError(String error) {
    return 'Anmeldefehler: $error';
  }

  @override
  String get emailAlreadyRegistered => 'Diese E-Mail ist bereits registriert';

  @override
  String registerError(String error) {
    return 'Registrierungsfehler: $error';
  }

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get resetPasswordTitle => 'Passwort zurücksetzen';

  @override
  String get resetPasswordHint =>
      'Geben Sie die E-Mail-Adresse ein, mit der Sie sich registriert haben. Wir senden Ihnen einen 6-stelligen Code.';

  @override
  String get sendResetCode => 'Code senden';

  @override
  String get enterCodeTitle => 'Code eingeben';

  @override
  String resetCodeSentTo(String email) {
    return 'Wir haben einen 6-stelligen Code an $email gesendet';
  }

  @override
  String get enterSixDigitCode => '6-stelligen Code eingeben';

  @override
  String get verifyCode => 'Bestätigen';

  @override
  String get resendCode => 'Code erneut senden';

  @override
  String resendCodeIn(int seconds) {
    return 'Erneut in $seconds Sek.';
  }

  @override
  String get resetCodeResent => 'Code erneut gesendet';

  @override
  String get newPasswordTitle => 'Neues Passwort';

  @override
  String get newPasswordHint =>
      'Erstellen Sie ein neues Passwort für Ihr Konto.';

  @override
  String get newPasswordLabel => 'Neues Passwort';

  @override
  String get confirmPasswordLabel => 'Passwort bestätigen';

  @override
  String get passwordsDoNotMatch => 'Passwörter stimmen nicht überein';

  @override
  String get resetPasswordButton => 'Passwort zurücksetzen';

  @override
  String get passwordResetSuccess =>
      'Passwort erfolgreich zurückgesetzt. Melden Sie sich mit Ihrem neuen Passwort an.';

  @override
  String get emailNotFound => 'Kein Konto mit dieser E-Mail';

  @override
  String get invalidResetCode => 'Ungültiger oder abgelaufener Code';

  @override
  String get proTitle => 'MealTracker Pro';

  @override
  String get proUnlockFeatures => 'Alle Funktionen freischalten:';

  @override
  String get proAiUnlimited => 'Unbegrenzte KI-Erkennung';

  @override
  String get proExtendedStats => 'Erweiterte Statistiken';

  @override
  String get proPersonalRecommendations => 'Persönliche Empfehlungen';

  @override
  String get proTryFree => 'Kostenlos testen';

  @override
  String get planLabel => 'Abo:';

  @override
  String get planWeekly => 'Wöchentlich';

  @override
  String get planYearly => 'Jährlich';

  @override
  String get billingLabel => 'Nächste Abrechnung:';

  @override
  String get manageSubscription => 'Abonnement verwalten';

  @override
  String get goalCaloriesKcal => 'Kalorien, kcal';

  @override
  String get goalProteinG => 'Eiweiß, g';

  @override
  String get goalFatG => 'Fett, g';

  @override
  String get goalCarbsG => 'Kohlenhydrate, g';

  @override
  String get remindersTitle => 'Erinnerungen';

  @override
  String get reminderOff => 'Aus';

  @override
  String get remindersDescription =>
      'Erinnerungen werden täglich zur festgelegten Uhrzeit gesendet, damit Sie nicht vergessen, Ihre Mahlzeiten zu erfassen.';

  @override
  String get notifBreakfastBody => 'Zeit, das Frühstück zu erfassen';

  @override
  String get notifLunchBody => 'Zeit, das Mittagessen zu erfassen';

  @override
  String get notifDinnerBody => 'Zeit, das Abendessen zu erfassen';

  @override
  String get notifSnackBody => 'Vergessen Sie nicht, Ihren Snack zu erfassen';

  @override
  String get notifChannelName => 'Mahlzeit-Erinnerungen';

  @override
  String get notifChannelDesc => 'Erinnerungen zur Mahlzeitenerfassung';

  @override
  String get diaryRecordsForDay => 'Heutige Einträge';

  @override
  String get diaryViewLabel => 'Ansicht';

  @override
  String get diaryViewCompact => 'kompakt';

  @override
  String get diaryViewExpanded => 'erweitert';

  @override
  String get recordsSortNewestFirst => 'Neueste zuerst';

  @override
  String get recordsSortOldestFirst => 'Älteste zuerst';

  @override
  String get diaryEmptyDay => 'Noch keine Einträge für diesen Tag';

  @override
  String get addMealTitle => 'Mahlzeit hinzufügen';

  @override
  String get mealTypeLabel => 'Mahlzeittyp';

  @override
  String get searchInDb => 'In Datenbank suchen';

  @override
  String get fromGallery => 'Aus der Galerie';

  @override
  String get recognizeByPhoto => 'Per Foto erkennen';

  @override
  String get productNameOrDish => 'Produkt- oder Gerichtname';

  @override
  String get addEntry => 'Eintrag hinzufügen';

  @override
  String get recognizingViaAi => 'Erkennung per KI...';

  @override
  String get notFoundInDb =>
      'Nicht in der Datenbank gefunden\nTippen Sie ➜ zur KI-Erkennung';

  @override
  String get historyTab => 'Kürzlich';

  @override
  String get favoritesTab => 'Favoriten';

  @override
  String get noRecentRecords => 'Keine kürzlichen Einträge';

  @override
  String get addMenuRecentEntries => 'Empfohlen';

  @override
  String get scanBarcodeAction => 'Barcode scannen';

  @override
  String get attachPhotoAction => 'Foto anhängen';

  @override
  String get noFavoriteProducts => 'Keine Lieblingsprodukte';

  @override
  String get gramsDialogLabel => 'Gramm';

  @override
  String get favoriteUpdated => 'Favoriten aktualisiert';

  @override
  String get addToFavorite => 'Zu Favoriten hinzufügen';

  @override
  String get dayNotYet => 'Dieser Tag ist noch nicht gekommen!';

  @override
  String copyMealTo(String meal) {
    return '$meal kopieren nach…';
  }

  @override
  String copiedRecords(int count, String date) {
    return '$count Einträge nach $date kopiert';
  }

  @override
  String get dayMon => 'MO';

  @override
  String get dayTue => 'DI';

  @override
  String get dayWed => 'MI';

  @override
  String get dayThu => 'DO';

  @override
  String get dayFri => 'FR';

  @override
  String get daySat => 'SA';

  @override
  String get daySun => 'SO';

  @override
  String get aiAnalyzingPhoto => 'Foto wird analysiert...';

  @override
  String get aiRecognizingIngredients => 'Zutaten werden erkannt...';

  @override
  String get aiCountingCalories => 'Kalorien werden berechnet...';

  @override
  String get aiDeterminingMacros => 'Makros werden bestimmt...';

  @override
  String get aiAlmostDone => 'Fast fertig...';

  @override
  String get aiAnalyzingData => 'Daten werden analysiert...';

  @override
  String get aiRecognitionFailed => 'Das Gericht konnte nicht erkannt werden';

  @override
  String get aiRecognizingDish => 'Gericht wird erkannt';

  @override
  String get addDish => 'Gericht hinzufügen';

  @override
  String get dishNameLabel => 'Name';

  @override
  String get dishParameters => 'Gerichtparameter';

  @override
  String get ingredientsLabel => 'Zutaten';

  @override
  String get unknownDish => 'Unbekanntes Gericht';

  @override
  String get defaultDishName => 'Gericht';

  @override
  String get saveEntry => 'Eintrag hinzufügen';

  @override
  String get saveChanges => 'Speichern';

  @override
  String get logEntry => 'Eintragen';

  @override
  String get saveMacros => 'Makros speichern';

  @override
  String get macrosSavedToast => 'Makros gespeichert';

  @override
  String get updateDish => 'Gericht aktualisieren';

  @override
  String get refineDish => 'Gericht präzisieren';

  @override
  String get refineDishHint => 'Gericht präzisieren ...';

  @override
  String get activityWalking => 'Gehen';

  @override
  String get activityBicycle => 'Radfahren';

  @override
  String get activityResting => 'Ruhe';

  @override
  String approxHours(int count) {
    return '~ $count h';
  }

  @override
  String approxMinutes(int count) {
    return '~ $count Min.';
  }

  @override
  String get healthRatingLabel => 'Bewertung';

  @override
  String healthRatingValue(int value) {
    return '$value / 10';
  }

  @override
  String get healthDescPoor =>
      'Viele Kalorien, einfache Kohlenhydrate, Fett oder Salz — besser nur gelegentlich.';

  @override
  String get healthDescFair =>
      'Lecker und sättigend, vermutlich aber kalorien-, fett- und salzreich.';

  @override
  String get healthDescGood =>
      'Ausgewogene Mahlzeit mit guter Makronährstoff-Mischung.';

  @override
  String get healthDescGreat =>
      'Nährstoffreich und ausgewogen — eine sehr gute Wahl.';

  @override
  String get healthDescVeggie =>
      'Leicht und wasserreich — viele Mikronährstoffe pro Kalorie.';

  @override
  String get healthDescHighProtein =>
      'Eiweißbetont — sehr sättigend und gut für die Regeneration.';

  @override
  String get healthDescLeanProtein => 'Mageres Eiweiß — eine starke Grundlage.';

  @override
  String get healthDescBalanced =>
      'Ausgewogene Makros — passt in die meisten Pläne.';

  @override
  String get healthDescCarbHeavy =>
      'Kohlenhydrat-lastig — mit Eiweiß oder Gemüse kombinieren.';

  @override
  String get healthDescFatHeavy =>
      'Kalorienreich durch Fett — auf die Portion achten.';

  @override
  String get healthDescSweet => 'Süß und energiereich — lieber selten essen.';

  @override
  String get healthDescUltraProcessed =>
      'Viele Kalorien, wenig Eiweiß — selten essen.';

  @override
  String get healthTraitHighProtein => 'Besonders eiweißreich.';

  @override
  String get healthTraitLowCalDensity => 'Passt locker ins Tagesbudget.';

  @override
  String get healthTraitHighFat => 'Kalorisch durch Fett.';

  @override
  String get healthTraitHighCarb => 'Vor allem Kohlenhydrate.';

  @override
  String get healthTraitBalancedMacros => 'Makros sind gleichmäßig verteilt.';

  @override
  String get healthAdviceGreat => 'Passt gut zu fast jedem Tag.';

  @override
  String get healthAdviceGood => 'Solide Wahl für einen ausgewogenen Tag.';

  @override
  String get healthAdviceFair => 'In Maßen genießen.';

  @override
  String get healthAdvicePoor => 'Lieber nur gelegentlich.';

  @override
  String get ofYourDailyCalories => 'von deiner Tagesmenge';

  @override
  String dailyCaloriesPercent(int percent) {
    return '$percent%';
  }

  @override
  String get recognizeDish => 'Gericht erkennen';

  @override
  String get photoDetailsHint =>
      'Beschreiben Sie es genauer, wenn Sie möchten ...';

  @override
  String get cameraLabel => 'Kamera';

  @override
  String get searchTitle => 'Suche';

  @override
  String get searchHint => 'Produkte suchen...';

  @override
  String get nothingFound => 'Nichts gefunden';

  @override
  String get recognizeViaAi => 'Per KI erkennen';

  @override
  String get createProduct => 'Produkt erstellen';

  @override
  String get newProduct => 'Neues Produkt';

  @override
  String get basicInfo => 'Grundinformationen';

  @override
  String get productNameRequired => 'Name *';

  @override
  String get enterName => 'Name eingeben';

  @override
  String get brandOptional => 'Marke (optional)';

  @override
  String get servingWeightG => 'Portionsgewicht (g)';

  @override
  String get macrosPer100g => 'Nährwerte pro 100 g';

  @override
  String get caloriesAutoCalc => 'Automatisch aus Makros berechnet';

  @override
  String get productAdded => 'Produkt hinzugefügt';

  @override
  String get saveProduct => 'Produkt speichern';

  @override
  String get myProductsCategory => 'Meine Produkte';

  @override
  String get newRecipe => 'Neues Rezept';

  @override
  String get recipeNameRequired => 'Rezeptname *';

  @override
  String get servingsCount => 'Anzahl der Portionen';

  @override
  String get enterRecipeName => 'Rezeptname eingeben';

  @override
  String get addAtLeastOneIngredient => 'Mindestens eine Zutat hinzufügen';

  @override
  String get recipeSaved => 'Rezept gespeichert';

  @override
  String get totalForRecipe => 'Gesamt für Rezept';

  @override
  String get per100g => 'Pro 100 g:';

  @override
  String perServing(int grams) {
    return 'Pro Portion ($grams g):';
  }

  @override
  String get ingredientSearchHint => 'Zutat suchen...';

  @override
  String get startTypingName => 'Beginnen Sie mit der Eingabe';

  @override
  String get tapAddToSelect =>
      'Tippen Sie auf Hinzufügen,\num Produkte auszuwählen';

  @override
  String ingredientsCount(int count) {
    return 'Zutaten ($count)';
  }

  @override
  String get weightLabel => 'Gewicht';

  @override
  String get favoritesTitle => 'Favoriten';

  @override
  String productAddedToMeal(String name) {
    return '$name hinzugefügt';
  }

  @override
  String get historyTitle => 'Verlauf';

  @override
  String get noRecords => 'Keine Einträge';

  @override
  String get today => 'Heute';

  @override
  String get yesterday => 'Gestern';

  @override
  String get statsTitle => 'Statistiken';

  @override
  String get averageLabel => 'Durchschnitt';

  @override
  String get byDays => 'Nach Tagen';

  @override
  String get periodWeek => 'Woche';

  @override
  String get period2Weeks => '2 Wochen';

  @override
  String get periodMonth => 'Monat';

  @override
  String totalGrams(int count) {
    return 'Gesamt $count g';
  }

  @override
  String get noOwnProducts => 'Keine eigenen Produkte';

  @override
  String get createProductWithMacros => 'Produkt mit Nährwerten erstellen';

  @override
  String get productLabel => 'Produkt';

  @override
  String get deleteConfirm => 'Löschen?';

  @override
  String deleteWhat(String what) {
    return '$what löschen?';
  }

  @override
  String get customizeView => 'Ansicht anpassen';

  @override
  String get primaryMetric => 'Hauptmetrik';

  @override
  String get otherMetrics => 'Weitere Metriken';

  @override
  String get showMore => 'Mehr anzeigen';

  @override
  String get showLess => 'Weniger anzeigen';

  @override
  String get caloriesRemaining => 'Kalorien übrig';

  @override
  String get dailyEatenLabel => 'Gegessen';

  @override
  String get dailyGoalLabel => 'Ziel';

  @override
  String get openMore => 'Mehr anzeigen';

  @override
  String get goToStatistics => 'Zur Statistik';

  @override
  String get goalsParamGoal => 'Ziel';

  @override
  String get goalsParamGender => 'Geschlecht';

  @override
  String get goalsParamAge => 'Alter';

  @override
  String get goalsParamHeight => 'Größe';

  @override
  String get goalsParamWeight => 'Gewicht';

  @override
  String get goalsParamTargetWeight => 'Zielgewicht';

  @override
  String get goalsParamActivity => 'Aktivität';

  @override
  String get goalsPlanNote => 'Basierend auf deinem Plan';

  @override
  String get goalsCustomNote => 'Eigene Werte';

  @override
  String get goalsEditManually => 'Manuell bearbeiten';

  @override
  String get goalsUsePlan => 'Aus Plan berechnen';

  @override
  String get networkTimeout =>
      'Server antwortet nicht. Überprüfen Sie Ihre Internetverbindung.';

  @override
  String get networkSslError =>
      'SSL-Verbindungsfehler. Versuchen Sie es später erneut.';

  @override
  String networkConnectionError(String message) {
    return 'Verbindungsfehler: $message';
  }

  @override
  String get networkRetryFailed => 'Server konnte nicht erreicht werden.';

  @override
  String get networkHostLookup =>
      'Server vorübergehend nicht erreichbar. Überprüfen Sie das Internet oder versuchen Sie es in einer Minute.';

  @override
  String get networkConnectionRefused =>
      'Server nimmt keine Verbindungen an. Versuchen Sie es später erneut.';

  @override
  String get networkConnectionReset =>
      'Verbindung unterbrochen. Versuchen Sie es erneut.';

  @override
  String get networkGenericError =>
      'Netzwerkfehler. Überprüfen Sie Ihre Internetverbindung.';

  @override
  String get onboardingGenderTitle => 'Wählen Sie Ihr Geschlecht';

  @override
  String get onboardingGenderHint =>
      'Wird für eine genaue Kalorienberechnung benötigt';

  @override
  String get genderMale => 'Männlich';

  @override
  String get genderFemale => 'Weiblich';

  @override
  String get onboardingMeasurementsTitle => 'Ihre Maße';

  @override
  String get onboardingUnitsTitle => 'Maßeinheiten';

  @override
  String get onboardingUnitsHint =>
      'Kann später in den Einstellungen geändert werden';

  @override
  String get unitsMetricTitle => 'Metrisch';

  @override
  String get unitsMetricExamples => 'cm, kg, ml';

  @override
  String get unitsImperialTitle => 'Imperial';

  @override
  String get unitsImperialExamples => 'ft, lb, fl oz';

  @override
  String get onboardingHeightTitle => 'Wie groß sind Sie?';

  @override
  String get onboardingHeightHint =>
      'Wird für die Berechnung des Grundumsatzes benötigt';

  @override
  String get onboardingWeightTitle => 'Wie viel wiegen Sie?';

  @override
  String get onboardingWeightHint => 'Der Ausgangspunkt für Ihren Plan';

  @override
  String get heightLabel => 'Größe';

  @override
  String get currentWeightLabel => 'Aktuelles Gewicht';

  @override
  String get onboardingAgeTitle => 'Wann haben Sie Geburtstag?';

  @override
  String get onboardingAgeHint => 'Das Alter beeinflusst Ihren Stoffwechsel';

  @override
  String get onboardingGoalTitle => 'Was ist Ihr Ziel?';

  @override
  String get onboardingGoalHint =>
      'Wir erstellen einen passenden Ernährungsplan';

  @override
  String get goalLoseWeight => 'Abnehmen';

  @override
  String get goalMaintainWeight => 'Gewicht halten';

  @override
  String get goalGainWeight => 'Muskeln aufbauen';

  @override
  String get onboardingActivityTitle => 'Wie aktiv sind Sie?';

  @override
  String get onboardingActivityHint =>
      'Aktivität bestimmt Ihren täglichen Kalorienbedarf';

  @override
  String get activitySedentary => 'Sitzend';

  @override
  String get activitySedentaryDesc => 'Bürojob, wenig Bewegung';

  @override
  String get activityLight => 'Leicht aktiv';

  @override
  String get activityLightDesc => 'Leichtes Training 1–3 Mal pro Woche';

  @override
  String get activityModerate => 'Mäßig aktiv';

  @override
  String get activityModerateDesc => 'Training 3–5 Mal pro Woche';

  @override
  String get activityHigh => 'Sehr aktiv';

  @override
  String get activityHighDesc => 'Intensives Training 6–7 Mal pro Woche';

  @override
  String get onboardingTargetWeightTitle => 'Was ist Ihr Zielgewicht?';

  @override
  String get onboardingTargetWeightHint => 'Wir berechnen Zeitrahmen und Tempo';

  @override
  String get onboardingAgeYearsUnit => 'Jahre';

  @override
  String get onboardingLoadingCalc => 'Ihre Antworten werden ausgewertet...';

  @override
  String get onboardingLoadingNorm => 'Tägliche Ziele werden eingerichtet...';

  @override
  String get onboardingLoadingPlan => 'Ihr persönlicher Plan wird erstellt...';

  @override
  String get onboardingResultTitle => 'Ihr persönlicher Plan';

  @override
  String get resultCongratsTitle => 'Herzlichen Glückwunsch!';

  @override
  String get resultCongratsSubtitle =>
      'Ihr persönlicher Gesundheitsplan ist fertig!';

  @override
  String get resultCanChange => 'Sie können dies jederzeit ändern';

  @override
  String get resultHowToTitle => 'So erreichen Sie Ihre Ziele';

  @override
  String get resultTip1 =>
      'Führen Sie ein Ernährungstagebuch — entwickeln Sie gesunde Gewohnheiten!';

  @override
  String get resultTip2 => 'Folgen Sie der täglichen Kalorienempfehlung';

  @override
  String get resultTip3 => 'Balancieren Sie Kohlenhydrate, Protein und Fette';

  @override
  String get resultImprovementsTitle =>
      'Sie werden bald Verbesserungen bemerken';

  @override
  String get resultImprovementsBody =>
      'Geringeres Diabetesrisiko, niedrigerer Blutdruck, bessere Cholesterinwerte';

  @override
  String get resultDisclaimer =>
      'Nur Ernährungsschätzungen. Keine medizinische Beratung.';

  @override
  String get kcalPerDay => 'kcal/Tag';

  @override
  String get weightLossGoalText => 'Abnehmen';

  @override
  String get weightGainGoalText => 'Muskelaufbau';

  @override
  String achievableGoal(String goalText) {
    return 'Erreichbares Ziel: $goalText';
  }

  @override
  String weeksToGoal(int weeks, String date) {
    return '$weeks Wochen bis zum Ziel — bis $date';
  }

  @override
  String maintainWeightHint(String weight) {
    return 'Wir helfen Ihnen, Ihr Gewicht\nbei $weight kg zu halten';
  }

  @override
  String weightWithUnit(String value) {
    return '$value kg';
  }

  @override
  String get onboardingNext => 'Weiter';

  @override
  String get onboardingStart => 'Starten';

  @override
  String get resultPlanReadyTitle => 'Ihr persönlicher Plan ist fertig';

  @override
  String get resultHeroSubtitle =>
      'Wir haben Empfehlungen basierend auf Ihren Antworten zusammengestellt';

  @override
  String get resultRingAdjustLine =>
      'Sie können diese Werte jederzeit anpassen';

  @override
  String get resultGoalCardTitle => 'Ihr Ziel';

  @override
  String resultGoalMaintainTitle(String weight) {
    return 'Gewicht bei etwa $weight halten';
  }

  @override
  String get resultGoalMaintainSubtitle =>
      'Keine strengen Einschränkungen — die tägliche Balance zählt';

  @override
  String get resultBridgeTitle =>
      'Damit der Plan funktioniert, müssen Sie täglich tracken';

  @override
  String get resultBridgeFreeLine =>
      'Kostenlos — 3 Mahlzeiten-Einträge zum Ausprobieren';

  @override
  String get resultBridgePremiumLine =>
      'Mit Premium — ohne Limits, bis zu Ihrem Ziel';

  @override
  String get resultDisclaimerShort =>
      'Empfehlungen ersetzen keinen ärztlichen Rat';

  @override
  String get resultDisclaimerExpand => 'Mehr erfahren';

  @override
  String get resultSourcesTitle => 'Quellen';

  @override
  String get resultSourceCaloriesLabel => 'Kalorienziel';

  @override
  String get resultSourceMacrosLabel => 'Makronährstoffverteilung';

  @override
  String get resultSourcesCta => 'Quellen und Methodik';

  @override
  String get profileMethodology => 'Ernährungsquellen & Methodik';

  @override
  String get profileMethodologyIntro =>
      'Wie Ihre täglichen Ziele geschätzt werden';

  @override
  String get methodologyCaloriesSection => 'Kalorienziel';

  @override
  String get methodologyMacrosSection => 'Makronährstoffziele';

  @override
  String get methodologyGeneralSection => 'Allgemeine Ernährungsempfehlungen';

  @override
  String get methodologySourceMifflinDescription =>
      'BMR-Formel für Kalorienschätzungen.';

  @override
  String get methodologySourceDriDescription =>
      'Referenzbereiche für Protein, Fett und Kohlenhydrate.';

  @override
  String get methodologySourceUsdaDescription =>
      'DRI-Referenzen für Kalorien und Nährstoffe.';

  @override
  String get methodologySourceWhoDescription =>
      'Allgemeine Empfehlungen für gesunde Ernährung.';

  @override
  String get methodologyOpenSourceFailed =>
      'Diese Quelle konnte nicht geöffnet werden.';

  @override
  String get resultOpenPlan => 'Meinen Plan öffnen';

  @override
  String get socialProofScaleTitle => 'Für ernsthaftes Tracking entwickelt';

  @override
  String get socialProofScaleSubtitle => 'Die Technologie hinter Ihrem Plan';

  @override
  String get socialProofScaleProductsLabel => 'Produkte in unserer Datenbank';

  @override
  String get socialProofScaleSecondsUnit => 'Sek.';

  @override
  String get socialProofScaleSpeedLabel => 'KI-Fotoerkennung';

  @override
  String get socialProofPoweredBy => 'Powered by';

  @override
  String get socialProofAccuracyTitle => 'Auf Genauigkeit geprüft';

  @override
  String get socialProofAccuracySubtitle =>
      'Wie genau unsere KI Ihre Mahlzeiten erkennt';

  @override
  String get socialProofAccuracyLabel => 'KI-Genauigkeit';

  @override
  String get socialProofAccuracyDisclaimer =>
      'Basierend auf interner Qualitätsprüfung mit über 500 Gerichten aus verschiedenen Küchen.';

  @override
  String get socialProofScienceTitle => 'Wissenschaftlich fundiert';

  @override
  String get socialProofScienceSubtitle =>
      'Ihr Plan basiert auf einer bewährten Formel';

  @override
  String get socialProofScienceFormulaCaption =>
      'Goldstandard der Ernährungswissenschaft seit 1990';

  @override
  String get socialProofScienceTrust =>
      'Wird weltweit von Diätassistenten und klinischen Ernährungsberatern genutzt.';

  @override
  String get paywallTitle => 'Pro kostenlos\ntesten';

  @override
  String get paywallWeeklyTitle => 'Pro heute\nfreischalten';

  @override
  String get paywallWeeklyTimelineTodayTitle => 'Heute — Pro freischalten';

  @override
  String get paywallWeeklyTimelineTodayDesc =>
      'KI-Scan, Mahlzeiten-Tracking und Analysen ohne Limits.';

  @override
  String get paywallWeeklyTimelineRenewTitle => 'Wöchentlich — Fortschritt';

  @override
  String get paywallWeeklyTimelineRenewDesc =>
      'Wöchentlich verlängert, damit der Zugriff bleibt.';

  @override
  String get paywallWeeklyTimelineCancelTitle => 'Jederzeit kündbar';

  @override
  String get paywallWeeklyTimelineCancelDesc =>
      'Kündigen Sie jederzeit in den Store-Einstellungen.';

  @override
  String get paywallTimelineTodayTitle => 'Heute — Pro freischalten';

  @override
  String get paywallTimelineTodayDesc =>
      'KI-Scan, Mahlzeiten-Tracking und Analysen ohne Limits.';

  @override
  String get paywallTimelineReminderTitle => 'Tag 2 — Erinnerung';

  @override
  String get paywallTimelineReminderDesc =>
      'Wir erinnern Sie vor Ende der Testphase';

  @override
  String get paywallTimelinePayTitle => 'Tag 3 — Zahlung';

  @override
  String paywallTimelinePayDesc(String date) {
    return 'Abbuchung am $date, falls Sie nicht kündigen';
  }

  @override
  String get paywallMonthly => 'Wöchentlich';

  @override
  String get paywallMonthlyPrice => '4,99 \$ / Woche';

  @override
  String get paywallYearly => 'Jährlich';

  @override
  String get paywallYearlyPrice => '39,99 \$ / Jahr';

  @override
  String get paywallPerWeek => 'Woche';

  @override
  String get paywallPerYear => 'Jahr';

  @override
  String get paywallTrialBadge => '3 Tage gratis';

  @override
  String get paywallYearlyDiscount => '-85%';

  @override
  String get paywallSubtitle =>
      'Hol dir das volle BodyMeal Pro mit allen Premium-Funktionen.';

  @override
  String get paywallFeatureAiTitle => 'KI-Erkennung';

  @override
  String get paywallFeatureAiDesc =>
      'Foto machen — die KI erkennt Kalorien und Nährwerte in Sekunden.';

  @override
  String get paywallFeatureDiaryTitle => 'Ernährungstagebuch';

  @override
  String get paywallFeatureDiaryDesc =>
      'Alle Mahlzeiten unbegrenzt protokollieren, jeden Tag.';

  @override
  String get paywallFeatureAnalyticsTitle => 'Detaillierte Analysen';

  @override
  String get paywallFeatureAnalyticsDesc =>
      'Kalorien, Makros und Zielfortschritt über jeden Zeitraum.';

  @override
  String get paywallFeatureBarcodeTitle => 'Barcode-Scanner';

  @override
  String get paywallFeatureBarcodeDesc =>
      'Kamera auf die Verpackung halten — Daten werden automatisch übernommen.';

  @override
  String get paywallNoPaymentNow => 'Jetzt keine Zahlung erforderlich';

  @override
  String get paywallStartTrial => 'Testphase starten';

  @override
  String get paywallTrialDisclaimer => '3 Tage kostenlos, dann 39,99 \$/Jahr';

  @override
  String get paywallWeeklyDisclaimer => 'Abrechnung heute. Jederzeit kündbar.';

  @override
  String paywallTrialDisclaimerFmt(String price) {
    return '3 Tage kostenlos, dann $price/Jahr';
  }

  @override
  String get paywallRestore => 'Wiederherstellen';

  @override
  String get paywallTerms => 'Bedingungen';

  @override
  String get paywallPrivacy => 'Datenschutz';

  @override
  String get paywallHaveCode => 'Code eingeben?';

  @override
  String get promoCodeApply => 'Anwenden';

  @override
  String get promoCodeInvalid => 'Ungültiger Code';

  @override
  String get paywallSkip => 'Überspringen';

  @override
  String get paywallRestoreSuccess => 'Abonnement wiederhergestellt';

  @override
  String get paywallRestoreNotFound => 'Keine aktiven Abonnements gefunden';

  @override
  String get paywallSubscriptionError =>
      'Abonnements konnten nicht geladen werden. Versuchen Sie es später erneut.';

  @override
  String get paywallLoadingPrice => 'Lädt…';

  @override
  String get paywallErrorTitle => 'Abonnement nicht verfügbar';

  @override
  String get paywallTryAgain => 'Erneut versuchen';

  @override
  String get paywallErrorStoreUnavailable =>
      'Der App Store ist gerade nicht erreichbar. Bitte stelle sicher, dass du im App Store angemeldet bist, und versuche es erneut.';

  @override
  String get paywallErrorProductsEmpty =>
      'Abonnement-Optionen konnten nicht geladen werden. Prüfe deine Verbindung und versuche es erneut.';

  @override
  String get paywallErrorSelectedProductUnavailable =>
      'Diese Abonnement-Option ist derzeit nicht verfügbar. Wählen Sie einen anderen Tarif oder versuchen Sie es erneut.';

  @override
  String get paywallErrorQueryFailed =>
      'Der App Store ist nicht erreichbar. Bitte versuche es gleich noch einmal.';

  @override
  String get paywallErrorPurchaseFailed =>
      'Der Kauf konnte nicht abgeschlossen werden. Bitte versuche es erneut.';

  @override
  String get paywallErrorRestoreFailed =>
      'Käufe konnten nicht wiederhergestellt werden. Bitte versuche es erneut.';

  @override
  String get paywallErrorPaymentPending =>
      'Deine Zahlung wird bearbeitet. Pro wird freigeschaltet, sobald sie bestätigt ist.';

  @override
  String get restartOnboarding => 'Neu starten';

  @override
  String get proActive => 'Aktiv';

  @override
  String get signInToSaveData => 'Anmelden, um Daten zu speichern';

  @override
  String get dataStoredLocally =>
      'Ihre Daten werden nur auf diesem Gerät gespeichert';

  @override
  String get barcodeScannerTitle => 'Barcode-Scanner';

  @override
  String get barcodeScanHint => 'Richten Sie die Kamera auf einen Barcode';

  @override
  String get paywallSubscribeNow => 'Abonnieren';

  @override
  String get paywallHardDisclaimer =>
      'Automatische Verlängerung. Jederzeit kündbar.';

  @override
  String get paywallHardTitle => 'Weiter\nmit Pro';

  @override
  String freeEntriesRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kostenlose Einträge übrig',
      one: '1 kostenloser Eintrag übrig',
    );
    return '$_temp0';
  }

  @override
  String get getPro => 'Pro holen';

  @override
  String get freeLimitReached => 'Alle kostenlosen Einträge aufgebraucht';

  @override
  String get analyticsTitle => 'Analytik';

  @override
  String get summarySection => 'Zusammenfassung';

  @override
  String get trendsSection => 'Trends';

  @override
  String get highlightsSection => 'Highlights';

  @override
  String dayStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tage in Folge',
      one: 'Tag in Folge',
    );
    return '$_temp0';
  }

  @override
  String get averageADay => 'Ø pro Tag';

  @override
  String calDifferenceCount(int count) {
    return 'Differenz: $count kcal';
  }

  @override
  String percentAverage(int count) {
    return '$count/100 % Durchschnitt';
  }

  @override
  String analyticsHighlightHigher(String metric) {
    return 'Die durchschnittliche $metric-Aufnahme pro Tag ist diese Woche höher als letzte Woche.';
  }

  @override
  String analyticsHighlightLower(String metric) {
    return 'Die durchschnittliche $metric-Aufnahme pro Tag ist diese Woche niedriger als letzte Woche.';
  }

  @override
  String analyticsHighlightSimilar(String metric) {
    return 'Die durchschnittliche $metric-Aufnahme pro Tag ist diese Woche ähnlich wie letzte Woche.';
  }

  @override
  String get analyticsPeriod1W => '1 W';

  @override
  String get analyticsPeriod2W => '2 W';

  @override
  String get analyticsPeriod1M => '1 M';

  @override
  String get analyticsPeriod3M => '3 M';

  @override
  String get analyticsPeriod6M => '6 M';

  @override
  String get analyticsPeriod1Y => '1 J';

  @override
  String get analyticsMetricCal => 'Kcal';

  @override
  String get analyticsMetricProtein => 'Eiw';

  @override
  String get analyticsMetricFat => 'Fett';

  @override
  String get analyticsMetricCarbs => 'Kohl';

  @override
  String get quantityLabel => 'Menge';

  @override
  String get addSuggestionsLabel => 'Vorschläge hinzufügen';

  @override
  String get suggestionSomethingElse => 'Sonstiges';

  @override
  String get untitledIngredientName => 'Ohne Namen';
}
