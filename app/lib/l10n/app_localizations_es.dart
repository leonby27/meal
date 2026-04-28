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
  String get yearsUnit => 'año de nacimiento';

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
  String get pushNotificationsShortOn => 'Activado';

  @override
  String get pushNotificationsShortOff => 'Desactivado';

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
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deleteAccountConfirmTitle => '¿Eliminar tu cuenta?';

  @override
  String get deleteAccountConfirmMessage =>
      'Esto eliminará permanentemente tu cuenta y borrará de este dispositivo tu historial de comidas, recetas, productos, favoritos y ajustes. Esta acción no se puede deshacer.';

  @override
  String get deleteAccountFinalConfirmTitle => '¿Estás completamente seguro?';

  @override
  String get deleteAccountFinalConfirmMessage =>
      'Tu cuenta y tus datos se eliminarán permanentemente.';

  @override
  String get deleteAccountSuccess => 'Tu cuenta ha sido eliminada.';

  @override
  String get deleteAccountFailed =>
      'No se pudo eliminar la cuenta. Comprueba tu conexión e inténtalo de nuevo.';

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
  String get signInTitle => 'Inicia sesión';

  @override
  String get signInGoogle => 'Iniciar sesión con Google';

  @override
  String get signInApple => 'Iniciar sesión con Apple';

  @override
  String get signInEmail => 'Iniciar sesión con Email';

  @override
  String get startOverOnboarding => 'Empezar de nuevo';

  @override
  String get startOverOnboardingConfirm =>
      '¿Volver a hacer el onboarding desde el principio?';

  @override
  String get startOverOnboardingHint =>
      'Se restablecerán tus respuestas del cuestionario. Los datos del diario en este dispositivo se conservan.';

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
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get resetPasswordTitle => 'Restablecer contraseña';

  @override
  String get resetPasswordHint =>
      'Introduce el email con el que te registraste. Te enviaremos un código de 6 dígitos.';

  @override
  String get sendResetCode => 'Enviar código';

  @override
  String get enterCodeTitle => 'Introduce el código';

  @override
  String resetCodeSentTo(String email) {
    return 'Enviamos un código de 6 dígitos a $email';
  }

  @override
  String get enterSixDigitCode => 'Introduce el código de 6 dígitos';

  @override
  String get verifyCode => 'Verificar';

  @override
  String get resendCode => 'Reenviar código';

  @override
  String resendCodeIn(int seconds) {
    return 'Reenviar en $seconds s';
  }

  @override
  String get resetCodeResent => 'Código reenviado';

  @override
  String get newPasswordTitle => 'Nueva contraseña';

  @override
  String get newPasswordHint => 'Crea una nueva contraseña para tu cuenta.';

  @override
  String get newPasswordLabel => 'Nueva contraseña';

  @override
  String get confirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get resetPasswordButton => 'Restablecer contraseña';

  @override
  String get passwordResetSuccess =>
      'Contraseña restablecida. Inicia sesión con tu nueva contraseña.';

  @override
  String get emailNotFound => 'No hay cuenta con este email';

  @override
  String get invalidResetCode => 'Código inválido o expirado';

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
  String get planYearly => 'Anual';

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
  String get diaryViewLabel => 'Vista';

  @override
  String get diaryViewCompact => 'compacta';

  @override
  String get diaryViewExpanded => 'ampliada';

  @override
  String get recordsSortNewestFirst => 'Más recientes primero';

  @override
  String get recordsSortOldestFirst => 'Más antiguas primero';

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
  String get historyTab => 'Recientes';

  @override
  String get favoritesTab => 'Favoritos';

  @override
  String get noRecentRecords => 'Sin registros recientes';

  @override
  String get addMenuRecentEntries => 'Recomendados';

  @override
  String get scanBarcodeAction => 'Escanear código de barras';

  @override
  String get attachPhotoAction => 'Adjuntar foto';

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
  String get photoDetailsHint => 'Describe con más detalle si quieres ...';

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
  String get onboardingUnitsTitle => 'Unidades de medida';

  @override
  String get onboardingUnitsHint => 'Puedes cambiarlo más tarde en ajustes';

  @override
  String get unitsMetricTitle => 'Métrica';

  @override
  String get unitsMetricExamples => 'cm, kg, ml';

  @override
  String get unitsImperialTitle => 'Imperial';

  @override
  String get unitsImperialExamples => 'ft, lb, fl oz';

  @override
  String get onboardingHeightTitle => '¿Cuál es tu estatura?';

  @override
  String get onboardingHeightHint =>
      'Se usa para calcular tu metabolismo basal';

  @override
  String get onboardingWeightTitle => '¿Cuál es tu peso?';

  @override
  String get onboardingWeightHint => 'El punto de partida para tu plan';

  @override
  String get heightLabel => 'Altura';

  @override
  String get currentWeightLabel => 'Peso actual';

  @override
  String get onboardingAgeTitle => '¿Cuándo es tu cumpleaños?';

  @override
  String get onboardingAgeHint => 'La edad afecta tu tasa metabólica';

  @override
  String get onboardingGoalTitle => '¿Cuál es tu objetivo?';

  @override
  String get onboardingGoalHint =>
      'Adaptaremos un plan de nutrición a tus necesidades';

  @override
  String get goalLoseWeight => 'Perder peso';

  @override
  String get goalMaintainWeight => 'Mantener peso';

  @override
  String get goalGainWeight => 'Ganar músculo';

  @override
  String get onboardingActivityTitle => '¿Qué tan activo eres?';

  @override
  String get onboardingActivityHint =>
      'Tu nivel de actividad determina tu meta calórica diaria';

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
  String get onboardingTargetWeightHint => 'Calcularemos los plazos y el ritmo';

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
  String get resultCongratsTitle => '¡Felicidades!';

  @override
  String get resultCongratsSubtitle =>
      '¡Tu plan de salud personalizado está listo!';

  @override
  String get resultCanChange => 'Puedes cambiar esto en cualquier momento';

  @override
  String get resultHowToTitle => 'Cómo alcanzar tus metas';

  @override
  String get resultTip1 => 'Registra tus comidas — ¡crea un hábito saludable!';

  @override
  String get resultTip2 => 'Sigue las recomendaciones diarias de calorías';

  @override
  String get resultTip3 => 'Equilibra carbohidratos, proteínas y grasas';

  @override
  String get resultImprovementsTitle =>
      'Pronto notarás mejoras en tu bienestar';

  @override
  String get resultImprovementsBody =>
      'Menor riesgo de diabetes, menor presión arterial, mejor nivel de colesterol';

  @override
  String get resultDisclaimer =>
      'Esta aplicación proporciona información nutricional, pero no está destinada al diagnóstico, tratamiento o prevención de enfermedades. No reemplaza el consejo médico profesional.';

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
  String get socialProofScaleTitle => 'Hecho para un seguimiento serio';

  @override
  String get socialProofScaleSubtitle => 'La tecnología detrás de tu plan';

  @override
  String get socialProofScaleProductsLabel =>
      'Productos en nuestra base de datos';

  @override
  String get socialProofScaleSecondsUnit => 's';

  @override
  String get socialProofScaleSpeedLabel => 'Reconocimiento de comida con IA';

  @override
  String get socialProofPoweredBy => 'Con tecnología de';

  @override
  String get socialProofAccuracyTitle => 'Probado para mayor precisión';

  @override
  String get socialProofAccuracySubtitle =>
      'Qué tan bien nuestra IA identifica tus comidas';

  @override
  String get socialProofAccuracyLabel => 'Precisión de la IA';

  @override
  String get socialProofAccuracyDisclaimer =>
      'Basado en pruebas internas de calidad con más de 500 platos de diversas cocinas.';

  @override
  String get socialProofScienceTitle => 'Respaldado por la nutrición';

  @override
  String get socialProofScienceSubtitle =>
      'Tu plan se basa en una fórmula comprobada';

  @override
  String get socialProofScienceFormulaCaption =>
      'Estándar de oro nutricional desde 1990';

  @override
  String get socialProofScienceTrust =>
      'Utilizado por dietistas y nutricionistas clínicos en todo el mundo.';

  @override
  String get paywallTitle =>
      'Para continuar, inicia tu prueba GRATUITA de 3 días';

  @override
  String get paywallTimelineTodayTitle => 'Hoy';

  @override
  String get paywallTimelineTodayDesc =>
      'Desbloquea todas las funciones — escaneo de calorías con IA y mucho más';

  @override
  String get paywallTimelineReminderTitle => 'En 2 días — recordatorio';

  @override
  String get paywallTimelineReminderDesc =>
      'Te recordaremos que la prueba está por terminar';

  @override
  String get paywallTimelinePayTitle => 'En 3 días — comienza el pago';

  @override
  String paywallTimelinePayDesc(String date) {
    return 'Se cobrará el $date si no cancelas antes';
  }

  @override
  String get paywallMonthly => 'Semanal';

  @override
  String get paywallMonthlyPrice => '\$4.99 / semana';

  @override
  String get paywallYearly => 'Anual';

  @override
  String get paywallYearlyPrice => '\$39.99 / año';

  @override
  String get paywallPerWeek => 'semana';

  @override
  String get paywallPerYear => 'año';

  @override
  String get paywallTrialBadge => '3 DÍAS GRATIS';

  @override
  String get paywallNoPaymentNow => 'No se requiere pago ahora';

  @override
  String get paywallStartTrial => 'Iniciar prueba gratuita de 3 días';

  @override
  String get paywallTrialDisclaimer => '3 días gratis, luego \$39.99/año';

  @override
  String paywallTrialDisclaimerFmt(String price) {
    return '3 días gratis, luego $price/año';
  }

  @override
  String get paywallRestore => 'Restaurar';

  @override
  String get paywallTerms => 'Términos';

  @override
  String get paywallPrivacy => 'Privacidad';

  @override
  String get paywallHaveCode => '¿Tienes un código?';

  @override
  String get promoCodeApply => 'Aplicar';

  @override
  String get promoCodeInvalid => 'Código inválido';

  @override
  String get paywallSkip => 'Omitir';

  @override
  String get paywallRestoreSuccess => 'Suscripción restaurada';

  @override
  String get paywallRestoreNotFound =>
      'No se encontraron suscripciones activas';

  @override
  String get paywallSubscriptionError =>
      'No se pudieron cargar las suscripciones. Inténtalo más tarde.';

  @override
  String get paywallLoadingPrice => 'Cargando…';

  @override
  String get paywallErrorTitle => 'Suscripción no disponible';

  @override
  String get paywallTryAgain => 'Intentar de nuevo';

  @override
  String get paywallErrorStoreUnavailable =>
      'La App Store no está disponible ahora. Asegúrate de haber iniciado sesión en la App Store e inténtalo de nuevo.';

  @override
  String get paywallErrorProductsEmpty =>
      'No se pudieron cargar las opciones de suscripción. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get paywallErrorQueryFailed =>
      'No se pudo conectar con la App Store. Inténtalo de nuevo en un momento.';

  @override
  String get paywallErrorPurchaseFailed =>
      'No se pudo completar la compra. Inténtalo de nuevo.';

  @override
  String get paywallErrorRestoreFailed =>
      'No se pudieron restaurar las compras. Inténtalo de nuevo.';

  @override
  String get paywallErrorPaymentPending =>
      'Tu pago está pendiente. Activaremos Pro en cuanto se apruebe.';

  @override
  String get restartOnboarding => 'Empezar de nuevo';

  @override
  String get proActive => 'Activa';

  @override
  String get signInToSaveData => 'Inicia sesión para guardar tus datos';

  @override
  String get dataStoredLocally =>
      'Tus datos se almacenan solo en este dispositivo';

  @override
  String get barcodeScannerTitle => 'Escáner de código de barras';

  @override
  String get barcodeScanHint => 'Apunte la cámara al código de barras';

  @override
  String get paywallSubscribeNow => 'Suscribirse';

  @override
  String get paywallHardDisclaimer =>
      'Renovación automática. Cancela en cualquier momento.';

  @override
  String get paywallHardTitle => '¿Te gusta la app?\nContinúa con Pro';

  @override
  String freeEntriesRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Quedan $count entradas gratuitas',
      one: 'Queda 1 entrada gratuita',
    );
    return '$_temp0';
  }

  @override
  String get getPro => 'Obtener Pro';

  @override
  String get freeLimitReached => 'Has agotado todas las entradas gratuitas';
}
