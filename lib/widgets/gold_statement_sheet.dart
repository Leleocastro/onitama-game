import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/gold_transaction.dart';
import '../services/firestore_service.dart';

class GoldStatementSheet extends StatelessWidget {
  GoldStatementSheet({required this.userId, super.key});

  final String userId;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd(l10n.localeName).add_Hm();

    return FractionallySizedBox(
      heightFactor: 0.7,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  children: [
                    Text(
                      l10n.goldStatementTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<GoldTransaction>>(
                  stream: _firestoreService.watchGoldTransactions(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _GoldStatementEmpty(label: l10n.goldStatementEmpty);
                    }
                    final transactions = snapshot.data ?? const <GoldTransaction>[];
                    if (transactions.isEmpty) {
                      return _GoldStatementEmpty(label: l10n.goldStatementEmpty);
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final txn = transactions[index];
                        final subtitleParts = <String>[dateFormat.format(txn.createdAt)];
                        if (txn.balanceAfter != null) {
                          subtitleParts.add(l10n.goldStatementBalance(txn.balanceAfter!));
                        }
                        final subtitle = subtitleParts.join(' · ');
                        final amountPrefix = txn.isCredit ? '+' : '-';
                        final amountColor = txn.isCredit ? Colors.green.shade600 : theme.colorScheme.error;
                        final iconBgColor = txn.isCredit ? Colors.green.shade50 : theme.colorScheme.error.withOpacity(0.08);
                        final iconColor = txn.isCredit ? Colors.green.shade600 : theme.colorScheme.error;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: iconBgColor,
                            child: Icon(
                              Icons.monetization_on,
                              color: iconColor,
                            ),
                          ),
                          title: Text(_descriptionFor(txn, l10n)),
                          subtitle: Text(subtitle),
                          trailing: Text(
                            '$amountPrefix${txn.amount}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: amountColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemCount: transactions.length,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _descriptionFor(GoldTransaction txn, AppLocalizations l10n) {
    switch (txn.reason) {
      case 'theme_purchase':
        return l10n.goldStatementThemePurchase;
      case 'store_purchase':
        return l10n.goldStatementStorePurchase;
      case 'online_match_reward':
        return l10n.goldStatementMatchReward;
      default:
        return l10n.goldStatementMatchReward;
    }
  }
}

class _GoldStatementEmpty extends StatelessWidget {
  const _GoldStatementEmpty({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long, size: 64, color: Colors.black38),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
