import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

import '../models/leaderboard_entry.dart';

class RankingService {
  RankingService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseApp? app,
    String region = 'us-central1',
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _app = app ?? Firebase.app(),
        _region = region;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseApp _app;
  final String _region;

  Stream<List<LeaderboardEntry>> watchTopEntries({int limit = 100}) {
    return _firestore.collection('leaderboard').orderBy('rating', descending: true).limit(limit).snapshots().map(
          (snapshot) => snapshot.docs
              .asMap()
              .entries
              .map(
                (entry) => LeaderboardEntry.fromSnapshot(entry.value).copyWith(rank: entry.key + 1),
              )
              .toList(),
        );
  }

  Stream<LeaderboardEntry?> watchPlayerEntry(String userId) {
    return _firestore.collection('leaderboard').doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return LeaderboardEntry.fromSnapshot(snapshot);
    });
  }

  Future<LeaderboardEntry?> fetchPlayerEntry(String userId) async {
    final doc = await _firestore.collection('leaderboard').doc(userId).get();
    if (!doc.exists) return null;
    return LeaderboardEntry.fromSnapshot(doc);
  }

  Future<void> submitMatchResult(String gameId) async {
    final projectId = _app.options.projectId;
    if (projectId.isEmpty) {
      throw Exception('Firebase projectId não encontrado para enviar ranking.');
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado para enviar ranking.');
    }
    final idToken = await user.getIdToken();

    final uri = Uri.parse(
      'https://$_region-$projectId.cloudfunctions.net/updateRanking',
    );
    final http.Response response;
    try {
      response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'data': {
            'gameId': gameId,
          },
        }),
      );
    } on http.ClientException catch (error) {
      throw Exception('Falha na comunicação com o servidor: $error');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Falha ao atualizar ranking: ${response.statusCode}');
    }

    if (response.body.isEmpty) {
      return;
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body.containsKey('error')) {
      throw Exception('Erro ao atualizar ranking: ${body['error']}');
    }

    final result = body['result'];
    if (result is Map<String, dynamic>) {
      if (result['alreadyProcessed'] == true) {
        return;
      }
      if (result['error'] != null) {
        throw Exception('Erro ao atualizar ranking: ${result['error']}');
      }
    }
  }
}
