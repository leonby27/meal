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
  String get proTitle => 'Body Meal Pro';

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
  String get planLifetime => 'Lebenslang';

  @override
  String get planPromo => 'Promo';

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
  String get duplicate => 'Duplizieren';

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
  String resultTailoredFromAnswers(int count) {
    return 'Auf $count Antworten zugeschnitten';
  }

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
  String get resultDisclaimerShort => 'Ersetzt keinen ärztlichen Rat.';

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
  String get paywallNoPaymentNow => 'Heute keine Zahlung';

  @override
  String get paywallStartTrial => 'Testphase starten';

  @override
  String get paywallContinuePro => 'Mit Pro fortfahren';

  @override
  String get paywallSave85 => '85 % sparen';

  @override
  String paywallDayPrefix(int n) {
    return 'Tag $n';
  }

  @override
  String get paywallTrialStarts => 'Testphase startet';

  @override
  String get paywallTrialRemindYou => 'Wir erinnern dich';

  @override
  String get paywallTrialPlanBegins => 'Plan beginnt';

  @override
  String get paywallFeatureSnap => 'Foto machen, KI zählt Kalorien';

  @override
  String get paywallFeatureScore => 'Health-Score für jede Mahlzeit';

  @override
  String get paywallFeatureTags => 'Persönliche Ziel-Tags';

  @override
  String get paywallFeaturePrivacy =>
      'Verschlüsselt · Werbefrei · Kein Verkauf';

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
  String get paywallGo => 'Loslegen';

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

  @override
  String get onbObstaclesTitle => 'Was ist für Sie am schwierigsten?';

  @override
  String get onbObstaclesHint =>
      'Wählen Sie alles aus, was zutrifft — je mehr wir wissen, desto besser Ihr Plan.';

  @override
  String onbObstaclesContinue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Weiter · $count ausgewählt',
      one: 'Weiter · 1 ausgewählt',
      zero: 'Mindestens eine Option wählen',
    );
    return '$_temp0';
  }

  @override
  String get obstacleConsistency => 'Schwer dranzubleiben';

  @override
  String get obstacleKnowledge => 'Unsicher, was ich essen soll';

  @override
  String get obstacleBusy => 'Immer im Stress';

  @override
  String get obstacleCravings => 'Heißhunger auf Süßes & Kohlenhydrate';

  @override
  String get obstacleSupport => 'Mache es alleine';

  @override
  String get obstacleEatingOut => 'Oft auswärts essen';

  @override
  String get obstacleMotivation => 'Schwer motiviert zu bleiben';

  @override
  String get obstacleTracking => 'Kalorienzählen ist schwierig';

  @override
  String get obstacleTagConsistency => 'Serien';

  @override
  String get obstacleTagKnowledge => 'Ziel-Tags';

  @override
  String get obstacleTagBusy => 'Schnell-Log';

  @override
  String get obstacleTagCravings => 'Zuckeralarm';

  @override
  String get obstacleTagSupport => 'KI-Coach';

  @override
  String get obstacleTagEatingOut => 'Überall';

  @override
  String get obstacleTagMotivation => 'Erfolge';

  @override
  String get obstacleTagTracking => 'Ohne Tippen';

  @override
  String get onbSpeedTitleLose => 'Wie schnell möchten Sie abnehmen?';

  @override
  String get onbSpeedTitleGain => 'Wie schnell möchten Sie zunehmen?';

  @override
  String onbSpeedHintKg(String rate) {
    return 'Empfohlenes Tempo — $rate kg/Woche';
  }

  @override
  String onbSpeedHintLb(String rate) {
    return 'Empfohlenes Tempo — $rate lb/Woche';
  }

  @override
  String onbSpeedKgPerWeek(String value) {
    return '$value kg/Woche';
  }

  @override
  String onbSpeedLbPerWeek(String value) {
    return '$value lb/Woche';
  }

  @override
  String get onbSpeedBadgeGentle => 'Sanftes Tempo ✅';

  @override
  String get onbSpeedBadgeRecommended => 'Empfohlenes Tempo ⭐';

  @override
  String get onbSpeedBadgeAmbitious => 'Ambitioniert 🔥';

  @override
  String get onbSpeedBadgeAggressive => 'Sehr aggressiv ⚠️';

  @override
  String onbSpeedTargetByPrefix(String weight) {
    return 'Sie erreichen $weight bis';
  }

  @override
  String get onbQuizTitle => 'Erzählen Sie uns von Ihren Gewohnheiten';

  @override
  String get onbQuizHint => 'So können wir Ihren Plan persönlicher machen';

  @override
  String get quizStressEatingLeft => 'Ich esse bei Stress';

  @override
  String get quizStressEatingRight => 'Ich esse nur für Energie';

  @override
  String get quizSweetPreferenceLeft => 'Ich liebe Süßes';

  @override
  String get quizSweetPreferenceRight => 'Ich mag eher Salziges/Scharfes';

  @override
  String get quizExerciseConsistencyLeft => 'Ich trainiere regelmäßig';

  @override
  String get quizExerciseConsistencyRight => 'Ich schaffe keine Routine';

  @override
  String get quizMealPlanningLeft => 'Ich plane meine Mahlzeiten';

  @override
  String get quizMealPlanningRight => 'Ich esse, was gerade da ist';

  @override
  String get quizMotivationTypeLeft => 'Ergebnisse motivieren mich';

  @override
  String get quizMotivationTypeRight => 'Gefühle motivieren mich';

  @override
  String get onbRateTitle => 'Gefällt Ihnen Ihr Plan?';

  @override
  String get onbRateSubtitle =>
      'Bewerten Sie Body Meal — Sie helfen uns, besser zu werden';

  @override
  String get onbRateButton => 'Bewerten';

  @override
  String get onbRateSkip => 'Überspringen';

  @override
  String get onbRateFeedbackTitle => 'Was können wir verbessern?';

  @override
  String get onbRateFeedbackHint => 'Sagen Sie uns, was nicht gepasst hat';

  @override
  String get onbRateFeedbackSubmit => 'Senden';

  @override
  String resultAnchorPrefix(String weight) {
    return 'Sie erreichen $weight bis';
  }

  @override
  String resultAnchorWeeksSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '(in $count Wochen)',
      one: '(in 1 Woche)',
    );
    return '$_temp0';
  }

  @override
  String resultMaintainCard(String weight) {
    return 'Wir helfen Ihnen, $weight zu halten';
  }

  @override
  String get resultDailyNormLabel => 'IHR TAGESZIEL';

  @override
  String resultPsychotypeLabel(String title) {
    return 'Ihr Ernährungstyp: $title';
  }

  @override
  String get resultObstaclesHeader => 'Ihr Plan berücksichtigt:';

  @override
  String get resultMilestonesHeader => 'Ihr Wochenfortschritt:';

  @override
  String get resultGoalRow => 'Ziel';

  @override
  String resultWeekRow(int week) {
    return 'Woche $week';
  }

  @override
  String get resultStartLabel => 'Start';

  @override
  String resultGoalReachLine(String weight) {
    return 'Sie erreichen $weight';
  }

  @override
  String resultGoalByDateLine(String date) {
    return 'bis $date';
  }

  @override
  String resultGoalInWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count Wochen',
      one: 'in 1 Woche',
    );
    return '$_temp0';
  }

  @override
  String get resultBenefit5MinDay => 'Nur 5 Minuten am Tag';

  @override
  String get resultBenefitSmartTracking => 'Smartes Tracking ohne Aufwand';

  @override
  String get resultBenefitTailored => 'Ernährungsplan passend zu Ihrem Leben';

  @override
  String get resultBenefitSustainable =>
      'Nachhaltige Ergebnisse statt schneller Diäten';

  @override
  String get resultFaqHeader => 'FAQ';

  @override
  String get resultFaqCancelQ => 'Wie kündige ich mein Abo?';

  @override
  String get resultFaqCancelAIos =>
      'Öffnen Sie Einstellungen → Ihr Name → Abos auf dem iPhone, suchen Sie Body Meal und tippen auf Abo kündigen.';

  @override
  String get resultFaqCancelAAndroid =>
      'Öffnen Sie den Google Play Store → Profilbild → Zahlungen und Abos → Abos, wählen Sie Body Meal und tippen auf Kündigen.';

  @override
  String get resultFaqSecurityQ => 'Sind meine Daten sicher?';

  @override
  String get resultFaqSecurityA =>
      'Ihre Daten werden bei Übertragung und Speicherung verschlüsselt. Wir geben sie nicht an Werbenetzwerke weiter — Ihr Konto lässt sich jederzeit in den Einstellungen löschen.';

  @override
  String get resultFaqTrialQ => 'Gibt es eine kostenlose Testphase?';

  @override
  String get resultFaqTrialA =>
      'Ja — der Jahres-Tarif startet mit einer kostenlosen Testphase. Wir berechnen nichts bis sie endet, und Sie können jederzeit vorher kündigen.';

  @override
  String get loadingMetabolism => 'Wir analysieren Ihren Stoffwechsel ...';

  @override
  String get loadingCalories => 'Wir berechnen Ihr Tageskalorienziel ...';

  @override
  String get loadingMacros =>
      'Wir stimmen Eiweiß / Fett / Kohlenhydrate ab ...';

  @override
  String get loadingPsychotype =>
      'Wir analysieren Ihren Ernährungstyp und Ihre Gewohnheiten ...';

  @override
  String get loadingPlanCreate => 'Wir erstellen Ihren persönlichen Plan ...';

  @override
  String get psyStressEaterTitle => 'Der Stress-Esser';

  @override
  String get psyStressEaterDesc =>
      'Sie essen mit den Gefühlen. Wir zeigen Alternativen.';

  @override
  String get psyFuelFocusedTitle => 'Der Energie-Esser';

  @override
  String get psyFuelFocusedDesc =>
      'Sie essen rational — wir feinjustieren nur die Zahlen.';

  @override
  String get psySweetLoverTitle => 'Die Naschkatze';

  @override
  String get psySweetLoverDesc =>
      'Wir zeigen Alternativen, die Lust auf Süßes stillen.';

  @override
  String get psySavoryLoverTitle => 'Der Würzig-Liebhaber';

  @override
  String get psySavoryLoverDesc =>
      'Salzig und scharf ist Ihr Stil — wir achten auf Natrium.';

  @override
  String get psyConsistentAthleteTitle => 'Der Konstante';

  @override
  String get psyConsistentAthleteDesc =>
      'Sie haben eine starke Basis. Eine präzise Diät multipliziert Ergebnisse.';

  @override
  String get psyInconsistentTitle => 'Der Neustarter';

  @override
  String get psyInconsistentDesc =>
      'Das Schwerste ist der Wiedereinstieg. Wir machen ihn leicht.';

  @override
  String get psyPlannerTitle => 'Der Planer';

  @override
  String get psyPlannerDesc =>
      'Sie lieben Kontrolle. KI rechnet alles für Sie aus.';

  @override
  String get psyConvenienceEaterTitle => 'Der Pragmatiker';

  @override
  String get psyConvenienceEaterDesc =>
      'Wenig Zeit — wir helfen Ihnen, schnell und richtig zu wählen.';

  @override
  String get psyResultsDrivenTitle => 'Der Zielstrebige';

  @override
  String get psyResultsDrivenDesc =>
      'Zahlen treiben Sie an — wir zeigen Ihren Fortschritt klar.';

  @override
  String get psyFeelingsDrivenTitle => 'Der Intuitive';

  @override
  String get psyFeelingsDrivenDesc =>
      'Sie hören auf sich — wir liefern die Daten dazu.';

  @override
  String get psyBalancedTitle => 'Der Ausgewogene';

  @override
  String get psyBalancedDesc =>
      'Sie haben einen gesunden Ansatz. Wir verstärken ihn mit Daten.';

  @override
  String get onbWelcomeTitle => 'Essen scannen.\nZiel erreichen.';

  @override
  String get onbWelcomeSubtitle =>
      'KI zählt Kalorien, Proteine, Kohlenhydrate und Fette — ohne manuelle Eingabe.';

  @override
  String get onbWelcomeCta => 'Loslegen';

  @override
  String get onbWelcomeLabelSalmon => 'Lachs';

  @override
  String get onbWelcomeLabelEggs => 'Eier';

  @override
  String get onbWelcomeLabelAvocado => 'Avocado';

  @override
  String get onbWelcomeLabelBread => 'Brot';

  @override
  String get onbLanguageSheetTitle => 'Sprache wählen';

  @override
  String get langShortEn => 'Eng';

  @override
  String get langShortRu => 'Rus';

  @override
  String get langShortDe => 'Deu';

  @override
  String get langShortEs => 'Spa';

  @override
  String get langShortFr => 'Fra';

  @override
  String get langShortPt => 'Por';

  @override
  String get langShortPl => 'Pol';

  @override
  String get onbConfidentTitle => 'Danke für Ihr Vertrauen';

  @override
  String get onbConfidentSubtitle =>
      'Wir passen Body Meal individuell an Ihre Ziele an';

  @override
  String get onbConfidentPrivacyTitle => 'Ihre Privatsphäre ist uns wichtig';

  @override
  String get onbConfidentPrivacyBody =>
      'Wir versprechen, Ihre persönlichen Daten vertraulich zu behandeln';

  @override
  String get onbKeepResultTitle => 'Abnehmen, das bleibt.';

  @override
  String get onbKeepResultSubtitle => 'Auf Ihren Körper abgestimmt. Auf Dauer.';

  @override
  String get onbCalorieHistoryTitle => 'Hast du schon einmal Kalorien gezählt?';

  @override
  String get onbCalorieHistoryYes => 'Ja, und ich mache es weiter';

  @override
  String onbCalorieHistoryTried(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Versucht, aber aufgegeben',
      'female': 'Versucht, aber aufgegeben',
      'other': 'Versucht, aber aufgegeben',
    });
    return '$_temp0';
  }

  @override
  String get onbCalorieHistoryNever => 'Nein, noch nie';

  @override
  String get onbImproveTitle => 'Was möchtest du verbessern?';

  @override
  String get onbImproveLookBetter => 'Besser aussehen';

  @override
  String get onbImproveFeelConfident => 'Mich selbstsicherer fühlen';

  @override
  String get onbImproveHealth => 'Gesundheit verbessern';

  @override
  String get onbImproveMoreEnergy => 'Mehr Energie';

  @override
  String get onbImproveLessStress => 'Weniger Stress';

  @override
  String get onbImproveImmunity => 'Immunsystem stärken';

  @override
  String get onbImproveFocus => 'Bessere Konzentration';

  @override
  String get onbImproveSleep => 'Besser schlafen';

  @override
  String get onbEatingObstacleTitle =>
      'Was hält dich davon ab, gesünder zu essen?';

  @override
  String get onbEatingObstacleCravings => 'Heißhunger auf Süßes oder Junkfood';

  @override
  String get onbEatingObstacleLateSnacks => 'Späte Snacks';

  @override
  String get onbEatingObstacleBadHabits => 'Ungesunde Gewohnheiten';

  @override
  String get onbHardestTitle => 'Was ist am schwersten — am Ball zu bleiben?';

  @override
  String get onbHardestBusy => 'Voller Terminkalender';

  @override
  String get onbHardestRestrictive => 'Zu viele Einschränkungen';

  @override
  String get onbHardestNoSupport => 'Fehlende Unterstützung';

  @override
  String get onbSupportTitle => 'Wir sind an deiner Seite!';

  @override
  String get onbSupportSubtitle =>
      'Der Weg zum Ziel kann hart sein — wir begleiten dich bei jedem Schritt.';

  @override
  String get onbSocialProofTitle =>
      'Mit Unterstützung nehmen Menschen schneller ab';

  @override
  String get onbSocialProofSubtitle =>
      'Die App hilft dir, nachhaltige Erfolge beim Abnehmen zu erzielen.';

  @override
  String get onbSpeedSlow => 'Langsam';

  @override
  String get onbSpeedBalanced => 'Ausgewogen';

  @override
  String get onbSpeedFast => 'Schnell';

  @override
  String onbSpeedGoodTitle(String date) {
    return 'Ziel: $date';
  }

  @override
  String get onbSpeedGoodBody =>
      'Ein vernünftiger Plan — stetige Ergebnisse ohne Erschöpfung.';

  @override
  String get onbSpeedAlertTitle => 'Zu schnell — Risiko der Erschöpfung';

  @override
  String get onbSpeedAlertBody =>
      'Wähle ein nachhaltigeres Tempo, um am Ball zu bleiben und nicht auszubrennen.';

  @override
  String get onbTrialReminderTitle =>
      'Wir schicken dir eine Erinnerung,\ndass deine Probezeit\nbald endet.';

  @override
  String get onbTrialReminderNoPaymentNow => 'Keine Zahlung erforderlich';

  @override
  String onbTrialReminderCta(String price) {
    return 'Für $price testen';
  }

  @override
  String onbTrialReminderSubtitle(String yearly, String monthly) {
    return 'Nur $yearly pro Jahr ($monthly/Mon.)';
  }

  @override
  String get tagHighProtein => 'Viel Eiweiß';

  @override
  String get tagContainsProtein => 'Mit Eiweiß';

  @override
  String get tagLowProtein => 'Wenig Eiweiß';

  @override
  String get tagCompleteProtein => 'Vollprotein';

  @override
  String get tagHealthyFats => 'Gesunde Fette';

  @override
  String get tagRichInOmega3 => 'Reich an Omega-3';

  @override
  String get tagHighFat => 'Viel Fett';

  @override
  String get tagHighSatFat => 'Viel ges. Fett';

  @override
  String get tagHighTransFat => 'Transfette';

  @override
  String get tagLowFat => 'Fettarm';

  @override
  String get tagHighFiber => 'Viele Ballaststoffe';

  @override
  String get tagContainsFiber => 'Mit Ballaststoffen';

  @override
  String get tagLowFiber => 'Wenig Ballaststoffe';

  @override
  String get tagComplexCarbs => 'Komplexe Kohlenhydrate';

  @override
  String get tagRefinedCarbs => 'Schnelle Kohlenhydrate';

  @override
  String get tagLowSugar => 'Wenig Zucker';

  @override
  String get tagHighSugar => 'Viel Zucker';

  @override
  String get tagLowCarb => 'Low-Carb';

  @override
  String get tagHighCalories => 'Kalorienreich';

  @override
  String get tagLowCalories => 'Kalorienarm';

  @override
  String get tagHighEnergy => 'Viel Energie';

  @override
  String get tagHelpsQuota => 'Erfüllt Tagesziel';

  @override
  String get tagNutrientDense => 'Nährstoffreich';

  @override
  String get tagEmptyCalories => 'Leere Kalorien';

  @override
  String get tagHeavyMeal => 'Schwere Mahlzeit';

  @override
  String get tagLightMeal => 'Leichte Mahlzeit';

  @override
  String get tagHighSalt => 'Viel Salz';

  @override
  String get tagLowSalt => 'Wenig Salz';

  @override
  String get tagHighCholesterol => 'Viel Cholesterin';

  @override
  String get tagGoodPostWorkout => 'Nach Workout';

  @override
  String get tagGoodPreWorkout => 'Vor Workout';

  @override
  String get tagBreakfastFriendly => 'Gutes Frühstück';

  @override
  String get tagHeartFriendly => 'Herzgesund';

  @override
  String get tagGutFriendly => 'Darmfreundlich';

  @override
  String get tagBrainFood => 'Brainfood';

  @override
  String get tagImmuneBoost => 'Immunbooster';

  @override
  String get tagBoneHealth => 'Knochengesund';

  @override
  String get tagRichInVitamins => 'Reich an Vitaminen';

  @override
  String get tagRichInIron => 'Eisenreich';

  @override
  String get tagRichInCalcium => 'Calciumreich';

  @override
  String get tagRichInPotassium => 'Kaliumreich';

  @override
  String get tagHighAntioxidants => 'Antioxidantienreich';

  @override
  String get tagBalancedMacros => 'Ausgewogen';

  @override
  String get tagWholeFoods => 'Naturbelassen';

  @override
  String get tagUltraProcessed => 'Hochverarbeitet';

  @override
  String get tagPlantBased => 'Pflanzlich';

  @override
  String get tagHydrating => 'Hydrierend';

  @override
  String get forYourGoalLose => 'Ziel: Abnehmen';

  @override
  String get forYourGoalMaintain => 'Ziel: Gewicht halten';

  @override
  String get forYourGoalGain => 'Ziel: Muskeln aufbauen';

  @override
  String get completeMacroSection => 'Vollständige Makros';

  @override
  String get macroSugar => 'Zucker';

  @override
  String get macroFiber => 'Ballaststoffe';

  @override
  String get macroSaturatedFat => 'Gesättigte Fette';

  @override
  String get macroCholesterol => 'Cholesterin';

  @override
  String get macroTransFat => 'Transfette';

  @override
  String get macroGlycemicLoad => 'Glykämische Last';

  @override
  String get macroCaloricDensity => 'Kaloriendichte';

  @override
  String get macroProcessing => 'Verarbeitungsgrad';

  @override
  String get macroVitamins => 'Vitamine und Mineralien';

  @override
  String get macroStatusWorse => 'Schlechter als Durchschnitt';

  @override
  String get macroStatusAverage => 'Durchschnittlich';

  @override
  String get macroStatusGood => 'Sehr gut';

  @override
  String macroValueOfDaily(String value, int percent) {
    return '$value · $percent%';
  }

  @override
  String get macroLevelLow => 'Niedrig';

  @override
  String get macroLevelModerate => 'Mittel';

  @override
  String get macroLevelModerateHigh => 'Mittel-hoch';

  @override
  String get macroLevelHigh => 'Hoch';

  @override
  String get macroLevelVeryHigh => 'Sehr hoch';

  @override
  String get macroProcessingUnprocessed => 'Unverarbeitet';

  @override
  String get macroProcessingMinimal => 'Gering';

  @override
  String get macroProcessingProcessed => 'Mäßig';

  @override
  String get macroProcessingUltra => 'Ultra';

  @override
  String get macroMgUnit => 'mg';

  @override
  String get dishWeightLabel => 'Gerichtgewicht';

  @override
  String get macroSalt => 'Salz';

  @override
  String get burnSectionTitle => 'Kalorien verbrennen?';

  @override
  String get burnWalking => 'Gehen';

  @override
  String get burnRunning => 'Laufen';

  @override
  String get burnGym => 'Krafttraining';

  @override
  String get burnCycling => 'Radfahren';

  @override
  String get burnResting => 'In Ruhe';

  @override
  String get burnOr => 'oder';

  @override
  String burnApproxSteps(String count) {
    return '~ $count Schritte';
  }

  @override
  String burnApproxKm(String count) {
    return '~ $count km';
  }

  @override
  String burnApproxHoursMinutes(int hours, int minutes) {
    return '~ $hours Std. $minutes Min.';
  }

  @override
  String get aiLoadingPhrase01 => 'Hmm… sieht verdächtig lecker aus.';

  @override
  String get aiLoadingPhrase02 => 'Moment, prüfe diese Schönheit.';

  @override
  String get aiLoadingPhrase03 => 'Mal sehen, was der Teller verbirgt.';

  @override
  String get aiLoadingPhrase04 => 'Essen erkannt. Neugier aktiviert.';

  @override
  String get aiLoadingPhrase05 => 'Warte, das Gericht hat Geheimnisse.';

  @override
  String get aiLoadingPhrase06 => 'Analysiere die köstliche Lage…';

  @override
  String get aiLoadingPhrase07 => 'Ich entschlüssele dieses Rätsel.';

  @override
  String get aiLoadingPhrase08 => 'Mini-Essensdetektiv im Einsatz.';

  @override
  String get aiLoadingPhrase09 => 'Sieht gut aus. Vielleicht zu gut.';

  @override
  String get aiLoadingPhrase10 => 'Scanne den Teller nach Antworten.';

  @override
  String get aiLoadingPhrase11 => 'Moment, untersuche das Lecker hier.';

  @override
  String get aiLoadingPhrase12 => 'Mal sehen, was hier wirklich läuft.';

  @override
  String get aiLoadingPhrase13 => 'Gabel wartet. Wissenschaft zuerst.';

  @override
  String get aiLoadingPhrase14 => 'Ist es so unschuldig wie es scheint?';

  @override
  String get aiLoadingPhrase15 => 'Etwas Leckeres geschieht hier…';

  @override
  String get aiLoadingPhrase16 => 'Zoome auf die köstlichen Beweise.';

  @override
  String get aiLoadingPhrase17 => 'Volle Snack-Ermittlung läuft.';

  @override
  String get aiLoadingPhrase18 => 'Ich rieche Kalorien. Metaphorisch.';

  @override
  String get aiLoadingPhrase19 => 'Dieser Teller ist im Analysemodus.';

  @override
  String get aiLoadingPhrase20 => 'Moment, ich lese den Essensklatsch.';

  @override
  String get aiLoadingPhrase21 => 'Suche die Makros hinter der Magie.';

  @override
  String get aiLoadingPhrase22 => 'Hmm… der Teller hat Star-Energie.';

  @override
  String get aiLoadingPhrase23 => 'Woraus besteht dieses Festmahl?';

  @override
  String get aiLoadingPhrase24 => 'Zähle Zahlen, nicht dein Essen.';

  @override
  String get aiLoadingPhrase25 => 'Food-Vibes erkannt. Berechne…';
}
