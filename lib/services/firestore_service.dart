import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../logic/game_state.dart';
import '../models/ai_difficulty.dart';
import '../models/firestore_game.dart';
import '../models/game_mode.dart';
import '../models/gold_transaction.dart';
import '../models/player.dart';
import '../models/user_profile.dart';

class FirestoreService {
  Future<bool> usernameExists(String username) async {
    final query = await _db.collection('users').where('username', isEqualTo: username).limit(1).get();
    return query.docs.isNotEmpty;
  }

  Future<String?> getUsername(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data()?['username'] != null) {
      return doc.data()!['username'] as String;
    }
    return null;
  }

  Future<UserProfile?> fetchUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromSnapshot(doc);
  }

  Stream<UserProfile?> watchUserProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return UserProfile.fromSnapshot(snapshot);
    });
  }

  Stream<List<GoldTransaction>> watchGoldTransactions(String uid, {int limit = 50}) {
    return _db.collection('users').doc(uid).collection('gold_transactions').orderBy('createdAt', descending: true).limit(limit).snapshots().map(
          (snapshot) => snapshot.docs.map(GoldTransaction.fromSnapshot).toList(),
        );
  }

  Future<void> setUsername(String uid, String username) async {
    await _db.collection('users').doc(uid).set(
      {
        'id': uid,
        'username': username,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> updateUserPhoto(String uid, String photoUrl) async {
    await _db.collection('users').doc(uid).set(
      {
        'photoUrl': photoUrl,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> ensureUserPhoto(User user) async {
    final photoUrl = user.photoURL;
    if (photoUrl == null || photoUrl.isEmpty) {
      return;
    }
    final docRef = _db.collection('users').doc(user.uid);
    final doc = await docRef.get();
    final storedUrl = doc.data()?['photoUrl'] as String?;
    if (storedUrl == null || storedUrl.isEmpty) {
      await docRef.set(
        {
          'id': user.uid,
          'photoUrl': photoUrl,
        },
        SetOptions(merge: true),
      );
    }
  }

  Future<void> updateUserFcmToken(String uid, String token, {Locale? locale}) async {
    if (token.isEmpty) return;
    await _db.collection('users').doc(uid).set(
      {
        'id': uid,
        'fcmToken': token,
        'fcmTokens': FieldValue.arrayUnion(<String>[token]),
        if (locale != null && locale.languageCode.isNotEmpty) 'preferredLocale': locale.languageCode,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> signInAnonymously() async {
    final userCredential = await _auth.signInAnonymously();
    return userCredential.user!.uid;
  }

  Future<String> createGame(String hostUid, {GameMode gameMode = GameMode.online, String status = 'lobby'}) async {
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
      blueTimeMillis: tempGameState.blueTimeMillis,
      redTimeMillis: tempGameState.redTimeMillis,
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
      'lastClockUpdateMillis': DateTime.now().millisecondsSinceEpoch,
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
        'lastClockUpdateMillis': DateTime.now().millisecondsSinceEpoch,
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
      'lastClockUpdateMillis': DateTime.now().millisecondsSinceEpoch,
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

  Future<List<FirestoreGame>> getFinishedGames() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    // Firestore não suporta OR entre campos diferentes, então precisamos buscar separadamente e juntar os resultados
    final finishedRed = await _db.collection('games').where('status', isEqualTo: 'finished').where('players.red', isEqualTo: userId).get();

    final finishedBlue = await _db.collection('games').where('status', isEqualTo: 'finished').where('players.blue', isEqualTo: userId).get();

    // Juntar e remover duplicados pelo id
    final allDocs = <String, QueryDocumentSnapshot>{};
    for (final doc in finishedRed.docs) {
      allDocs[doc.id] = doc;
    }
    for (final doc in finishedBlue.docs) {
      allDocs[doc.id] = doc;
    }

    final games = allDocs.values.map((doc) => FirestoreGame.fromFirestore(doc)).toList();
    games.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return games;
  }
}
