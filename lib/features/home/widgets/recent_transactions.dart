import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../core/localization/translation_helper.dart';

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
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_rounded,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.noTransactions,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.startTrackingFinances,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onAddPressed,
            icon: Icon(Icons.add_rounded, color: theme.colorScheme.onPrimary),
            label: Text(
              l10n.addTransaction,
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
        return _buildTransactionItem(context, tx, theme, locale, l10n);
      },
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    TransactionModel tx,
    ThemeData theme,
    Locale locale,
    AppLocalizations l10n,
  ) {
    final isIncome = tx.type == 'income';
    final amountColor = isIncome ? AppColors.income : AppColors.expense;
    final currency = NumberFormat.simpleCurrency(
      locale: locale.toString(),
      name: 'ILS',
    );

    // Format date nicely (e.g. "Today", "Yesterday", or "Dec 30")
    String dateString;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDate = DateTime(
      tx.createdAt.year,
      tx.createdAt.month,
      tx.createdAt.day,
    );

    if (txDate == today) {
      dateString = l10n.today;
    } else if (txDate == today.subtract(const Duration(days: 1))) {
      dateString = l10n.yesterday;
    } else {
      dateString = DateFormat.MMMd(locale.toString()).format(tx.createdAt);
    }

    // Get display title based on locale
    final displayTitle =
        (locale.languageCode == 'ar' &&
            tx.titleAr != null &&
            tx.titleAr!.isNotEmpty)
        ? tx.titleAr!
        : tx.title;

    // Get translated category name
    final displayCategoryName = TranslationHelper.getCategoryName(
      context,
      tx.categoryName,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => context.push('/transaction-details', extra: tx),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: amountColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    IconHelper.getIcon(tx.categoryIcon),
                    color: amountColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$dateString • $displayCategoryName',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isIncome ? '+' : ''}${currency.format(tx.amount)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: amountColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.jm().format(tx.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
