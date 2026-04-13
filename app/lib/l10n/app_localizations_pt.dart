// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get mealBreakfast => 'Café da manhã';

  @override
  String get mealLunch => 'Almoço';

  @override
  String get mealDinner => 'Jantar';

  @override
  String get mealSnack => 'Lanche';

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
  String get yearsUnit => 'anos';

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
  String get fatLabel => 'Gorduras';

  @override
  String get carbsLabel => 'Carboidratos';

  @override
  String get carbsLabelShort => 'Carbos';

  @override
  String get caloriesLabel => 'Calorias';

  @override
  String get caloriesKcalLabel => 'Calorias, kcal';

  @override
  String get proteinGramsLabel => 'Proteínas, g';

  @override
  String get fatGramsLabel => 'Gorduras, g';

  @override
  String get carbsGramsLabel => 'Carboidratos, g';

  @override
  String get caloriesKcalInputLabel => 'Calorias (kcal)';

  @override
  String proteinGoalLabel(int count) {
    return '$count proteínas';
  }

  @override
  String fatGoalLabel(int count) {
    return '$count gorduras';
  }

  @override
  String carbsGoalLabel(int count) {
    return '$count carbos';
  }

  @override
  String get profileTitle => 'Perfil';

  @override
  String get myProfile => 'Meu Perfil';

  @override
  String get subscription => 'Assinatura';

  @override
  String get myGoals => 'Meus Objetivos';

  @override
  String get myProducts => 'Meus Produtos';

  @override
  String get settings => 'Configurações';

  @override
  String get productsList => 'Lista de Produtos';

  @override
  String get allProducts => 'Todos';

  @override
  String get appTheme => 'Tema do App';

  @override
  String get languageSelector => 'Idioma da interface';

  @override
  String get pushNotifications => 'Notificações push';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get signOut => 'Sair';

  @override
  String get signOutConfirm => 'Sair da sua conta?';

  @override
  String get signOutLocalDataKept =>
      'Os dados locais permanecerão no dispositivo.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Excluir';

  @override
  String get save => 'Salvar';

  @override
  String get add => 'Adicionar';

  @override
  String get close => 'Fechar';

  @override
  String get edit => 'Editar';

  @override
  String get guestMode => 'Modo visitante';

  @override
  String get defaultUserName => 'Usuário';

  @override
  String get signedInSnackbar => 'Conectado com sucesso';

  @override
  String get signInGoogle => 'Entrar com Google';

  @override
  String get signInEmail => 'Entrar com Email';

  @override
  String get skipLogin => 'Continuar sem entrar';

  @override
  String get signInSyncHint =>
      'Entrar permite sincronizar dados\nentre dispositivos';

  @override
  String get calorieTracking => 'Acompanhamento nutricional e calórico';

  @override
  String get loginTitle => 'Entrar';

  @override
  String get registerTitle => 'Cadastrar';

  @override
  String get nameOptional => 'Nome (opcional)';

  @override
  String get enterEmail => 'Digite seu email';

  @override
  String get invalidEmail => 'Email inválido';

  @override
  String get passwordLabel => 'Senha';

  @override
  String get enterPassword => 'Digite sua senha';

  @override
  String get minPasswordLength => 'Mínimo de 6 caracteres';

  @override
  String get signInButton => 'Entrar';

  @override
  String get registerButton => 'Cadastrar';

  @override
  String get switchToLogin => 'Entrar na conta';

  @override
  String get wrongCredentials => 'Email ou senha incorretos';

  @override
  String signInError(String error) {
    return 'Erro ao entrar: $error';
  }

  @override
  String get emailAlreadyRegistered => 'Este email já está cadastrado';

  @override
  String registerError(String error) {
    return 'Erro no cadastro: $error';
  }

  @override
  String get proTitle => 'MealTracker Pro';

  @override
  String get proUnlockFeatures => 'Desbloqueie todos os recursos:';

  @override
  String get proAiUnlimited => 'Reconhecimento IA ilimitado';

  @override
  String get proExtendedStats => 'Estatísticas detalhadas';

  @override
  String get proPersonalRecommendations => 'Recomendações personalizadas';

  @override
  String get proTryFree => 'Experimentar grátis';

  @override
  String get planLabel => 'Plano:';

  @override
  String get planWeekly => 'Semanal';

  @override
  String get billingLabel => 'Próxima cobrança:';

  @override
  String get manageSubscription => 'Gerenciar Assinatura';

  @override
  String get goalCaloriesKcal => 'Calorias, kcal';

  @override
  String get goalProteinG => 'Proteínas, g';

  @override
  String get goalFatG => 'Gorduras, g';

  @override
  String get goalCarbsG => 'Carboidratos, g';

  @override
  String get remindersTitle => 'Lembretes';

  @override
  String get reminderOff => 'Desativado';

  @override
  String get remindersDescription =>
      'Os lembretes serão enviados diariamente no horário definido para que você não esqueça de registrar suas refeições.';

  @override
  String get notifBreakfastBody => 'Hora de registrar o café da manhã';

  @override
  String get notifLunchBody => 'Hora de registrar o almoço';

  @override
  String get notifDinnerBody => 'Hora de registrar o jantar';

  @override
  String get notifSnackBody => 'Não esqueça de registrar seu lanche';

  @override
  String get notifChannelName => 'Lembretes de refeições';

  @override
  String get notifChannelDesc => 'Lembretes para registrar refeições';

  @override
  String get diaryRecordsForDay => 'Registros de hoje';

  @override
  String get diaryEmptyDay => 'Ainda sem registros para este dia';

  @override
  String get addMealTitle => 'Adicionar Refeição';

  @override
  String get mealTypeLabel => 'Tipo de refeição';

  @override
  String get searchInDb => 'Buscar no banco de dados';

  @override
  String get fromGallery => 'Da galeria';

  @override
  String get recognizeByPhoto => 'Reconhecer por foto';

  @override
  String get productNameOrDish => 'Nome do produto ou prato';

  @override
  String get addEntry => 'Adicionar registro';

  @override
  String get recognizingViaAi => 'Reconhecendo por IA...';

  @override
  String get notFoundInDb =>
      'Não encontrado no banco de dados\nToque ➜ para reconhecer por IA';

  @override
  String get historyTab => 'Histórico';

  @override
  String get favoritesTab => 'Favoritos';

  @override
  String get noRecentRecords => 'Sem registros recentes';

  @override
  String get noFavoriteProducts => 'Sem produtos favoritos';

  @override
  String get gramsDialogLabel => 'Gramas';

  @override
  String get favoriteUpdated => 'Favoritos atualizados';

  @override
  String get addToFavorite => 'Adicionar aos favoritos';

  @override
  String get dayNotYet => 'Este dia ainda não chegou!';

  @override
  String get voiceUnavailable =>
      'Entrada de voz indisponível. Verifique as permissões do microfone.';

  @override
  String get holdToRecord => 'Segure para gravar voz';

  @override
  String copyMealTo(String meal) {
    return 'Copiar $meal para…';
  }

  @override
  String copiedRecords(int count, String date) {
    return '$count registros copiados para $date';
  }

  @override
  String get dayMon => 'SE';

  @override
  String get dayTue => 'TE';

  @override
  String get dayWed => 'QU';

  @override
  String get dayThu => 'QU';

  @override
  String get dayFri => 'SE';

  @override
  String get daySat => 'SÁ';

  @override
  String get daySun => 'DO';

  @override
  String get aiAnalyzingPhoto => 'Analisando foto...';

  @override
  String get aiRecognizingIngredients => 'Reconhecendo ingredientes...';

  @override
  String get aiCountingCalories => 'Contando calorias...';

  @override
  String get aiDeterminingMacros => 'Determinando macros...';

  @override
  String get aiAlmostDone => 'Quase pronto...';

  @override
  String get aiAnalyzingData => 'Analisando dados...';

  @override
  String get aiRecognitionFailed => 'Não foi possível reconhecer o prato';

  @override
  String get aiRecognizingDish => 'Reconhecendo prato';

  @override
  String get addDish => 'Adicionar Prato';

  @override
  String get dishNameLabel => 'Nome';

  @override
  String get dishParameters => 'Parâmetros do prato';

  @override
  String get ingredientsLabel => 'Ingredientes';

  @override
  String get unknownDish => 'Prato desconhecido';

  @override
  String get defaultDishName => 'Prato';

  @override
  String get saveEntry => 'Adicionar registro';

  @override
  String get saveChanges => 'Salvar';

  @override
  String get recognizeDish => 'Reconhecer prato';

  @override
  String get cameraLabel => 'Câmera';

  @override
  String get searchTitle => 'Buscar';

  @override
  String get searchHint => 'Buscar produtos...';

  @override
  String get nothingFound => 'Nada encontrado';

  @override
  String get recognizeViaAi => 'Reconhecer por IA';

  @override
  String get createProduct => 'Criar produto';

  @override
  String get newProduct => 'Novo Produto';

  @override
  String get basicInfo => 'Informações básicas';

  @override
  String get productNameRequired => 'Nome *';

  @override
  String get enterName => 'Digite o nome';

  @override
  String get brandOptional => 'Marca (opcional)';

  @override
  String get servingWeightG => 'Peso da porção (g)';

  @override
  String get macrosPer100g => 'Macros por 100 g';

  @override
  String get caloriesAutoCalc =>
      'Calculado automaticamente a partir dos macros';

  @override
  String get productAdded => 'Produto adicionado';

  @override
  String get saveProduct => 'Salvar Produto';

  @override
  String get myProductsCategory => 'Meus Produtos';

  @override
  String get newRecipe => 'Nova Receita';

  @override
  String get recipeNameRequired => 'Nome da receita *';

  @override
  String get servingsCount => 'Número de porções';

  @override
  String get enterRecipeName => 'Digite o nome da receita';

  @override
  String get addAtLeastOneIngredient => 'Adicione pelo menos um ingrediente';

  @override
  String get recipeSaved => 'Receita salva';

  @override
  String get totalForRecipe => 'Total da receita';

  @override
  String get per100g => 'Por 100 g:';

  @override
  String perServing(int grams) {
    return 'Por porção ($grams g):';
  }

  @override
  String get ingredientSearchHint => 'Buscar ingrediente...';

  @override
  String get startTypingName => 'Comece a digitar um nome';

  @override
  String get tapAddToSelect =>
      'Toque em \"Adicionar\" para\nselecionar produtos';

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
    return '$name adicionado';
  }

  @override
  String get historyTitle => 'Histórico';

  @override
  String get noRecords => 'Sem registros';

  @override
  String get today => 'Hoje';

  @override
  String get yesterday => 'Ontem';

  @override
  String get statsTitle => 'Estatísticas';

  @override
  String get averageLabel => 'Média';

  @override
  String get byDays => 'Por dias';

  @override
  String get periodWeek => 'Semana';

  @override
  String get period2Weeks => '2 semanas';

  @override
  String get periodMonth => 'Mês';

  @override
  String totalGrams(int count) {
    return 'Total $count g';
  }

  @override
  String get noOwnProducts => 'Sem produtos próprios';

  @override
  String get createProductWithMacros => 'Crie um produto com macros';

  @override
  String get productLabel => 'Produto';

  @override
  String get deleteConfirm => 'Excluir?';

  @override
  String deleteWhat(String what) {
    return 'Excluir $what?';
  }

  @override
  String get customizeView => 'Personalizar visualização';

  @override
  String get primaryMetric => 'Métrica principal';

  @override
  String get otherMetrics => 'Outras métricas';

  @override
  String get showMore => 'Mostrar mais';

  @override
  String get showLess => 'Mostrar menos';

  @override
  String get networkTimeout =>
      'Servidor não responde. Verifique sua conexão com a internet.';

  @override
  String get networkSslError =>
      'Erro de conexão SSL. Tente novamente mais tarde.';

  @override
  String networkConnectionError(String message) {
    return 'Erro de conexão: $message';
  }

  @override
  String get networkRetryFailed => 'Não foi possível acessar o servidor.';

  @override
  String get networkHostLookup =>
      'Servidor temporariamente indisponível. Verifique sua internet ou tente em um minuto.';

  @override
  String get networkConnectionRefused =>
      'Servidor não está aceitando conexões. Tente novamente mais tarde.';

  @override
  String get networkConnectionReset => 'Conexão perdida. Tente novamente.';

  @override
  String get networkGenericError =>
      'Erro de rede. Verifique sua conexão com a internet.';

  @override
  String get onboardingGenderTitle => 'Selecione seu gênero';

  @override
  String get onboardingGenderHint =>
      'Necessário para um cálculo preciso de calorias';

  @override
  String get genderMale => 'Masculino';

  @override
  String get genderFemale => 'Feminino';

  @override
  String get onboardingMeasurementsTitle => 'Suas medidas';

  @override
  String get heightLabel => 'Altura';

  @override
  String get currentWeightLabel => 'Peso atual';

  @override
  String get onboardingAgeTitle => 'Quantos anos você tem?';

  @override
  String get onboardingGoalTitle => 'Qual é o seu objetivo?';

  @override
  String get goalLoseWeight => 'Perder peso';

  @override
  String get goalMaintainWeight => 'Manter peso';

  @override
  String get goalGainWeight => 'Ganhar músculo';

  @override
  String get onboardingActivityTitle => 'Qual é o seu nível de atividade?';

  @override
  String get activitySedentary => 'Sedentário';

  @override
  String get activitySedentaryDesc => 'Trabalho de escritório, pouca caminhada';

  @override
  String get activityLight => 'Levemente ativo';

  @override
  String get activityLightDesc => 'Exercício leve 1–3 vezes por semana';

  @override
  String get activityModerate => 'Moderadamente ativo';

  @override
  String get activityModerateDesc => 'Exercício 3–5 vezes por semana';

  @override
  String get activityHigh => 'Muito ativo';

  @override
  String get activityHighDesc => 'Exercício intenso 6–7 vezes por semana';

  @override
  String get onboardingTargetWeightTitle => 'Qual é o seu peso alvo?';

  @override
  String get safeWeightLossPace => 'Ritmo seguro — 0,5 kg por semana';

  @override
  String get recommendedWeightGainPace =>
      'Ritmo recomendado — 0,25 kg por semana';

  @override
  String get onboardingLoadingCalc => 'Calculando metabolismo...';

  @override
  String get onboardingLoadingNorm => 'Encontrando sua norma calórica...';

  @override
  String get onboardingLoadingPlan => 'Criando seu plano personalizado...';

  @override
  String get onboardingResultTitle => 'Seu Plano Pessoal';

  @override
  String get kcalPerDay => 'kcal/dia';

  @override
  String get weightLossGoalText => 'perda de peso';

  @override
  String get weightGainGoalText => 'ganho muscular';

  @override
  String achievableGoal(String goalText) {
    return 'Objetivo alcançável de $goalText';
  }

  @override
  String weeksToGoal(int weeks, String date) {
    return '$weeks semanas até o objetivo — até $date';
  }

  @override
  String maintainWeightHint(String weight) {
    return 'Vamos ajudá-lo a manter seu peso\nem $weight kg';
  }

  @override
  String weightWithUnit(String value) {
    return '$value kg';
  }

  @override
  String get onboardingNext => 'Próximo';

  @override
  String get onboardingStart => 'Começar';

  @override
  String get paywallTitle => 'Comece sua jornada\nrumo aos resultados';

  @override
  String get paywallAiRecognition => 'Reconhecimento de alimentos por IA';

  @override
  String get paywallAiRecognitionDesc =>
      'Tire uma foto e descubra as calorias em um segundo';

  @override
  String get paywallPersonalGoals => 'Objetivos pessoais';

  @override
  String get paywallPersonalGoalsDesc =>
      'Norma calculada para o seu corpo e objetivo';

  @override
  String get paywallProgressTracking => 'Acompanhamento de progresso';

  @override
  String get paywallProgressTrackingDesc =>
      'Estatísticas visuais por dias e semanas';

  @override
  String get paywallWeekly => 'Semanal';

  @override
  String get paywallWeeklyPrice => '\$2.99/semana';

  @override
  String get paywallWeeklyTrial => 'Primeiros 3 dias — grátis';

  @override
  String get paywallPopular => 'Popular';

  @override
  String get paywallYearly => 'Anual';

  @override
  String get paywallYearlyPrice => '\$19.99/ano';

  @override
  String get paywallYearlySavings => '≈ \$0.05/dia · Economize 85%';

  @override
  String get paywallRating => '4,8 · Mais de 10.000 usuários';

  @override
  String get paywallToday => 'Hoje';

  @override
  String get paywallFullAccess => 'Acesso completo';

  @override
  String get paywallDay2 => 'Dia 2';

  @override
  String get paywallReminder => 'Lembrete';

  @override
  String get paywallDay3 => 'Dia 3';

  @override
  String get paywallDay3Price => '\$2.99';

  @override
  String get paywallContinue => 'Continuar';

  @override
  String get paywallDisclaimer =>
      'Cancele a qualquer momento. Sem cobrança\ndurante o período de teste.';

  @override
  String get paywallSkip => 'Pular';

  @override
  String get barcodeScannerTitle => 'Scanner de código de barras';

  @override
  String get barcodeScanHint => 'Aponte a câmera para o código de barras';
}
