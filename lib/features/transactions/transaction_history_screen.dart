import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../core/models/transaction_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/icon_helper.dart';
import '../../core/localization/translation_helper.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../core/theme/theme_provider.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);
    final isGlassy = themeMode == AppThemeMode.glassy;

    final user = ref.watch(authServiceProvider).currentUser;
    final transactionsAsync = ref.watch(transactionsProvider(user?.uid ?? ''));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background for Glassy
          if (isGlassy)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F172A),
                      Color(0xFF1E1B4B),
                      Color(0xFF312E81),
                    ],
                  ),
                ),
              ),
            ),

          // Decorative elements for other themes
          if (!isGlassy) ...[
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.primaryColor.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -60,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.income.withValues(alpha: 0.05),
                ),
              ),
            ),
          ],

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                _buildAppBar(context, l10n, theme, isGlassy),

                // Content
                Expanded(
                  child: transactionsAsync.when(
                    data: (transactions) {
                      if (transactions.isEmpty) {
                        return _buildEmptyState(context, l10n, theme, isGlassy);
                      }

                      // Calculate summary
                      double totalIncome = 0;
                      double totalExpense = 0;
                      for (var tx in transactions) {
                        if (tx.type == 'income') {
                          totalIncome += tx.amount;
                        } else {
                          totalExpense += tx.amount;
                        }
                      }

                      // Group transactions by date
                      final groupedTransactions =
                          <DateTime, List<TransactionModel>>{};
                      for (var tx in transactions) {
                        final date = DateTime(
                          tx.createdAt.year,
                          tx.createdAt.month,
                          tx.createdAt.day,
                        );
                        if (!groupedTransactions.containsKey(date)) {
                          groupedTransactions[date] = [];
                        }
                        groupedTransactions[date]!.add(tx);
                      }

                      final sortedDates = groupedTransactions.keys.toList()
                        ..sort((a, b) => b.compareTo(a));

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        itemCount: sortedDates.length + 1, // +1 for summary row
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Column(
                              children: [
                                _buildSummaryRow(
                                  context,
                                  l10n,
                                  totalIncome,
                                  totalExpense,
                                  theme,
                                  isGlassy,
                                ),
                                const SizedBox(height: 32),
                              ],
                            );
                          }

                          final date = sortedDates[index - 1];
                          final txs = groupedTransactions[date]!;
                          final dateHeader = _getDateHeader(date, l10n);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 12,
                                  top: 8,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: isGlassy
                                            ? Colors.white
                                            : theme.primaryColor,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      dateHeader,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: isGlassy
                                                ? Colors.white
                                                : theme.colorScheme.onSurface,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              ...txs.map(
                                (tx) => _buildTransactionItem(
                                  context,
                                  tx,
                                  theme,
                                  isGlassy,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) =>
                        Center(child: Text('${l10n.error}: $err')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    bool isGlassy,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isGlassy
                  ? Colors.white.withValues(alpha: 0.1)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: isGlassy
                  ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                  : null,
              boxShadow: isGlassy
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
              onPressed: () => context.pop(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.recentTransactions,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isGlassy
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Transaction History',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isGlassy
                        ? Colors.white.withValues(alpha: 0.7)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    AppLocalizations l10n,
    double income,
    double expense,
    ThemeData theme,
    bool isGlassy,
  ) {
    final currency = NumberFormat.simpleCurrency(name: 'ILS');
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            context,
            icon: Icons.arrow_downward_rounded,
            label: l10n.income,
            amount: income,
            color: AppColors.income,
            currency: currency,
            theme: theme,
            isGlassy: isGlassy,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            context,
            icon: Icons.arrow_upward_rounded,
            label: l10n.expenses,
            amount: expense,
            color: AppColors.expense,
            currency: currency,
            theme: theme,
            isGlassy: isGlassy,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
    required NumberFormat currency,
    required ThemeData theme,
    required bool isGlassy,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isGlassy
            ? Colors.white.withValues(alpha: 0.1)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: isGlassy
            ? Border.all(color: Colors.white.withValues(alpha: 0.1))
            : null,
        boxShadow: isGlassy
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          FittedBox(
            child: Text(
              currency.format(amount),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isGlassy
                  ? Colors.white.withValues(alpha: 0.7)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    bool isGlassy,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isGlassy
                  ? Colors.white.withValues(alpha: 0.1)
                  : theme.colorScheme.surface.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_rounded,
              size: 64,
              color: isGlassy
                  ? Colors.white.withValues(alpha: 0.2)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.noTransactions,
            style: theme.textTheme.titleLarge?.copyWith(
              color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.startTrackingFinances,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isGlassy
                  ? Colors.white.withValues(alpha: 0.6)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _getDateHeader(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return l10n.today;
    if (checkDate == yesterday) return l10n.yesterday;
    return DateFormat.yMMMd().format(date);
  }

  Widget _buildTransactionItem(
    BuildContext context,
    TransactionModel tx,
    ThemeData theme,
    bool isGlassy,
  ) {
    final isIncome = tx.type == 'income';
    final color = isIncome ? AppColors.income : AppColors.expense;
    final currency = NumberFormat.simpleCurrency(name: 'ILS');
    final locale = Localizations.localeOf(context).languageCode;

    final displayTitle =
        (locale == 'ar' && tx.titleAr != null && tx.titleAr!.isNotEmpty)
        ? tx.titleAr!
        : tx.title;

    final displayCategory = TranslationHelper.getCategoryName(
      context,
      tx.categoryName,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isGlassy
            ? Colors.white.withValues(alpha: 0.1)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: isGlassy
            ? Border.all(color: Colors.white.withValues(alpha: 0.1))
            : null,
        boxShadow: isGlassy
            ? null
            : [
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
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    IconHelper.getIcon(tx.categoryIcon),
                    color: color,
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
                          color: isGlassy
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayCategory,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isGlassy
                              ? Colors.white.withValues(alpha: 0.6)
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
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
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.jm().format(tx.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isGlassy
                            ? Colors.white.withValues(alpha: 0.4)
                            : Colors.grey[400],
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
