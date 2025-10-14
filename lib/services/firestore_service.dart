import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../logic/game_state.dart';
import '../models/firestore_game.dart';
import '../models/game_mode.dart';
import '../models/player.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Authenticate user anonymously
  Future<String> signInAnonymously() async {
    final userCredential = await _auth.signInAnonymously();
    return userCredential.user!.uid;
  }

  // Create a new game room
  Future<String> createGame(String hostUid) async {
    final tempGameState = GameState(gameMode: GameMode.online);

    final gameData = FirestoreGame(
      id: '',
      board: tempGameState.board,
      redHand: tempGameState.redHand,
      blueHand: tempGameState.blueHand,
      reserveCard: tempGameState.reserveCard,
      currentPlayer: PlayerColor.blue,
      players: {'blue': hostUid},
      createdAt: Timestamp.now(),
    );

    final mapData = gameData.toFirestore();

    final DocumentReference docRef = await _db.collection('games').add(mapData);
    await docRef.update({'id': docRef.id}); // Update the document with its own ID
    return docRef.id;
  }

  // Join an existing game room
  Stream<FirestoreGame> joinGame(String gameId, String playerUid) {
    _db.collection('games').doc(gameId).update({'players.red': playerUid});
    return _db.collection('games').doc(gameId).snapshots().map((snapshot) => FirestoreGame.fromFirestore(snapshot));
  }

  Future<FirestoreGame?> getGame(String gameId) async {
    final DocumentSnapshot doc = await _db.collection('games').doc(gameId).get();
    if (doc.exists) {
      return FirestoreGame.fromFirestore(doc);
    }
    return null;
  }

  // Stream game updates
  Stream<FirestoreGame> streamGame(String gameId) {
    return _db.collection('games').doc(gameId).snapshots().map((snapshot) => FirestoreGame.fromFirestore(snapshot));
  }

  // Update game state
  Future<void> updateGame(String gameId, FirestoreGame game) async {
    await _db.collection('games').doc(gameId).set(game.toFirestore(), SetOptions(merge: true));
  }

  // Add game history log
  Future<void> addGameLog(String gameId, Map<String, dynamic> logEntry) async {
    await _db.collection('games').doc(gameId).collection('logs').add(logEntry);
  }
}
