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
  String get yearsUnit => 'ano de nascimento';

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
  String get pushNotificationsShortOn => 'Ativado';

  @override
  String get pushNotificationsShortOff => 'Desativado';

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
  String get signInTitle => 'Entre na sua conta';

  @override
  String get signInGoogle => 'Entrar com Google';

  @override
  String get signInApple => 'Entrar com Apple';

  @override
  String get signInEmail => 'Entrar com Email';

  @override
  String get startOverOnboarding => 'Começar de novo';

  @override
  String get startOverOnboardingConfirm =>
      'Refazer o onboarding desde o início?';

  @override
  String get startOverOnboardingHint =>
      'As respostas do questionário serão redefinidas. Os dados do diário neste dispositivo são mantidos.';

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
  String get forgotPassword => 'Esqueceu a senha?';

  @override
  String get resetPasswordTitle => 'Redefinir senha';

  @override
  String get resetPasswordHint =>
      'Digite o email usado no cadastro. Enviaremos um código de 6 dígitos.';

  @override
  String get sendResetCode => 'Enviar código';

  @override
  String get enterCodeTitle => 'Digite o código';

  @override
  String resetCodeSentTo(String email) {
    return 'Enviamos um código de 6 dígitos para $email';
  }

  @override
  String get enterSixDigitCode => 'Digite o código de 6 dígitos';

  @override
  String get verifyCode => 'Verificar';

  @override
  String get resendCode => 'Reenviar código';

  @override
  String resendCodeIn(int seconds) {
    return 'Reenviar em $seconds s';
  }

  @override
  String get resetCodeResent => 'Código reenviado';

  @override
  String get newPasswordTitle => 'Nova senha';

  @override
  String get newPasswordHint => 'Crie uma nova senha para sua conta.';

  @override
  String get newPasswordLabel => 'Nova senha';

  @override
  String get confirmPasswordLabel => 'Confirmar senha';

  @override
  String get passwordsDoNotMatch => 'As senhas não coincidem';

  @override
  String get resetPasswordButton => 'Redefinir senha';

  @override
  String get passwordResetSuccess =>
      'Senha redefinida. Entre com sua nova senha.';

  @override
  String get emailNotFound => 'Nenhuma conta com este email';

  @override
  String get invalidResetCode => 'Código inválido ou expirado';

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
  String get planYearly => 'Anual';

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
  String get onboardingUnitsTitle => 'Unidades de medida';

  @override
  String get onboardingUnitsHint => 'Pode alterar depois nas configurações';

  @override
  String get unitsMetricTitle => 'Métrica';

  @override
  String get unitsMetricExamples => 'cm, kg, ml';

  @override
  String get unitsImperialTitle => 'Imperial';

  @override
  String get unitsImperialExamples => 'ft, lb, fl oz';

  @override
  String get onboardingHeightTitle => 'Qual é a sua altura?';

  @override
  String get onboardingHeightHint => 'Usada para calcular o metabolismo basal';

  @override
  String get onboardingWeightTitle => 'Qual é o seu peso?';

  @override
  String get onboardingWeightHint => 'O ponto de partida para o seu plano';

  @override
  String get heightLabel => 'Altura';

  @override
  String get currentWeightLabel => 'Peso atual';

  @override
  String get onboardingAgeTitle => 'Quando é o seu aniversário?';

  @override
  String get onboardingAgeHint => 'A idade influencia a taxa metabólica';

  @override
  String get onboardingGoalTitle => 'Qual é o seu objetivo?';

  @override
  String get onboardingGoalHint =>
      'Vamos criar um plano nutricional sob medida';

  @override
  String get goalLoseWeight => 'Perder peso';

  @override
  String get goalMaintainWeight => 'Manter peso';

  @override
  String get goalGainWeight => 'Ganhar músculo';

  @override
  String get onboardingActivityTitle => 'Qual é o seu nível de atividade?';

  @override
  String get onboardingActivityHint =>
      'Seu nível de atividade determina a meta calórica diária';

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
  String get onboardingTargetWeightHint => 'Calcularemos prazos e ritmo';

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
  String get resultCongratsTitle => 'Parabéns!';

  @override
  String get resultCongratsSubtitle =>
      'Seu plano de saúde personalizado está pronto!';

  @override
  String get resultCanChange => 'Você pode alterar isso a qualquer momento';

  @override
  String get resultHowToTitle => 'Como alcançar seus objetivos';

  @override
  String get resultTip1 => 'Registre suas refeições — crie um hábito saudável!';

  @override
  String get resultTip2 => 'Siga as recomendações diárias de calorias';

  @override
  String get resultTip3 => 'Equilibre carboidratos, proteínas e gorduras';

  @override
  String get resultImprovementsTitle => 'Em breve você notará melhorias';

  @override
  String get resultImprovementsBody =>
      'Menor risco de diabetes, pressão arterial mais baixa, melhor nível de colesterol';

  @override
  String get resultDisclaimer =>
      'Este aplicativo fornece informações nutricionais, mas não se destina ao diagnóstico, tratamento ou prevenção de doenças. Não substitui aconselhamento médico profissional.';

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
  String get paywallTitle =>
      'Para continuar, inicie seu teste GRATUITO de 3 dias';

  @override
  String get paywallTimelineTodayTitle => 'Hoje';

  @override
  String get paywallTimelineTodayDesc =>
      'Desbloqueie todos os recursos — escaneamento de calorias com IA e muito mais';

  @override
  String get paywallTimelineReminderTitle => 'Em 2 dias — lembrete';

  @override
  String get paywallTimelineReminderDesc =>
      'Vamos lembrá-lo de que o período de teste está terminando';

  @override
  String get paywallTimelinePayTitle => 'Em 3 dias — pagamento começa';

  @override
  String paywallTimelinePayDesc(String date) {
    return 'A cobrança será em $date se não cancelar antes';
  }

  @override
  String get paywallMonthly => 'Semanal';

  @override
  String get paywallMonthlyPrice => '\$4.99 / semana';

  @override
  String get paywallYearly => 'Anual';

  @override
  String get paywallYearlyPrice => '\$39.99 / ano';

  @override
  String get paywallPerWeek => 'semana';

  @override
  String get paywallPerYear => 'ano';

  @override
  String get paywallTrialBadge => '3 DIAS GRÁTIS';

  @override
  String get paywallNoPaymentNow => 'Nenhum pagamento necessário agora';

  @override
  String get paywallStartTrial => 'Iniciar teste gratuito de 3 dias';

  @override
  String get paywallTrialDisclaimer => '3 dias grátis, depois \$39.99/ano';

  @override
  String paywallTrialDisclaimerFmt(String price) {
    return '3 dias grátis, depois $price/ano';
  }

  @override
  String get paywallRestore => 'Restaurar';

  @override
  String get paywallTerms => 'Termos';

  @override
  String get paywallPrivacy => 'Privacidade';

  @override
  String get paywallHaveCode => 'Tem um código?';

  @override
  String get promoCodeApply => 'Aplicar';

  @override
  String get promoCodeInvalid => 'Código inválido';

  @override
  String get paywallSkip => 'Pular';

  @override
  String get paywallRestoreSuccess => 'Assinatura restaurada';

  @override
  String get paywallRestoreNotFound => 'Nenhuma assinatura ativa encontrada';

  @override
  String get paywallSubscriptionError =>
      'Não foi possível carregar as assinaturas. Tente novamente mais tarde.';

  @override
  String get restartOnboarding => 'Recomeçar';

  @override
  String get proActive => 'Ativa';

  @override
  String get signInToSaveData => 'Faça login para salvar seus dados';

  @override
  String get dataStoredLocally =>
      'Seus dados são armazenados apenas neste dispositivo';

  @override
  String get barcodeScannerTitle => 'Scanner de código de barras';

  @override
  String get barcodeScanHint => 'Aponte a câmera para o código de barras';

  @override
  String get paywallSubscribeNow => 'Assinar';

  @override
  String get paywallHardDisclaimer =>
      'Renovação automática. Cancele a qualquer momento.';

  @override
  String get paywallHardTitle => 'Gostou do app?\nContinue com Pro';

  @override
  String freeEntriesRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entradas gratuitas restantes',
      one: '1 entrada gratuita restante',
    );
    return '$_temp0';
  }

  @override
  String get getPro => 'Obter Pro';

  @override
  String get freeLimitReached => 'Todas as entradas gratuitas foram usadas';
}
