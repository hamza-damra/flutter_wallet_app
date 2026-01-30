import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../models/friend_model.dart';
import '../models/debt_transaction_model.dart';
import '../providers/debts_provider.dart';
import '../repositories/debts_repository.dart';

class FriendDetailsScreen extends ConsumerWidget {
  final FriendModel friend;

  const FriendDetailsScreen({super.key, required this.friend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Watch fresh data
    final friendAsync = ref.watch(friendDetailsProvider(friend.id));
    final transactionsAsync = ref.watch(friendTransactionsProvider(friend.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          friend.name,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: theme.colorScheme.onSurface),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDeleteFriend(context, ref, friend.id),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Summary Cards
            friendAsync.when(
              data: (currentFriend) => _buildSummary(context, currentFriend),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // History Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.debtHistory,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Transactions List
            transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        l10n.noTransactions,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return _buildTransactionItem(context, ref, tx);
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => Text('Error: $e'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-debt-transaction', extra: friend),
        label: Text(l10n.newDebtTransaction),
        icon: const Icon(Icons.add),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSummary(BuildContext context, FriendModel currentFriend) {
    // We need totals. friend.netBalance is available.
    // But we also want Total Lent and Total Borrowed.
    // We can iterate transactions or maybe we should compute this in provider.
    // For now, simpler to reuse the list from transaction provider if available,
    // but here we are in _buildSummary which only takes FriendModel.
    // Check if we can get transactions here easily.
    // Actually, standard design is just to show net balance big,
    // or we can pass transactions to this widget.

    return Consumer(
      builder: (context, ref, _) {
        final transactionsAsync = ref.watch(
          friendTransactionsProvider(currentFriend.id),
        );
        return transactionsAsync.when(
          data: (transactions) {
            double lent = 0;
            double borrowed = 0;
            for (var t in transactions) {
              if (t.type == 'lent')
                lent += t.amount;
              else
                borrowed += t.amount;
            }

            return Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    context,
                    AppLocalizations.of(context).totalLent,
                    lent,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    context,
                    AppLocalizations.of(context).totalBorrowed,
                    borrowed,
                    Colors.red,
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    double amount,
    Color color,
  ) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(
      symbol: '₪',
      decimalDigits: 2,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormatter.format(amount),
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    WidgetRef ref,
    DebtTransactionModel tx,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isLent = tx.type == 'lent';
    final color = isLent ? Colors.green : Colors.red;
    final currencyFormatter = NumberFormat.currency(
      symbol: '₪',
      decimalDigits: 2,
    );
    final dateFormatter = DateFormat.yMMMd();
    final dateTimeFormatter = DateFormat.yMMMd().add_jm();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLent ? Icons.arrow_upward : Icons.arrow_downward,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLent ? l10n.lent : l10n.borrowed,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      dateFormatter.format(tx.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    if (tx.note != null && tx.note!.isNotEmpty)
                      Text(
                        tx.note!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                currencyFormatter.format(tx.amount),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Updated at row
          Row(
            children: [
              Icon(Icons.update, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${l10n.updatedAt}: ${dateTimeFormatter.format(tx.updatedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Action buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showSettleDebtDialog(context, ref, tx),
                icon: Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                label: Text(
                  l10n.settled,
                  style: const TextStyle(color: Colors.green),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: () => context.push(
                  '/edit-debt-transaction',
                  extra: {'friend': friend, 'transaction': tx},
                ),
                icon: Icon(Icons.edit, size: 18, color: theme.primaryColor),
                label: Text(
                  l10n.edit,
                  style: TextStyle(color: theme.primaryColor),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: () => _confirmDeleteTransaction(context, ref, tx.id),
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                label: Text(
                  l10n.delete,
                  style: const TextStyle(color: Colors.red),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTransaction(
    BuildContext context,
    WidgetRef ref,
    String transactionId,
  ) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteDebtTransaction),
        content: Text(l10n.deleteDebtTransactionConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(debtsRepositoryProvider).deleteDebtTransaction(transactionId);
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFriend(
    BuildContext context,
    WidgetRef ref,
    String friendId,
  ) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteFriend),
        content: Text(l10n.deleteFriendConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              ref.read(debtsRepositoryProvider).deleteFriend(friendId);
              context.pop(); // Go back to list
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSettleDebtDialog(
    BuildContext context,
    WidgetRef ref,
    DebtTransactionModel tx,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isArabic = l10n.localeName == 'ar';
    final currencyFormatter = NumberFormat.currency(
      symbol: '₪',
      decimalDigits: 2,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isArabic ? 'تأكيد السداد' : 'Confirm Settlement',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic
                  ? 'هل تريد تسجيل سداد هذا الدين؟'
                  : 'Do you want to mark this debt as paid?',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? 'المبلغ:' : 'Amount:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    currencyFormatter.format(tx.amount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: tx.type == 'lent' ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isArabic
                  ? 'سيتم إنشاء معاملة معاكسة لتسوية هذا الدين.'
                  : 'An opposite transaction will be created to settle this debt.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await _settleDebt(ref, tx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isArabic ? 'تم تسوية الدين بنجاح' : 'Debt settled successfully',
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check, size: 18),
            label: Text(l10n.confirm),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _settleDebt(WidgetRef ref, DebtTransactionModel tx) async {
    // Create an opposite transaction to settle the debt
    // If original was 'lent', create 'borrowed' and vice versa
    final oppositeType = tx.type == 'lent' ? 'borrowed' : 'lent';
    
    final settlementTransaction = DebtTransactionModel(
      id: '0', // Will be assigned by DB
      userId: tx.userId,
      friendId: tx.friendId,
      amount: tx.amount,
      type: oppositeType,
      date: DateTime.now(),
      note: 'Settlement for ${tx.type == 'lent' ? 'lent' : 'borrowed'} amount',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ref.read(debtsRepositoryProvider).addDebtTransaction(settlementTransaction);
  }
}
