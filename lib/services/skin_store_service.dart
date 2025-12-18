import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

import '../models/skin_store_item.dart';
import '../models/theme_model.dart';
import '../models/theme_ownership.dart';

class SkinStoreService {
  SkinStoreService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<List<SkinStoreItem>> fetchStoreItems() async {
    final snapshot = await _firestore.collection('themes').where('enabled', isEqualTo: true).get();
    if (snapshot.docs.isEmpty) {
      return const <SkinStoreItem>[];
    }

    final items = <SkinStoreItem>[];
    for (final doc in snapshot.docs) {
      final theme = ThemeModel.fromMap(doc.data(), doc.id);
      if (theme.values.isEmpty) continue;
      for (final variant in theme.values.values) {
        items.add(SkinStoreItem.fromTheme(theme: theme, variant: variant));
      }
    }
    items.sort((a, b) => a.finalPrice.compareTo(b.finalPrice));
    return items;
  }

  Stream<ThemeOwnership> watchOwnership(String userId) {
    if (userId.isEmpty) {
      return Stream.value(ThemeOwnership.empty());
    }
    return _firestore.collection('users').doc(userId).collection('themes').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return ThemeOwnership.empty();
      }
      final data = <String, Set<String>>{};
      for (final doc in snapshot.docs) {
        final assetsData = doc.data()['assets'];
        final ownedAssets = <String>{};
        if (assetsData is Map<String, dynamic>) {
          for (final entry in assetsData.entries) {
            final assetId = entry.key;
            if (assetId.isNotEmpty) {
              ownedAssets.add(assetId);
            }
          }
        }
        if (ownedAssets.isNotEmpty) {
          data[doc.id] = ownedAssets;
        }
      }
      return ThemeOwnership(data);
    });
  }

  Future<ThemePurchaseResult> purchaseItem({required String themeId, required String valueId}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw ThemePurchaseException(ThemePurchaseError.unauthenticated, 'User not authenticated');
    }

    final token = await user.getIdToken();
    final projectId = Firebase.app().options.projectId;
    if (projectId.isEmpty) {
      throw ThemePurchaseException(ThemePurchaseError.unknown, 'Missing Firebase project id');
    }

    final uri = Uri.https('us-central1-$projectId.cloudfunctions.net', 'purchaseThemeValue');
    final response = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'themeId': themeId,
        'valueId': valueId,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return ThemePurchaseResult.fromJson(decoded);
    }

    var code = ThemePurchaseError.unknown;
    var message = 'Unable to purchase the selected item.';
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final error = decoded['error'];
      if (error is Map<String, dynamic>) {
        final errorCode = (error['code'] as String?) ?? '';
        message = (error['message'] as String?) ?? message;
        code = ThemePurchaseErrorX.fromCode(errorCode);
      }
    } catch (_) {
      // ignore decoding errors and fallback to default message
    }
    throw ThemePurchaseException(code, message);
  }

  Future<void> equipAssets({required String userId, required String themeId, required List<String> assetIds}) async {
    if (userId.isEmpty || assetIds.isEmpty) return;
    final themeUpdates = <String, String>{};
    for (final asset in assetIds) {
      if (asset.isNotEmpty) {
        themeUpdates[asset] = themeId;
      }
    }
    if (themeUpdates.isEmpty) return;
    await _firestore.collection('users').doc(userId).set({'theme': themeUpdates}, SetOptions(merge: true));
  }
}

class ThemePurchaseResult {
  const ThemePurchaseResult({
    required this.themeId,
    required this.valueId,
    required this.assetIds,
    required this.newBalance,
  });

  factory ThemePurchaseResult.fromJson(Map<String, dynamic> json) {
    final assets = <String>[];
    final rawAssets = json['assets'];
    if (rawAssets is Iterable) {
      for (final entry in rawAssets) {
        if (entry is String && entry.isNotEmpty) {
          assets.add(entry);
        }
      }
    }
    return ThemePurchaseResult(
      themeId: json['themeId'] as String? ?? '',
      valueId: json['valueId'] as String? ?? '',
      assetIds: List.unmodifiable(assets),
      newBalance: (json['balance'] as num?)?.round() ?? 0,
    );
  }

  final String themeId;
  final String valueId;
  final List<String> assetIds;
  final int newBalance;
}

enum ThemePurchaseError {
  unauthenticated,
  insufficientFunds,
  alreadyOwned,
  notFound,
  unauthorized,
  unknown,
}

extension ThemePurchaseErrorX on ThemePurchaseError {
  static ThemePurchaseError fromCode(String code) {
    switch (code) {
      case 'insufficient_funds':
        return ThemePurchaseError.insufficientFunds;
      case 'already_owned':
        return ThemePurchaseError.alreadyOwned;
      case 'not_found':
        return ThemePurchaseError.notFound;
      case 'unauthorized':
        return ThemePurchaseError.unauthorized;
      case 'unauthenticated':
        return ThemePurchaseError.unauthenticated;
      default:
        return ThemePurchaseError.unknown;
    }
  }
}

class ThemePurchaseException implements Exception {
  ThemePurchaseException(this.code, this.message);

  final ThemePurchaseError code;
  final String message;

  @override
  String toString() => 'ThemePurchaseException(code: $code, message: $message)';
}
