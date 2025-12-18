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
  String get timerTitle => 'Reloj de partida';

  @override
  String get timerDescription =>
      'Cada jugador comienza con 5 minutos. Solo el reloj del jugador en turno disminuye y, si tu tiempo llega a cero, tu oponente gana de inmediato.';

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
  String get wonByTimeout => '¡ganó por tiempo!';

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
  String get historyCanceled => 'Cancelado';

  @override
  String get historyGameOn => 'Partida el';

  @override
  String get historyErrorLoading => 'Error al cargar partidas.';

  @override
  String get historyNoFinished => 'No se encontraron partidas finalizadas.';

  @override
  String get historyTitle => 'Historial de Partidas';

  @override
  String get matchResultVictoryTitle => '¡Victoria!';

  @override
  String get matchResultDefeatTitle => 'Derrota';

  @override
  String matchResultGainedPoints(Object points) {
    return 'Ganaste $points puntos de rating.';
  }

  @override
  String matchResultLostPoints(Object points) {
    return 'Perdiste $points puntos de rating.';
  }

  @override
  String get matchResultNoChange => 'Tu rating no cambió.';

  @override
  String get matchResultPreviousRating => 'Rating anterior';

  @override
  String get matchResultNewRating => 'Rating actual';

  @override
  String get matchResultTierLabel => 'Rango';

  @override
  String get matchResultSeasonLabel => 'Temporada';

  @override
  String get matchResultGoldRewardLabel => 'Recompensa de oro';

  @override
  String matchResultGoldBalance(Object amount) {
    return 'Oro actual: $amount';
  }

  @override
  String get login => 'Login';

  @override
  String get loginRequiredTitle => 'Inicio de sesión requerido';

  @override
  String get loginRequiredMessage =>
      'Necesitas iniciar sesión para jugar en línea.';

  @override
  String get loginRequiredAction => 'Ir al login';

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
  String get profileChangePhoto => 'Cambiar foto';

  @override
  String get profileCamera => 'Cámara';

  @override
  String get profileGallery => 'Galería';

  @override
  String get profilePhotoUpdated => '¡Foto de perfil actualizada!';

  @override
  String get profilePhotoUpdateError =>
      'No pudimos actualizar tu foto. Inténtalo de nuevo.';

  @override
  String get currentGameHistory => 'Historial de la Partida Actual';

  @override
  String get descriptionElephant =>
      'Nunca olvidará a aquellos que más le importan.';

  @override
  String get descriptionTiger =>
      'Fuerte y valiente, protege su hogar con fervor.';

  @override
  String get descriptionDragon =>
      'Con sabiduría ancestral, guarda los secretos de los cielos.';

  @override
  String get descriptionFrog =>
      'La calma del sapo esconde la agilidad de un depredador.';

  @override
  String get descriptionRabbit =>
      'Su astucia y velocidad le ayudan a superar cualquier obstáculo.';

  @override
  String get descriptionCrab =>
      'Su fuerza y resistencia lo convierten en un guerrero del mar.';

  @override
  String get descriptionGoose =>
      'Con lealtad y bravura, defiende a quienes ama.';

  @override
  String get descriptionRooster =>
      'Su canto anuncia la llegada de un nuevo día, lleno de energía.';

  @override
  String get descriptionMonkey =>
      'Inteligente y juguetón, explora la vida con curiosidad.';

  @override
  String get descriptionMantis =>
      'Paciencia y precisión son sus armas en el bosque.';

  @override
  String get descriptionHorse =>
      'La libertad y la fuerza guían su espíritu salvaje.';

  @override
  String get descriptionOx =>
      'Símbolo de trabajo y persistencia, garantiza el sustento.';

  @override
  String get descriptionCrane =>
      'Su elegancia y gracia inspiran armonía y longevidad.';

  @override
  String get descriptionBoar =>
      'Determinado y audaz, se enfrenta a los desafíos del bosque.';

  @override
  String get descriptionEel =>
      'Sutil y ágil, navega por las profundidades con destreza.';

  @override
  String get descriptionCobra =>
      'Con su sabiduría milenaria, observa el mundo en silencio.';

  @override
  String get startGame => 'Iniciar Juego';

  @override
  String get tutorialSkip => 'Omitir';

  @override
  String get tutorialMenuPlayTitle => 'Inicia una partida';

  @override
  String get tutorialMenuPlayDescription =>
      'Abre el menú de juego para buscar partidas en línea, bots o salas privadas.';

  @override
  String get tutorialMenuLeaderboardTitle => 'Clasificación';

  @override
  String get tutorialMenuLeaderboardDescription =>
      'Consulta a los maestros y tu posición.';

  @override
  String get tutorialMenuHowToPlayTitle => 'Aprende las reglas';

  @override
  String get tutorialMenuHowToPlayDescription =>
      'Abre la guía cuando necesites recordarlas.';

  @override
  String get tutorialMenuProfileTitle => 'Perfil y acceso';

  @override
  String get tutorialMenuProfileDescription =>
      'Inicia sesión, edita tu avatar o ajusta tu cuenta aquí.';

  @override
  String get tutorialMenuVolumeTitle => 'Sonido';

  @override
  String get tutorialMenuVolumeDescription =>
      'Controla música y efectos o silencia el juego.';

  @override
  String get tutorialPlayMenuStartTitle => 'Emparejamiento rápido';

  @override
  String get tutorialPlayMenuStartDescription =>
      'Encuentra un oponente en línea automáticamente.';

  @override
  String get tutorialPlayMenuPvpTitle => 'PvP local';

  @override
  String get tutorialPlayMenuPvpDescription =>
      'Reta a un amigo en el mismo dispositivo.';

  @override
  String get tutorialPlayMenuAiTitle => 'Practica vs IA';

  @override
  String get tutorialPlayMenuAiDescription =>
      'Enfrenta distintas dificultades para entrenar.';

  @override
  String get tutorialPlayMenuPrivateTitle => 'Salas privadas';

  @override
  String get tutorialPlayMenuPrivateDescription =>
      'Crea o únete a partidas con un código compartido.';

  @override
  String get tutorialGameplayPlayerCardsTitle => 'Tus cartas';

  @override
  String get tutorialGameplayPlayerCardsDescription =>
      'Cada duelo usa cinco de las 16 cartas de movimiento. Estas dos muestran los movimientos disponibles ahora.';

  @override
  String get tutorialGameplayOpponentCardsTitle => 'Cartas del rival';

  @override
  String get tutorialGameplayOpponentCardsDescription =>
      'Anticipa los movimientos que tu oponente podría usar.';

  @override
  String get tutorialGameplayBoardTitle => 'Tablero y piezas';

  @override
  String get tutorialGameplayBoardDescription =>
      'Mueve estudiantes o al maestro. Captura al maestro enemigo o llega a su templo para ganar.';

  @override
  String get tutorialGameplayReserveTitle => 'Carta de reserva';

  @override
  String get tutorialGameplayReserveDescription =>
      'Cuando juegas una carta viene aquí y tomas esta, manteniendo el intercambio constante.';

  @override
  String get goldBalanceLabel => 'Oro';

  @override
  String get goldStatementTitle => 'Estado de oro';

  @override
  String get goldStatementEmpty => 'Aún no tienes transacciones de oro.';

  @override
  String get goldStatementMatchReward => 'Recompensa de partida';

  @override
  String get goldStatementStorePurchase => 'Compra de oro';

  @override
  String get goldStatementThemePurchase => 'Compra de tema';

  @override
  String goldStatementBalance(Object amount) {
    return 'Saldo: $amount';
  }

  @override
  String get goldStoreTitle => 'Tienda de oro';

  @override
  String get goldStoreSubtitle =>
      'Recarga tu oro para desbloquear cosméticos en el futuro.';

  @override
  String get goldStoreBadgeMostPopular => 'Más popular';

  @override
  String goldStoreBonusLabel(Object amount) {
    return '$amount de bonificación';
  }

  @override
  String get goldStoreBuyButton => 'Comprar ahora';

  @override
  String get goldStoreError =>
      'No pudimos cargar la tienda. Inténtalo de nuevo en unos instantes.';

  @override
  String get goldStoreRetry => 'Reintentar';

  @override
  String get goldStoreRestoreButton => 'Restaurar compras';

  @override
  String get goldStorePurchaseSuccess => '¡Oro añadido a tu saldo!';

  @override
  String get goldStorePurchaseError =>
      'No pudimos completar tu compra. Inténtalo de nuevo más tarde.';

  @override
  String get goldStoreAddTooltip => 'Comprar más oro';

  @override
  String get goldStoreLoading => 'Cargando ofertas...';

  @override
  String get skinStoreTitle => 'Tienda de Cosméticos';

  @override
  String get skinStoreSubtitle =>
      'Colecciona skins exclusivas para tus maestros.';

  @override
  String get skinStoreLoading => 'Cargando cosméticos...';

  @override
  String get skinStoreError =>
      'No pudimos cargar los cosméticos. Inténtalo de nuevo.';

  @override
  String get skinStoreEmpty => 'No hay cosméticos disponibles por ahora.';

  @override
  String get skinStoreFilterEmpty => 'Aún no hay artículos en esta categoría.';

  @override
  String get skinStoreRetry => 'Recargar';

  @override
  String get skinStoreCategoryPieces => 'Piezas';

  @override
  String get skinStoreCategoryBoards => 'Tableros';

  @override
  String get skinStoreCategoryCards => 'Cartas';

  @override
  String get skinStoreCategoryBackgrounds => 'Fondos';

  @override
  String get skinStoreCategoryGroup => 'Paquetes';

  @override
  String get skinStoreCategoryAll => 'Todos';

  @override
  String get skinStoreOwnedTag => 'Adquirido';

  @override
  String get skinStoreEquippedTag => 'Equipado';

  @override
  String skinStoreDiscountLabel(Object amount) {
    return '$amount de descuento';
  }

  @override
  String get skinStoreOwnedMessage => 'Ya posees este cosmético.';

  @override
  String get skinStoreBuyButton => 'Comprar';

  @override
  String get skinStoreOwnedButton => 'Adquirido';

  @override
  String get skinStoreInsufficientGold => 'No tienes oro suficiente.';

  @override
  String get skinStoreConfirmTitle => 'Confirmar compra';

  @override
  String skinStoreConfirmDescription(
      Object item, Object price, Object balance) {
    return '¿Comprar $item por $price de oro? Saldo restante: $balance.';
  }

  @override
  String skinStorePurchaseSuccess(Object item) {
    return '¡$item desbloqueado!';
  }

  @override
  String get skinStoreEquipPromptTitle => 'Equipar cosmético';

  @override
  String skinStoreEquipPromptDescription(Object item) {
    return '¿Deseas equipar $item ahora?';
  }

  @override
  String get skinStoreEquipConfirm => 'Equipar';

  @override
  String get skinStoreEquipLater => 'Después';

  @override
  String skinStoreEquipSuccess(Object item) {
    return '¡$item equipado!';
  }

  @override
  String get skinStoreDetailAssetsTitle => 'Elementos incluidos';

  @override
  String get skinStoreDetailPriceLabel => 'Precio';

  @override
  String get skinStoreEmptyAssets =>
      'Este paquete aún no tiene assets asociados.';

  @override
  String get skinLoadoutTitle => 'Selección de Skins';

  @override
  String get skinLoadoutSubtitle =>
      'Elige qué cosméticos usar en cada espacio.';

  @override
  String get skinLoadoutSelectionTab => 'Selección';

  @override
  String get skinLoadoutPreviewTab => 'Vista previa';

  @override
  String get skinLoadoutCategoryPieces => 'Piezas';

  @override
  String get skinLoadoutCategoryCards => 'Cartas';

  @override
  String get skinLoadoutCategoryBoards => 'Tableros';

  @override
  String get skinLoadoutCategoryBackgrounds => 'Fondo';

  @override
  String get skinLoadoutSave => 'Guardar selección';

  @override
  String get skinLoadoutSaving => 'Guardando...';

  @override
  String get skinLoadoutReset => 'Restablecer por defecto';

  @override
  String get skinLoadoutPreviewTitle => 'Vista previa';

  @override
  String get skinLoadoutPreviewDescription =>
      'Mira cómo se ven tus elecciones durante un duelo.';

  @override
  String get skinLoadoutAllCardsLabel => 'Todas las cartas';

  @override
  String get skinLoadoutEmptyCategory =>
      'Todavía no hay espacios en esta categoría.';

  @override
  String get skinLoadoutEmptySlot =>
      'Aún no desbloqueaste cosméticos para este espacio.';

  @override
  String get skinLoadoutUnsavedBanner => 'Tienes cambios sin guardar.';

  @override
  String get skinLoadoutUnableToLoad =>
      'No pudimos cargar los temas disponibles.';

  @override
  String get skinLoadoutRetry => 'Reintentar';

  @override
  String get skinLoadoutUnavailable => 'Aún no hay cosméticos configurables.';

  @override
  String get skinLoadoutApplyError =>
      'No pudimos guardar tu selección. Inténtalo de nuevo.';

  @override
  String get skinLoadoutSaved => '¡Selección guardada!';

  @override
  String get skinLoadoutDefaultTag => 'Predeterminado';

  @override
  String get skinLoadoutManageButton => 'Personalizar skins';

  @override
  String get skinSlotBlueMaster => 'Maestro Azul';

  @override
  String get skinSlotBlueStudent1 => 'Alumno Azul I';

  @override
  String get skinSlotBlueStudent2 => 'Alumno Azul II';

  @override
  String get skinSlotBlueStudent3 => 'Alumno Azul III';

  @override
  String get skinSlotBlueStudent4 => 'Alumno Azul IV';

  @override
  String get skinSlotRedMaster => 'Maestro Rojo';

  @override
  String get skinSlotRedStudent1 => 'Alumno Rojo I';

  @override
  String get skinSlotRedStudent2 => 'Alumno Rojo II';

  @override
  String get skinSlotRedStudent3 => 'Alumno Rojo III';

  @override
  String get skinSlotRedStudent4 => 'Alumno Rojo IV';

  @override
  String get skinSlotBackground => 'Fondo';

  @override
  String get skinSlotBoardSurface => 'Superficie del tablero';

  @override
  String get skinSlotBoardLight => 'Casillas claras';

  @override
  String get skinSlotBoardDark => 'Casillas oscuras';
}
