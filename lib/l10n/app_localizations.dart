import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt')
  ];

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @onitama.
  ///
  /// In en, this message translates to:
  /// **'Masters of Onitama'**
  String get onitama;

  /// No description provided for @gameOfTheMasters.
  ///
  /// In en, this message translates to:
  /// **'The Game of the Masters'**
  String get gameOfTheMasters;

  /// No description provided for @localMultiplayer.
  ///
  /// In en, this message translates to:
  /// **'Local Multiplayer'**
  String get localMultiplayer;

  /// No description provided for @playerVsAi.
  ///
  /// In en, this message translates to:
  /// **'Player vs AI'**
  String get playerVsAi;

  /// No description provided for @onlineMultiplayer.
  ///
  /// In en, this message translates to:
  /// **'Online Multiplayer'**
  String get onlineMultiplayer;

  /// No description provided for @privateGame.
  ///
  /// In en, this message translates to:
  /// **'Private Game'**
  String get privateGame;

  /// No description provided for @createOnlineGame.
  ///
  /// In en, this message translates to:
  /// **'Create Online Game'**
  String get createOnlineGame;

  /// No description provided for @gameId.
  ///
  /// In en, this message translates to:
  /// **'Game ID'**
  String get gameId;

  /// No description provided for @joinOnlineGame.
  ///
  /// In en, this message translates to:
  /// **'Join Online Game'**
  String get joinOnlineGame;

  /// No description provided for @howToPlay.
  ///
  /// In en, this message translates to:
  /// **'How to Play'**
  String get howToPlay;

  /// No description provided for @selectDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Select Difficulty'**
  String get selectDifficulty;

  /// No description provided for @easy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get easy;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @hard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hard;

  /// No description provided for @matchmaking.
  ///
  /// In en, this message translates to:
  /// **'Matchmaking'**
  String get matchmaking;

  /// No description provided for @waitingForAnOpponent.
  ///
  /// In en, this message translates to:
  /// **'Waiting for an opponent...'**
  String get waitingForAnOpponent;

  /// No description provided for @howToPlayTitle.
  ///
  /// In en, this message translates to:
  /// **'How to Play'**
  String get howToPlayTitle;

  /// No description provided for @onitamaDescription.
  ///
  /// In en, this message translates to:
  /// **'Onitama is a two-player abstract strategy game with a unique movement mechanic.'**
  String get onitamaDescription;

  /// No description provided for @objectiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Objective'**
  String get objectiveTitle;

  /// No description provided for @objectiveDescription.
  ///
  /// In en, this message translates to:
  /// **'There are two ways to win:'**
  String get objectiveDescription;

  /// No description provided for @wayOfTheStone.
  ///
  /// In en, this message translates to:
  /// **'1. Way of the Stone: Capture your opponent\'s Master pawn.'**
  String get wayOfTheStone;

  /// No description provided for @wayOfTheStream.
  ///
  /// In en, this message translates to:
  /// **'2. Way of the Stream: Move your Master pawn to your opponent\'s starting Temple Arch space.'**
  String get wayOfTheStream;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get setupTitle;

  /// No description provided for @setupDescription1.
  ///
  /// In en, this message translates to:
  /// **'1. Each player starts with five pawns: one Master and four Students.'**
  String get setupDescription1;

  /// No description provided for @setupDescription2.
  ///
  /// In en, this message translates to:
  /// **'2. Pawns are placed on the 5x5 board in their starting positions.'**
  String get setupDescription2;

  /// No description provided for @setupDescription3.
  ///
  /// In en, this message translates to:
  /// **'3. Each player receives two random Move cards.'**
  String get setupDescription3;

  /// No description provided for @setupDescription4.
  ///
  /// In en, this message translates to:
  /// **'4. One extra card is placed on the side of the board.'**
  String get setupDescription4;

  /// No description provided for @gameplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Gameplay'**
  String get gameplayTitle;

  /// No description provided for @gameplayDescription.
  ///
  /// In en, this message translates to:
  /// **'On your turn, you must perform the following steps:'**
  String get gameplayDescription;

  /// No description provided for @gameplayStep1.
  ///
  /// In en, this message translates to:
  /// **'1. Choose one of your two Move cards.'**
  String get gameplayStep1;

  /// No description provided for @gameplayStep2.
  ///
  /// In en, this message translates to:
  /// **'2. Move one of your pawns according to the selected card.'**
  String get gameplayStep2;

  /// No description provided for @gameplayStep3.
  ///
  /// In en, this message translates to:
  /// **'3. The card you used is then exchanged with the card on the side of the board.'**
  String get gameplayStep3;

  /// No description provided for @movementTitle.
  ///
  /// In en, this message translates to:
  /// **'Movement'**
  String get movementTitle;

  /// No description provided for @movementDescription1.
  ///
  /// In en, this message translates to:
  /// **'- The black square on a Move card represents the pawn\'s current position.'**
  String get movementDescription1;

  /// No description provided for @movementDescription2.
  ///
  /// In en, this message translates to:
  /// **'- The colored squares show the possible moves from that position.'**
  String get movementDescription2;

  /// No description provided for @movementDescription3.
  ///
  /// In en, this message translates to:
  /// **'- You cannot move a pawn off the board or onto a space occupied by your own pawn.'**
  String get movementDescription3;

  /// No description provided for @capturingTitle.
  ///
  /// In en, this message translates to:
  /// **'Capturing'**
  String get capturingTitle;

  /// No description provided for @capturingDescription.
  ///
  /// In en, this message translates to:
  /// **'If you move a pawn to a square occupied by an opponent\'s pawn, the opponent\'s pawn is captured and removed from the game.'**
  String get capturingDescription;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @gameOver.
  ///
  /// In en, this message translates to:
  /// **'Game Over'**
  String get gameOver;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @opponent.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get opponent;

  /// No description provided for @restartGame.
  ///
  /// In en, this message translates to:
  /// **'Restart Game'**
  String get restartGame;

  /// No description provided for @areYouSureRestart.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restart the game?'**
  String get areYouSureRestart;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @surrender.
  ///
  /// In en, this message translates to:
  /// **'Surrender'**
  String get surrender;

  /// No description provided for @surrenderGame.
  ///
  /// In en, this message translates to:
  /// **'Surrender Game'**
  String get surrenderGame;

  /// No description provided for @areYouSureSurrender.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to surrender the game?'**
  String get areYouSureSurrender;

  /// No description provided for @exitGame.
  ///
  /// In en, this message translates to:
  /// **'Exit Game'**
  String get exitGame;

  /// No description provided for @areYouSureExit.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit to the menu?'**
  String get areYouSureExit;

  /// No description provided for @cardTiger.
  ///
  /// In en, this message translates to:
  /// **'Tiger'**
  String get cardTiger;

  /// No description provided for @cardDragon.
  ///
  /// In en, this message translates to:
  /// **'Dragon'**
  String get cardDragon;

  /// No description provided for @cardFrog.
  ///
  /// In en, this message translates to:
  /// **'Frog'**
  String get cardFrog;

  /// No description provided for @cardRabbit.
  ///
  /// In en, this message translates to:
  /// **'Rabbit'**
  String get cardRabbit;

  /// No description provided for @cardCrab.
  ///
  /// In en, this message translates to:
  /// **'Crab'**
  String get cardCrab;

  /// No description provided for @cardElephant.
  ///
  /// In en, this message translates to:
  /// **'Elephant'**
  String get cardElephant;

  /// No description provided for @cardGoose.
  ///
  /// In en, this message translates to:
  /// **'Goose'**
  String get cardGoose;

  /// No description provided for @cardRooster.
  ///
  /// In en, this message translates to:
  /// **'Rooster'**
  String get cardRooster;

  /// No description provided for @cardMonkey.
  ///
  /// In en, this message translates to:
  /// **'Monkey'**
  String get cardMonkey;

  /// No description provided for @cardMantis.
  ///
  /// In en, this message translates to:
  /// **'Mantis'**
  String get cardMantis;

  /// No description provided for @cardHorse.
  ///
  /// In en, this message translates to:
  /// **'Horse'**
  String get cardHorse;

  /// No description provided for @cardOx.
  ///
  /// In en, this message translates to:
  /// **'Ox'**
  String get cardOx;

  /// No description provided for @cardCrane.
  ///
  /// In en, this message translates to:
  /// **'Crane'**
  String get cardCrane;

  /// No description provided for @cardBoar.
  ///
  /// In en, this message translates to:
  /// **'Boar'**
  String get cardBoar;

  /// No description provided for @cardEel.
  ///
  /// In en, this message translates to:
  /// **'Eel'**
  String get cardEel;

  /// No description provided for @cardCobra.
  ///
  /// In en, this message translates to:
  /// **'Cobra'**
  String get cardCobra;

  /// No description provided for @wonByCapture.
  ///
  /// In en, this message translates to:
  /// **'won by capture!'**
  String get wonByCapture;

  /// No description provided for @wonByTemple.
  ///
  /// In en, this message translates to:
  /// **'won by temple!'**
  String get wonByTemple;

  /// No description provided for @blue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get blue;

  /// No description provided for @red.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get red;

  /// No description provided for @historyWon.
  ///
  /// In en, this message translates to:
  /// **'Won'**
  String get historyWon;

  /// No description provided for @historyLost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get historyLost;

  /// No description provided for @historyNA.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get historyNA;

  /// No description provided for @historyGameOn.
  ///
  /// In en, this message translates to:
  /// **'Game on'**
  String get historyGameOn;

  /// No description provided for @historyErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading games.'**
  String get historyErrorLoading;

  /// No description provided for @historyNoFinished.
  ///
  /// In en, this message translates to:
  /// **'No finished games found.'**
  String get historyNoFinished;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Game History'**
  String get historyTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @chooseUsername.
  ///
  /// In en, this message translates to:
  /// **'Choose a username to continue:'**
  String get chooseUsername;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @usernameAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This username is already taken.'**
  String get usernameAlreadyExists;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @signInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInWithApple;

  /// No description provided for @moveHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Current Game History'**
  String get moveHistoryTitle;

  /// No description provided for @moveHistoryMove.
  ///
  /// In en, this message translates to:
  /// **'Move {number}'**
  String moveHistoryMove(Object number);

  /// No description provided for @moveHistoryFromTo.
  ///
  /// In en, this message translates to:
  /// **'From: ({fromR}, {fromC}) To: ({toR}, {toC}) with {cardName}'**
  String moveHistoryFromTo(
      Object cardName, Object fromR, Object fromC, Object toR, Object toC);

  /// No description provided for @undoWithAd.
  ///
  /// In en, this message translates to:
  /// **'Watch ad to undo'**
  String get undoWithAd;

  /// No description provided for @preloadLoadingTheme.
  ///
  /// In en, this message translates to:
  /// **'Loading theme...'**
  String get preloadLoadingTheme;

  /// No description provided for @preloadFetchingThemes.
  ///
  /// In en, this message translates to:
  /// **'Fetching available themes...'**
  String get preloadFetchingThemes;

  /// No description provided for @preloadPreloadingImages.
  ///
  /// In en, this message translates to:
  /// **'Preloading images...'**
  String get preloadPreloadingImages;

  /// No description provided for @preloadDownloadingImages.
  ///
  /// In en, this message translates to:
  /// **'Downloading images ({done}/{total})...'**
  String preloadDownloadingImages(Object done, Object total);

  /// No description provided for @preloadDone.
  ///
  /// In en, this message translates to:
  /// **'Done!'**
  String get preloadDone;

  /// No description provided for @preloadImagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No images} =1{1 image} other{{count} images}}'**
  String preloadImagesCount(num count);

  /// No description provided for @lobbyGameIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Game ID: {gameId}'**
  String lobbyGameIdLabel(Object gameId);

  /// No description provided for @lobbyGameIdCopied.
  ///
  /// In en, this message translates to:
  /// **'Game ID copied to clipboard'**
  String get lobbyGameIdCopied;

  /// No description provided for @lobbyPlayersCount.
  ///
  /// In en, this message translates to:
  /// **'Players: {count}/2'**
  String lobbyPlayersCount(Object count);

  /// No description provided for @leaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboardTitle;

  /// No description provided for @leaderboardInvite.
  ///
  /// In en, this message translates to:
  /// **'Play online matches to join the leaderboard!'**
  String get leaderboardInvite;

  /// No description provided for @leaderboardPlayerSummary.
  ///
  /// In en, this message translates to:
  /// **'Your rank: {rating} • {tier} • {winRate}% wins'**
  String leaderboardPlayerSummary(Object rating, Object tier, Object winRate);

  /// No description provided for @leaderboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Be the first to reach the top!'**
  String get leaderboardEmpty;

  /// No description provided for @leaderboardPlayerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{rating} points • {tier}'**
  String leaderboardPlayerSubtitle(Object rating, Object tier);

  /// No description provided for @leaderboardWinRateShort.
  ///
  /// In en, this message translates to:
  /// **'{winRate}%'**
  String leaderboardWinRateShort(Object winRate);

  /// No description provided for @leaderboardTierBronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get leaderboardTierBronze;

  /// No description provided for @leaderboardTierSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get leaderboardTierSilver;

  /// No description provided for @leaderboardTierGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get leaderboardTierGold;

  /// No description provided for @leaderboardTierPlatine.
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get leaderboardTierPlatine;

  /// No description provided for @leaderboardTierDiamond.
  ///
  /// In en, this message translates to:
  /// **'Diamond'**
  String get leaderboardTierDiamond;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
