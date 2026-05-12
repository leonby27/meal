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
  String get deleteAccount => 'Excluir conta';

  @override
  String get deleteAccountConfirmTitle => 'Excluir sua conta?';

  @override
  String get deleteAccountConfirmMessage =>
      'Isso excluirá permanentemente sua conta e removerá deste dispositivo seu histórico de refeições, receitas, produtos, favoritos e configurações. Esta ação não pode ser desfeita.';

  @override
  String get deleteAccountFinalConfirmTitle => 'Tem certeza absoluta?';

  @override
  String get deleteAccountFinalConfirmMessage =>
      'Sua conta e seus dados serão excluídos permanentemente.';

  @override
  String get deleteAccountSuccess => 'Sua conta foi excluída.';

  @override
  String get deleteAccountFailed =>
      'Não foi possível excluir a conta. Verifique sua conexão e tente novamente.';

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
  String get mergeLocalDataTitle =>
      'Migrar seus dados recentes para sua conta?';

  @override
  String get mergeLocalDataKeep => 'Migrar';

  @override
  String get mergeLocalDataReplace => 'Deixar como está';

  @override
  String get loginSyncing => 'Sincronizando…';

  @override
  String get loginSyncFailed =>
      'Não foi possível sincronizar os dados. Tente novamente mais tarde.';

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
  String get planLifetime => 'Vitalícia';

  @override
  String get planPromo => 'Promo';

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
  String get diaryViewLabel => 'Visualização';

  @override
  String get diaryViewCompact => 'compacta';

  @override
  String get diaryViewExpanded => 'expandida';

  @override
  String get recordsSortNewestFirst => 'Mais recentes primeiro';

  @override
  String get recordsSortOldestFirst => 'Mais antigas primeiro';

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
  String get historyTab => 'Recentes';

  @override
  String get favoritesTab => 'Favoritos';

  @override
  String get noRecentRecords => 'Sem registros recentes';

  @override
  String get addMenuRecentEntries => 'Recomendados';

  @override
  String get scanBarcodeAction => 'Escanear código de barras';

  @override
  String get attachPhotoAction => 'Anexar foto';

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
  String get logEntry => 'Registrar';

  @override
  String get saveMacros => 'Salvar macros';

  @override
  String get macrosSavedToast => 'Macros salvos';

  @override
  String get updateDish => 'Atualizar prato';

  @override
  String get refineDish => 'Precisar prato';

  @override
  String get refineDishHint => 'Precisar o prato ...';

  @override
  String get activityWalking => 'Caminhada';

  @override
  String get activityBicycle => 'Ciclismo';

  @override
  String get activityResting => 'Repouso';

  @override
  String approxHours(int count) {
    return '~ $count h';
  }

  @override
  String approxMinutes(int count) {
    return '~ $count min';
  }

  @override
  String get healthRatingLabel => 'Saúde';

  @override
  String healthRatingValue(int value) {
    return '$value / 10';
  }

  @override
  String get healthDescPoor =>
      'Muitas calorias, açúcares, gordura ou sal — melhor como prazer ocasional.';

  @override
  String get healthDescFair =>
      'Saboroso e saciante, mas provavelmente rico em calorias, gordura e sal.';

  @override
  String get healthDescGood =>
      'Refeição equilibrada com uma boa mistura de macros.';

  @override
  String get healthDescGreat =>
      'Rica em nutrientes e bem equilibrada — uma ótima escolha.';

  @override
  String get healthDescVeggie =>
      'Leve e rico em água — muitos micronutrientes por caloria.';

  @override
  String get healthDescHighProtein =>
      'Predomina a proteína — sacia bem e ajuda na recuperação.';

  @override
  String get healthDescLeanProtein =>
      'Proteína magra — uma base sólida para a dieta.';

  @override
  String get healthDescBalanced =>
      'Macros equilibrados — combina com a maioria dos planos.';

  @override
  String get healthDescCarbHeavy =>
      'Carboidrato em destaque — combine com proteína ou vegetais.';

  @override
  String get healthDescFatHeavy =>
      'Calórico por causa da gordura — cuide da porção.';

  @override
  String get healthDescSweet =>
      'Doce e energético — melhor manter como exceção.';

  @override
  String get healthDescUltraProcessed =>
      'Muitas calorias e pouca proteína — limite a frequência.';

  @override
  String get healthTraitHighProtein => 'Especialmente rico em proteína.';

  @override
  String get healthTraitLowCalDensity => 'Cabe fácil na sua meta diária.';

  @override
  String get healthTraitHighFat => 'Calórico por causa da gordura.';

  @override
  String get healthTraitHighCarb => 'Predomina em carboidratos.';

  @override
  String get healthTraitBalancedMacros => 'Macros bem distribuídos.';

  @override
  String get healthAdviceGreat => 'Combina com quase todo dia.';

  @override
  String get healthAdviceGood => 'Boa escolha para um dia equilibrado.';

  @override
  String get healthAdviceFair => 'Aproveite com moderação.';

  @override
  String get healthAdvicePoor => 'Melhor como prazer ocasional.';

  @override
  String get ofYourDailyCalories => 'da sua meta diária';

  @override
  String dailyCaloriesPercent(int percent) {
    return '$percent%';
  }

  @override
  String get recognizeDish => 'Reconhecer prato';

  @override
  String get photoDetailsHint => 'Descreva com mais detalhes se quiser ...';

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
  String get caloriesRemaining => 'Calorias restantes';

  @override
  String get dailyEatenLabel => 'Comido';

  @override
  String get dailyGoalLabel => 'Meta';

  @override
  String get openMore => 'Ver mais';

  @override
  String get goToStatistics => 'Ir para estatísticas';

  @override
  String get goalsParamGoal => 'Meta';

  @override
  String get goalsParamGender => 'Gênero';

  @override
  String get goalsParamAge => 'Idade';

  @override
  String get goalsParamHeight => 'Altura';

  @override
  String get goalsParamWeight => 'Peso';

  @override
  String get goalsParamTargetWeight => 'Peso alvo';

  @override
  String get goalsParamActivity => 'Atividade';

  @override
  String get goalsPlanNote => 'Baseado em seu plano';

  @override
  String get goalsCustomNote => 'Valores personalizados';

  @override
  String get goalsEditManually => 'Editar manualmente';

  @override
  String get goalsUsePlan => 'Calcular do plano';

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
  String get onboardingAgeYearsUnit => 'anos';

  @override
  String get onboardingLoadingCalc => 'Analisando suas respostas...';

  @override
  String get onboardingLoadingNorm => 'Configurando suas metas diárias...';

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
      'Apenas estimativas nutricionais. Não é aconselhamento médico.';

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
  String get resultPlanReadyTitle => 'Seu plano personalizado está pronto';

  @override
  String get resultHeroSubtitle =>
      'Reunimos recomendações com base nas suas respostas';

  @override
  String get resultRingAdjustLine =>
      'Você pode ajustar esses valores a qualquer momento';

  @override
  String get resultGoalCardTitle => 'Sua meta';

  @override
  String resultGoalMaintainTitle(String weight) {
    return 'Manter o peso em cerca de $weight';
  }

  @override
  String get resultGoalMaintainSubtitle =>
      'Sem restrições rígidas — o equilíbrio diário é o que importa';

  @override
  String get resultBridgeTitle =>
      'Para o plano funcionar, você precisa registrar todos os dias';

  @override
  String get resultBridgeFreeLine =>
      'Grátis — 3 registros de refeição para experimentar';

  @override
  String get resultBridgePremiumLine =>
      'Com Premium — sem limites, até alcançar sua meta';

  @override
  String get resultDisclaimerShort => 'Não substitui aconselhamento médico.';

  @override
  String get resultDisclaimerExpand => 'Saiba mais';

  @override
  String get resultSourcesTitle => 'Fontes';

  @override
  String get resultSourceCaloriesLabel => 'Meta de calorias';

  @override
  String get resultSourceMacrosLabel => 'Distribuição de macronutrientes';

  @override
  String get resultSourcesCta => 'Fontes e metodologia';

  @override
  String get profileMethodology => 'Fontes nutricionais e metodologia';

  @override
  String get profileMethodologyIntro => 'Como suas metas diárias são estimadas';

  @override
  String get methodologyCaloriesSection => 'Meta de calorias';

  @override
  String get methodologyMacrosSection => 'Metas de macronutrientes';

  @override
  String get methodologyGeneralSection => 'Orientação nutricional geral';

  @override
  String get methodologySourceMifflinDescription =>
      'Fórmula BMR para estimar calorias.';

  @override
  String get methodologySourceDriDescription =>
      'Faixas de referência para proteína, gordura e carboidratos.';

  @override
  String get methodologySourceUsdaDescription =>
      'Referências DRI de calorias e nutrientes.';

  @override
  String get methodologySourceWhoDescription =>
      'Orientação geral de alimentação saudável.';

  @override
  String get methodologyOpenSourceFailed =>
      'Não foi possível abrir esta fonte.';

  @override
  String get resultOpenPlan => 'Abrir meu plano';

  @override
  String get socialProofScaleTitle => 'Feito para um acompanhamento sério';

  @override
  String get socialProofScaleSubtitle => 'A tecnologia por trás do seu plano';

  @override
  String get socialProofScaleProductsLabel => 'Produtos em nossa base de dados';

  @override
  String get socialProofScaleSecondsUnit => 's';

  @override
  String get socialProofScaleSpeedLabel => 'Reconhecimento de refeições por IA';

  @override
  String get socialProofPoweredBy => 'Desenvolvido com';

  @override
  String get socialProofAccuracyTitle => 'Testado para precisão';

  @override
  String get socialProofAccuracySubtitle =>
      'Quão bem nossa IA identifica suas refeições';

  @override
  String get socialProofAccuracyLabel => 'Precisão da IA';

  @override
  String get socialProofAccuracyDisclaimer =>
      'Com base em testes internos de qualidade em mais de 500 pratos de várias cozinhas.';

  @override
  String get socialProofScienceTitle => 'Baseado em ciência nutricional';

  @override
  String get socialProofScienceSubtitle =>
      'Seu plano é construído sobre uma fórmula comprovada';

  @override
  String get socialProofScienceFormulaCaption =>
      'Padrão-ouro da nutrição desde 1990';

  @override
  String get socialProofScienceTrust =>
      'Utilizado por nutricionistas registrados e clínicos em todo o mundo.';

  @override
  String get paywallTitle => 'Teste o Pro\ngrátis';

  @override
  String get paywallWeeklyTitle => 'Desbloqueie o Pro\nhoje';

  @override
  String get paywallWeeklyTimelineTodayTitle => 'Hoje — desbloqueie o Pro';

  @override
  String get paywallWeeklyTimelineTodayDesc =>
      'Escaneamento com IA, registro de refeições e insights sem limites.';

  @override
  String get paywallWeeklyTimelineRenewTitle => 'Semanal — progresso';

  @override
  String get paywallWeeklyTimelineRenewDesc =>
      'Renova toda semana para manter seu acesso.';

  @override
  String get paywallWeeklyTimelineCancelTitle => 'Cancele quando quiser';

  @override
  String get paywallWeeklyTimelineCancelDesc =>
      'Cancele quando quiser na sua conta da loja.';

  @override
  String get paywallTimelineTodayTitle => 'Hoje — desbloqueie o Pro';

  @override
  String get paywallTimelineTodayDesc =>
      'Escaneamento com IA, registro de refeições e insights sem limites.';

  @override
  String get paywallTimelineReminderTitle => 'Dia 2 — lembrete';

  @override
  String get paywallTimelineReminderDesc =>
      'Vamos avisar antes do fim do teste';

  @override
  String get paywallTimelinePayTitle => 'Dia 3 — pagamento';

  @override
  String paywallTimelinePayDesc(String date) {
    return 'Cobrança em $date, se não cancelar antes';
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
  String get paywallTrialBadge => '3 dias grátis';

  @override
  String get paywallYearlyDiscount => '-85%';

  @override
  String get paywallSubtitle =>
      'Aproveite todos os recursos exclusivos do BodyMeal Pro.';

  @override
  String get paywallFeatureAiTitle => 'Reconhecimento por IA';

  @override
  String get paywallFeatureAiDesc =>
      'Tire uma foto — a IA mostra calorias e nutrientes em segundos.';

  @override
  String get paywallFeatureDiaryTitle => 'Diário alimentar';

  @override
  String get paywallFeatureDiaryDesc =>
      'Registre todas as refeições sem limites, todos os dias.';

  @override
  String get paywallFeatureAnalyticsTitle => 'Análises detalhadas';

  @override
  String get paywallFeatureAnalyticsDesc =>
      'Gráficos de calorias, macros e progresso por qualquer período.';

  @override
  String get paywallFeatureBarcodeTitle => 'Leitor de códigos de barras';

  @override
  String get paywallFeatureBarcodeDesc =>
      'Aponte a câmera para a embalagem — os dados aparecem sozinhos.';

  @override
  String get paywallNoPaymentNow => 'Nenhum pagamento necessário agora';

  @override
  String get paywallStartTrial => 'Iniciar teste';

  @override
  String get paywallTrialDisclaimer => '3 dias grátis, depois \$39.99/ano';

  @override
  String get paywallWeeklyDisclaimer => 'Cobrado hoje. Cancele quando quiser.';

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
  String get paywallLoadingPrice => 'Carregando…';

  @override
  String get paywallErrorTitle => 'Assinatura indisponível';

  @override
  String get paywallTryAgain => 'Tentar de novo';

  @override
  String get paywallErrorStoreUnavailable =>
      'A App Store não está disponível no momento. Certifique-se de estar conectado à App Store e tente novamente.';

  @override
  String get paywallErrorProductsEmpty =>
      'Não foi possível carregar as opções de assinatura. Verifique sua conexão e tente novamente.';

  @override
  String get paywallErrorSelectedProductUnavailable =>
      'Esta opção de assinatura não está disponível agora. Escolha outro plano ou tente novamente.';

  @override
  String get paywallErrorQueryFailed =>
      'Não foi possível contatar a App Store. Tente novamente em instantes.';

  @override
  String get paywallErrorPurchaseFailed =>
      'Não foi possível concluir a compra. Tente novamente.';

  @override
  String get paywallErrorRestoreFailed =>
      'Não foi possível restaurar as compras. Tente novamente.';

  @override
  String get paywallErrorPaymentPending =>
      'Seu pagamento está pendente. O Pro será liberado assim que for aprovado.';

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
  String get paywallHardTitle => 'Continue\ncom Pro';

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

  @override
  String get analyticsTitle => 'Análise';

  @override
  String get summarySection => 'Resumo';

  @override
  String get trendsSection => 'Tendências';

  @override
  String get highlightsSection => 'Destaques';

  @override
  String dayStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dias seguidos',
      one: 'Dia seguido',
    );
    return '$_temp0';
  }

  @override
  String get averageADay => 'média por dia';

  @override
  String calDifferenceCount(int count) {
    return 'Diferença de $count cal';
  }

  @override
  String percentAverage(int count) {
    return '$count/100% média';
  }

  @override
  String analyticsHighlightHigher(String metric) {
    return 'O consumo médio de $metric por dia esta semana é maior que na semana passada.';
  }

  @override
  String analyticsHighlightLower(String metric) {
    return 'O consumo médio de $metric por dia esta semana é menor que na semana passada.';
  }

  @override
  String analyticsHighlightSimilar(String metric) {
    return 'O consumo médio de $metric por dia esta semana é similar ao da semana passada.';
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
  String get analyticsMetricFat => 'Gord';

  @override
  String get analyticsMetricCarbs => 'Carb';

  @override
  String get quantityLabel => 'Quantidade';

  @override
  String get addSuggestionsLabel => 'Adicionar sugestões';

  @override
  String get suggestionSomethingElse => 'Outro';

  @override
  String get untitledIngredientName => 'Sem nome';

  @override
  String get onbObstaclesTitle => 'O que te impediu antes?';

  @override
  String get onbObstaclesHint => 'Selecione tudo o que se aplica';

  @override
  String get obstacleConsistency => 'Difícil ser consistente';

  @override
  String get obstacleKnowledge => 'Não sei o que comer';

  @override
  String get obstacleBusy => 'Agenda apertada';

  @override
  String get obstacleCravings => 'Fortes desejos por doces/carboidratos';

  @override
  String get obstacleSupport => 'Falta de apoio';

  @override
  String get obstacleEatingOut => 'Como fora com frequência';

  @override
  String get obstacleMotivation => 'Falta de motivação';

  @override
  String get obstacleTracking => 'Difícil contar calorias';

  @override
  String get onbSpeedTitleLose => 'Em que ritmo quer emagrecer?';

  @override
  String get onbSpeedTitleGain => 'Em que ritmo quer ganhar massa?';

  @override
  String onbSpeedHintKg(String rate) {
    return 'Ritmo recomendado — $rate kg/semana';
  }

  @override
  String onbSpeedHintLb(String rate) {
    return 'Ritmo recomendado — $rate lb/semana';
  }

  @override
  String onbSpeedKgPerWeek(String value) {
    return '$value kg/semana';
  }

  @override
  String onbSpeedLbPerWeek(String value) {
    return '$value lb/semana';
  }

  @override
  String get onbSpeedBadgeGentle => 'Ritmo suave ✅';

  @override
  String get onbSpeedBadgeRecommended => 'Ritmo recomendado ⭐';

  @override
  String get onbSpeedBadgeAmbitious => 'Ambicioso 🔥';

  @override
  String get onbSpeedBadgeAggressive => 'Muito agressivo ⚠️';

  @override
  String onbSpeedTargetByPrefix(String weight) {
    return 'Alcançará $weight até';
  }

  @override
  String get onbQuizTitle => 'Conte sobre seus hábitos';

  @override
  String get onbQuizHint => 'Isso ajuda a personalizar seu plano';

  @override
  String get quizStressEatingLeft => 'Como quando estou estressado';

  @override
  String get quizStressEatingRight => 'Como só por energia';

  @override
  String get quizSweetPreferenceLeft => 'Adoro doces';

  @override
  String get quizSweetPreferenceRight => 'Prefiro salgado/apimentado';

  @override
  String get quizExerciseConsistencyLeft => 'Treino com regularidade';

  @override
  String get quizExerciseConsistencyRight => 'Não mantenho rotina';

  @override
  String get quizMealPlanningLeft => 'Planejo minhas refeições';

  @override
  String get quizMealPlanningRight => 'Como o que está à mão';

  @override
  String get quizMotivationTypeLeft => 'Resultados me movem';

  @override
  String get quizMotivationTypeRight => 'Sensações me movem';

  @override
  String get onbRateTitle => 'Gostou do seu plano?';

  @override
  String get onbRateSubtitle => 'Avalie o MealTracker — nos ajuda a melhorar';

  @override
  String get onbRateButton => 'Avaliar';

  @override
  String get onbRateSkip => 'Pular';

  @override
  String get onbRateFeedbackTitle => 'O que podemos melhorar?';

  @override
  String get onbRateFeedbackHint => 'Conte o que não funcionou';

  @override
  String get onbRateFeedbackSubmit => 'Enviar';

  @override
  String resultAnchorPrefix(String weight) {
    return 'Alcançará $weight até';
  }

  @override
  String resultAnchorWeeksSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '(em $count semanas)',
      one: '(em 1 semana)',
    );
    return '$_temp0';
  }

  @override
  String resultMaintainCard(String weight) {
    return 'Vamos ajudar a manter $weight';
  }

  @override
  String get resultDailyNormLabel => 'SUA META DIÁRIA';

  @override
  String resultPsychotypeLabel(String title) {
    return 'Seu estilo alimentar: $title';
  }

  @override
  String get resultObstaclesHeader => 'Seu plano leva em conta:';

  @override
  String get resultMilestonesHeader => 'Seu progresso semanal:';

  @override
  String get resultGoalRow => 'Meta';

  @override
  String resultWeekRow(int week) {
    return 'Semana $week';
  }

  @override
  String resultGoalReachLine(String weight) {
    return 'Você alcançará $weight';
  }

  @override
  String resultGoalByDateLine(String date) {
    return 'até $date';
  }

  @override
  String resultGoalInWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'em $count semanas',
      one: 'em 1 semana',
    );
    return '$_temp0';
  }

  @override
  String get resultBenefit5MinDay => 'Apenas 5 minutos por dia';

  @override
  String get resultBenefitSmartTracking =>
      'Acompanhamento inteligente, sem esforço';

  @override
  String get resultBenefitTailored => 'Plano alimentar feito para sua rotina';

  @override
  String get resultBenefitSustainable =>
      'Resultados duradouros, sem soluções rápidas';

  @override
  String get resultFaqHeader => 'FAQ';

  @override
  String get resultFaqCancelQ => 'Como cancelar minha assinatura?';

  @override
  String get resultFaqCancelAIos =>
      'Abra Ajustes → seu nome → Assinaturas no iPhone, encontre o MealTracker e toque em Cancelar assinatura.';

  @override
  String get resultFaqCancelAAndroid =>
      'Abra a Google Play → seu perfil → Pagamentos e assinaturas → Assinaturas, encontre o MealTracker e toque em Cancelar.';

  @override
  String get resultFaqSecurityQ => 'Meus dados pessoais estão seguros?';

  @override
  String get resultFaqSecurityA =>
      'Seus dados são criptografados em trânsito e em repouso. Não os vendemos a anunciantes, e você pode excluir sua conta a qualquer momento nas configurações.';

  @override
  String get resultFaqTrialQ => 'Existe um período de avaliação gratuito?';

  @override
  String get resultFaqTrialA =>
      'Sim — o plano anual inclui um período gratuito. Não cobramos nada até ele terminar e pode cancelar antes para não pagar.';

  @override
  String get loadingMetabolism => 'Analisando seu metabolismo...';

  @override
  String get loadingCalories => 'Calculando sua meta diária de calorias...';

  @override
  String get loadingMacros =>
      'Ajustando o equilíbrio proteína / gordura / carboidratos...';

  @override
  String get loadingPsychotype =>
      'Analisando seu estilo alimentar e hábitos...';

  @override
  String get loadingPlanCreate => 'Criando seu plano pessoal...';

  @override
  String get psyStressEaterTitle => 'O Comedor Emocional';

  @override
  String get psyStressEaterDesc =>
      'Você come com as emoções. Vamos encontrar alternativas.';

  @override
  String get psyFuelFocusedTitle => 'O Comedor Racional';

  @override
  String get psyFuelFocusedDesc =>
      'Você é racional com a comida — só vamos afinar os números.';

  @override
  String get psySweetLoverTitle => 'O Guloso';

  @override
  String get psySweetLoverDesc =>
      'Vamos mostrar trocas que matam o desejo sem sabotagem.';

  @override
  String get psySavoryLoverTitle => 'O Sabor Forte';

  @override
  String get psySavoryLoverDesc =>
      'Salgado e apimentado é seu estilo — cuidaremos do sódio.';

  @override
  String get psyConsistentAthleteTitle => 'O Consistente';

  @override
  String get psyConsistentAthleteDesc =>
      'Você tem uma base sólida. Uma dieta precisa vai multiplicar resultados.';

  @override
  String get psyInconsistentTitle => 'O Recomeço';

  @override
  String get psyInconsistentDesc =>
      'O mais difícil é recomeçar. Vamos facilitar a volta.';

  @override
  String get psyPlannerTitle => 'O Planejador';

  @override
  String get psyPlannerDesc => 'Você ama controle. Deixe a IA fazer as contas.';

  @override
  String get psyConvenienceEaterTitle => 'O Prático';

  @override
  String get psyConvenienceEaterDesc =>
      'Pouco tempo — vamos te ajudar a escolher rápido e certo.';

  @override
  String get psyResultsDrivenTitle => 'O Realizador';

  @override
  String get psyResultsDrivenDesc =>
      'Números te movem — mostraremos seu progresso com clareza.';

  @override
  String get psyFeelingsDrivenTitle => 'O Intuitivo';

  @override
  String get psyFeelingsDrivenDesc =>
      'Você escuta seu corpo — adicionaremos os dados.';

  @override
  String get psyBalancedTitle => 'O Equilibrado';

  @override
  String get psyBalancedDesc =>
      'Você tem uma abordagem saudável. Vamos reforçar com dados.';

  @override
  String get onbWelcomeTitle => 'Vamos montar um plano para seu objetivo';

  @override
  String get onbWelcomeSubtitle =>
      'Conte calorias e macros de forma rápida e precisa — sem entrada manual!';

  @override
  String get onbWelcomeCta => 'Começar';

  @override
  String get onbLanguageSheetTitle => 'Escolha o idioma';

  @override
  String get langShortEn => 'Ing';

  @override
  String get langShortRu => 'Rus';

  @override
  String get langShortDe => 'Ale';

  @override
  String get langShortEs => 'Esp';

  @override
  String get langShortFr => 'Fra';

  @override
  String get langShortPt => 'Por';

  @override
  String get onbConfidentTitle => 'Obrigado pela sua confiança';

  @override
  String get onbConfidentSubtitle =>
      'Personalizamos o MealTracker especificamente para os seus objetivos';

  @override
  String get onbConfidentPrivacyTitle => 'Sua privacidade importa';

  @override
  String get onbConfidentPrivacyBody =>
      'Prometemos manter suas informações pessoais em sigilo';

  @override
  String get onbKeepResultTitle =>
      'MealTracker ajuda você a manter os resultados';

  @override
  String get onbKeepResultSubtitle =>
      'Mantenha um progresso estável mesmo após 6 meses!';

  @override
  String get onbCalorieHistoryTitle => 'Você já contou calorias?';

  @override
  String get onbCalorieHistoryYes => 'Sim, e continuo';

  @override
  String onbCalorieHistoryTried(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Tentei, mas desisti',
      'female': 'Tentei, mas desisti',
      'other': 'Tentei, mas desisti',
    });
    return '$_temp0';
  }

  @override
  String get onbCalorieHistoryNever => 'Não, nunca';

  @override
  String get onbImproveTitle => 'O que você quer melhorar?';

  @override
  String get onbImproveLookBetter => 'Aparência';

  @override
  String get onbImproveFeelConfident => 'Sentir mais confiança';

  @override
  String get onbImproveHealth => 'Melhorar a saúde';

  @override
  String get onbImproveMoreEnergy => 'Mais energia';

  @override
  String get onbImproveLessStress => 'Menos estresse';

  @override
  String get onbImproveImmunity => 'Reforçar a imunidade';

  @override
  String get onbImproveFocus => 'Foco maior';

  @override
  String get onbImproveSleep => 'Dormir melhor';

  @override
  String get onbEatingObstacleTitle => 'O que te impede de comer melhor?';

  @override
  String get onbEatingObstacleCravings => 'Vontade de doce ou besteiras';

  @override
  String get onbEatingObstacleLateSnacks => 'Beliscar à noite';

  @override
  String get onbEatingObstacleBadHabits => 'Hábitos pouco saudáveis';

  @override
  String get onbHardestTitle => 'O que é mais difícil — manter a constância?';

  @override
  String get onbHardestBusy => 'Agenda apertada';

  @override
  String get onbHardestRestrictive => 'Restrições demais';

  @override
  String get onbHardestNoSupport => 'Falta de apoio';

  @override
  String get onbSupportTitle => 'Estamos com você até o fim!';

  @override
  String get onbSupportSubtitle =>
      'O caminho até o objetivo pode ser difícil, mas vamos te apoiar em cada passo.';

  @override
  String get onbSocialProofTitle =>
      'Com apoio, as pessoas perdem peso mais rápido';

  @override
  String get onbSocialProofSubtitle =>
      'O app ajuda você a alcançar resultados duradouros na perda de peso.';

  @override
  String get onbSpeedSlow => 'Devagar';

  @override
  String get onbSpeedBalanced => 'Equilibrado';

  @override
  String get onbSpeedFast => 'Rápido';

  @override
  String onbSpeedGoodTitle(String date) {
    return 'Meta: $date';
  }

  @override
  String get onbSpeedGoodBody =>
      'Um plano sensato — resultados estáveis e duradouros sem esgotamento.';

  @override
  String get onbSpeedAlertTitle => 'Muito rápido — risco de desistir';

  @override
  String get onbSpeedAlertBody =>
      'Escolha um ritmo mais sustentável para manter a constância e evitar o esgotamento.';

  @override
  String get onbTrialReminderTitle =>
      'Vamos te enviar um lembrete\nquando seu período de teste\nestiver perto do fim.';

  @override
  String get onbTrialReminderNoPaymentNow => 'Sem cobrança agora';

  @override
  String onbTrialReminderCta(String price) {
    return 'Testar por $price';
  }

  @override
  String onbTrialReminderSubtitle(String yearly, String monthly) {
    return 'Apenas $yearly por ano ($monthly/mês)';
  }
}
