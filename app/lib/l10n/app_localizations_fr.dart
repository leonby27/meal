// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get mealBreakfast => 'Petit-déjeuner';

  @override
  String get mealLunch => 'Déjeuner';

  @override
  String get mealDinner => 'Dîner';

  @override
  String get mealSnack => 'Collation';

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
  String get yearsUnit => 'ans';

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
    return 'Pour 100 g : $cal kcal  P$prot L$fat G$carbs';
  }

  @override
  String get proteinShort => 'P';

  @override
  String get fatShort => 'L';

  @override
  String get carbsShort => 'G';

  @override
  String get proteinLabel => 'Protéines';

  @override
  String get fatLabel => 'Lipides';

  @override
  String get carbsLabel => 'Glucides';

  @override
  String get carbsLabelShort => 'Glucides';

  @override
  String get caloriesLabel => 'Calories';

  @override
  String get caloriesKcalLabel => 'Calories, kcal';

  @override
  String get proteinGramsLabel => 'Protéines, g';

  @override
  String get fatGramsLabel => 'Lipides, g';

  @override
  String get carbsGramsLabel => 'Glucides, g';

  @override
  String get caloriesKcalInputLabel => 'Calories (kcal)';

  @override
  String proteinGoalLabel(int count) {
    return '$count protéines';
  }

  @override
  String fatGoalLabel(int count) {
    return '$count lipides';
  }

  @override
  String carbsGoalLabel(int count) {
    return '$count glucides';
  }

  @override
  String get profileTitle => 'Profil';

  @override
  String get myProfile => 'Mon Profil';

  @override
  String get subscription => 'Abonnement';

  @override
  String get myGoals => 'Mes Objectifs';

  @override
  String get myProducts => 'Mes Produits';

  @override
  String get settings => 'Paramètres';

  @override
  String get productsList => 'Liste de produits';

  @override
  String get allProducts => 'Tous';

  @override
  String get appTheme => 'Thème de l\'app';

  @override
  String get languageSelector => 'Langue de l\'interface';

  @override
  String get pushNotifications => 'Notifications push';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get signOutConfirm => 'Se déconnecter du compte ?';

  @override
  String get signOutLocalDataKept =>
      'Les données locales resteront sur l\'appareil.';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get save => 'Enregistrer';

  @override
  String get add => 'Ajouter';

  @override
  String get close => 'Fermer';

  @override
  String get edit => 'Modifier';

  @override
  String get guestMode => 'Mode invité';

  @override
  String get defaultUserName => 'Utilisateur';

  @override
  String get signedInSnackbar => 'Connecté avec succès';

  @override
  String get signInGoogle => 'Se connecter avec Google';

  @override
  String get signInEmail => 'Se connecter avec Email';

  @override
  String get skipLogin => 'Continuer sans se connecter';

  @override
  String get signInSyncHint =>
      'La connexion vous permet de synchroniser\nvos données entre appareils';

  @override
  String get calorieTracking => 'Suivi nutritionnel et calorique';

  @override
  String get loginTitle => 'Connexion';

  @override
  String get registerTitle => 'Inscription';

  @override
  String get nameOptional => 'Nom (facultatif)';

  @override
  String get enterEmail => 'Entrez votre email';

  @override
  String get invalidEmail => 'Email invalide';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get enterPassword => 'Entrez votre mot de passe';

  @override
  String get minPasswordLength => '6 caractères minimum';

  @override
  String get signInButton => 'Se connecter';

  @override
  String get registerButton => 'S\'inscrire';

  @override
  String get switchToLogin => 'Se connecter au compte';

  @override
  String get wrongCredentials => 'Email ou mot de passe incorrect';

  @override
  String signInError(String error) {
    return 'Erreur de connexion : $error';
  }

  @override
  String get emailAlreadyRegistered => 'Cet email est déjà enregistré';

  @override
  String registerError(String error) {
    return 'Erreur d\'inscription : $error';
  }

  @override
  String get proTitle => 'MealTracker Pro';

  @override
  String get proUnlockFeatures => 'Débloquez toutes les fonctionnalités :';

  @override
  String get proAiUnlimited => 'Reconnaissance IA illimitée';

  @override
  String get proExtendedStats => 'Statistiques détaillées';

  @override
  String get proPersonalRecommendations => 'Recommandations personnalisées';

  @override
  String get proTryFree => 'Essayer gratuitement';

  @override
  String get planLabel => 'Abonnement :';

  @override
  String get planWeekly => 'Hebdomadaire';

  @override
  String get billingLabel => 'Prochaine facturation :';

  @override
  String get manageSubscription => 'Gérer l\'abonnement';

  @override
  String get goalCaloriesKcal => 'Calories, kcal';

  @override
  String get goalProteinG => 'Protéines, g';

  @override
  String get goalFatG => 'Lipides, g';

  @override
  String get goalCarbsG => 'Glucides, g';

  @override
  String get remindersTitle => 'Rappels';

  @override
  String get reminderOff => 'Désactivé';

  @override
  String get remindersDescription =>
      'Les rappels seront envoyés quotidiennement à l\'heure indiquée pour ne pas oublier d\'enregistrer vos repas.';

  @override
  String get notifBreakfastBody =>
      'C\'est l\'heure d\'enregistrer le petit-déjeuner';

  @override
  String get notifLunchBody => 'C\'est l\'heure d\'enregistrer le déjeuner';

  @override
  String get notifDinnerBody => 'C\'est l\'heure d\'enregistrer le dîner';

  @override
  String get notifSnackBody => 'N\'oubliez pas d\'enregistrer votre collation';

  @override
  String get notifChannelName => 'Rappels de repas';

  @override
  String get notifChannelDesc => 'Rappels pour enregistrer les repas';

  @override
  String get diaryRecordsForDay => 'Entrées du jour';

  @override
  String get diaryEmptyDay => 'Aucune entrée pour ce jour';

  @override
  String get addMealTitle => 'Ajouter un repas';

  @override
  String get mealTypeLabel => 'Type de repas';

  @override
  String get searchInDb => 'Rechercher dans la base';

  @override
  String get fromGallery => 'Depuis la galerie';

  @override
  String get recognizeByPhoto => 'Reconnaître par photo';

  @override
  String get productNameOrDish => 'Nom du produit ou du plat';

  @override
  String get addEntry => 'Ajouter une entrée';

  @override
  String get recognizingViaAi => 'Reconnaissance par IA...';

  @override
  String get notFoundInDb =>
      'Non trouvé dans la base de données\nAppuyez ➜ pour reconnaître par IA';

  @override
  String get historyTab => 'Historique';

  @override
  String get favoritesTab => 'Favoris';

  @override
  String get noRecentRecords => 'Aucun enregistrement récent';

  @override
  String get noFavoriteProducts => 'Aucun produit favori';

  @override
  String get gramsDialogLabel => 'Grammes';

  @override
  String get favoriteUpdated => 'Favoris mis à jour';

  @override
  String get addToFavorite => 'Ajouter aux favoris';

  @override
  String get dayNotYet => 'Ce jour n\'est pas encore arrivé !';

  @override
  String get voiceUnavailable =>
      'Saisie vocale indisponible. Vérifiez les autorisations du micro.';

  @override
  String get holdToRecord => 'Maintenez pour enregistrer la voix';

  @override
  String copyMealTo(String meal) {
    return 'Copier $meal vers…';
  }

  @override
  String copiedRecords(int count, String date) {
    return '$count entrées copiées vers $date';
  }

  @override
  String get dayMon => 'LU';

  @override
  String get dayTue => 'MA';

  @override
  String get dayWed => 'ME';

  @override
  String get dayThu => 'JE';

  @override
  String get dayFri => 'VE';

  @override
  String get daySat => 'SA';

  @override
  String get daySun => 'DI';

  @override
  String get aiAnalyzingPhoto => 'Analyse de la photo...';

  @override
  String get aiRecognizingIngredients => 'Reconnaissance des ingrédients...';

  @override
  String get aiCountingCalories => 'Calcul des calories...';

  @override
  String get aiDeterminingMacros => 'Détermination des macros...';

  @override
  String get aiAlmostDone => 'Presque terminé...';

  @override
  String get aiAnalyzingData => 'Analyse des données...';

  @override
  String get aiRecognitionFailed => 'Impossible de reconnaître le plat';

  @override
  String get aiRecognizingDish => 'Reconnaissance du plat';

  @override
  String get addDish => 'Ajouter un plat';

  @override
  String get dishNameLabel => 'Nom';

  @override
  String get dishParameters => 'Paramètres du plat';

  @override
  String get ingredientsLabel => 'Ingrédients';

  @override
  String get unknownDish => 'Plat inconnu';

  @override
  String get defaultDishName => 'Plat';

  @override
  String get saveEntry => 'Ajouter une entrée';

  @override
  String get saveChanges => 'Enregistrer';

  @override
  String get recognizeDish => 'Reconnaître le plat';

  @override
  String get cameraLabel => 'Appareil photo';

  @override
  String get searchTitle => 'Recherche';

  @override
  String get searchHint => 'Rechercher des produits...';

  @override
  String get nothingFound => 'Aucun résultat';

  @override
  String get recognizeViaAi => 'Reconnaître par IA';

  @override
  String get createProduct => 'Créer un produit';

  @override
  String get newProduct => 'Nouveau Produit';

  @override
  String get basicInfo => 'Informations de base';

  @override
  String get productNameRequired => 'Nom *';

  @override
  String get enterName => 'Entrez le nom';

  @override
  String get brandOptional => 'Marque (facultatif)';

  @override
  String get servingWeightG => 'Poids par portion (g)';

  @override
  String get macrosPer100g => 'Macros pour 100 g';

  @override
  String get caloriesAutoCalc => 'Calculé automatiquement à partir des macros';

  @override
  String get productAdded => 'Produit ajouté';

  @override
  String get saveProduct => 'Enregistrer le produit';

  @override
  String get myProductsCategory => 'Mes Produits';

  @override
  String get newRecipe => 'Nouvelle Recette';

  @override
  String get recipeNameRequired => 'Nom de la recette *';

  @override
  String get servingsCount => 'Nombre de portions';

  @override
  String get enterRecipeName => 'Entrez le nom de la recette';

  @override
  String get addAtLeastOneIngredient => 'Ajoutez au moins un ingrédient';

  @override
  String get recipeSaved => 'Recette enregistrée';

  @override
  String get totalForRecipe => 'Total de la recette';

  @override
  String get per100g => 'Pour 100 g :';

  @override
  String perServing(int grams) {
    return 'Par portion ($grams g) :';
  }

  @override
  String get ingredientSearchHint => 'Rechercher un ingrédient...';

  @override
  String get startTypingName => 'Commencez à taper un nom';

  @override
  String get tapAddToSelect =>
      'Appuyez sur « Ajouter » pour\nsélectionner des produits';

  @override
  String ingredientsCount(int count) {
    return 'Ingrédients ($count)';
  }

  @override
  String get weightLabel => 'Poids';

  @override
  String get favoritesTitle => 'Favoris';

  @override
  String productAddedToMeal(String name) {
    return '$name ajouté';
  }

  @override
  String get historyTitle => 'Historique';

  @override
  String get noRecords => 'Aucun enregistrement';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get statsTitle => 'Statistiques';

  @override
  String get averageLabel => 'Moyenne';

  @override
  String get byDays => 'Par jours';

  @override
  String get periodWeek => 'Semaine';

  @override
  String get period2Weeks => '2 semaines';

  @override
  String get periodMonth => 'Mois';

  @override
  String totalGrams(int count) {
    return 'Total $count g';
  }

  @override
  String get noOwnProducts => 'Aucun produit personnalisé';

  @override
  String get createProductWithMacros => 'Créez un produit avec ses macros';

  @override
  String get productLabel => 'Produit';

  @override
  String get deleteConfirm => 'Supprimer ?';

  @override
  String deleteWhat(String what) {
    return 'Supprimer $what ?';
  }

  @override
  String get customizeView => 'Personnaliser l\'affichage';

  @override
  String get primaryMetric => 'Métrique principale';

  @override
  String get otherMetrics => 'Autres métriques';

  @override
  String get showMore => 'Afficher plus';

  @override
  String get showLess => 'Afficher moins';

  @override
  String get networkTimeout =>
      'Le serveur ne répond pas. Vérifiez votre connexion internet.';

  @override
  String get networkSslError => 'Erreur de connexion SSL. Réessayez plus tard.';

  @override
  String networkConnectionError(String message) {
    return 'Erreur de connexion : $message';
  }

  @override
  String get networkRetryFailed => 'Impossible de joindre le serveur.';

  @override
  String get networkHostLookup =>
      'Serveur temporairement indisponible. Vérifiez votre connexion ou réessayez dans une minute.';

  @override
  String get networkConnectionRefused =>
      'Le serveur n\'accepte pas les connexions. Réessayez plus tard.';

  @override
  String get networkConnectionReset => 'Connexion perdue. Réessayez.';

  @override
  String get networkGenericError =>
      'Erreur réseau. Vérifiez votre connexion internet.';

  @override
  String get onboardingGenderTitle => 'Sélectionnez votre genre';

  @override
  String get onboardingGenderHint =>
      'Nécessaire pour un calcul précis des calories';

  @override
  String get genderMale => 'Homme';

  @override
  String get genderFemale => 'Femme';

  @override
  String get onboardingMeasurementsTitle => 'Vos mensurations';

  @override
  String get heightLabel => 'Taille';

  @override
  String get currentWeightLabel => 'Poids actuel';

  @override
  String get onboardingAgeTitle => 'Quel âge avez-vous ?';

  @override
  String get onboardingGoalTitle => 'Quel est votre objectif ?';

  @override
  String get goalLoseWeight => 'Perdre du poids';

  @override
  String get goalMaintainWeight => 'Maintenir le poids';

  @override
  String get goalGainWeight => 'Prendre du muscle';

  @override
  String get onboardingActivityTitle => 'Quel est votre niveau d\'activité ?';

  @override
  String get activitySedentary => 'Sédentaire';

  @override
  String get activitySedentaryDesc => 'Travail de bureau, peu de marche';

  @override
  String get activityLight => 'Légèrement actif';

  @override
  String get activityLightDesc => 'Exercice léger 1 à 3 fois par semaine';

  @override
  String get activityModerate => 'Modérément actif';

  @override
  String get activityModerateDesc => 'Exercice 3 à 5 fois par semaine';

  @override
  String get activityHigh => 'Très actif';

  @override
  String get activityHighDesc => 'Exercice intense 6 à 7 fois par semaine';

  @override
  String get onboardingTargetWeightTitle => 'Quel est votre poids cible ?';

  @override
  String get safeWeightLossPace => 'Rythme sûr — 0,5 kg par semaine';

  @override
  String get recommendedWeightGainPace =>
      'Rythme recommandé — 0,25 kg par semaine';

  @override
  String get onboardingLoadingCalc => 'Calcul du métabolisme...';

  @override
  String get onboardingLoadingNorm => 'Recherche de votre norme calorique...';

  @override
  String get onboardingLoadingPlan => 'Création de votre plan personnalisé...';

  @override
  String get onboardingResultTitle => 'Votre Plan Personnel';

  @override
  String get kcalPerDay => 'kcal/jour';

  @override
  String get weightLossGoalText => 'perte de poids';

  @override
  String get weightGainGoalText => 'prise de muscle';

  @override
  String achievableGoal(String goalText) {
    return 'Objectif atteignable : $goalText';
  }

  @override
  String weeksToGoal(int weeks, String date) {
    return '$weeks semaines jusqu\'à l\'objectif — d\'ici le $date';
  }

  @override
  String maintainWeightHint(String weight) {
    return 'Nous vous aiderons à maintenir votre poids\nà $weight kg';
  }

  @override
  String weightWithUnit(String value) {
    return '$value kg';
  }

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingStart => 'Commencer';

  @override
  String get paywallTitle => 'Commencez votre parcours\nvers les résultats';

  @override
  String get paywallAiRecognition => 'Reconnaissance alimentaire par IA';

  @override
  String get paywallAiRecognitionDesc =>
      'Prenez une photo et découvrez les calories en un instant';

  @override
  String get paywallPersonalGoals => 'Objectifs personnels';

  @override
  String get paywallPersonalGoalsDesc =>
      'Norme calculée pour votre corps et votre objectif';

  @override
  String get paywallProgressTracking => 'Suivi des progrès';

  @override
  String get paywallProgressTrackingDesc =>
      'Statistiques visuelles par jours et semaines';

  @override
  String get paywallWeekly => 'Hebdomadaire';

  @override
  String get paywallWeeklyPrice => '2,99 €/semaine';

  @override
  String get paywallWeeklyTrial => 'Les 3 premiers jours — gratuits';

  @override
  String get paywallPopular => 'Populaire';

  @override
  String get paywallYearly => 'Annuel';

  @override
  String get paywallYearlyPrice => '19,99 €/an';

  @override
  String get paywallYearlySavings => '≈ 0,05 €/jour · Économisez 85 %';

  @override
  String get paywallRating => '4,8 · Plus de 10 000 utilisateurs';

  @override
  String get paywallToday => 'Aujourd\'hui';

  @override
  String get paywallFullAccess => 'Accès complet';

  @override
  String get paywallDay2 => 'Jour 2';

  @override
  String get paywallReminder => 'Rappel';

  @override
  String get paywallDay3 => 'Jour 3';

  @override
  String get paywallDay3Price => '2,99 €';

  @override
  String get paywallContinue => 'Continuer';

  @override
  String get paywallDisclaimer =>
      'Annulation à tout moment. Aucun frais\npendant la période d\'essai.';

  @override
  String get paywallSkip => 'Passer';

  @override
  String get barcodeScannerTitle => 'Scanner de code-barres';

  @override
  String get barcodeScanHint => 'Pointez la caméra vers un code-barres';
}
