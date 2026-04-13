// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get mealBreakfast => 'Breakfast';

  @override
  String get mealLunch => 'Lunch';

  @override
  String get mealDinner => 'Dinner';

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
  String get yearsUnit => 'years';

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
    return 'Per 100 g: $cal kcal  P$prot F$fat C$carbs';
  }

  @override
  String get proteinShort => 'P';

  @override
  String get fatShort => 'F';

  @override
  String get carbsShort => 'C';

  @override
  String get proteinLabel => 'Protein';

  @override
  String get fatLabel => 'Fat';

  @override
  String get carbsLabel => 'Carbs';

  @override
  String get carbsLabelShort => 'Carbs';

  @override
  String get caloriesLabel => 'Calories';

  @override
  String get caloriesKcalLabel => 'Calories, kcal';

  @override
  String get proteinGramsLabel => 'Protein, g';

  @override
  String get fatGramsLabel => 'Fat, g';

  @override
  String get carbsGramsLabel => 'Carbs, g';

  @override
  String get caloriesKcalInputLabel => 'Calories (kcal)';

  @override
  String proteinGoalLabel(int count) {
    return '$count protein';
  }

  @override
  String fatGoalLabel(int count) {
    return '$count fat';
  }

  @override
  String carbsGoalLabel(int count) {
    return '$count carbs';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get myProfile => 'My Profile';

  @override
  String get subscription => 'Subscription';

  @override
  String get myGoals => 'My Goals';

  @override
  String get myProducts => 'My Products';

  @override
  String get settings => 'Settings';

  @override
  String get productsList => 'Products List';

  @override
  String get allProducts => 'All';

  @override
  String get appTheme => 'App Theme';

  @override
  String get languageSelector => 'Interface Language';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutConfirm => 'Sign out of your account?';

  @override
  String get signOutLocalDataKept => 'Local data will remain on the device.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get add => 'Add';

  @override
  String get close => 'Close';

  @override
  String get edit => 'Edit';

  @override
  String get guestMode => 'Guest Mode';

  @override
  String get defaultUserName => 'User';

  @override
  String get signedInSnackbar => 'Signed in successfully';

  @override
  String get signInGoogle => 'Sign in with Google';

  @override
  String get signInEmail => 'Sign in with Email';

  @override
  String get skipLogin => 'Continue without signing in';

  @override
  String get signInSyncHint =>
      'Signing in allows you to sync data\nacross devices';

  @override
  String get calorieTracking => 'Nutrition & calorie tracking';

  @override
  String get loginTitle => 'Sign In';

  @override
  String get registerTitle => 'Sign Up';

  @override
  String get nameOptional => 'Name (optional)';

  @override
  String get enterEmail => 'Enter email';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get enterPassword => 'Enter password';

  @override
  String get minPasswordLength => 'Minimum 6 characters';

  @override
  String get signInButton => 'Sign In';

  @override
  String get registerButton => 'Sign Up';

  @override
  String get switchToLogin => 'Sign in to account';

  @override
  String get wrongCredentials => 'Wrong email or password';

  @override
  String signInError(String error) {
    return 'Sign-in error: $error';
  }

  @override
  String get emailAlreadyRegistered => 'This email is already registered';

  @override
  String registerError(String error) {
    return 'Registration error: $error';
  }

  @override
  String get proTitle => 'MealTracker Pro';

  @override
  String get proUnlockFeatures => 'Unlock all features:';

  @override
  String get proAiUnlimited => 'Unlimited AI recognition';

  @override
  String get proExtendedStats => 'Extended statistics';

  @override
  String get proPersonalRecommendations => 'Personal recommendations';

  @override
  String get proTryFree => 'Try for free';

  @override
  String get planLabel => 'Plan:';

  @override
  String get planWeekly => 'Weekly';

  @override
  String get billingLabel => 'Next billing:';

  @override
  String get manageSubscription => 'Manage Subscription';

  @override
  String get goalCaloriesKcal => 'Calories, kcal';

  @override
  String get goalProteinG => 'Protein, g';

  @override
  String get goalFatG => 'Fat, g';

  @override
  String get goalCarbsG => 'Carbs, g';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get reminderOff => 'Off';

  @override
  String get remindersDescription =>
      'Reminders will be sent daily at the specified time so you don\'t forget to log your meals.';

  @override
  String get notifBreakfastBody => 'Time to log breakfast';

  @override
  String get notifLunchBody => 'Time to log lunch';

  @override
  String get notifDinnerBody => 'Time to log dinner';

  @override
  String get notifSnackBody => 'Don\'t forget to log your snack';

  @override
  String get notifChannelName => 'Meal reminders';

  @override
  String get notifChannelDesc => 'Reminders to log meals';

  @override
  String get diaryRecordsForDay => 'Today\'s entries';

  @override
  String get diaryEmptyDay => 'No entries for this day yet';

  @override
  String get addMealTitle => 'Add Meal';

  @override
  String get mealTypeLabel => 'Meal Type';

  @override
  String get searchInDb => 'Search database';

  @override
  String get fromGallery => 'From gallery';

  @override
  String get recognizeByPhoto => 'Recognize by photo';

  @override
  String get productNameOrDish => 'Product or dish name';

  @override
  String get addEntry => 'Add entry';

  @override
  String get recognizingViaAi => 'Recognizing via AI...';

  @override
  String get notFoundInDb => 'Not found in database\nTap ➜ to recognize via AI';

  @override
  String get historyTab => 'History';

  @override
  String get favoritesTab => 'Favorites';

  @override
  String get noRecentRecords => 'No recent records';

  @override
  String get noFavoriteProducts => 'No favorite products';

  @override
  String get gramsDialogLabel => 'Grams';

  @override
  String get favoriteUpdated => 'Favorites updated';

  @override
  String get addToFavorite => 'Add to favorites';

  @override
  String get dayNotYet => 'This day hasn\'t come yet!';

  @override
  String get voiceUnavailable =>
      'Voice input unavailable. Check microphone permissions.';

  @override
  String get holdToRecord => 'Hold to record voice';

  @override
  String copyMealTo(String meal) {
    return 'Copy $meal to…';
  }

  @override
  String copiedRecords(int count, String date) {
    return 'Copied $count entries to $date';
  }

  @override
  String get dayMon => 'MO';

  @override
  String get dayTue => 'TU';

  @override
  String get dayWed => 'WE';

  @override
  String get dayThu => 'TH';

  @override
  String get dayFri => 'FR';

  @override
  String get daySat => 'SA';

  @override
  String get daySun => 'SU';

  @override
  String get aiAnalyzingPhoto => 'Analyzing photo...';

  @override
  String get aiRecognizingIngredients => 'Recognizing ingredients...';

  @override
  String get aiCountingCalories => 'Counting calories...';

  @override
  String get aiDeterminingMacros => 'Determining macros...';

  @override
  String get aiAlmostDone => 'Almost done...';

  @override
  String get aiAnalyzingData => 'Analyzing data...';

  @override
  String get aiRecognitionFailed => 'Could not recognize the dish';

  @override
  String get aiRecognizingDish => 'Recognizing dish';

  @override
  String get addDish => 'Add Dish';

  @override
  String get dishNameLabel => 'Name';

  @override
  String get dishParameters => 'Dish Parameters';

  @override
  String get ingredientsLabel => 'Ingredients';

  @override
  String get unknownDish => 'Unknown dish';

  @override
  String get defaultDishName => 'Dish';

  @override
  String get saveEntry => 'Add entry';

  @override
  String get saveChanges => 'Save';

  @override
  String get recognizeDish => 'Recognize dish';

  @override
  String get cameraLabel => 'Camera';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchHint => 'Search products...';

  @override
  String get nothingFound => 'Nothing found';

  @override
  String get recognizeViaAi => 'Recognize via AI';

  @override
  String get createProduct => 'Create product';

  @override
  String get newProduct => 'New Product';

  @override
  String get basicInfo => 'Basic Info';

  @override
  String get productNameRequired => 'Name *';

  @override
  String get enterName => 'Enter name';

  @override
  String get brandOptional => 'Brand (optional)';

  @override
  String get servingWeightG => 'Serving weight (g)';

  @override
  String get macrosPer100g => 'Macros per 100 g';

  @override
  String get caloriesAutoCalc => 'Auto-calculated from macros';

  @override
  String get productAdded => 'Product added';

  @override
  String get saveProduct => 'Save Product';

  @override
  String get myProductsCategory => 'My Products';

  @override
  String get newRecipe => 'New Recipe';

  @override
  String get recipeNameRequired => 'Recipe name *';

  @override
  String get servingsCount => 'Number of servings';

  @override
  String get enterRecipeName => 'Enter recipe name';

  @override
  String get addAtLeastOneIngredient => 'Add at least one ingredient';

  @override
  String get recipeSaved => 'Recipe saved';

  @override
  String get totalForRecipe => 'Total for recipe';

  @override
  String get per100g => 'Per 100 g:';

  @override
  String perServing(int grams) {
    return 'Per serving ($grams g):';
  }

  @override
  String get ingredientSearchHint => 'Search ingredient...';

  @override
  String get startTypingName => 'Start typing a name';

  @override
  String get tapAddToSelect => 'Tap \"Add\" to\nselect products';

  @override
  String ingredientsCount(int count) {
    return 'Ingredients ($count)';
  }

  @override
  String get weightLabel => 'Weight';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String productAddedToMeal(String name) {
    return '$name added';
  }

  @override
  String get historyTitle => 'History';

  @override
  String get noRecords => 'No records';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get averageLabel => 'Average';

  @override
  String get byDays => 'By days';

  @override
  String get periodWeek => 'Week';

  @override
  String get period2Weeks => '2 weeks';

  @override
  String get periodMonth => 'Month';

  @override
  String totalGrams(int count) {
    return 'Total $count g';
  }

  @override
  String get noOwnProducts => 'No custom products';

  @override
  String get createProductWithMacros => 'Create a product with macros';

  @override
  String get productLabel => 'Product';

  @override
  String get deleteConfirm => 'Delete?';

  @override
  String deleteWhat(String what) {
    return 'Delete $what?';
  }

  @override
  String get customizeView => 'Customize View';

  @override
  String get primaryMetric => 'Primary Metric';

  @override
  String get otherMetrics => 'Other Metrics';

  @override
  String get showMore => 'Show more';

  @override
  String get showLess => 'Show less';

  @override
  String get networkTimeout =>
      'Server not responding. Check your internet connection.';

  @override
  String get networkSslError => 'SSL connection error. Try again later.';

  @override
  String networkConnectionError(String message) {
    return 'Connection error: $message';
  }

  @override
  String get networkRetryFailed => 'Could not reach the server.';

  @override
  String get networkHostLookup =>
      'Server temporarily unavailable. Check internet or try in a minute.';

  @override
  String get networkConnectionRefused =>
      'Server not accepting connections. Try again later.';

  @override
  String get networkConnectionReset => 'Connection lost. Try again.';

  @override
  String get networkGenericError =>
      'Network error. Check your internet connection.';

  @override
  String get onboardingGenderTitle => 'Select your gender';

  @override
  String get onboardingGenderHint => 'Needed for accurate calorie calculation';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get onboardingMeasurementsTitle => 'Your measurements';

  @override
  String get heightLabel => 'Height';

  @override
  String get currentWeightLabel => 'Current weight';

  @override
  String get onboardingAgeTitle => 'How old are you?';

  @override
  String get onboardingGoalTitle => 'What is your goal?';

  @override
  String get goalLoseWeight => 'Lose weight';

  @override
  String get goalMaintainWeight => 'Maintain weight';

  @override
  String get goalGainWeight => 'Gain muscle';

  @override
  String get onboardingActivityTitle => 'How active are you?';

  @override
  String get activitySedentary => 'Sedentary';

  @override
  String get activitySedentaryDesc => 'Desk job, little walking';

  @override
  String get activityLight => 'Lightly active';

  @override
  String get activityLightDesc => 'Light exercise 1-3 times a week';

  @override
  String get activityModerate => 'Moderately active';

  @override
  String get activityModerateDesc => 'Exercise 3-5 times a week';

  @override
  String get activityHigh => 'Very active';

  @override
  String get activityHighDesc => 'Heavy exercise 6-7 times a week';

  @override
  String get onboardingTargetWeightTitle => 'What is your target weight?';

  @override
  String get safeWeightLossPace => 'Safe pace — 0.5 kg per week';

  @override
  String get recommendedWeightGainPace => 'Recommended pace — 0.25 kg per week';

  @override
  String get onboardingLoadingCalc => 'Calculating metabolism...';

  @override
  String get onboardingLoadingNorm => 'Finding your calorie norm...';

  @override
  String get onboardingLoadingPlan => 'Creating your personal plan...';

  @override
  String get onboardingResultTitle => 'Your Personal Plan';

  @override
  String get kcalPerDay => 'kcal/day';

  @override
  String get weightLossGoalText => 'weight loss';

  @override
  String get weightGainGoalText => 'muscle gain';

  @override
  String achievableGoal(String goalText) {
    return 'Achievable $goalText goal';
  }

  @override
  String weeksToGoal(int weeks, String date) {
    return '$weeks weeks to goal — by $date';
  }

  @override
  String maintainWeightHint(String weight) {
    return 'We\'ll help you maintain your weight\nat $weight kg';
  }

  @override
  String weightWithUnit(String value) {
    return '$value kg';
  }

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Start';

  @override
  String get paywallTitle => 'Start your journey\nto results';

  @override
  String get paywallAiRecognition => 'AI food recognition';

  @override
  String get paywallAiRecognitionDesc =>
      'Take a photo and learn calories in a second';

  @override
  String get paywallPersonalGoals => 'Personal goals';

  @override
  String get paywallPersonalGoalsDesc =>
      'Norm calculated for your body and goal';

  @override
  String get paywallProgressTracking => 'Progress tracking';

  @override
  String get paywallProgressTrackingDesc => 'Visual stats by days and weeks';

  @override
  String get paywallWeekly => 'Weekly';

  @override
  String get paywallWeeklyPrice => '\$2.99/week';

  @override
  String get paywallWeeklyTrial => 'First 3 days — free';

  @override
  String get paywallPopular => 'Popular';

  @override
  String get paywallYearly => 'Yearly';

  @override
  String get paywallYearlyPrice => '\$19.99/year';

  @override
  String get paywallYearlySavings => '≈ \$0.05/day · Save 85%';

  @override
  String get paywallRating => '4.8 · Over 10,000 users';

  @override
  String get paywallToday => 'Today';

  @override
  String get paywallFullAccess => 'Full access';

  @override
  String get paywallDay2 => 'Day 2';

  @override
  String get paywallReminder => 'Reminder';

  @override
  String get paywallDay3 => 'Day 3';

  @override
  String get paywallDay3Price => '\$2.99';

  @override
  String get paywallContinue => 'Continue';

  @override
  String get paywallDisclaimer =>
      'Cancel anytime. No charge during\nthe trial period.';

  @override
  String get paywallSkip => 'Skip';

  @override
  String get barcodeScannerTitle => 'Barcode Scanner';

  @override
  String get barcodeScanHint => 'Point the camera at a barcode';
}
