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
  String get yearsUnit => 'year of birth';

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
  String get pushNotificationsShortOn => 'On';

  @override
  String get pushNotificationsShortOff => 'Off';

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
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountConfirmTitle => 'Delete your account?';

  @override
  String get deleteAccountConfirmMessage =>
      'This will permanently delete your account and remove your local meal history, recipes, products, favorites, and settings from this device. This cannot be undone.';

  @override
  String get deleteAccountFinalConfirmTitle => 'Are you absolutely sure?';

  @override
  String get deleteAccountFinalConfirmMessage =>
      'Your account and data will be deleted permanently.';

  @override
  String get deleteAccountSuccess => 'Your account has been deleted.';

  @override
  String get deleteAccountFailed =>
      'Could not delete the account. Please check your connection and try again.';

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
  String get signInTitle => 'Sign in to your account';

  @override
  String get signInGoogle => 'Sign in with Google';

  @override
  String get signInApple => 'Sign in with Apple';

  @override
  String get signInEmail => 'Sign in with Email';

  @override
  String get startOverOnboarding => 'Start over';

  @override
  String get startOverOnboardingConfirm =>
      'Start onboarding from the beginning?';

  @override
  String get startOverOnboardingHint =>
      'Your questionnaire answers will be reset. Diary data on this device is kept.';

  @override
  String get skipLogin => 'Continue without signing in';

  @override
  String get signInSyncHint =>
      'Signing in allows you to sync data\nacross devices';

  @override
  String get calorieTracking => 'Nutrition & calorie tracking';

  @override
  String get mergeLocalDataTitle => 'Migrate your latest data to your account?';

  @override
  String get mergeLocalDataKeep => 'Migrate';

  @override
  String get mergeLocalDataReplace => 'Leave as is';

  @override
  String get loginSyncing => 'Syncing…';

  @override
  String get loginSyncFailed =>
      'Couldn\'t sync your data. Please try again later.';

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
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get resetPasswordHint =>
      'Enter the email you used to sign up. We\'ll send a 6-digit code to reset your password.';

  @override
  String get sendResetCode => 'Send code';

  @override
  String get enterCodeTitle => 'Enter Code';

  @override
  String resetCodeSentTo(String email) {
    return 'We sent a 6-digit code to $email';
  }

  @override
  String get enterSixDigitCode => 'Enter the 6-digit code';

  @override
  String get verifyCode => 'Verify';

  @override
  String get resendCode => 'Resend code';

  @override
  String resendCodeIn(int seconds) {
    return 'Resend in $seconds s';
  }

  @override
  String get resetCodeResent => 'Code resent';

  @override
  String get newPasswordTitle => 'New Password';

  @override
  String get newPasswordHint => 'Create a new password for your account.';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get resetPasswordButton => 'Reset password';

  @override
  String get passwordResetSuccess =>
      'Password reset successfully. Sign in with your new password.';

  @override
  String get emailNotFound => 'No account with this email';

  @override
  String get invalidResetCode => 'Invalid or expired code';

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
  String get planYearly => 'Yearly';

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
  String get diaryViewLabel => 'View';

  @override
  String get diaryViewCompact => 'compact';

  @override
  String get diaryViewExpanded => 'expanded';

  @override
  String get recordsSortNewestFirst => 'Newest first';

  @override
  String get recordsSortOldestFirst => 'Oldest first';

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
  String get historyTab => 'Recent';

  @override
  String get favoritesTab => 'Favorites';

  @override
  String get noRecentRecords => 'No recent records';

  @override
  String get addMenuRecentEntries => 'Recommended';

  @override
  String get scanBarcodeAction => 'Scan barcode';

  @override
  String get attachPhotoAction => 'Attach photo';

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
  String get logEntry => 'Log entry';

  @override
  String get saveMacros => 'Save macros';

  @override
  String get macrosSavedToast => 'Macros saved';

  @override
  String get updateDish => 'Update dish';

  @override
  String get refineDish => 'Refine dish';

  @override
  String get refineDishHint => 'Refine the dish ...';

  @override
  String get activityWalking => 'Walking';

  @override
  String get activityBicycle => 'Cycling';

  @override
  String get activityResting => 'Resting';

  @override
  String approxHours(int count) {
    return '~ $count h';
  }

  @override
  String approxMinutes(int count) {
    return '~ $count min';
  }

  @override
  String get healthRatingLabel => 'Health rating';

  @override
  String healthRatingValue(int value) {
    return '$value / 10';
  }

  @override
  String get healthDescPoor =>
      'Heavy on calories, refined carbs, fat, or sodium — best as an occasional treat.';

  @override
  String get healthDescFair =>
      'Tasty and filling, but likely high in calories, refined carbs, fat, and sodium.';

  @override
  String get healthDescGood =>
      'A balanced meal with a reasonable mix of macros.';

  @override
  String get healthDescGreat =>
      'Nutrient-dense and well-balanced — a great choice.';

  @override
  String get healthDescVeggie =>
      'Light and water-rich — packed with micronutrients per calorie.';

  @override
  String get healthDescHighProtein =>
      'Protein-dominant — great for satiety and recovery.';

  @override
  String get healthDescLeanProtein =>
      'Lean protein with low fat — a strong building block.';

  @override
  String get healthDescBalanced =>
      'Balanced macros — fits well into most meal plans.';

  @override
  String get healthDescCarbHeavy =>
      'Carb-forward — pair with protein or veggies for staying power.';

  @override
  String get healthDescFatHeavy =>
      'Calorie-dense from fats — keep an eye on portion size.';

  @override
  String get healthDescSweet =>
      'Sugary and energy-dense — keep this one occasional.';

  @override
  String get healthDescUltraProcessed =>
      'Calorie-dense with little protein — limit how often you eat it.';

  @override
  String get healthTraitHighProtein => 'Notably protein-rich.';

  @override
  String get healthTraitLowCalDensity => 'Easy on the calorie budget.';

  @override
  String get healthTraitHighFat => 'Calorie-dense from fat.';

  @override
  String get healthTraitHighCarb => 'Carbs make up the bulk.';

  @override
  String get healthTraitBalancedMacros => 'Macros are evenly split.';

  @override
  String get healthAdviceGreat => 'Great fit for most days.';

  @override
  String get healthAdviceGood => 'A solid pick for a balanced day.';

  @override
  String get healthAdviceFair => 'Enjoy in moderation.';

  @override
  String get healthAdvicePoor => 'Best kept as an occasional treat.';

  @override
  String get ofYourDailyCalories => 'of your daily calories';

  @override
  String dailyCaloriesPercent(int percent) {
    return '$percent%';
  }

  @override
  String get recognizeDish => 'Recognize dish';

  @override
  String get photoDetailsHint => 'Describe in more detail if you want ...';

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
  String get onboardingUnitsTitle => 'Units of measurement';

  @override
  String get onboardingUnitsHint => 'You can change this later in settings';

  @override
  String get unitsMetricTitle => 'Metric';

  @override
  String get unitsMetricExamples => 'cm, kg, ml';

  @override
  String get unitsImperialTitle => 'Imperial';

  @override
  String get unitsImperialExamples => 'ft, lb, fl oz';

  @override
  String get onboardingHeightTitle => 'What is your height?';

  @override
  String get onboardingHeightHint =>
      'Used to calculate your basal metabolic rate';

  @override
  String get onboardingWeightTitle => 'What is your weight?';

  @override
  String get onboardingWeightHint => 'The starting point for your plan';

  @override
  String get heightLabel => 'Height';

  @override
  String get currentWeightLabel => 'Current weight';

  @override
  String get onboardingAgeTitle => 'When is your birthday?';

  @override
  String get onboardingAgeHint => 'Age affects your metabolic rate';

  @override
  String get onboardingGoalTitle => 'What is your goal?';

  @override
  String get onboardingGoalHint =>
      'We\'ll tailor a nutrition plan to your needs';

  @override
  String get goalLoseWeight => 'Lose weight';

  @override
  String get goalMaintainWeight => 'Maintain weight';

  @override
  String get goalGainWeight => 'Gain muscle';

  @override
  String get onboardingActivityTitle => 'How active are you?';

  @override
  String get onboardingActivityHint =>
      'Activity level determines your daily calorie goal';

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
  String get onboardingTargetWeightHint => 'We\'ll calculate timeline and pace';

  @override
  String get onboardingAgeYearsUnit => 'years';

  @override
  String get onboardingLoadingCalc => 'Analyzing your answers...';

  @override
  String get onboardingLoadingNorm => 'Setting your daily targets...';

  @override
  String get onboardingLoadingPlan => 'Creating your personal plan...';

  @override
  String get onboardingResultTitle => 'Your Personal Plan';

  @override
  String get resultCongratsTitle => 'Congratulations!';

  @override
  String get resultCongratsSubtitle => 'Your personal health plan is ready!';

  @override
  String get resultCanChange => 'You can change this at any time';

  @override
  String get resultHowToTitle => 'How to reach your goals';

  @override
  String get resultTip1 => 'Track your meals — build a healthy habit!';

  @override
  String get resultTip2 => 'Follow daily calorie recommendations';

  @override
  String get resultTip3 => 'Balance your carbs, protein, and fats';

  @override
  String get resultImprovementsTitle => 'You\'ll soon notice improvements';

  @override
  String get resultImprovementsBody =>
      'Lower risk of diabetes, lower blood pressure, better cholesterol levels';

  @override
  String get resultDisclaimer =>
      'Nutrition estimates only. Not medical advice.';

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
  String get resultPlanReadyTitle => 'Your personal plan is ready';

  @override
  String get resultHeroSubtitle => 'Based on your answers';

  @override
  String get resultRingAdjustLine => 'You can adjust these values at any time';

  @override
  String get resultGoalCardTitle => 'Your goal';

  @override
  String resultGoalMaintainTitle(String weight) {
    return 'Maintain weight at about $weight';
  }

  @override
  String get resultGoalMaintainSubtitle =>
      'No strict limits — daily balance is what matters';

  @override
  String get resultBridgeTitle =>
      'For the plan to work, you need to track every day';

  @override
  String get resultBridgeFreeLine => 'Free — 10 meal entries to try it out';

  @override
  String get resultBridgePremiumLine =>
      'With Premium — no limits, all the way to your goal';

  @override
  String get resultDisclaimerShort =>
      'Recommendations do not replace medical advice';

  @override
  String get resultDisclaimerExpand => 'Learn more';

  @override
  String get resultSourcesTitle => 'Sources';

  @override
  String get resultSourceCaloriesLabel => 'Calorie target';

  @override
  String get resultSourceMacrosLabel => 'Macronutrient ranges';

  @override
  String get resultSourcesCta => 'Sources and methodology';

  @override
  String get profileMethodology => 'Nutrition sources & methodology';

  @override
  String get profileMethodologyIntro => 'How your daily targets are estimated';

  @override
  String get methodologyCaloriesSection => 'Calorie target';

  @override
  String get methodologyMacrosSection => 'Macronutrient targets';

  @override
  String get methodologyGeneralSection => 'General nutrition guidance';

  @override
  String get methodologySourceMifflinDescription =>
      'BMR formula for calorie estimates.';

  @override
  String get methodologySourceDriDescription =>
      'Reference ranges for protein, fat, and carbs.';

  @override
  String get methodologySourceUsdaDescription =>
      'DRI-based calorie and nutrient references.';

  @override
  String get methodologySourceWhoDescription =>
      'General healthy eating guidance.';

  @override
  String get methodologyOpenSourceFailed => 'Could not open this source.';

  @override
  String get resultOpenPlan => 'Open my plan';

  @override
  String get socialProofScaleTitle => 'Built for serious tracking';

  @override
  String get socialProofScaleSubtitle => 'The technology behind your plan';

  @override
  String get socialProofScaleProductsLabel => 'Products in our database';

  @override
  String get socialProofScaleSecondsUnit => 'sec';

  @override
  String get socialProofScaleSpeedLabel => 'AI photo recognition';

  @override
  String get socialProofPoweredBy => 'Powered by';

  @override
  String get socialProofAccuracyTitle => 'Tested for accuracy';

  @override
  String get socialProofAccuracySubtitle =>
      'How well our AI identifies your meals';

  @override
  String get socialProofAccuracyLabel => 'AI accuracy';

  @override
  String get socialProofAccuracyDisclaimer =>
      'Based on internal quality testing on 500+ dishes from a range of cuisines.';

  @override
  String get socialProofScienceTitle => 'Backed by nutrition science';

  @override
  String get socialProofScienceSubtitle =>
      'Your plan is built on a proven formula';

  @override
  String get socialProofScienceFormulaCaption =>
      'Nutrition gold standard since 1990';

  @override
  String get socialProofScienceTrust =>
      'Used by registered dietitians and clinical nutritionists worldwide.';

  @override
  String get paywallTitle => 'Try Pro\nfor free';

  @override
  String get paywallWeeklyTitle => 'Unlock Pro\ntoday';

  @override
  String get paywallWeeklyTimelineTodayTitle => 'Today — unlock Pro';

  @override
  String get paywallWeeklyTimelineTodayDesc =>
      'AI scanning, meal tracking, and insights without limits.';

  @override
  String get paywallWeeklyTimelineRenewTitle => 'Weekly — progress';

  @override
  String get paywallWeeklyTimelineRenewDesc =>
      'Renews weekly so your access stays uninterrupted.';

  @override
  String get paywallWeeklyTimelineCancelTitle => 'Cancel anytime';

  @override
  String get paywallWeeklyTimelineCancelDesc =>
      'Cancel anytime in your store account settings.';

  @override
  String get paywallTimelineTodayTitle => 'Today — unlock Pro';

  @override
  String get paywallTimelineTodayDesc =>
      'AI scanning, meal tracking, and insights without limits.';

  @override
  String get paywallTimelineReminderTitle => 'Day 2 — reminder';

  @override
  String get paywallTimelineReminderDesc =>
      'We\'ll remind you before the trial ends';

  @override
  String get paywallTimelinePayTitle => 'Day 3 — payment';

  @override
  String paywallTimelinePayDesc(String date) {
    return 'Charged on $date unless you cancel first';
  }

  @override
  String get paywallMonthly => 'Weekly';

  @override
  String get paywallMonthlyPrice => '\$4.99 / week';

  @override
  String get paywallYearly => 'Yearly';

  @override
  String get paywallYearlyPrice => '\$39.99 / year';

  @override
  String get paywallPerWeek => 'week';

  @override
  String get paywallPerYear => 'year';

  @override
  String get paywallTrialBadge => '3 DAYS FREE';

  @override
  String get paywallNoPaymentNow => 'No payment required now';

  @override
  String get paywallStartTrial => 'Start trial';

  @override
  String get paywallTrialDisclaimer => '3 days free, then \$39.99/year';

  @override
  String get paywallWeeklyDisclaimer => 'Billed today. Cancel anytime.';

  @override
  String paywallTrialDisclaimerFmt(String price) {
    return '3 days free, then $price/year';
  }

  @override
  String get paywallRestore => 'Restore';

  @override
  String get paywallTerms => 'Terms';

  @override
  String get paywallPrivacy => 'Privacy';

  @override
  String get paywallHaveCode => 'Have a code?';

  @override
  String get promoCodeApply => 'Apply';

  @override
  String get promoCodeInvalid => 'Invalid code';

  @override
  String get paywallSkip => 'Skip';

  @override
  String get paywallRestoreSuccess => 'Subscription restored';

  @override
  String get paywallRestoreNotFound => 'No active subscriptions found';

  @override
  String get paywallSubscriptionError =>
      'Could not load subscriptions. Try again later.';

  @override
  String get paywallLoadingPrice => 'Loading…';

  @override
  String get paywallErrorTitle => 'Subscription unavailable';

  @override
  String get paywallTryAgain => 'Try again';

  @override
  String get paywallErrorStoreUnavailable =>
      'The App Store is not available right now. Please make sure you are signed in to the App Store and try again.';

  @override
  String get paywallErrorProductsEmpty =>
      'We couldn\'t load subscription options. Please check your connection and try again.';

  @override
  String get paywallErrorSelectedProductUnavailable =>
      'This subscription option is not available right now. Please choose another plan or try again.';

  @override
  String get paywallErrorQueryFailed =>
      'Couldn\'t reach the App Store. Please try again in a moment.';

  @override
  String get paywallErrorPurchaseFailed =>
      'The purchase couldn\'t be completed. Please try again.';

  @override
  String get paywallErrorRestoreFailed =>
      'Couldn\'t restore purchases. Please try again.';

  @override
  String get paywallErrorPaymentPending =>
      'Your payment is pending. We\'ll unlock Pro as soon as it\'s approved.';

  @override
  String get restartOnboarding => 'Start over';

  @override
  String get proActive => 'Active';

  @override
  String get signInToSaveData => 'Sign in to save your data';

  @override
  String get dataStoredLocally => 'Your data is stored only on this device';

  @override
  String get barcodeScannerTitle => 'Barcode Scanner';

  @override
  String get barcodeScanHint => 'Point the camera at a barcode';

  @override
  String get paywallSubscribeNow => 'Subscribe';

  @override
  String get paywallHardDisclaimer => 'Auto-renews. Cancel anytime.';

  @override
  String get paywallHardTitle => 'Continue\nwith Pro';

  @override
  String freeEntriesRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count free entries remaining',
      one: '1 free entry remaining',
    );
    return '$_temp0';
  }

  @override
  String get getPro => 'Get Pro';

  @override
  String get freeLimitReached => 'You\'ve used all free entries';
}
