// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get hello => 'Olá';

  @override
  String get onitama => 'Mestres de Onitama';

  @override
  String get gameOfTheMasters => 'O Jogo dos Mestres';

  @override
  String get localMultiplayer => 'Multijogador Local';

  @override
  String get playerVsAi => 'Jogador vs IA';

  @override
  String get onlineMultiplayer => 'Multijogador Online';

  @override
  String get privateGame => 'Jogo Privado';

  @override
  String get createOnlineGame => 'Criar Jogo Online';

  @override
  String get gameId => 'ID do Jogo';

  @override
  String get joinOnlineGame => 'Entrar em Jogo Online';

  @override
  String get howToPlay => 'Como Jogar';

  @override
  String get selectDifficulty => 'Selecionar Dificuldade';

  @override
  String get easy => 'Fácil';

  @override
  String get medium => 'Médio';

  @override
  String get hard => 'Difícil';

  @override
  String get matchmaking => 'Procurando Partida';

  @override
  String get waitingForAnOpponent => 'Esperando por um oponente...';

  @override
  String get howToPlayTitle => 'Como Jogar';

  @override
  String get onitamaDescription =>
      'Onitama é um jogo de estratégia abstrato para dois jogadores com uma mecânica de movimento única.';

  @override
  String get objectiveTitle => 'Objetivo';

  @override
  String get objectiveDescription => 'Existem duas maneiras de vencer:';

  @override
  String get wayOfTheStone =>
      '1. Caminho da Pedra: Capture o peão Mestre do seu oponente.';

  @override
  String get wayOfTheStream =>
      '2. Caminho do Riacho: Mova seu peão Mestre para o espaço do Arco do Templo inicial do seu oponente.';

  @override
  String get setupTitle => 'Configuração';

  @override
  String get setupDescription1 =>
      '1. Cada jogador começa com cinco peões: um Mestre e quatro Alunos.';

  @override
  String get setupDescription2 =>
      '2. Os peões são colocados no tabuleiro 5x5 em suas posições iniciais.';

  @override
  String get setupDescription3 =>
      '3. Cada jogador recebe duas cartas de Movimento aleatórias.';

  @override
  String get setupDescription4 =>
      '4. Uma carta extra é colocada ao lado do tabuleiro.';

  @override
  String get gameplayTitle => 'Jogabilidade';

  @override
  String get gameplayDescription =>
      'No seu turno, você deve realizar os seguintes passos:';

  @override
  String get gameplayStep1 =>
      '1. Escolha uma de suas duas cartas de Movimento.';

  @override
  String get gameplayStep2 =>
      '2. Mova um de seus peões de acordo com a carta selecionada.';

  @override
  String get gameplayStep3 =>
      '3. A carta que você usou é então trocada com a carta ao lado do tabuleiro.';

  @override
  String get movementTitle => 'Movimento';

  @override
  String get movementDescription1 =>
      '- O quadrado preto em uma carta de Movimento representa a posição atual do peão.';

  @override
  String get movementDescription2 =>
      '- Os quadrados coloridos mostram os movimentos possíveis a partir dessa posição.';

  @override
  String get movementDescription3 =>
      '- Você não pode mover um peão para fora do tabuleiro ou para um espaço já ocupado por um de seus próprios peões.';

  @override
  String get capturingTitle => 'Captura';

  @override
  String get capturingDescription =>
      'Se você mover um peão para um quadrado ocupado por um peão do oponente, o peão do oponente é capturado e removido do jogo.';

  @override
  String get loading => 'Carregando...';

  @override
  String get gameOver => 'Fim de Jogo';

  @override
  String get exit => 'Sair';

  @override
  String get restart => 'Reiniciar';

  @override
  String get you => 'Você';

  @override
  String get opponent => 'Oponente';

  @override
  String get restartGame => 'Reiniciar Jogo';

  @override
  String get areYouSureRestart => 'Tem certeza de que deseja reiniciar o jogo?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get surrender => 'Render-se';

  @override
  String get surrenderGame => 'Render-se';

  @override
  String get areYouSureSurrender => 'Tem certeza de que deseja se render?';

  @override
  String get exitGame => 'Sair do Jogo';

  @override
  String get areYouSureExit => 'Tem certeza de que deseja sair para o menu?';

  @override
  String get cardTiger => 'Tigre';

  @override
  String get cardDragon => 'Dragão';

  @override
  String get cardFrog => 'Sapo';

  @override
  String get cardRabbit => 'Coelho';

  @override
  String get cardCrab => 'Caranguejo';

  @override
  String get cardElephant => 'Elefante';

  @override
  String get cardGoose => 'Ganso';

  @override
  String get cardRooster => 'Galo';

  @override
  String get cardMonkey => 'Macaco';

  @override
  String get cardMantis => 'Louvadeus';

  @override
  String get cardHorse => 'Cavalo';

  @override
  String get cardOx => 'Boi';

  @override
  String get cardCrane => 'Grou';

  @override
  String get cardBoar => 'Javali';

  @override
  String get cardEel => 'Enguia';

  @override
  String get cardCobra => 'Cobra';

  @override
  String get wonByCapture => 'venceu por captura!';

  @override
  String get wonByTemple => 'venceu pelo templo!';

  @override
  String get blue => 'Azul';

  @override
  String get red => 'Vermelho';

  @override
  String get historyWon => 'Venceu';

  @override
  String get historyLost => 'Perdeu';

  @override
  String get historyNA => 'N/A';

  @override
  String get historyGameOn => 'Jogo em';

  @override
  String get historyErrorLoading => 'Erro ao carregar jogos.';

  @override
  String get historyNoFinished => 'Nenhum jogo finalizado encontrado.';

  @override
  String get historyTitle => 'Histórico de Jogos';

  @override
  String get matchResultVictoryTitle => 'Vitória!';

  @override
  String get matchResultDefeatTitle => 'Derrota';

  @override
  String matchResultGainedPoints(Object points) {
    return 'Você ganhou $points pontos de rating.';
  }

  @override
  String matchResultLostPoints(Object points) {
    return 'Você perdeu $points pontos de rating.';
  }

  @override
  String get matchResultNoChange => 'Seu rating não mudou.';

  @override
  String get matchResultPreviousRating => 'Rating anterior';

  @override
  String get matchResultNewRating => 'Rating atual';

  @override
  String get matchResultTierLabel => 'Nível';

  @override
  String get matchResultSeasonLabel => 'Temporada';

  @override
  String get login => 'Login';

  @override
  String get chooseUsername => 'Escolha um nome de usuário para continuar:';

  @override
  String get username => 'Nome de usuário';

  @override
  String get save => 'Salvar';

  @override
  String get usernameAlreadyExists => 'Este nome de usuário já está em uso.';

  @override
  String get signInWithGoogle => 'Entrar com Google';

  @override
  String get signInWithApple => 'Entrar com Apple';

  @override
  String get moveHistoryTitle => 'Histórico da Partida';

  @override
  String moveHistoryMove(Object number) {
    return 'Movimento $number';
  }

  @override
  String moveHistoryFromTo(
      Object cardName, Object fromR, Object fromC, Object toR, Object toC) {
    return 'De: ($fromR, $fromC) Para: ($toR, $toC) com $cardName';
  }

  @override
  String get undoWithAd => 'Assistir anúncio para desfazer';

  @override
  String get preloadLoadingTheme => 'Carregando tema...';

  @override
  String get preloadFetchingThemes => 'Buscando temas disponíveis...';

  @override
  String get preloadPreloadingImages => 'Pré-carregando imagens...';

  @override
  String preloadDownloadingImages(Object done, Object total) {
    return 'Baixando imagens ($done/$total)...';
  }

  @override
  String get preloadDone => 'Concluído!';

  @override
  String preloadImagesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count imagens',
      one: '1 imagem',
      zero: 'Nenhuma imagem',
    );
    return '$_temp0';
  }

  @override
  String lobbyGameIdLabel(Object gameId) {
    return 'ID do jogo: $gameId';
  }

  @override
  String get lobbyGameIdCopied =>
      'ID do jogo copiado para a área de transferência';

  @override
  String lobbyPlayersCount(Object count) {
    return 'Jogadores: $count/2';
  }

  @override
  String get leaderboardTitle => 'Ranking';

  @override
  String get leaderboardInvite =>
      'Jogue partidas online para entrar no ranking!';

  @override
  String leaderboardPlayerSummary(Object rating, Object tier, Object winRate) {
    return 'Sua classificação: $rating • $tier • $winRate% vitórias';
  }

  @override
  String get leaderboardEmpty => 'Seja o primeiro a aparecer no topo!';

  @override
  String leaderboardPlayerSubtitle(Object rating, Object tier) {
    return '$rating pontos • $tier';
  }

  @override
  String leaderboardWinRateShort(Object winRate) {
    return '$winRate%';
  }

  @override
  String get leaderboardTierBronze => 'Bronze';

  @override
  String get leaderboardTierSilver => 'Prata';

  @override
  String get leaderboardTierGold => 'Ouro';

  @override
  String get leaderboardTierPlatine => 'Platina';

  @override
  String get leaderboardTierDiamond => 'Diamante';

  @override
  String get play => 'Jogar';

  @override
  String get signOut => 'Sair';

  @override
  String get profile => 'Perfil';

  @override
  String get email => 'Email';

  @override
  String get displayName => 'Nome';

  @override
  String get profileChangePhoto => 'Alterar foto';

  @override
  String get profileCamera => 'Câmera';

  @override
  String get profileGallery => 'Galeria';

  @override
  String get profilePhotoUpdated => 'Foto de perfil atualizada!';

  @override
  String get profilePhotoUpdateError =>
      'Não foi possível atualizar sua foto. Tente novamente.';

  @override
  String get currentGameHistory => 'Histórico da Partida Atual';

  @override
  String get descriptionElephant =>
      'Nunca se esquecerá daqueles que mais lhe importam.';

  @override
  String get descriptionTiger =>
      'Forte e corajoso, ele protege seu lar com fervor.';

  @override
  String get descriptionDragon =>
      'Com sabedoria ancestral, ele guarda os segredos dos céus.';

  @override
  String get descriptionFrog =>
      'A calma do sapo esconde a agilidade de um predador.';

  @override
  String get descriptionRabbit =>
      'Sua astúcia e velocidade o ajudam a superar qualquer obstáculo.';

  @override
  String get descriptionCrab =>
      'A sua força e resiliência o tornam um guerreiro do mar.';

  @override
  String get descriptionGoose =>
      'Com lealdade e bravura, ele defende aqueles que ama.';

  @override
  String get descriptionRooster =>
      'Seu canto anuncia a chegada de um novo dia, cheio de energia.';

  @override
  String get descriptionMonkey =>
      'Inteligente e brincalhão, ele explora a vida com curiosidade.';

  @override
  String get descriptionMantis =>
      'Paciência e precisão são suas armas na floresta.';

  @override
  String get descriptionHorse =>
      'A liberdade e a força guiam seu espírito selvagem.';

  @override
  String get descriptionOx =>
      'Símbolo de trabalho e persistência, ele garante o sustento.';

  @override
  String get descriptionCrane =>
      'Sua elegância e graça inspiram a harmonia e a longevidade.';

  @override
  String get descriptionBoar =>
      'Determinado e destemido, ele enfrenta os desafios da floresta.';

  @override
  String get descriptionEel =>
      'Sutil e ágil, ela navega pelas profundezas com destreza.';

  @override
  String get descriptionCobra =>
      'Com sua sabedoria milenar, ela observa o mundo em silêncio.';
}
