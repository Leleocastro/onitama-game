// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get hello => 'Hello';

  @override
  String get onitama => 'Masters of Onitama';

  @override
  String get gameOfTheMasters => 'The Game of the Masters';

  @override
  String get localMultiplayer => 'Local Multiplayer';

  @override
  String get playerVsAi => 'Player vs AI';

  @override
  String get onlineMultiplayer => 'Online Multiplayer';

  @override
  String get privateGame => 'Private Game';

  @override
  String get createOnlineGame => 'Create Online Game';

  @override
  String get gameId => 'Game ID';

  @override
  String get joinOnlineGame => 'Join Online Game';

  @override
  String get howToPlay => 'How to Play';

  @override
  String get selectDifficulty => 'Select Difficulty';

  @override
  String get easy => 'Easy';

  @override
  String get medium => 'Medium';

  @override
  String get hard => 'Hard';

  @override
  String get matchmaking => 'Matchmaking';

  @override
  String get waitingForAnOpponent => 'Waiting for an opponent...';

  @override
  String get howToPlayTitle => 'How to Play';

  @override
  String get onitamaDescription =>
      'Onitama is a two-player abstract strategy game with a unique movement mechanic.';

  @override
  String get objectiveTitle => 'Objective';

  @override
  String get objectiveDescription => 'There are two ways to win:';

  @override
  String get wayOfTheStone =>
      '1. Way of the Stone: Capture your opponent\'s Master pawn.';

  @override
  String get wayOfTheStream =>
      '2. Way of the Stream: Move your Master pawn to your opponent\'s starting Temple Arch space.';

  @override
  String get setupTitle => 'Setup';

  @override
  String get setupDescription1 =>
      '1. Each player starts with five pawns: one Master and four Students.';

  @override
  String get setupDescription2 =>
      '2. Pawns are placed on the 5x5 board in their starting positions.';

  @override
  String get setupDescription3 =>
      '3. Each player receives two random Move cards.';

  @override
  String get setupDescription4 =>
      '4. One extra card is placed on the side of the board.';

  @override
  String get gameplayTitle => 'Gameplay';

  @override
  String get gameplayDescription =>
      'On your turn, you must perform the following steps:';

  @override
  String get gameplayStep1 => '1. Choose one of your two Move cards.';

  @override
  String get gameplayStep2 =>
      '2. Move one of your pawns according to the selected card.';

  @override
  String get gameplayStep3 =>
      '3. The card you used is then exchanged with the card on the side of the board.';

  @override
  String get movementTitle => 'Movement';

  @override
  String get movementDescription1 =>
      '- The black square on a Move card represents the pawn\'s current position.';

  @override
  String get movementDescription2 =>
      '- The colored squares show the possible moves from that position.';

  @override
  String get movementDescription3 =>
      '- You cannot move a pawn off the board or onto a space occupied by your own pawn.';

  @override
  String get capturingTitle => 'Capturing';

  @override
  String get capturingDescription =>
      'If you move a pawn to a square occupied by an opponent\'s pawn, the opponent\'s pawn is captured and removed from the game.';

  @override
  String get timerTitle => 'Match Timer';

  @override
  String get timerDescription =>
      'Each player starts with 5 minutes. Only the active player\'s clock decreases, and if your time reaches zero your opponent wins immediately.';

  @override
  String get loading => 'Loading...';

  @override
  String get gameOver => 'Game Over';

  @override
  String get exit => 'Exit';

  @override
  String get restart => 'Restart';

  @override
  String get you => 'You';

  @override
  String get opponent => 'Opponent';

  @override
  String get restartGame => 'Restart Game';

  @override
  String get areYouSureRestart => 'Are you sure you want to restart the game?';

  @override
  String get cancel => 'Cancel';

  @override
  String get surrender => 'Surrender';

  @override
  String get surrenderGame => 'Surrender Game';

  @override
  String get areYouSureSurrender =>
      'Are you sure you want to surrender the game?';

  @override
  String get exitGame => 'Exit Game';

  @override
  String get areYouSureExit => 'Are you sure you want to exit to the menu?';

  @override
  String get cardTiger => 'Tiger';

  @override
  String get cardDragon => 'Dragon';

  @override
  String get cardFrog => 'Frog';

  @override
  String get cardRabbit => 'Rabbit';

  @override
  String get cardCrab => 'Crab';

  @override
  String get cardElephant => 'Elephant';

  @override
  String get cardGoose => 'Goose';

  @override
  String get cardRooster => 'Rooster';

  @override
  String get cardMonkey => 'Monkey';

  @override
  String get cardMantis => 'Mantis';

  @override
  String get cardHorse => 'Horse';

  @override
  String get cardOx => 'Ox';

  @override
  String get cardCrane => 'Crane';

  @override
  String get cardBoar => 'Boar';

  @override
  String get cardEel => 'Eel';

  @override
  String get cardCobra => 'Cobra';

  @override
  String get wonByCapture => 'won by capture!';

  @override
  String get wonByTemple => 'won by temple!';

  @override
  String get wonByTimeout => 'won by time!';

  @override
  String get blue => 'Blue';

  @override
  String get red => 'Red';

  @override
  String get historyWon => 'Won';

  @override
  String get historyLost => 'Lost';

  @override
  String get historyNA => 'N/A';

  @override
  String get historyCanceled => 'Canceled';

  @override
  String get historyGameOn => 'Game on';

  @override
  String get historyErrorLoading => 'Error loading games.';

  @override
  String get historyNoFinished => 'No finished games found.';

  @override
  String get historyTitle => 'Game History';

  @override
  String get matchResultVictoryTitle => 'Victory!';

  @override
  String get matchResultDefeatTitle => 'Defeat';

  @override
  String matchResultGainedPoints(Object points) {
    return 'You gained $points rating points.';
  }

  @override
  String matchResultLostPoints(Object points) {
    return 'You lost $points rating points.';
  }

  @override
  String get matchResultNoChange => 'Your rating remains unchanged.';

  @override
  String get matchResultPreviousRating => 'Previous rating';

  @override
  String get matchResultNewRating => 'New rating';

  @override
  String get matchResultTierLabel => 'Tier';

  @override
  String get matchResultSeasonLabel => 'Season';

  @override
  String get matchResultGoldRewardLabel => 'Gold reward';

  @override
  String matchResultGoldBalance(Object amount) {
    return 'Current gold: $amount';
  }

  @override
  String get login => 'Login';

  @override
  String get loginRequiredTitle => 'Login required';

  @override
  String get loginRequiredMessage => 'You need to be logged in to play online.';

  @override
  String get loginRequiredAction => 'Go to login';

  @override
  String get chooseUsername => 'Choose a username to continue:';

  @override
  String get username => 'Username';

  @override
  String get save => 'Save';

  @override
  String get usernameAlreadyExists => 'This username is already taken.';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get moveHistoryTitle => 'Current Game History';

  @override
  String moveHistoryMove(Object number) {
    return 'Move $number';
  }

  @override
  String moveHistoryFromTo(
      Object cardName, Object fromR, Object fromC, Object toR, Object toC) {
    return 'From: ($fromR, $fromC) To: ($toR, $toC) with $cardName';
  }

  @override
  String get undoWithAd => 'Watch ad to undo';

  @override
  String get preloadLoadingTheme => 'Loading theme...';

  @override
  String get preloadFetchingThemes => 'Fetching available themes...';

  @override
  String get preloadPreloadingImages => 'Preloading images...';

  @override
  String preloadDownloadingImages(Object done, Object total) {
    return 'Downloading images ($done/$total)...';
  }

  @override
  String get preloadDone => 'Done!';

  @override
  String preloadImagesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count images',
      one: '1 image',
      zero: 'No images',
    );
    return '$_temp0';
  }

  @override
  String lobbyGameIdLabel(Object gameId) {
    return 'Game ID: $gameId';
  }

  @override
  String get lobbyGameIdCopied => 'Game ID copied to clipboard';

  @override
  String lobbyPlayersCount(Object count) {
    return 'Players: $count/2';
  }

  @override
  String get leaderboardTitle => 'Leaderboard';

  @override
  String get leaderboardInvite =>
      'Play online matches to join the leaderboard!';

  @override
  String leaderboardPlayerSummary(Object rating, Object tier, Object winRate) {
    return 'Your rank: $rating • $tier • $winRate% wins';
  }

  @override
  String get leaderboardEmpty => 'Be the first to reach the top!';

  @override
  String leaderboardPlayerSubtitle(Object rating, Object tier) {
    return '$rating points • $tier';
  }

  @override
  String leaderboardWinRateShort(Object winRate) {
    return '$winRate%';
  }

  @override
  String get leaderboardTierBronze => 'Bronze';

  @override
  String get leaderboardTierSilver => 'Silver';

  @override
  String get leaderboardTierGold => 'Gold';

  @override
  String get leaderboardTierPlatine => 'Platinum';

  @override
  String get leaderboardTierDiamond => 'Diamond';

  @override
  String get play => 'Play';

  @override
  String get signOut => 'Sign Out';

  @override
  String get profile => 'Profile';

  @override
  String get email => 'Email';

  @override
  String get displayName => 'Display Name';

  @override
  String get profileChangePhoto => 'Change photo';

  @override
  String get profileCamera => 'Camera';

  @override
  String get profileGallery => 'Gallery';

  @override
  String get profilePhotoUpdated => 'Profile photo updated!';

  @override
  String get profilePhotoUpdateError =>
      'We couldn\'t update your photo. Try again.';

  @override
  String get currentGameHistory => 'Current Game History';

  @override
  String get descriptionElephant =>
      'He will never forget those who matter most to him.';

  @override
  String get descriptionTiger =>
      'Strong and courageous, he fiercely protects his home.';

  @override
  String get descriptionDragon =>
      'With ancient wisdom, he guards the secrets of the heavens.';

  @override
  String get descriptionFrog =>
      'The frog\'s calmness hides a predator\'s agility.';

  @override
  String get descriptionRabbit =>
      'His cunning and speed help him overcome any obstacle.';

  @override
  String get descriptionCrab =>
      'His strength and resilience make him a warrior of the sea.';

  @override
  String get descriptionGoose =>
      'With loyalty and bravery, he defends those he loves.';

  @override
  String get descriptionRooster =>
      'His crow heralds the arrival of a new day, full of energy.';

  @override
  String get descriptionMonkey =>
      'Intelligent and playful, he explores life with curiosity.';

  @override
  String get descriptionMantis =>
      'Patience and precision are his weapons in the forest.';

  @override
  String get descriptionHorse => 'Freedom and strength guide his wild spirit.';

  @override
  String get descriptionOx =>
      'A symbol of labor and persistence, he ensures sustenance.';

  @override
  String get descriptionCrane =>
      'His elegance and grace inspire harmony and longevity.';

  @override
  String get descriptionBoar =>
      'Determined and fearless, he faces the challenges of the forest.';

  @override
  String get descriptionEel =>
      'Subtle and agile, she navigates the depths with skill.';

  @override
  String get descriptionCobra =>
      'With its millenary wisdom, it observes the world in silence.';

  @override
  String get startGame => 'Start Game';

  @override
  String get tutorialSkip => 'Skip';

  @override
  String get tutorialMenuPlayTitle => 'Start a match';

  @override
  String get tutorialMenuPlayDescription =>
      'Open the play menu to find online games, bots, or private rooms.';

  @override
  String get tutorialMenuLeaderboardTitle => 'Leaderboard';

  @override
  String get tutorialMenuLeaderboardDescription =>
      'Check the masters and see where you stand.';

  @override
  String get tutorialMenuHowToPlayTitle => 'Learn the rules';

  @override
  String get tutorialMenuHowToPlayDescription =>
      'Open the guide whenever you need a refresher.';

  @override
  String get tutorialMenuProfileTitle => 'Profile & login';

  @override
  String get tutorialMenuProfileDescription =>
      'Sign in, edit your avatar, or access account options here.';

  @override
  String get tutorialMenuVolumeTitle => 'Sound';

  @override
  String get tutorialMenuVolumeDescription =>
      'Adjust music, sound effects, or mute the game.';

  @override
  String get tutorialPlayMenuStartTitle => 'Instant matchmaking';

  @override
  String get tutorialPlayMenuStartDescription =>
      'Find an online opponent automatically.';

  @override
  String get tutorialPlayMenuPvpTitle => 'Local PvP';

  @override
  String get tutorialPlayMenuPvpDescription =>
      'Challenge a friend on the same device.';

  @override
  String get tutorialPlayMenuAiTitle => 'Practice vs AI';

  @override
  String get tutorialPlayMenuAiDescription =>
      'Battle different difficulties to sharpen your skills.';

  @override
  String get tutorialPlayMenuPrivateTitle => 'Private rooms';

  @override
  String get tutorialPlayMenuPrivateDescription =>
      'Create or join a match with a shareable code.';

  @override
  String get tutorialGameplayPlayerCardsTitle => 'Your cards';

  @override
  String get tutorialGameplayPlayerCardsDescription =>
      'Each duel uses five of the 16 movement cards. These two show the moves you can play now.';

  @override
  String get tutorialGameplayOpponentCardsTitle => 'Opponent cards';

  @override
  String get tutorialGameplayOpponentCardsDescription =>
      'Keep track of the moves your rival can choose next.';

  @override
  String get tutorialGameplayBoardTitle => 'Board & pieces';

  @override
  String get tutorialGameplayBoardDescription =>
      'Move students or your master. Capture the enemy master or reach their temple to win.';

  @override
  String get tutorialGameplayReserveTitle => 'Reserve card';

  @override
  String get tutorialGameplayReserveDescription =>
      'When you play a card it enters the reserve and you take this one, so cards constantly rotate.';

  @override
  String get goldBalanceLabel => 'Gold';

  @override
  String get goldStatementTitle => 'Gold statement';

  @override
  String get goldStatementEmpty => 'You don\'t have any gold transactions yet.';

  @override
  String get goldStatementMatchReward => 'Match reward';

  @override
  String get goldStatementStorePurchase => 'Gold purchase';

  @override
  String get goldStatementThemePurchase => 'Theme purchase';

  @override
  String goldStatementBalance(Object amount) {
    return 'Balance: $amount';
  }

  @override
  String get goldStoreTitle => 'Gold Store';

  @override
  String get goldStoreSubtitle =>
      'Top up your gold to unlock future cosmetics.';

  @override
  String get goldStoreBadgeMostPopular => 'Most popular';

  @override
  String goldStoreBonusLabel(Object amount) {
    return '$amount bonus';
  }

  @override
  String get goldStoreBuyButton => 'Buy now';

  @override
  String get goldStoreError =>
      'We couldn\'t load the store. Please try again in a moment.';

  @override
  String get goldStoreRetry => 'Try again';

  @override
  String get goldStoreRestoreButton => 'Restore purchases';

  @override
  String get goldStorePurchaseSuccess => 'Gold added to your balance!';

  @override
  String get goldStorePurchaseError =>
      'We couldn\'t complete your purchase. Try again later.';

  @override
  String get goldStoreAddTooltip => 'Buy more gold';

  @override
  String get goldStoreLoading => 'Loading offers...';

  @override
  String get goldStoreWatchAdTitle => 'Watch an ad';

  @override
  String goldStoreWatchAdDescription(Object amount) {
    return 'Watch a short ad and earn $amount gold.';
  }

  @override
  String get goldStoreWatchAdButton => 'Watch now';

  @override
  String get skinStoreTitle => 'Cosmetics Store';

  @override
  String get skinStoreSubtitle => 'Collect exclusive skins for your masters.';

  @override
  String get skinStoreLoading => 'Loading cosmetics...';

  @override
  String get skinStoreError =>
      'We couldn\'t load the cosmetics. Please try again.';

  @override
  String get skinStoreEmpty => 'No cosmetics are available right now.';

  @override
  String get skinStoreFilterEmpty => 'Nothing to show in this category yet.';

  @override
  String get skinStoreRetry => 'Reload';

  @override
  String get skinStoreCategoryPieces => 'Pieces';

  @override
  String get skinStoreCategoryBoards => 'Boards';

  @override
  String get skinStoreCategoryCards => 'Cards';

  @override
  String get skinStoreCategoryBackgrounds => 'Backgrounds';

  @override
  String get skinStoreCategoryGroup => 'Bundles';

  @override
  String get skinStoreCategoryAll => 'All';

  @override
  String get skinStoreOwnedTag => 'Owned';

  @override
  String get skinStoreEquippedTag => 'Equipped';

  @override
  String skinStoreDiscountLabel(Object amount) {
    return '$amount off';
  }

  @override
  String get skinStoreOwnedMessage => 'You already own this cosmetic.';

  @override
  String get skinStoreBuyButton => 'Purchase';

  @override
  String get skinStoreOwnedButton => 'Owned';

  @override
  String get skinStoreInsufficientGold => 'You don\'t have enough gold.';

  @override
  String get skinStoreConfirmTitle => 'Confirm purchase';

  @override
  String skinStoreConfirmDescription(
      Object item, Object price, Object balance) {
    return 'Buy $item for $price gold? Remaining balance: $balance.';
  }

  @override
  String skinStorePurchaseSuccess(Object item) {
    return '$item unlocked!';
  }

  @override
  String get skinStoreEquipPromptTitle => 'Equip cosmetic';

  @override
  String skinStoreEquipPromptDescription(Object item) {
    return 'Do you want to equip $item now?';
  }

  @override
  String get skinStoreEquipConfirm => 'Equip';

  @override
  String get skinStoreEquipLater => 'Later';

  @override
  String skinStoreEquipSuccess(Object item) {
    return '$item equipped!';
  }

  @override
  String get skinStoreDetailAssetsTitle => 'Included assets';

  @override
  String get skinStoreDetailPriceLabel => 'Price';

  @override
  String get skinStoreEmptyAssets =>
      'No assets are associated with this bundle yet.';

  @override
  String get skinLoadoutTitle => 'Skin Loadout';

  @override
  String get skinLoadoutSubtitle =>
      'Choose which cosmetics to equip in each slot.';

  @override
  String get skinLoadoutSelectionTab => 'Selection';

  @override
  String get skinLoadoutPreviewTab => 'Preview';

  @override
  String get skinLoadoutCategoryPieces => 'Pieces';

  @override
  String get skinLoadoutCategoryCards => 'Cards';

  @override
  String get skinLoadoutCategoryBoards => 'Boards';

  @override
  String get skinLoadoutCategoryBackgrounds => 'Background';

  @override
  String get skinLoadoutSave => 'Save loadout';

  @override
  String get skinLoadoutSaving => 'Saving...';

  @override
  String get skinLoadoutReset => 'Reset to default';

  @override
  String get skinLoadoutPreviewTitle => 'Preview';

  @override
  String get skinLoadoutPreviewDescription =>
      'See how your selections look inside a duel.';

  @override
  String get skinLoadoutAllCardsLabel => 'All cards';

  @override
  String get skinLoadoutEmptyCategory =>
      'There are no slots in this category yet.';

  @override
  String get skinLoadoutEmptySlot =>
      'You haven\'t unlocked cosmetics for this slot yet.';

  @override
  String get skinLoadoutUnsavedBanner => 'You have unsaved changes.';

  @override
  String get skinLoadoutUnableToLoad =>
      'We couldn\'t load the available themes.';

  @override
  String get skinLoadoutRetry => 'Try again';

  @override
  String get skinLoadoutUnavailable => 'No cosmetics can be configured yet.';

  @override
  String get skinLoadoutApplyError =>
      'We couldn\'t save your loadout. Please try again.';

  @override
  String get skinLoadoutSaved => 'Loadout saved!';

  @override
  String get skinLoadoutDefaultTag => 'Default';

  @override
  String get skinLoadoutManageButton => 'Customize skins';

  @override
  String get skinSlotBlueMaster => 'Blue Master';

  @override
  String get skinSlotBlueStudent1 => 'Blue Student I';

  @override
  String get skinSlotBlueStudent2 => 'Blue Student II';

  @override
  String get skinSlotBlueStudent3 => 'Blue Student III';

  @override
  String get skinSlotBlueStudent4 => 'Blue Student IV';

  @override
  String get skinSlotRedMaster => 'Red Master';

  @override
  String get skinSlotRedStudent1 => 'Red Student I';

  @override
  String get skinSlotRedStudent2 => 'Red Student II';

  @override
  String get skinSlotRedStudent3 => 'Red Student III';

  @override
  String get skinSlotRedStudent4 => 'Red Student IV';

  @override
  String get skinSlotBackground => 'Background';

  @override
  String get skinSlotBoardSurface => 'Board surface';

  @override
  String get skinSlotBoardLight => 'Light tiles';

  @override
  String get skinSlotBoardDark => 'Dark tiles';
}
