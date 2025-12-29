import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';

/// Card widget displaying the user's total balance, income, and expenses
class BalanceCard extends StatelessWidget {
  final double totalBalance;
  final double income;
  final double expense;

  const BalanceCard({
    super.key,
    required this.totalBalance,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);

    // Using ILS (Shekels) with locale-aware formatting
    final currency = NumberFormat.simpleCurrency(
      locale: locale.toString(),
      name: 'ILS',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.totalBalance, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            currency.format(totalBalance),
            style: theme.textTheme.headlineLarge?.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Income section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.arrow_downward,
                          color: AppColors.income,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(l10n.income, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+${currency.format(income)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.income,
                      ),
                    ),
                  ],
                ),
              ),
              // Divider
              Container(width: 1, height: 40, color: AppColors.border),
              // Expenses section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(l10n.expenses, style: theme.textTheme.bodyMedium),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_upward,
                          color: AppColors.expense,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currency.format(expense),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.expense,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
