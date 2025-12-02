import 'package:cloud_firestore/cloud_firestore.dart';

class GoldTransaction {
  const GoldTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.createdAt,
    this.reason,
    this.gameId,
    this.balanceAfter,
  });

  final String id;
  final int amount;
  final String type;
  final DateTime createdAt;
  final String? reason;
  final String? gameId;
  final int? balanceAfter;

  bool get isCredit => type == 'credit';

  factory GoldTransaction.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return GoldTransaction(
      id: snapshot.id,
      amount: (data['amount'] as num?)?.round() ?? 0,
      type: data['type'] as String? ?? 'credit',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reason: data['reason'] as String?,
      gameId: data['gameId'] as String?,
      balanceAfter: (data['balanceAfter'] as num?)?.round(),
    );
  }
}
