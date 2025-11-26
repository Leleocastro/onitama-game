// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get hello => 'Hola';

  @override
  String get onitama => 'Maestros de Onitama';

  @override
  String get gameOfTheMasters => 'El Juego de los Maestros';

  @override
  String get localMultiplayer => 'Multijugador Local';

  @override
  String get playerVsAi => 'Jugador vs IA';

  @override
  String get onlineMultiplayer => 'Multijugador en Línea';

  @override
  String get privateGame => 'Partida Privada';

  @override
  String get createOnlineGame => 'Crear Partida en Línea';

  @override
  String get gameId => 'ID de la Partida';

  @override
  String get joinOnlineGame => 'Unirse a Partida en Línea';

  @override
  String get howToPlay => 'Cómo Jugar';

  @override
  String get selectDifficulty => 'Seleccionar Dificultad';

  @override
  String get easy => 'Fácil';

  @override
  String get medium => 'Medio';

  @override
  String get hard => 'Difícil';

  @override
  String get matchmaking => 'Buscando Partida';

  @override
  String get waitingForAnOpponent => 'Esperando a un oponente...';

  @override
  String get howToPlayTitle => 'Cómo Jugar';

  @override
  String get onitamaDescription =>
      'Onitama es un juego de estrategia abstracto para dos jugadores con una mecánica de movimiento única.';

  @override
  String get objectiveTitle => 'Objetivo';

  @override
  String get objectiveDescription => 'Hay dos formas de ganar:';

  @override
  String get wayOfTheStone =>
      '1. Camino de la Piedra: Captura el peón Maestro de tu oponente.';

  @override
  String get wayOfTheStream =>
      '2. Camino del Arroyo: Mueve tu peón Maestro al espacio del Arco del Templo inicial de tu oponente.';

  @override
  String get setupTitle => 'Configuración';

  @override
  String get setupDescription1 =>
      '1. Cada jugador comienza con cinco peones: un Maestro y cuatro Estudiantes.';

  @override
  String get setupDescription2 =>
      '2. Los peones se colocan en el tablero de 5x5 en sus posiciones iniciales.';

  @override
  String get setupDescription3 =>
      '3. Cada jugador recibe dos cartas de Movimiento aleatorias.';

  @override
  String get setupDescription4 =>
      '4. Se coloca una carta extra al costado del tablero.';

  @override
  String get gameplayTitle => 'Jugabilidad';

  @override
  String get gameplayDescription =>
      'En tu turno, debes realizar los siguientes pasos:';

  @override
  String get gameplayStep1 => '1. Elige una de tus dos cartas de Movimiento.';

  @override
  String get gameplayStep2 =>
      '2. Mueve uno de tus peones según la carta seleccionada.';

  @override
  String get gameplayStep3 =>
      '3. La carta que usaste se intercambia con la carta al costado del tablero.';

  @override
  String get movementTitle => 'Movimiento';

  @override
  String get movementDescription1 =>
      '- El cuadrado negro en una carta de Movimiento representa la posición actual del peón.';

  @override
  String get movementDescription2 =>
      '- Los cuadrados de colores muestran los posibles movimientos desde esa posición.';

  @override
  String get movementDescription3 =>
      '- No puedes mover un peón fuera del tablero o a un espacio ya ocupado por uno de tus propios peones.';

  @override
  String get capturingTitle => 'Captura';

  @override
  String get capturingDescription =>
      'Si mueves un peón a un cuadrado ocupado por un peón del oponente, el peón del oponente es capturado y eliminado del juego.';

  @override
  String get loading => 'Cargando...';

  @override
  String get gameOver => 'Fin del Juego';

  @override
  String get exit => 'Salir';

  @override
  String get restart => 'Reiniciar';

  @override
  String get you => 'Tú';

  @override
  String get opponent => 'Oponente';

  @override
  String get restartGame => 'Reiniciar Juego';

  @override
  String get areYouSureRestart =>
      '¿Estás seguro de que quieres reiniciar el juego?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get surrender => 'Rendirse';

  @override
  String get surrenderGame => 'Rendirse';

  @override
  String get areYouSureSurrender => '¿Estás seguro de que quieres rendirte?';

  @override
  String get exitGame => 'Salir del Juego';

  @override
  String get areYouSureExit => '¿Estás seguro de que quieres salir al menú?';

  @override
  String get cardTiger => 'Tigre';

  @override
  String get cardDragon => 'Dragón';

  @override
  String get cardFrog => 'Rana';

  @override
  String get cardRabbit => 'Conejo';

  @override
  String get cardCrab => 'Cangrejo';

  @override
  String get cardElephant => 'Elefante';

  @override
  String get cardGoose => 'Ganso';

  @override
  String get cardRooster => 'Gallo';

  @override
  String get cardMonkey => 'Mono';

  @override
  String get cardMantis => 'Mantis';

  @override
  String get cardHorse => 'Caballo';

  @override
  String get cardOx => 'Buey';

  @override
  String get cardCrane => 'Grulla';

  @override
  String get cardBoar => 'Jabalí';

  @override
  String get cardEel => 'Anguila';

  @override
  String get cardCobra => 'Cobra';

  @override
  String get wonByCapture => '¡ganó por captura!';

  @override
  String get wonByTemple => '¡ganó por templo!';

  @override
  String get blue => 'Azul';

  @override
  String get red => 'Rojo';

  @override
  String get historyWon => 'Ganó';

  @override
  String get historyLost => 'Perdió';

  @override
  String get historyNA => 'N/A';

  @override
  String get historyGameOn => 'Partida em';

  @override
  String get historyErrorLoading => 'Error al cargar partidas.';

  @override
  String get historyNoFinished => 'No se encontraron partidas finalizadas.';

  @override
  String get historyTitle => 'Historial de Partidas';

  @override
  String get login => 'Login';

  @override
  String get chooseUsername => 'Elige un nombre de usuario para continuar:';

  @override
  String get username => 'Nombre de usuario';

  @override
  String get save => 'Guardar';

  @override
  String get usernameAlreadyExists => 'Este nombre de usuario ya está en uso.';

  @override
  String get signInWithGoogle => 'Iniciar sesión con Google';

  @override
  String get signInWithApple => 'Iniciar sesión con Apple';

  @override
  String get moveHistoryTitle => 'Historial de la Partida';

  @override
  String moveHistoryMove(Object number) {
    return 'Movimiento $number';
  }

  @override
  String moveHistoryFromTo(
      Object cardName, Object fromR, Object fromC, Object toR, Object toC) {
    return 'De: ($fromR, $fromC) A: ($toR, $toC) con $cardName';
  }

  @override
  String get undoWithAd => 'Ver anuncio para deshacer';

  @override
  String get preloadLoadingTheme => 'Cargando tema...';

  @override
  String get preloadFetchingThemes => 'Buscando temas disponibles...';

  @override
  String get preloadPreloadingImages => 'Pre-cargando imágenes...';

  @override
  String preloadDownloadingImages(Object done, Object total) {
    return 'Descargando imágenes ($done/$total)...';
  }

  @override
  String get preloadDone => '¡Listo!';

  @override
  String preloadImagesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count imágenes',
      one: '1 imagen',
      zero: 'Sin imágenes',
    );
    return '$_temp0';
  }

  @override
  String lobbyGameIdLabel(Object gameId) {
    return 'ID de la partida: $gameId';
  }

  @override
  String get lobbyGameIdCopied => 'ID de la partida copiado al portapapeles';

  @override
  String lobbyPlayersCount(Object count) {
    return 'Jugadores: $count/2';
  }

  @override
  String get leaderboardTitle => 'Clasificación';

  @override
  String get leaderboardInvite =>
      '¡Juega partidas en línea para entrar en la clasificación!';

  @override
  String leaderboardPlayerSummary(Object rating, Object tier, Object winRate) {
    return 'Tu clasificación: $rating • $tier • $winRate% victorias';
  }

  @override
  String get leaderboardEmpty => '¡Sé el primero en llegar a la cima!';

  @override
  String leaderboardPlayerSubtitle(Object rating, Object tier) {
    return '$rating puntos • $tier';
  }

  @override
  String leaderboardWinRateShort(Object winRate) {
    return '$winRate%';
  }

  @override
  String get leaderboardTierBronze => 'Bronce';

  @override
  String get leaderboardTierSilver => 'Plata';

  @override
  String get leaderboardTierGold => 'Oro';

  @override
  String get leaderboardTierPlatine => 'Platino';

  @override
  String get leaderboardTierDiamond => 'Diamante';

  @override
  String get play => 'Jugar';

  @override
  String get signOut => 'Salir';

  @override
  String get profile => 'Perfil';

  @override
  String get email => 'Email';

  @override
  String get displayName => 'Nombre';

  @override
  String get currentGameHistory => 'Historial de la Partida Actual';
}
