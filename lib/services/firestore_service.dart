import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../logic/game_state.dart';
import '../models/ai_difficulty.dart';
import '../models/firestore_game.dart';
import '../models/game_mode.dart';
import '../models/player.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> signInAnonymously() async {
    final userCredential = await _auth.signInAnonymously();
    return userCredential.user!.uid;
  }

  Future<String> createGame(String hostUid, {GameMode gameMode = GameMode.online, String status = 'inprogress'}) async {
    final tempGameState = GameState(gameMode: gameMode);

    final gameData = FirestoreGame(
      id: '',
      board: tempGameState.board,
      redHand: tempGameState.redHand,
      blueHand: tempGameState.blueHand,
      reserveCard: tempGameState.reserveCard,
      currentPlayer: PlayerColor.blue,
      players: {'blue': hostUid},
      createdAt: Timestamp.now(),
      status: status,
      gameMode: gameMode,
    );

    final mapData = gameData.toFirestore();

    final DocumentReference docRef = await _db.collection('games').add(mapData);
    await docRef.update({'id': docRef.id});
    return docRef.id;
  }

  Stream<FirestoreGame> joinGame(String gameId, String playerUid) {
    _db.collection('games').doc(gameId).update({
      'players.red': playerUid,
      'status': 'inprogress',
    });
    return _db.collection('games').doc(gameId).snapshots().map((snapshot) => FirestoreGame.fromFirestore(snapshot));
  }

  Future<Map<String, dynamic>> findOrCreateGame(String playerUid) async {
    final redInProgressGames = await _db.collection('games').where('status', isEqualTo: 'inprogress').where('players.red', isEqualTo: playerUid).limit(1).get();

    if (redInProgressGames.docs.isNotEmpty) {
      final gameDoc = redInProgressGames.docs.first;
      return {'gameId': gameDoc.id, 'isHost': false, 'inProgress': true};
    }

    final blueInProgressGames =
        await _db.collection('games').where('status', isEqualTo: 'inprogress').where('players.blue', isEqualTo: playerUid).limit(1).get();

    if (blueInProgressGames.docs.isNotEmpty) {
      final gameDoc = blueInProgressGames.docs.first;
      return {'gameId': gameDoc.id, 'isHost': true, 'inProgress': true};
    }

    final yourWaitingGames = await _db.collection('games').where('status', isEqualTo: 'waiting').where('players.blue', isEqualTo: playerUid).limit(1).get();

    if (yourWaitingGames.docs.isNotEmpty) {
      final gameDoc = yourWaitingGames.docs.first;
      return {'gameId': gameDoc.id, 'isHost': true};
    }

    final waitingGames = await _db.collection('games').where('status', isEqualTo: 'waiting').where('players.blue', isNotEqualTo: playerUid).limit(1).get();

    if (waitingGames.docs.isNotEmpty) {
      final gameDoc = waitingGames.docs.first;
      await gameDoc.reference.update({
        'players.red': playerUid,
        'status': 'inprogress',
      });
      return {'gameId': gameDoc.id, 'isHost': false};
    } else {
      final gameId = await createGame(playerUid, status: 'waiting');
      return {'gameId': gameId, 'isHost': true};
    }
  }

  Future<void> convertToPvAI(String gameId) async {
    await _db.collection('games').doc(gameId).update({
      'gameMode': GameMode.pvai.name,
      'aiDifficulty': AIDifficulty.medium.name,
      'status': 'inprogress',
      'players.red': 'ai',
    });
  }

  Future<FirestoreGame?> getGame(String gameId) async {
    final DocumentSnapshot doc = await _db.collection('games').doc(gameId).get();
    if (doc.exists) {
      return FirestoreGame.fromFirestore(doc);
    }
    return null;
  }

  Stream<FirestoreGame> streamGame(String gameId) {
    return _db.collection('games').doc(gameId).snapshots().map((snapshot) => FirestoreGame.fromFirestore(snapshot));
  }

  Future<void> updateGame(String gameId, FirestoreGame game) async {
    await _db.collection('games').doc(gameId).set(game.toFirestore(), SetOptions(merge: true));
  }

  Future<void> addGameLog(String gameId, Map<String, dynamic> logEntry) async {
    await _db.collection('games').doc(gameId).collection('logs').add(logEntry);
  }
}
