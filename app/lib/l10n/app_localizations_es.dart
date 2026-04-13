// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get mealBreakfast => 'Desayuno';

  @override
  String get mealLunch => 'Almuerzo';

  @override
  String get mealDinner => 'Cena';

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
  String get yearsUnit => 'años';

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
    return 'Por 100 g: $cal kcal  P$prot G$fat C$carbs';
  }

  @override
  String get proteinShort => 'P';

  @override
  String get fatShort => 'G';

  @override
  String get carbsShort => 'C';

  @override
  String get proteinLabel => 'Proteínas';

  @override
  String get fatLabel => 'Grasas';

  @override
  String get carbsLabel => 'Carbohidratos';

  @override
  String get carbsLabelShort => 'Carbos';

  @override
  String get caloriesLabel => 'Calorías';

  @override
  String get caloriesKcalLabel => 'Calorías, kcal';

  @override
  String get proteinGramsLabel => 'Proteínas, g';

  @override
  String get fatGramsLabel => 'Grasas, g';

  @override
  String get carbsGramsLabel => 'Carbohidratos, g';

  @override
  String get caloriesKcalInputLabel => 'Calorías (kcal)';

  @override
  String proteinGoalLabel(int count) {
    return '$count proteínas';
  }

  @override
  String fatGoalLabel(int count) {
    return '$count grasas';
  }

  @override
  String carbsGoalLabel(int count) {
    return '$count carbos';
  }

  @override
  String get profileTitle => 'Perfil';

  @override
  String get myProfile => 'Mi Perfil';

  @override
  String get subscription => 'Suscripción';

  @override
  String get myGoals => 'Mis Objetivos';

  @override
  String get myProducts => 'Mis Productos';

  @override
  String get settings => 'Ajustes';

  @override
  String get productsList => 'Lista de Productos';

  @override
  String get allProducts => 'Todos';

  @override
  String get appTheme => 'Tema de la App';

  @override
  String get languageSelector => 'Idioma de la interfaz';

  @override
  String get pushNotifications => 'Notificaciones push';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get signOutConfirm => '¿Cerrar sesión de tu cuenta?';

  @override
  String get signOutLocalDataKept =>
      'Los datos locales permanecerán en el dispositivo.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get save => 'Guardar';

  @override
  String get add => 'Añadir';

  @override
  String get close => 'Cerrar';

  @override
  String get edit => 'Editar';

  @override
  String get guestMode => 'Modo invitado';

  @override
  String get defaultUserName => 'Usuario';

  @override
  String get signedInSnackbar => 'Sesión iniciada correctamente';

  @override
  String get signInGoogle => 'Iniciar sesión con Google';

  @override
  String get signInEmail => 'Iniciar sesión con Email';

  @override
  String get skipLogin => 'Continuar sin iniciar sesión';

  @override
  String get signInSyncHint =>
      'Iniciar sesión permite sincronizar datos\nentre dispositivos';

  @override
  String get calorieTracking => 'Seguimiento de nutrición y calorías';

  @override
  String get loginTitle => 'Iniciar Sesión';

  @override
  String get registerTitle => 'Registrarse';

  @override
  String get nameOptional => 'Nombre (opcional)';

  @override
  String get enterEmail => 'Introduce tu email';

  @override
  String get invalidEmail => 'Email no válido';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get enterPassword => 'Introduce tu contraseña';

  @override
  String get minPasswordLength => 'Mínimo 6 caracteres';

  @override
  String get signInButton => 'Iniciar Sesión';

  @override
  String get registerButton => 'Registrarse';

  @override
  String get switchToLogin => 'Iniciar sesión en cuenta';

  @override
  String get wrongCredentials => 'Email o contraseña incorrectos';

  @override
  String signInError(String error) {
    return 'Error de inicio de sesión: $error';
  }

  @override
  String get emailAlreadyRegistered => 'Este email ya está registrado';

  @override
  String registerError(String error) {
    return 'Error de registro: $error';
  }

  @override
  String get proTitle => 'MealTracker Pro';

  @override
  String get proUnlockFeatures => 'Desbloquea todas las funciones:';

  @override
  String get proAiUnlimited => 'Reconocimiento IA ilimitado';

  @override
  String get proExtendedStats => 'Estadísticas ampliadas';

  @override
  String get proPersonalRecommendations => 'Recomendaciones personalizadas';

  @override
  String get proTryFree => 'Probar gratis';

  @override
  String get planLabel => 'Plan:';

  @override
  String get planWeekly => 'Semanal';

  @override
  String get billingLabel => 'Próxima facturación:';

  @override
  String get manageSubscription => 'Gestionar Suscripción';

  @override
  String get goalCaloriesKcal => 'Calorías, kcal';

  @override
  String get goalProteinG => 'Proteínas, g';

  @override
  String get goalFatG => 'Grasas, g';

  @override
  String get goalCarbsG => 'Carbohidratos, g';

  @override
  String get remindersTitle => 'Recordatorios';

  @override
  String get reminderOff => 'Desactivado';

  @override
  String get remindersDescription =>
      'Los recordatorios se enviarán diariamente a la hora indicada para que no olvides registrar tus comidas.';

  @override
  String get notifBreakfastBody => 'Hora de registrar el desayuno';

  @override
  String get notifLunchBody => 'Hora de registrar el almuerzo';

  @override
  String get notifDinnerBody => 'Hora de registrar la cena';

  @override
  String get notifSnackBody => 'No olvides registrar tu snack';

  @override
  String get notifChannelName => 'Recordatorios de comidas';

  @override
  String get notifChannelDesc => 'Recordatorios para registrar comidas';

  @override
  String get diaryRecordsForDay => 'Entradas de hoy';

  @override
  String get diaryEmptyDay => 'Aún no hay entradas para este día';

  @override
  String get addMealTitle => 'Añadir Comida';

  @override
  String get mealTypeLabel => 'Tipo de comida';

  @override
  String get searchInDb => 'Buscar en la base de datos';

  @override
  String get fromGallery => 'Desde la galería';

  @override
  String get recognizeByPhoto => 'Reconocer por foto';

  @override
  String get productNameOrDish => 'Nombre de producto o plato';

  @override
  String get addEntry => 'Añadir entrada';

  @override
  String get recognizingViaAi => 'Reconociendo con IA...';

  @override
  String get notFoundInDb =>
      'No encontrado en la base de datos\nToca ➜ para reconocer con IA';

  @override
  String get historyTab => 'Historial';

  @override
  String get favoritesTab => 'Favoritos';

  @override
  String get noRecentRecords => 'No hay registros recientes';

  @override
  String get noFavoriteProducts => 'No hay productos favoritos';

  @override
  String get gramsDialogLabel => 'Gramos';

  @override
  String get favoriteUpdated => 'Favoritos actualizados';

  @override
  String get addToFavorite => 'Añadir a favoritos';

  @override
  String get dayNotYet => '¡Este día aún no ha llegado!';

  @override
  String get voiceUnavailable =>
      'Entrada de voz no disponible. Comprueba los permisos del micrófono.';

  @override
  String get holdToRecord => 'Mantén pulsado para grabar voz';

  @override
  String copyMealTo(String meal) {
    return 'Copiar $meal a…';
  }

  @override
  String copiedRecords(int count, String date) {
    return '$count entradas copiadas a $date';
  }

  @override
  String get dayMon => 'LU';

  @override
  String get dayTue => 'MA';

  @override
  String get dayWed => 'MI';

  @override
  String get dayThu => 'JU';

  @override
  String get dayFri => 'VI';

  @override
  String get daySat => 'SÁ';

  @override
  String get daySun => 'DO';

  @override
  String get aiAnalyzingPhoto => 'Analizando foto...';

  @override
  String get aiRecognizingIngredients => 'Reconociendo ingredientes...';

  @override
  String get aiCountingCalories => 'Contando calorías...';

  @override
  String get aiDeterminingMacros => 'Determinando macros...';

  @override
  String get aiAlmostDone => 'Casi listo...';

  @override
  String get aiAnalyzingData => 'Analizando datos...';

  @override
  String get aiRecognitionFailed => 'No se pudo reconocer el plato';

  @override
  String get aiRecognizingDish => 'Reconociendo plato';

  @override
  String get addDish => 'Añadir Plato';

  @override
  String get dishNameLabel => 'Nombre';

  @override
  String get dishParameters => 'Parámetros del plato';

  @override
  String get ingredientsLabel => 'Ingredientes';

  @override
  String get unknownDish => 'Plato desconocido';

  @override
  String get defaultDishName => 'Plato';

  @override
  String get saveEntry => 'Añadir entrada';

  @override
  String get saveChanges => 'Guardar';

  @override
  String get recognizeDish => 'Reconocer plato';

  @override
  String get cameraLabel => 'Cámara';

  @override
  String get searchTitle => 'Buscar';

  @override
  String get searchHint => 'Buscar productos...';

  @override
  String get nothingFound => 'No se encontró nada';

  @override
  String get recognizeViaAi => 'Reconocer con IA';

  @override
  String get createProduct => 'Crear producto';

  @override
  String get newProduct => 'Nuevo Producto';

  @override
  String get basicInfo => 'Información básica';

  @override
  String get productNameRequired => 'Nombre *';

  @override
  String get enterName => 'Introduce el nombre';

  @override
  String get brandOptional => 'Marca (opcional)';

  @override
  String get servingWeightG => 'Peso por porción (g)';

  @override
  String get macrosPer100g => 'Macros por 100 g';

  @override
  String get caloriesAutoCalc => 'Calculado automáticamente a partir de macros';

  @override
  String get productAdded => 'Producto añadido';

  @override
  String get saveProduct => 'Guardar Producto';

  @override
  String get myProductsCategory => 'Mis Productos';

  @override
  String get newRecipe => 'Nueva Receta';

  @override
  String get recipeNameRequired => 'Nombre de la receta *';

  @override
  String get servingsCount => 'Número de porciones';

  @override
  String get enterRecipeName => 'Introduce el nombre de la receta';

  @override
  String get addAtLeastOneIngredient => 'Añade al menos un ingrediente';

  @override
  String get recipeSaved => 'Receta guardada';

  @override
  String get totalForRecipe => 'Total de la receta';

  @override
  String get per100g => 'Por 100 g:';

  @override
  String perServing(int grams) {
    return 'Por porción ($grams g):';
  }

  @override
  String get ingredientSearchHint => 'Buscar ingrediente...';

  @override
  String get startTypingName => 'Empieza a escribir un nombre';

  @override
  String get tapAddToSelect => 'Toca \"Añadir\" para\nseleccionar productos';

  @override
  String ingredientsCount(int count) {
    return 'Ingredientes ($count)';
  }

  @override
  String get weightLabel => 'Peso';

  @override
  String get favoritesTitle => 'Favoritos';

  @override
  String productAddedToMeal(String name) {
    return '$name añadido';
  }

  @override
  String get historyTitle => 'Historial';

  @override
  String get noRecords => 'Sin registros';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String get statsTitle => 'Estadísticas';

  @override
  String get averageLabel => 'Promedio';

  @override
  String get byDays => 'Por días';

  @override
  String get periodWeek => 'Semana';

  @override
  String get period2Weeks => '2 semanas';

  @override
  String get periodMonth => 'Mes';

  @override
  String totalGrams(int count) {
    return 'Total $count g';
  }

  @override
  String get noOwnProducts => 'Sin productos propios';

  @override
  String get createProductWithMacros => 'Crea un producto con macros';

  @override
  String get productLabel => 'Producto';

  @override
  String get deleteConfirm => '¿Eliminar?';

  @override
  String deleteWhat(String what) {
    return '¿Eliminar $what?';
  }

  @override
  String get customizeView => 'Personalizar vista';

  @override
  String get primaryMetric => 'Métrica principal';

  @override
  String get otherMetrics => 'Otras métricas';

  @override
  String get showMore => 'Mostrar más';

  @override
  String get showLess => 'Mostrar menos';

  @override
  String get networkTimeout =>
      'El servidor no responde. Comprueba tu conexión a internet.';

  @override
  String get networkSslError => 'Error de conexión SSL. Inténtalo más tarde.';

  @override
  String networkConnectionError(String message) {
    return 'Error de conexión: $message';
  }

  @override
  String get networkRetryFailed => 'No se pudo contactar con el servidor.';

  @override
  String get networkHostLookup =>
      'Servidor temporalmente no disponible. Comprueba tu internet o inténtalo en un minuto.';

  @override
  String get networkConnectionRefused =>
      'El servidor no acepta conexiones. Inténtalo más tarde.';

  @override
  String get networkConnectionReset => 'Conexión perdida. Inténtalo de nuevo.';

  @override
  String get networkGenericError =>
      'Error de red. Comprueba tu conexión a internet.';

  @override
  String get onboardingGenderTitle => 'Selecciona tu género';

  @override
  String get onboardingGenderHint =>
      'Necesario para un cálculo preciso de calorías';

  @override
  String get genderMale => 'Masculino';

  @override
  String get genderFemale => 'Femenino';

  @override
  String get onboardingMeasurementsTitle => 'Tus medidas';

  @override
  String get heightLabel => 'Altura';

  @override
  String get currentWeightLabel => 'Peso actual';

  @override
  String get onboardingAgeTitle => '¿Cuántos años tienes?';

  @override
  String get onboardingGoalTitle => '¿Cuál es tu objetivo?';

  @override
  String get goalLoseWeight => 'Perder peso';

  @override
  String get goalMaintainWeight => 'Mantener peso';

  @override
  String get goalGainWeight => 'Ganar músculo';

  @override
  String get onboardingActivityTitle => '¿Qué tan activo eres?';

  @override
  String get activitySedentary => 'Sedentario';

  @override
  String get activitySedentaryDesc => 'Trabajo de escritorio, poca actividad';

  @override
  String get activityLight => 'Ligeramente activo';

  @override
  String get activityLightDesc => 'Ejercicio ligero 1–3 veces por semana';

  @override
  String get activityModerate => 'Moderadamente activo';

  @override
  String get activityModerateDesc => 'Ejercicio 3–5 veces por semana';

  @override
  String get activityHigh => 'Muy activo';

  @override
  String get activityHighDesc => 'Ejercicio intenso 6–7 veces por semana';

  @override
  String get onboardingTargetWeightTitle => '¿Cuál es tu peso objetivo?';

  @override
  String get safeWeightLossPace => 'Ritmo seguro — 0,5 kg por semana';

  @override
  String get recommendedWeightGainPace =>
      'Ritmo recomendado — 0,25 kg por semana';

  @override
  String get onboardingLoadingCalc => 'Calculando metabolismo...';

  @override
  String get onboardingLoadingNorm => 'Buscando tu norma calórica...';

  @override
  String get onboardingLoadingPlan => 'Creando tu plan personalizado...';

  @override
  String get onboardingResultTitle => 'Tu Plan Personal';

  @override
  String get kcalPerDay => 'kcal/día';

  @override
  String get weightLossGoalText => 'pérdida de peso';

  @override
  String get weightGainGoalText => 'ganancia muscular';

  @override
  String achievableGoal(String goalText) {
    return 'Objetivo alcanzable de $goalText';
  }

  @override
  String weeksToGoal(int weeks, String date) {
    return '$weeks semanas hasta el objetivo — para $date';
  }

  @override
  String maintainWeightHint(String weight) {
    return 'Te ayudaremos a mantener tu peso\nen $weight kg';
  }

  @override
  String weightWithUnit(String value) {
    return '$value kg';
  }

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingStart => 'Comenzar';

  @override
  String get paywallTitle => 'Comienza tu camino\nhacia los resultados';

  @override
  String get paywallAiRecognition => 'Reconocimiento de alimentos con IA';

  @override
  String get paywallAiRecognitionDesc =>
      'Toma una foto y conoce las calorías al instante';

  @override
  String get paywallPersonalGoals => 'Objetivos personales';

  @override
  String get paywallPersonalGoalsDesc =>
      'Norma calculada para tu cuerpo y objetivo';

  @override
  String get paywallProgressTracking => 'Seguimiento de progreso';

  @override
  String get paywallProgressTrackingDesc =>
      'Estadísticas visuales por días y semanas';

  @override
  String get paywallWeekly => 'Semanal';

  @override
  String get paywallWeeklyPrice => '\$2.99/semana';

  @override
  String get paywallWeeklyTrial => 'Primeros 3 días — gratis';

  @override
  String get paywallPopular => 'Popular';

  @override
  String get paywallYearly => 'Anual';

  @override
  String get paywallYearlyPrice => '\$19.99/año';

  @override
  String get paywallYearlySavings => '≈ \$0.05/día · Ahorra 85%';

  @override
  String get paywallRating => '4.8 · Más de 10.000 usuarios';

  @override
  String get paywallToday => 'Hoy';

  @override
  String get paywallFullAccess => 'Acceso completo';

  @override
  String get paywallDay2 => 'Día 2';

  @override
  String get paywallReminder => 'Recordatorio';

  @override
  String get paywallDay3 => 'Día 3';

  @override
  String get paywallDay3Price => '\$2.99';

  @override
  String get paywallContinue => 'Continuar';

  @override
  String get paywallDisclaimer =>
      'Cancela en cualquier momento. Sin cargos\ndurante el periodo de prueba.';

  @override
  String get paywallSkip => 'Omitir';

  @override
  String get barcodeScannerTitle => 'Escáner de código de barras';

  @override
  String get barcodeScanHint => 'Apunte la cámara al código de barras';
}
