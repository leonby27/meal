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
      'Cette application fournit des informations nutritionnelles mais n\'est pas destinée au diagnostic, au traitement ou à la prévention des maladies. Elle ne remplace pas un avis médical professionnel.';

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
  String get paywallTitle =>
      'Pour continuer, commencez votre essai GRATUIT de 3 jours';

  @override
  String get paywallTimelineTodayTitle => 'Aujourd\'hui';

  @override
  String get paywallTimelineTodayDesc =>
      'Débloquez toutes les fonctionnalités — scan IA des calories et bien plus';

  @override
  String get paywallTimelineReminderTitle => 'Dans 2 jours — rappel';

  @override
  String get paywallTimelineReminderDesc =>
      'Nous vous rappellerons que l\'essai touche à sa fin';

  @override
  String get paywallTimelinePayTitle => 'Dans 3 jours — paiement';

  @override
  String paywallTimelinePayDesc(String date) {
    return 'Le prélèvement aura lieu le $date sauf annulation';
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
  String get paywallTrialBadge => '3 JOURS GRATUITS';

  @override
  String get paywallNoPaymentNow => 'Aucun paiement requis maintenant';

  @override
  String get paywallStartTrial => 'Commencer l\'essai gratuit de 3 jours';

  @override
  String get paywallTrialDisclaimer => '3 jours gratuits, puis 39,99 \$/an';

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
  String get paywallHardTitle => 'Vous aimez l\'app ?\nContinuez avec Pro';

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
}
