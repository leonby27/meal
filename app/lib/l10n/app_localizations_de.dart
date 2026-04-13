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
  String get yearsUnit => 'Jahre';

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
  String get signInGoogle => 'Mit Google anmelden';

  @override
  String get signInEmail => 'Mit E-Mail anmelden';

  @override
  String get skipLogin => 'Ohne Anmeldung fortfahren';

  @override
  String get signInSyncHint =>
      'Mit Anmeldung können Sie Daten\nzwischen Geräten synchronisieren';

  @override
  String get calorieTracking => 'Ernährungs- & Kalorienverfolgung';

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
  String get historyTab => 'Verlauf';

  @override
  String get favoritesTab => 'Favoriten';

  @override
  String get noRecentRecords => 'Keine aktuellen Einträge';

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
  String get voiceUnavailable =>
      'Spracheingabe nicht verfügbar. Überprüfen Sie die Mikrofonberechtigungen.';

  @override
  String get holdToRecord => 'Gedrückt halten zum Aufnehmen';

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
  String get recognizeDish => 'Gericht erkennen';

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
  String get heightLabel => 'Größe';

  @override
  String get currentWeightLabel => 'Aktuelles Gewicht';

  @override
  String get onboardingAgeTitle => 'Wie alt sind Sie?';

  @override
  String get onboardingGoalTitle => 'Was ist Ihr Ziel?';

  @override
  String get goalLoseWeight => 'Abnehmen';

  @override
  String get goalMaintainWeight => 'Gewicht halten';

  @override
  String get goalGainWeight => 'Muskeln aufbauen';

  @override
  String get onboardingActivityTitle => 'Wie aktiv sind Sie?';

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
  String get safeWeightLossPace => 'Sicheres Tempo — 0,5 kg pro Woche';

  @override
  String get recommendedWeightGainPace =>
      'Empfohlenes Tempo — 0,25 kg pro Woche';

  @override
  String get onboardingLoadingCalc => 'Stoffwechsel wird berechnet...';

  @override
  String get onboardingLoadingNorm => 'Ihre Kaloriennorm wird ermittelt...';

  @override
  String get onboardingLoadingPlan => 'Ihr persönlicher Plan wird erstellt...';

  @override
  String get onboardingResultTitle => 'Ihr persönlicher Plan';

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
  String get paywallTitle => 'Starten Sie Ihren Weg\nzu Ergebnissen';

  @override
  String get paywallAiRecognition => 'KI-Lebensmittelerkennung';

  @override
  String get paywallAiRecognitionDesc =>
      'Fotografieren und in Sekunden Kalorien erfahren';

  @override
  String get paywallPersonalGoals => 'Persönliche Ziele';

  @override
  String get paywallPersonalGoalsDesc =>
      'Norm berechnet für Ihren Körper und Ihr Ziel';

  @override
  String get paywallProgressTracking => 'Fortschrittsverfolgung';

  @override
  String get paywallProgressTrackingDesc =>
      'Visuelle Statistiken nach Tagen und Wochen';

  @override
  String get paywallWeekly => 'Wöchentlich';

  @override
  String get paywallWeeklyPrice => '2,99 €/Woche';

  @override
  String get paywallWeeklyTrial => 'Erste 3 Tage — kostenlos';

  @override
  String get paywallPopular => 'Beliebt';

  @override
  String get paywallYearly => 'Jährlich';

  @override
  String get paywallYearlyPrice => '19,99 €/Jahr';

  @override
  String get paywallYearlySavings => '≈ 0,05 €/Tag · 85 % sparen';

  @override
  String get paywallRating => '4,8 · Über 10.000 Nutzer';

  @override
  String get paywallToday => 'Heute';

  @override
  String get paywallFullAccess => 'Voller Zugang';

  @override
  String get paywallDay2 => 'Tag 2';

  @override
  String get paywallReminder => 'Erinnerung';

  @override
  String get paywallDay3 => 'Tag 3';

  @override
  String get paywallDay3Price => '2,99 €';

  @override
  String get paywallContinue => 'Weiter';

  @override
  String get paywallDisclaimer =>
      'Jederzeit kündbar. Keine Kosten\nwährend der Testphase.';

  @override
  String get paywallSkip => 'Überspringen';

  @override
  String get barcodeScannerTitle => 'Barcode-Scanner';

  @override
  String get barcodeScanHint => 'Richten Sie die Kamera auf einen Barcode';
}
