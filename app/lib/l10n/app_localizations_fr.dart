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
  String get yearsUnit => 'année de naissance';

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
  String get pushNotificationsShortOn => 'Activé';

  @override
  String get pushNotificationsShortOff => 'Désactivé';

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
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deleteAccountConfirmTitle => 'Supprimer votre compte ?';

  @override
  String get deleteAccountConfirmMessage =>
      'Cela supprimera définitivement votre compte et effacera de cet appareil votre historique de repas, vos recettes, produits, favoris et réglages. Cette action est irréversible.';

  @override
  String get deleteAccountFinalConfirmTitle => 'Êtes-vous absolument sûr ?';

  @override
  String get deleteAccountFinalConfirmMessage =>
      'Votre compte et vos données seront supprimés définitivement.';

  @override
  String get deleteAccountSuccess => 'Votre compte a été supprimé.';

  @override
  String get deleteAccountFailed =>
      'Impossible de supprimer le compte. Vérifiez votre connexion et réessayez.';

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
  String get signInTitle => 'Connectez-vous';

  @override
  String get signInGoogle => 'Se connecter avec Google';

  @override
  String get signInApple => 'Se connecter avec Apple';

  @override
  String get signInEmail => 'Se connecter avec Email';

  @override
  String get startOverOnboarding => 'Recommencer';

  @override
  String get startOverOnboardingConfirm =>
      'Recommencer l’intégration depuis le début ?';

  @override
  String get startOverOnboardingHint =>
      'Vos réponses au questionnaire seront réinitialisées. Les données du journal sur cet appareil sont conservées.';

  @override
  String get skipLogin => 'Continuer sans se connecter';

  @override
  String get signInSyncHint =>
      'La connexion vous permet de synchroniser\nvos données entre appareils';

  @override
  String get calorieTracking => 'Suivi nutritionnel et calorique';

  @override
  String get mergeLocalDataTitle =>
      'Migrer vos dernières données vers votre compte ?';

  @override
  String get mergeLocalDataKeep => 'Migrer';

  @override
  String get mergeLocalDataReplace => 'Laisser tel quel';

  @override
  String get loginSyncing => 'Synchronisation…';

  @override
  String get loginSyncFailed =>
      'Impossible de synchroniser les données. Réessayez plus tard.';

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
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get resetPasswordTitle => 'Réinitialiser le mot de passe';

  @override
  String get resetPasswordHint =>
      'Entrez l\'email utilisé lors de votre inscription. Nous vous enverrons un code à 6 chiffres.';

  @override
  String get sendResetCode => 'Envoyer le code';

  @override
  String get enterCodeTitle => 'Entrez le code';

  @override
  String resetCodeSentTo(String email) {
    return 'Nous avons envoyé un code à 6 chiffres à $email';
  }

  @override
  String get enterSixDigitCode => 'Entrez le code à 6 chiffres';

  @override
  String get verifyCode => 'Vérifier';

  @override
  String get resendCode => 'Renvoyer le code';

  @override
  String resendCodeIn(int seconds) {
    return 'Renvoyer dans $seconds s';
  }

  @override
  String get resetCodeResent => 'Code renvoyé';

  @override
  String get newPasswordTitle => 'Nouveau mot de passe';

  @override
  String get newPasswordHint =>
      'Créez un nouveau mot de passe pour votre compte.';

  @override
  String get newPasswordLabel => 'Nouveau mot de passe';

  @override
  String get confirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get resetPasswordButton => 'Réinitialiser le mot de passe';

  @override
  String get passwordResetSuccess =>
      'Mot de passe réinitialisé. Connectez-vous avec votre nouveau mot de passe.';

  @override
  String get emailNotFound => 'Aucun compte avec cet email';

  @override
  String get invalidResetCode => 'Code invalide ou expiré';

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
  String get planYearly => 'Annuel';

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
  String get diaryViewLabel => 'Vue';

  @override
  String get diaryViewCompact => 'compacte';

  @override
  String get diaryViewExpanded => 'étendue';

  @override
  String get recordsSortNewestFirst => 'Plus récentes d\'abord';

  @override
  String get recordsSortOldestFirst => 'Plus anciennes d\'abord';

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
  String get historyTab => 'Récents';

  @override
  String get favoritesTab => 'Favoris';

  @override
  String get noRecentRecords => 'Aucun enregistrement récent';

  @override
  String get addMenuRecentEntries => 'Recommandés';

  @override
  String get scanBarcodeAction => 'Scanner le code-barres';

  @override
  String get attachPhotoAction => 'Joindre une photo';

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
  String get logEntry => 'Enregistrer';

  @override
  String get saveMacros => 'Enregistrer les macros';

  @override
  String get macrosSavedToast => 'Macros enregistrés';

  @override
  String get updateDish => 'Mettre à jour le plat';

  @override
  String get refineDish => 'Préciser le plat';

  @override
  String get refineDishHint => 'Préciser le plat ...';

  @override
  String get activityWalking => 'Marche';

  @override
  String get activityBicycle => 'Vélo';

  @override
  String get activityResting => 'Repos';

  @override
  String approxHours(int count) {
    return '~ $count h';
  }

  @override
  String approxMinutes(int count) {
    return '~ $count min';
  }

  @override
  String get healthRatingLabel => 'Santé';

  @override
  String healthRatingValue(int value) {
    return '$value / 10';
  }

  @override
  String get healthDescPoor =>
      'Plat calorique, riche en sucres, graisses ou sel — à réserver aux occasions.';

  @override
  String get healthDescFair =>
      'Savoureux et nourrissant, mais probablement riche en calories, graisses et sel.';

  @override
  String get healthDescGood =>
      'Repas équilibré avec une bonne répartition des macros.';

  @override
  String get healthDescGreat =>
      'Riche en nutriments et bien équilibré — un excellent choix.';

  @override
  String get healthDescVeggie =>
      'Léger et riche en eau — beaucoup de micronutriments par calorie.';

  @override
  String get healthDescHighProtein =>
      'Très protéiné — rassasiant et bon pour la récupération.';

  @override
  String get healthDescLeanProtein =>
      'Protéine maigre — une base solide pour ton menu.';

  @override
  String get healthDescBalanced =>
      'Macros équilibrés — s\'adapte à la plupart des régimes.';

  @override
  String get healthDescCarbHeavy =>
      'Riche en glucides — associe à des protéines ou des légumes.';

  @override
  String get healthDescFatHeavy =>
      'Calorique à cause des matières grasses — surveille la portion.';

  @override
  String get healthDescSweet => 'Sucré et énergétique — à garder occasionnel.';

  @override
  String get healthDescUltraProcessed =>
      'Calorique avec peu de protéines — à limiter.';

  @override
  String get healthTraitHighProtein => 'Particulièrement riche en protéines.';

  @override
  String get healthTraitLowCalDensity => 'Léger pour ton budget calorique.';

  @override
  String get healthTraitHighFat => 'Calorique à cause des graisses.';

  @override
  String get healthTraitHighCarb => 'Surtout des glucides.';

  @override
  String get healthTraitBalancedMacros => 'Les macros sont équilibrés.';

  @override
  String get healthAdviceGreat => 'Convient à presque tous les jours.';

  @override
  String get healthAdviceGood => 'Bon choix pour une journée équilibrée.';

  @override
  String get healthAdviceFair => 'À déguster avec modération.';

  @override
  String get healthAdvicePoor => 'À garder pour les occasions.';

  @override
  String get ofYourDailyCalories => 'de ton apport journalier';

  @override
  String dailyCaloriesPercent(int percent) {
    return '$percent%';
  }

  @override
  String get recognizeDish => 'Reconnaître le plat';

  @override
  String get photoDetailsHint => 'Décrivez plus en détail si vous voulez ...';

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
  String get caloriesRemaining => 'Calories restantes';

  @override
  String get dailyEatenLabel => 'Mangé';

  @override
  String get dailyGoalLabel => 'Objectif';

  @override
  String get openMore => 'Voir plus';

  @override
  String get goToStatistics => 'Aller aux statistiques';

  @override
  String get goalsParamGoal => 'Objectif';

  @override
  String get goalsParamGender => 'Genre';

  @override
  String get goalsParamAge => 'Âge';

  @override
  String get goalsParamHeight => 'Taille';

  @override
  String get goalsParamWeight => 'Poids';

  @override
  String get goalsParamTargetWeight => 'Poids cible';

  @override
  String get goalsParamActivity => 'Activité';

  @override
  String get goalsPlanNote => 'Basé sur votre plan';

  @override
  String get goalsCustomNote => 'Valeurs personnalisées';

  @override
  String get goalsEditManually => 'Modifier manuellement';

  @override
  String get goalsUsePlan => 'Calculer depuis le plan';

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
  String get onboardingUnitsTitle => 'Unités de mesure';

  @override
  String get onboardingUnitsHint => 'Modifiable plus tard dans les paramètres';

  @override
  String get unitsMetricTitle => 'Métrique';

  @override
  String get unitsMetricExamples => 'cm, kg, ml';

  @override
  String get unitsImperialTitle => 'Impérial';

  @override
  String get unitsImperialExamples => 'ft, lb, fl oz';

  @override
  String get onboardingHeightTitle => 'Quelle est votre taille ?';

  @override
  String get onboardingHeightHint =>
      'Utilisée pour calculer votre métabolisme de base';

  @override
  String get onboardingWeightTitle => 'Quel est votre poids ?';

  @override
  String get onboardingWeightHint => 'Le point de départ de votre plan';

  @override
  String get heightLabel => 'Taille';

  @override
  String get currentWeightLabel => 'Poids actuel';

  @override
  String get onboardingAgeTitle => 'Quelle est votre date de naissance ?';

  @override
  String get onboardingAgeHint => 'L\'âge influence votre métabolisme';

  @override
  String get onboardingGoalTitle => 'Quel est votre objectif ?';

  @override
  String get onboardingGoalHint =>
      'Nous adapterons un plan nutritionnel à vos besoins';

  @override
  String get goalLoseWeight => 'Perdre du poids';

  @override
  String get goalMaintainWeight => 'Maintenir le poids';

  @override
  String get goalGainWeight => 'Prendre du muscle';

  @override
  String get onboardingActivityTitle => 'Quel est votre niveau d\'activité ?';

  @override
  String get onboardingActivityHint =>
      'Votre activité détermine votre objectif calorique quotidien';

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
  String get onboardingTargetWeightHint =>
      'Nous calculerons le calendrier et le rythme';

  @override
  String get onboardingAgeYearsUnit => 'ans';

  @override
  String get onboardingLoadingCalc => 'Analyse de vos réponses...';

  @override
  String get onboardingLoadingNorm =>
      'Configuration de vos objectifs quotidiens...';

  @override
  String get onboardingLoadingPlan => 'Création de votre plan personnalisé...';

  @override
  String get onboardingResultTitle => 'Votre Plan Personnel';

  @override
  String get resultCongratsTitle => 'Félicitations !';

  @override
  String get resultCongratsSubtitle =>
      'Votre plan de santé personnalisé est prêt !';

  @override
  String get resultCanChange => 'Vous pouvez modifier cela à tout moment';

  @override
  String get resultHowToTitle => 'Comment atteindre vos objectifs';

  @override
  String get resultTip1 => 'Suivez vos repas — créez une habitude saine !';

  @override
  String get resultTip2 => 'Suivez les recommandations caloriques quotidiennes';

  @override
  String get resultTip3 => 'Équilibrez glucides, protéines et lipides';

  @override
  String get resultImprovementsTitle =>
      'Vous remarquerez bientôt des améliorations';

  @override
  String get resultImprovementsBody =>
      'Risque de diabète réduit, pression artérielle plus basse, meilleur taux de cholestérol';

  @override
  String get resultDisclaimer =>
      'Estimations nutritionnelles uniquement. Pas un avis médical.';

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
  String get resultPlanReadyTitle => 'Votre plan personnalisé est prêt';

  @override
  String get resultHeroSubtitle =>
      'Nous avons préparé des recommandations à partir de vos réponses';

  @override
  String get resultRingAdjustLine =>
      'Vous pouvez ajuster ces valeurs à tout moment';

  @override
  String get resultGoalCardTitle => 'Votre objectif';

  @override
  String resultGoalMaintainTitle(String weight) {
    return 'Maintenir le poids autour de $weight';
  }

  @override
  String get resultGoalMaintainSubtitle =>
      'Pas de restrictions strictes — l\'équilibre quotidien suffit';

  @override
  String get resultBridgeTitle =>
      'Pour que le plan fonctionne, vous devez enregistrer chaque jour';

  @override
  String get resultBridgeFreeLine =>
      'Gratuit — 3 enregistrements de repas pour essayer';

  @override
  String get resultBridgePremiumLine =>
      'Avec Premium — sans limites, jusqu\'à votre objectif';

  @override
  String get resultDisclaimerShort =>
      'Les recommandations ne remplacent pas un avis médical';

  @override
  String get resultDisclaimerExpand => 'En savoir plus';

  @override
  String get resultSourcesTitle => 'Sources';

  @override
  String get resultSourceCaloriesLabel => 'Objectif calorique';

  @override
  String get resultSourceMacrosLabel => 'Répartition des macronutriments';

  @override
  String get resultSourcesCta => 'Sources et méthodologie';

  @override
  String get profileMethodology => 'Sources nutritionnelles et méthodologie';

  @override
  String get profileMethodologyIntro =>
      'Comment vos objectifs quotidiens sont estimés';

  @override
  String get methodologyCaloriesSection => 'Objectif calorique';

  @override
  String get methodologyMacrosSection => 'Objectifs en macronutriments';

  @override
  String get methodologyGeneralSection => 'Conseils nutritionnels généraux';

  @override
  String get methodologySourceMifflinDescription =>
      'Formule BMR pour estimer les calories.';

  @override
  String get methodologySourceDriDescription =>
      'Plages de référence pour protéines, lipides et glucides.';

  @override
  String get methodologySourceUsdaDescription =>
      'Références DRI pour calories et nutriments.';

  @override
  String get methodologySourceWhoDescription =>
      'Conseils généraux d\'alimentation saine.';

  @override
  String get methodologyOpenSourceFailed =>
      'Impossible d\'ouvrir cette source.';

  @override
  String get resultOpenPlan => 'Ouvrir mon plan';

  @override
  String get socialProofScaleTitle => 'Conçu pour un suivi sérieux';

  @override
  String get socialProofScaleSubtitle => 'La technologie derrière votre plan';

  @override
  String get socialProofScaleProductsLabel =>
      'Produits dans notre base de données';

  @override
  String get socialProofScaleSecondsUnit => 's';

  @override
  String get socialProofScaleSpeedLabel => 'Reconnaissance photo par IA';

  @override
  String get socialProofPoweredBy => 'Propulsé par';

  @override
  String get socialProofAccuracyTitle => 'Testé pour la précision';

  @override
  String get socialProofAccuracySubtitle =>
      'Avec quelle précision notre IA identifie vos plats';

  @override
  String get socialProofAccuracyLabel => 'Précision de l\'IA';

  @override
  String get socialProofAccuracyDisclaimer =>
      'Sur la base de tests qualité internes effectués sur plus de 500 plats de différentes cuisines.';

  @override
  String get socialProofScienceTitle => 'Fondé sur la science nutritionnelle';

  @override
  String get socialProofScienceSubtitle =>
      'Votre plan repose sur une formule éprouvée';

  @override
  String get socialProofScienceFormulaCaption =>
      'Référence en nutrition depuis 1990';

  @override
  String get socialProofScienceTrust =>
      'Utilisé par des diététiciens et nutritionnistes cliniques dans le monde entier.';

  @override
  String get paywallTitle => 'Essayez Pro\ngratuitement';

  @override
  String get paywallWeeklyTitle => 'Débloquez Pro\naujourd\'hui';

  @override
  String get paywallWeeklyTimelineTodayTitle => 'Aujourd\'hui — débloquez Pro';

  @override
  String get paywallWeeklyTimelineTodayDesc =>
      'Scan IA, suivi des repas et analyses sans limite.';

  @override
  String get paywallWeeklyTimelineRenewTitle => 'Hebdo — progression';

  @override
  String get paywallWeeklyTimelineRenewDesc =>
      'Renouvelé chaque semaine pour garder l\'accès.';

  @override
  String get paywallWeeklyTimelineCancelTitle => 'Annulation à tout moment';

  @override
  String get paywallWeeklyTimelineCancelDesc =>
      'Annulez quand vous voulez depuis votre compte de boutique.';

  @override
  String get paywallTimelineTodayTitle => 'Aujourd\'hui — débloquez Pro';

  @override
  String get paywallTimelineTodayDesc =>
      'Scan IA, suivi des repas et analyses sans limite.';

  @override
  String get paywallTimelineReminderTitle => 'Jour 2 — rappel';

  @override
  String get paywallTimelineReminderDesc =>
      'Nous vous préviendrons avant la fin de l\'essai';

  @override
  String get paywallTimelinePayTitle => 'Jour 3 — paiement';

  @override
  String paywallTimelinePayDesc(String date) {
    return 'Prélèvement le $date, sauf annulation';
  }

  @override
  String get paywallMonthly => 'Hebdomadaire';

  @override
  String get paywallMonthlyPrice => '4,99 \$ / semaine';

  @override
  String get paywallYearly => 'Annuel';

  @override
  String get paywallYearlyPrice => '39,99 \$ / an';

  @override
  String get paywallPerWeek => 'semaine';

  @override
  String get paywallPerYear => 'an';

  @override
  String get paywallTrialBadge => '3 jours gratuits';

  @override
  String get paywallYearlyDiscount => '-85%';

  @override
  String get paywallSubtitle =>
      'Profitez de toutes les fonctionnalités premium de BodyMeal Pro.';

  @override
  String get paywallFeatureAiTitle => 'Reconnaissance IA';

  @override
  String get paywallFeatureAiDesc =>
      'Prenez une photo — l\'IA donne calories et nutriments en une seconde.';

  @override
  String get paywallFeatureDiaryTitle => 'Journal alimentaire';

  @override
  String get paywallFeatureDiaryDesc =>
      'Enregistrez tous vos repas sans limite, chaque jour.';

  @override
  String get paywallFeatureAnalyticsTitle => 'Analyses détaillées';

  @override
  String get paywallFeatureAnalyticsDesc =>
      'Calories, macros et progression vers vos objectifs sur toute période.';

  @override
  String get paywallFeatureBarcodeTitle => 'Scanner de codes-barres';

  @override
  String get paywallFeatureBarcodeDesc =>
      'Pointez la caméra sur l\'emballage — les données s\'ajoutent seules.';

  @override
  String get paywallNoPaymentNow => 'Aucun paiement requis maintenant';

  @override
  String get paywallStartTrial => 'Commencer l\'essai';

  @override
  String get paywallTrialDisclaimer => '3 jours gratuits, puis 39,99 \$/an';

  @override
  String get paywallWeeklyDisclaimer =>
      'Facturé aujourd\'hui. Annulation à tout moment.';

  @override
  String paywallTrialDisclaimerFmt(String price) {
    return '3 jours gratuits, puis $price/an';
  }

  @override
  String get paywallRestore => 'Restaurer';

  @override
  String get paywallTerms => 'Conditions';

  @override
  String get paywallPrivacy => 'Confidentialité';

  @override
  String get paywallHaveCode => 'Vous avez un code ?';

  @override
  String get promoCodeApply => 'Appliquer';

  @override
  String get promoCodeInvalid => 'Code invalide';

  @override
  String get paywallSkip => 'Passer';

  @override
  String get paywallRestoreSuccess => 'Abonnement restauré';

  @override
  String get paywallRestoreNotFound => 'Aucun abonnement actif trouvé';

  @override
  String get paywallSubscriptionError =>
      'Impossible de charger les abonnements. Réessayez plus tard.';

  @override
  String get paywallLoadingPrice => 'Chargement…';

  @override
  String get paywallErrorTitle => 'Abonnement indisponible';

  @override
  String get paywallTryAgain => 'Réessayer';

  @override
  String get paywallErrorStoreUnavailable =>
      'L\'App Store n\'est pas disponible. Vérifiez que vous êtes connecté à l\'App Store et réessayez.';

  @override
  String get paywallErrorProductsEmpty =>
      'Impossible de charger les options d\'abonnement. Vérifiez votre connexion et réessayez.';

  @override
  String get paywallErrorSelectedProductUnavailable =>
      'Cette option d\'abonnement n\'est pas disponible pour le moment. Choisissez une autre offre ou réessayez.';

  @override
  String get paywallErrorQueryFailed =>
      'Impossible de contacter l\'App Store. Réessayez dans un instant.';

  @override
  String get paywallErrorPurchaseFailed =>
      'L\'achat n\'a pas pu aboutir. Veuillez réessayer.';

  @override
  String get paywallErrorRestoreFailed =>
      'Impossible de restaurer les achats. Veuillez réessayer.';

  @override
  String get paywallErrorPaymentPending =>
      'Votre paiement est en attente. Pro sera débloqué dès son approbation.';

  @override
  String get restartOnboarding => 'Recommencer';

  @override
  String get proActive => 'Actif';

  @override
  String get signInToSaveData => 'Connectez-vous pour sauvegarder vos données';

  @override
  String get dataStoredLocally =>
      'Vos données sont stockées uniquement sur cet appareil';

  @override
  String get barcodeScannerTitle => 'Scanner de code-barres';

  @override
  String get barcodeScanHint => 'Pointez la caméra vers un code-barres';

  @override
  String get paywallSubscribeNow => 'S\'abonner';

  @override
  String get paywallHardDisclaimer =>
      'Renouvellement automatique. Annulation à tout moment.';

  @override
  String get paywallHardTitle => 'Continuez\navec Pro';

  @override
  String freeEntriesRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrées gratuites restantes',
      one: '1 entrée gratuite restante',
    );
    return '$_temp0';
  }

  @override
  String get getPro => 'Obtenir Pro';

  @override
  String get freeLimitReached => 'Toutes les entrées gratuites sont épuisées';

  @override
  String get analyticsTitle => 'Analytique';

  @override
  String get summarySection => 'Résumé';

  @override
  String get trendsSection => 'Tendances';

  @override
  String get highlightsSection => 'Points forts';

  @override
  String dayStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Jours consécutifs',
      one: 'Jour consécutif',
    );
    return '$_temp0';
  }

  @override
  String get averageADay => 'moyenne par jour';

  @override
  String calDifferenceCount(int count) {
    return 'Différence de $count cal';
  }

  @override
  String percentAverage(int count) {
    return '$count/100 % moyenne';
  }

  @override
  String analyticsHighlightHigher(String metric) {
    return 'L\'apport moyen en $metric par jour est plus élevé cette semaine que la semaine dernière.';
  }

  @override
  String analyticsHighlightLower(String metric) {
    return 'L\'apport moyen en $metric par jour est plus faible cette semaine que la semaine dernière.';
  }

  @override
  String analyticsHighlightSimilar(String metric) {
    return 'L\'apport moyen en $metric par jour est similaire à la semaine dernière.';
  }

  @override
  String get analyticsPeriod1W => '1 S';

  @override
  String get analyticsPeriod2W => '2 S';

  @override
  String get analyticsPeriod1M => '1 M';

  @override
  String get analyticsPeriod3M => '3 M';

  @override
  String get analyticsPeriod6M => '6 M';

  @override
  String get analyticsPeriod1Y => '1 A';

  @override
  String get analyticsMetricCal => 'Cal';

  @override
  String get analyticsMetricProtein => 'Prot';

  @override
  String get analyticsMetricFat => 'Lip';

  @override
  String get analyticsMetricCarbs => 'Gluc';

  @override
  String get quantityLabel => 'Quantité';

  @override
  String get addSuggestionsLabel => 'Ajouter des suggestions';

  @override
  String get suggestionSomethingElse => 'Autre';

  @override
  String get untitledIngredientName => 'Sans nom';

  @override
  String get onbObstaclesTitle => 'Qu\'est-ce qui vous a freiné jusqu\'ici ?';

  @override
  String get onbObstaclesHint => 'Sélectionnez tout ce qui vous correspond';

  @override
  String get obstacleConsistency => 'Difficile d\'être régulier';

  @override
  String get obstacleKnowledge => 'Je ne sais pas quoi manger';

  @override
  String get obstacleBusy => 'Emploi du temps chargé';

  @override
  String get obstacleCravings => 'Fortes envies de sucré/féculents';

  @override
  String get obstacleSupport => 'Manque de soutien';

  @override
  String get obstacleEatingOut => 'Je mange souvent dehors';

  @override
  String get obstacleMotivation => 'Manque de motivation';

  @override
  String get obstacleTracking => 'Difficile de compter les calories';

  @override
  String get onbSpeedTitleLose =>
      'À quelle vitesse voulez-vous perdre du poids ?';

  @override
  String get onbSpeedTitleGain =>
      'À quelle vitesse voulez-vous prendre du muscle ?';

  @override
  String onbSpeedHintKg(String rate) {
    return 'Rythme recommandé — $rate kg/semaine';
  }

  @override
  String onbSpeedHintLb(String rate) {
    return 'Rythme recommandé — $rate lb/semaine';
  }

  @override
  String onbSpeedKgPerWeek(String value) {
    return '$value kg/semaine';
  }

  @override
  String onbSpeedLbPerWeek(String value) {
    return '$value lb/semaine';
  }

  @override
  String get onbSpeedBadgeGentle => 'Rythme doux ✅';

  @override
  String get onbSpeedBadgeRecommended => 'Rythme recommandé ⭐';

  @override
  String get onbSpeedBadgeAmbitious => 'Ambitieux 🔥';

  @override
  String get onbSpeedBadgeAggressive => 'Très agressif ⚠️';

  @override
  String onbSpeedTargetByPrefix(String weight) {
    return 'Vous atteindrez $weight d’ici';
  }

  @override
  String get onbQuizTitle => 'Parlez-nous de vos habitudes';

  @override
  String get onbQuizHint => 'Cela nous aide à personnaliser votre plan';

  @override
  String get quizStressEatingLeft => 'Je mange quand je stresse';

  @override
  String get quizStressEatingRight => 'Je mange juste pour l’énergie';

  @override
  String get quizSweetPreferenceLeft => 'J\'adore le sucré';

  @override
  String get quizSweetPreferenceRight => 'Je préfère salé/épicé';

  @override
  String get quizExerciseConsistencyLeft => 'Je m\'entraîne régulièrement';

  @override
  String get quizExerciseConsistencyRight =>
      'Je n’arrive pas à tenir une routine';

  @override
  String get quizMealPlanningLeft => 'Je planifie mes repas';

  @override
  String get quizMealPlanningRight => 'Je mange ce qui est sous la main';

  @override
  String get quizMotivationTypeLeft => 'Les résultats me motivent';

  @override
  String get quizMotivationTypeRight => 'Les sensations me motivent';

  @override
  String get onbRateTitle => 'Votre plan vous plaît ?';

  @override
  String get onbRateSubtitle =>
      'Évaluez MealTracker — cela nous aide à progresser';

  @override
  String get onbRateButton => 'Évaluer';

  @override
  String get onbRateSkip => 'Passer';

  @override
  String get onbRateFeedbackTitle => 'Que pouvons-nous améliorer ?';

  @override
  String get onbRateFeedbackHint => 'Dites-nous ce qui n\'a pas marché';

  @override
  String get onbRateFeedbackSubmit => 'Envoyer';

  @override
  String resultAnchorPrefix(String weight) {
    return 'Vous atteindrez $weight d’ici';
  }

  @override
  String resultAnchorWeeksSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '(dans $count semaines)',
      one: '(dans 1 semaine)',
    );
    return '$_temp0';
  }

  @override
  String resultMaintainCard(String weight) {
    return 'Nous vous aiderons à maintenir $weight';
  }

  @override
  String get resultDailyNormLabel => 'VOTRE OBJECTIF QUOTIDIEN';

  @override
  String resultPsychotypeLabel(String title) {
    return 'Votre profil alimentaire : $title';
  }

  @override
  String get resultObstaclesHeader => 'Votre plan prend en compte :';

  @override
  String get resultMilestonesHeader => 'Votre progression hebdomadaire :';

  @override
  String get resultGoalRow => 'Objectif';

  @override
  String resultWeekRow(int week) {
    return 'Semaine $week';
  }

  @override
  String get loadingMetabolism => 'Analyse de votre métabolisme...';

  @override
  String get loadingCalories =>
      'Calcul de votre objectif calorique quotidien...';

  @override
  String get loadingMacros =>
      'Réglage de l’équilibre protéines / lipides / glucides...';

  @override
  String get loadingPsychotype =>
      'Analyse de votre profil alimentaire et de vos habitudes...';

  @override
  String get loadingPlanCreate => 'Création de votre plan personnel...';

  @override
  String get psyStressEaterTitle => 'Le Mangeur de Stress';

  @override
  String get psyStressEaterDesc =>
      'Vous mangez avec vos émotions. Nous trouverons des alternatives.';

  @override
  String get psyFuelFocusedTitle => 'Le Carburant';

  @override
  String get psyFuelFocusedDesc =>
      'Vous mangez rationnellement — nous réglerons les chiffres.';

  @override
  String get psySweetLoverTitle => 'Le Bec Sucré';

  @override
  String get psySweetLoverDesc =>
      'Nous proposerons des alternatives qui apaisent les envies.';

  @override
  String get psySavoryLoverTitle => 'Le Salé-Épicé';

  @override
  String get psySavoryLoverDesc =>
      'Salé et épicé sont votre style — attention au sodium.';

  @override
  String get psyConsistentAthleteTitle => 'Le Régulier';

  @override
  String get psyConsistentAthleteDesc =>
      'Vous avez une base solide. Une diète précise démultipliera les résultats.';

  @override
  String get psyInconsistentTitle => 'Le Redémarreur';

  @override
  String get psyInconsistentDesc =>
      'Le plus dur, c’est de recommencer. Nous le rendrons facile.';

  @override
  String get psyPlannerTitle => 'Le Planificateur';

  @override
  String get psyPlannerDesc =>
      'Vous aimez le contrôle. Laissez l’IA faire les calculs.';

  @override
  String get psyConvenienceEaterTitle => 'Le Pragmatique';

  @override
  String get psyConvenienceEaterDesc =>
      'Peu de temps — nous vous aiderons à choisir vite et bien.';

  @override
  String get psyResultsDrivenTitle => 'L’Accompli';

  @override
  String get psyResultsDrivenDesc =>
      'Les chiffres vous animent — nous montrerons clairement vos progrès.';

  @override
  String get psyFeelingsDrivenTitle => 'L’Intuitif';

  @override
  String get psyFeelingsDrivenDesc =>
      'Vous écoutez votre corps — nous ajouterons les données.';

  @override
  String get psyBalancedTitle => 'L’Équilibré';

  @override
  String get psyBalancedDesc =>
      'Vous avez une approche saine. Nous la renforcerons avec des données.';

  @override
  String get onbWelcomeTitle => 'Créons un plan pour atteindre votre objectif';

  @override
  String get onbWelcomeSubtitle =>
      'Comptez calories et macros rapidement et précisément — sans saisie manuelle !';

  @override
  String get onbWelcomeCta => 'Commencer';

  @override
  String get onbLanguageSheetTitle => 'Choisir la langue';

  @override
  String get langShortEn => 'Ang';

  @override
  String get langShortRu => 'Rus';

  @override
  String get langShortDe => 'All';

  @override
  String get langShortEs => 'Esp';

  @override
  String get langShortFr => 'Fra';

  @override
  String get langShortPt => 'Por';

  @override
  String get onbConfidentTitle => 'Merci de votre confiance';

  @override
  String get onbConfidentSubtitle =>
      'Nous personnalisons MealTracker spécialement pour vos objectifs';

  @override
  String get onbConfidentPrivacyTitle => 'Votre vie privée nous importe';

  @override
  String get onbConfidentPrivacyBody =>
      'Nous nous engageons à garder vos données personnelles confidentielles';

  @override
  String get onbKeepResultTitle =>
      'MealTracker vous aide à garder vos résultats';

  @override
  String get onbKeepResultSubtitle =>
      'Maintenez vos progrès dans la durée — même après six mois !';

  @override
  String get onbCalorieHistoryTitle => 'Avez-vous déjà compté les calories ?';

  @override
  String get onbCalorieHistoryYes => 'Oui, et je continue';

  @override
  String onbCalorieHistoryTried(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'J\'ai essayé, mais j\'ai abandonné',
      'female': 'J\'ai essayé, mais j\'ai abandonné',
      'other': 'J\'ai essayé, mais j\'ai abandonné',
    });
    return '$_temp0';
  }

  @override
  String get onbCalorieHistoryNever => 'Non, jamais';

  @override
  String get onbImproveTitle => 'Que voulez-vous améliorer ?';

  @override
  String get onbImproveLookBetter => 'Avoir meilleure mine';

  @override
  String get onbImproveFeelConfident => 'Avoir plus confiance en moi';

  @override
  String get onbImproveHealth => 'Améliorer ma santé';

  @override
  String get onbImproveMoreEnergy => 'Plus d\'énergie';

  @override
  String get onbImproveLessStress => 'Moins de stress';

  @override
  String get onbImproveImmunity => 'Renforcer l’immunité';

  @override
  String get onbImproveFocus => 'Mieux me concentrer';

  @override
  String get onbImproveSleep => 'Mieux dormir';

  @override
  String get onbEatingObstacleTitle =>
      'Qu\'est-ce qui vous empêche de mieux manger ?';

  @override
  String get onbEatingObstacleCravings => 'Envies de sucré ou de malbouffe';

  @override
  String get onbEatingObstacleLateSnacks => 'Grignotages tardifs';

  @override
  String get onbEatingObstacleBadHabits => 'Mauvaises habitudes';

  @override
  String get onbHardestTitle =>
      'Qu\'est-ce qui est le plus dur — rester régulier ?';

  @override
  String get onbHardestBusy => 'Emploi du temps chargé';

  @override
  String get onbHardestRestrictive => 'Trop de restrictions';

  @override
  String get onbHardestNoSupport => 'Manque de soutien';

  @override
  String get onbSupportTitle => 'Nous serons à vos côtés !';

  @override
  String get onbSupportSubtitle =>
      'Le chemin vers votre objectif peut être difficile, mais nous vous soutiendrons à chaque étape.';

  @override
  String get onbSocialProofTitle =>
      'Avec du soutien, on perd plus de poids et plus vite';

  @override
  String get onbSocialProofSubtitle =>
      'L\'app vous aide à obtenir des résultats durables.';

  @override
  String get onbSpeedSlow => 'Lent';

  @override
  String get onbSpeedBalanced => 'Équilibré';

  @override
  String get onbSpeedFast => 'Rapide';

  @override
  String onbSpeedGoodTitle(String date) {
    return 'Objectif : $date';
  }

  @override
  String get onbSpeedGoodBody =>
      'Un plan raisonnable — des résultats stables, durables, sans épuisement.';

  @override
  String get onbSpeedAlertTitle => 'Trop rapide — risque d\'abandon';

  @override
  String get onbSpeedAlertBody =>
      'Optez pour un rythme plus durable, pour rester régulier et éviter l\'épuisement.';

  @override
  String get onbTrialReminderTitle =>
      'Nous t\'enverrons un rappel\nquand ta période d\'essai\ntouchera à sa fin.';

  @override
  String get onbTrialReminderNoPaymentNow => 'Aucun paiement requis maintenant';

  @override
  String onbTrialReminderCta(String price) {
    return 'Essayer pour $price';
  }

  @override
  String onbTrialReminderSubtitle(String yearly, String monthly) {
    return 'Seulement $yearly par an ($monthly/mois)';
  }
}
