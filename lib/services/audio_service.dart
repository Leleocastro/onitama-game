import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global music volume that other widgets can read synchronously.
double globalMusicVolume = 0.6;

/// Global sound-effect volume that other widgets can read synchronously.
double globalSfxVolume = 0.8;

/// Notifiers to allow UI widgets (like sliders) to react to live volume changes.
final ValueNotifier<double> musicVolumeNotifier = ValueNotifier<double>(globalMusicVolume);
final ValueNotifier<double> sfxVolumeNotifier = ValueNotifier<double>(globalSfxVolume);

class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  static const String _musicVolumeKey = 'audio_music_volume';
  static const String _sfxVolumeKey = 'audio_sfx_volume';

  static const List<String> _moveAssets = <String>[
    'sounds/move_1.wav',
    'sounds/move_2.wav',
    'sounds/move_3.wav',
    'sounds/move_4.wav',
    'sounds/move_5.wav',
  ];

  static const String _uiSelectAsset = 'sounds/ui_select.wav';
  static const String _uiConfirmAsset = 'sounds/ui_confirm.wav';
  static const String _uiCardAsset = 'sounds/ui_card.wav';
  static const String _navigationAsset = 'sounds/screen_transition.wav';

  static const String _ambienceMenuAsset = 'sounds/ambience_temple.mp3';
  static const String _ambienceHomeAsset = 'sounds/ambience_garden.mp3';
  static const String _bgmTempleAsset = 'sounds/bgm_temple_loop.mp3';

  static const String _specialMasterAsset = 'sounds/special_master_move.wav';
  static const String _specialWinAsset = 'sounds/special_win.wav';

  static final Set<String> _preloadableSfx = <String>{
    ..._moveAssets,
    _uiSelectAsset,
    _uiConfirmAsset,
    _uiCardAsset,
    _navigationAsset,
    _specialMasterAsset,
    _specialWinAsset,
  };

  final AudioPlayer _musicPlayer = AudioPlayer(playerId: 'onitama_music');
  final AudioPlayer _ambiencePlayer = AudioPlayer(playerId: 'onitama_ambience');

  SharedPreferences? _prefs;
  bool _initialized = false;
  String? _currentMusicAsset;
  String? _currentAmbienceAsset;
  DateTime? _lastInteractionFx;
  final Random _random = Random();
  Future<void>? _preloadFuture;
  final List<AudioPlayer> _sfxPool = <AudioPlayer>[];
  final Set<AudioPlayer> _busyPlayers = <AudioPlayer>{};
  static const int _basePoolSize = 4;

  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();
    globalMusicVolume = _prefs?.getDouble(_musicVolumeKey) ?? globalMusicVolume;
    globalSfxVolume = _prefs?.getDouble(_sfxVolumeKey) ?? globalSfxVolume;

    musicVolumeNotifier.value = globalMusicVolume;
    sfxVolumeNotifier.value = globalSfxVolume;

    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _ambiencePlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.setVolume(globalMusicVolume);
    await _ambiencePlayer.setVolume(globalMusicVolume);
    await _ensureSfxPool();
    await _preloadSfxAssets();

    _initialized = true;
  }

  Future<void> playMenuMusic() => _playAmbience(_ambienceMenuAsset);

  Future<void> playHomeMusic() async {
    await _playAmbience(_ambienceHomeAsset);
    await playTempleBgm();
  }

  Future<void> playTempleBgm() async {
    await _playMusicLoop(_bgmTempleAsset);
  }

  Future<void> _playMusicLoop(String asset) async {
    await initialize();
    if (_currentMusicAsset == asset) {
      return;
    }
    _currentMusicAsset = asset;
    await _musicPlayer.stop();
    await _musicPlayer.play(AssetSource(asset), volume: globalMusicVolume);
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> _playAmbience(String asset) async {
    await initialize();
    if (_currentAmbienceAsset == asset) {
      return;
    }
    _currentAmbienceAsset = asset;
    await _ambiencePlayer.stop();
    await _ambiencePlayer.play(AssetSource(asset), volume: globalMusicVolume);
    await _ambiencePlayer.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> stopBackground() async {
    await _musicPlayer.stop();
    await _ambiencePlayer.stop();
    _currentMusicAsset = null;
    _currentAmbienceAsset = null;
  }

  Future<void> playRandomMoveSound() async => _playSfxAsset(_moveAssets[_random.nextInt(_moveAssets.length)], usualTime: false);

  Future<void> playUiSelectSound() async {
    await initialize();
    final now = DateTime.now();
    if (_lastInteractionFx != null && now.difference(_lastInteractionFx!) < const Duration(milliseconds: 80)) {
      return;
    }
    _lastInteractionFx = now;
    await _playSfxAsset(_uiSelectAsset);
  }

  Future<void> playUiConfirmSound() => _playSfxAsset(_uiConfirmAsset);

  Future<void> playUiCardSound() => _playSfxAsset(_uiCardAsset);

  Future<void> playSpecialMasterMoveSound() => _playSfxAsset(_specialMasterAsset);

  Future<void> playSpecialWinSound() => _playSfxAsset(_specialWinAsset, usualTime: false);

  Future<void> playInteractionSound() => playUiSelectSound();

  Future<void> playNavigationSound() => _playSfxAsset(_navigationAsset);

  Future<void> _playSfxAsset(String assetPath, {bool usualTime = true}) async {
    await initialize();
    final player = await _acquirePlayer();
    _busyPlayers.add(player);
    try {
      await player.stop();
      await player.setVolume(globalSfxVolume);
      await player.setSource(AssetSource(assetPath));
      final seekPosition = await _resolveStartOffset(player, percent: 0.2);
      if (seekPosition != null && usualTime) {
        await player.seek(seekPosition);
      }
      await player.resume();
      unawaited(
        player.onPlayerComplete.first.then((_) => _busyPlayers.remove(player)),
      );
    } catch (_) {
      _busyPlayers.remove(player);
      rethrow;
    }
  }

  Future<Duration?> _resolveStartOffset(AudioPlayer player, {required double percent}) async {
    var duration = await player.getDuration();
    duration ??= await player.onDurationChanged.firstWhere(
      (d) => d > Duration.zero,
      orElse: () => Duration.zero,
    );
    if (duration == Duration.zero) {
      return null;
    }
    final microseconds = (duration.inMicroseconds * percent).round();
    if (microseconds <= 0 || microseconds >= duration.inMicroseconds) {
      return null;
    }
    return Duration(microseconds: microseconds);
  }

  Future<void> _preloadSfxAssets() async {
    _preloadFuture ??= () async {
      final tempPlayer = AudioPlayer(playerId: 'onitama_sfx_preload');
      await tempPlayer.setReleaseMode(ReleaseMode.stop);
      try {
        for (final asset in _preloadableSfx) {
          await tempPlayer.setSource(AssetSource(asset));
        }
      } finally {
        await tempPlayer.dispose();
      }
    }();
    await _preloadFuture;
  }

  Future<void> _ensureSfxPool() async {
    if (_sfxPool.length >= _basePoolSize) return;
    final missing = _basePoolSize - _sfxPool.length;
    for (var i = 0; i < missing; i++) {
      _sfxPool.add(await _createSfxPlayer());
    }
  }

  Future<AudioPlayer> _createSfxPlayer() async {
    final player = AudioPlayer(playerId: 'onitama_sfx_${_sfxPool.length}');
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setVolume(globalSfxVolume);
    player.onPlayerComplete.listen((_) {
      _busyPlayers.remove(player);
    });
    return player;
  }

  Future<AudioPlayer> _acquirePlayer() async {
    for (final player in _sfxPool) {
      if (!_busyPlayers.contains(player)) {
        return player;
      }
    }
    final newPlayer = await _createSfxPlayer();
    _sfxPool.add(newPlayer);
    return newPlayer;
  }

  Future<void> setMusicVolume(double volume) async {
    await initialize();
    final clamped = volume.clamp(0.0, 1.0).toDouble();
    globalMusicVolume = clamped;
    musicVolumeNotifier.value = clamped;
    await _prefs?.setDouble(_musicVolumeKey, clamped);
    await _musicPlayer.setVolume(clamped);
    await _ambiencePlayer.setVolume(clamped);
  }

  Future<void> setSfxVolume(double volume) async {
    await initialize();
    final clamped = volume.clamp(0.0, 1.0).toDouble();
    globalSfxVolume = clamped;
    sfxVolumeNotifier.value = clamped;
    await _prefs?.setDouble(_sfxVolumeKey, clamped);
    for (final player in _sfxPool) {
      await player.setVolume(clamped);
    }
  }

  Future<void> increaseMusicVolume([double step = 0.05]) async => setMusicVolume(globalMusicVolume + step);

  Future<void> decreaseMusicVolume([double step = 0.05]) async => setMusicVolume(globalMusicVolume - step);

  Future<void> increaseSfxVolume([double step = 0.05]) async => setSfxVolume(globalSfxVolume + step);

  Future<void> decreaseSfxVolume([double step = 0.05]) async => setSfxVolume(globalSfxVolume - step);
}
