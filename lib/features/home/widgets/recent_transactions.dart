import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/illustration_widget.dart';
import '../../../core/utils/icon_helper.dart';

/// Widget displaying a list of recent transactions or an empty state
class RecentTransactions extends StatelessWidget {
  final List<TransactionModel> transactions;
  final VoidCallback onAddPressed;

  const RecentTransactions({
    super.key,
    required this.transactions,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);

    if (transactions.isEmpty) {
      return _buildEmptyState(context, l10n, theme);
    }

    return _buildTransactionsList(context, l10n, theme, locale);
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          const IllustrationWidget(
            path: 'assets/illustrations/no_transactions.svg',
            height: 120,
          ),
          const SizedBox(height: 16),
          Text(l10n.noTransactions, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            l10n.startTrackingFinances,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAddPressed,
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            label: Text(
              l10n.addTransaction,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    Locale locale,
  ) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return _buildTransactionItem(context, tx, theme, locale);
      },
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    TransactionModel tx,
    ThemeData theme,
    Locale locale,
  ) {
    final isIncome = tx.type == 'income';
    final currency = NumberFormat.simpleCurrency(
      locale: locale.toString(),
      name: 'ILS',
    );

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 12),
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                IconHelper.getIcon(tx.categoryIcon),
                color: isIncome ? AppColors.income : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  DateFormat.yMMMd(locale.toString()).format(tx.createdAt),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          // Amount
          Text(
            '${isIncome ? '+' : ''}${currency.format(tx.amount)}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isIncome ? AppColors.income : AppColors.expense,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
