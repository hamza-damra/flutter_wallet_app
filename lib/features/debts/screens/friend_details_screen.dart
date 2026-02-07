import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../services/auth_service.dart';
import '../../home/providers/home_stats_provider.dart';
import '../../reports/pdf_generator.dart';
import '../models/friend_model.dart';
import '../models/debt_transaction_model.dart';
import '../providers/debts_provider.dart';
import '../repositories/debts_repository.dart';
import '../services/debt_service.dart';

class FriendDetailsScreen extends ConsumerWidget {
  final FriendModel friend;

  const FriendDetailsScreen({super.key, required this.friend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);

    // Watch fresh data - use reactive data for UI updates
    final friendAsync = ref.watch(friendDetailsProvider(friend.id));
    final transactionsAsync = ref.watch(friendTransactionsProvider(friend.id));
    
    // Get current friend data (reactive) or fallback to initial
    final currentFriend = friendAsync.value ?? friend;
    
    // Get display name based on locale
    final isArabic = locale.languageCode == 'ar';
    final displayName = (isArabic &&
            currentFriend.nameAr != null &&
            currentFriend.nameAr!.isNotEmpty)
        ? currentFriend.nameAr!
        : currentFriend.name;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          displayName,
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
            icon: Icon(Icons.picture_as_pdf_outlined, color: Colors.purple),
            onPressed: () => _generateAndSharePdf(context, ref, currentFriend),
            tooltip: l10n.exportPdf,
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: theme.primaryColor),
            onPressed: () => _showEditFriendDialog(context, ref, currentFriend),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDeleteFriend(context, ref, currentFriend.id),
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
            double owesMe = 0;
            double iOwe = 0;
            // Only count unsettled debts for the summary
            final unsettledTransactions = transactions.where((t) => !t.settled);
            for (var t in unsettledTransactions) {
              switch (t.type) {
                case DebtEventType.lend:
                  owesMe += t.amount;
                  break;
                case DebtEventType.borrow:
                  iOwe += t.amount;
                  break;
                case DebtEventType.settlePay:
                  iOwe -= t.amount;
                  break;
                case DebtEventType.settleReceive:
                  owesMe -= t.amount;
                  break;
              }
            }
            // Ensure we don't show negative values
            owesMe = owesMe > 0 ? owesMe : 0;
            iOwe = iOwe > 0 ? iOwe : 0;

            return Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    context,
                    AppLocalizations.of(context).owesMe,
                    owesMe,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    context,
                    AppLocalizations.of(context).iOwe,
                    iOwe,
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
    final isLend = tx.type == DebtEventType.lend;
    final isSettleReceive = tx.type == DebtEventType.settleReceive;
    final isSettlementType = tx.type.isSettlement;
    final isSettled = tx.settled;
    
    // Color logic: lend/settleReceive = green (money coming to me), borrow/settlePay = red (money going out)
    Color color;
    if (isSettled) {
      color = Colors.grey;
    } else if (isLend || isSettleReceive) {
      color = Colors.green;
    } else {
      color = Colors.red;
    }
    final currencyFormatter = NumberFormat.currency(
      symbol: '₪',
      decimalDigits: 2,
    );
    final localeStr = l10n.localeName;
    final dateFormatter = DateFormat.yMMMd(localeStr);
    final dateTimeFormatter = DateFormat.yMMMd(localeStr).add_jm();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSettled 
            ? theme.colorScheme.surface.withValues(alpha: 0.7)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isSettled 
            ? Border.all(color: Colors.green.withValues(alpha: 0.3), width: 1)
            : null,
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
                  isSettled 
                      ? Icons.check_circle 
                      : (isSettlementType 
                          ? Icons.swap_horiz
                          : (isLend ? Icons.arrow_upward : Icons.arrow_downward)),
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getTypeLabel(tx.type, l10n),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: isSettled ? TextDecoration.lineThrough : null,
                            color: isSettled ? Colors.grey : null,
                          ),
                        ),
                        if (isSettled) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l10n.settled,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
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
                    if (isSettled && tx.settledAt != null)
                      Text(
                        '${l10n.settledOn} ${dateFormatter.format(tx.settledAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green[600],
                          fontSize: 11,
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
                  decoration: isSettled ? TextDecoration.lineThrough : null,
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
          // Action buttons row - only show settle button if not already settled
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isSettled)
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
              if (!isSettled) const SizedBox(width: 4),
              if (!isSettled)
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
              if (!isSettled) const SizedBox(width: 4),
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

  void _showEditFriendDialog(BuildContext context, WidgetRef ref, FriendModel currentFriend) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
    final nameController = TextEditingController(text: currentFriend.name);
    final nameArController = TextEditingController(text: currentFriend.nameAr ?? '');
    final phoneController = TextEditingController(text: currentFriend.phoneNumber ?? '');

    final inputDecoration = InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
      ),
      filled: true,
      fillColor: theme.colorScheme.surface,
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
                color: theme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.edit, color: theme.primaryColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.editFriendInfo,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: inputDecoration.copyWith(
                  labelText: l10n.friendName,
                  prefixIcon: Icon(Icons.person_outline, color: theme.primaryColor),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameArController,
                decoration: inputDecoration.copyWith(
                  labelText: l10n.nameArHint,
                  prefixIcon: Icon(Icons.person_outline, color: theme.primaryColor),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: inputDecoration.copyWith(
                  labelText: l10n.phoneNumber,
                  prefixIcon: Icon(Icons.phone_outlined, color: theme.primaryColor),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                return;
              }
              
              final updatedFriend = FriendModel(
                id: currentFriend.id,
                userId: currentFriend.userId,
                name: nameController.text.trim(),
                nameAr: nameArController.text.trim().isEmpty 
                    ? null 
                    : nameArController.text.trim(),
                phoneNumber: phoneController.text.trim().isEmpty 
                    ? null 
                    : phoneController.text.trim(),
                createdAt: currentFriend.createdAt,
                updatedAt: DateTime.now(),
                netBalance: currentFriend.netBalance,
              );
              
              await ref.read(debtsRepositoryProvider).updateFriend(updatedFriend);
              
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.friendInfoUpdated,
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
            icon: const Icon(Icons.save, size: 18),
            label: Text(l10n.save),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
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

  void _showSettleDebtDialog(
    BuildContext context,
    WidgetRef ref,
    DebtTransactionModel tx,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(
      symbol: '₪',
      decimalDigits: 2,
    );
    bool affectMainBalance = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                  l10n.confirmSettlement,
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
                l10n.confirmSettlementMessage,
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
                      l10n.amountLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      currencyFormatter.format(tx.amount),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: (tx.type == DebtEventType.lend || tx.type == DebtEventType.settleReceive) ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Affect Main Balance Toggle
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: affectMainBalance
                      ? Colors.blue.withValues(alpha: 0.1)
                      : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: affectMainBalance
                      ? Border.all(color: Colors.blue.withValues(alpha: 0.3))
                      : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.affectMainBalance,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tx.type == DebtEventType.lend
                                ? l10n.amountAddedToBalance
                                : l10n.amountDeductedFromBalance,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: affectMainBalance,
                      onChanged: (value) {
                        setDialogState(() {
                          affectMainBalance = value;
                        });
                      },
                      activeColor: Colors.blue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.debtSettledMessage,
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
                await _settleDebt(ref, tx, affectMainBalance);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.debtSettledSuccess,
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
      ),
    );
  }

  Future<void> _settleDebt(WidgetRef ref, DebtTransactionModel tx, bool affectMainBalance) async {
    final debtService = ref.read(debtServiceProvider);
    await debtService.settleDebt(
      debtEventId: tx.id,
      friendName: friend.name,
      friendNameAr: friend.nameAr,
      amount: tx.amount,
      originalType: tx.type,
      affectMainBalance: affectMainBalance,
    );
    // Refresh providers to update state across screens
    final userId = tx.userId;
    ref.invalidate(debtTransactionsStreamProvider);
    ref.invalidate(rawFriendsStreamProvider);
    ref.invalidate(transactionsStreamProvider(userId));
    ref.invalidate(homeStatsProvider);
  }

  String _getTypeLabel(DebtEventType type, AppLocalizations l10n) {
    switch (type) {
      case DebtEventType.lend:
        return l10n.lent;
      case DebtEventType.borrow:
        return l10n.borrowed;
      case DebtEventType.settlePay:
        return l10n.settlePay;
      case DebtEventType.settleReceive:
        return l10n.settleReceive;
    }
  }

  Future<void> _generateAndSharePdf(
    BuildContext context,
    WidgetRef ref,
    FriendModel currentFriend,
  ) async {
    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';
    final l10n = AppLocalizations.of(context);
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                l10n.generatingReport,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Get transactions from the provider
      final transactionsAsync = ref.read(friendTransactionsProvider(currentFriend.id));
      final transactions = transactionsAsync.value ?? <DebtTransactionModel>[];
      
      // Calculate totals from unsettled transactions
      double owesMe = 0;
      double iOwe = 0;
      final unsettledTransactions = transactions.where((t) => !t.settled);
      for (var t in unsettledTransactions) {
        switch (t.type) {
          case DebtEventType.lend:
            owesMe += t.amount;
            break;
          case DebtEventType.borrow:
            iOwe += t.amount;
            break;
          case DebtEventType.settlePay:
            iOwe -= t.amount;
            break;
          case DebtEventType.settleReceive:
            owesMe -= t.amount;
            break;
        }
      }
      owesMe = owesMe > 0 ? owesMe : 0;
      iOwe = iOwe > 0 ? iOwe : 0;

      // Get user name
      final user = ref.read(authStateProvider).value;
      final userName = user?.displayName ?? user?.email ?? 'User';

      // Generate PDF
      final pdfBytes = await PdfGenerator.generateFriendDebtReport(
        friend: currentFriend,
        transactions: transactions,
        owesMe: owesMe,
        iOwe: iOwe,
        userName: userName,
        isArabic: isArabic,
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Get display name for filename
      final displayName = (isArabic &&
              currentFriend.nameAr != null &&
              currentFriend.nameAr!.isNotEmpty)
          ? currentFriend.nameAr!
          : currentFriend.name;

      // Save to temp file and share
      final tempDir = await getTemporaryDirectory();
      final fileName = 'debt_report_${displayName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '${l10n.debtReport} - $displayName',
      );
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.failedToGenerateReport}: $e',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
