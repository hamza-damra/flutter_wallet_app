import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/theme_provider.dart';

/// Card widget displaying the user's total balance, income, and expenses
class BalanceCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final themeMode = ref.watch(themeProvider);

    // Using ILS (Shekels) with locale-aware formatting
    final currency = NumberFormat.simpleCurrency(
      locale: locale.toString(),
      name: 'ILS',
    );

    final isGlassy = themeMode == AppThemeMode.glassy;
    final isModernDark = themeMode == AppThemeMode.modernDark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        gradient: isGlassy
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.05),
                ],
              )
            : isModernDark
            ? LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [
                  theme.colorScheme.surface,
                  theme.primaryColor.withValues(alpha: 0.2),
                ],
              )
            : LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withValues(alpha: 0.8),
                ],
              ),
        border: (isGlassy || isModernDark)
            ? Border.all(
                color: (isGlassy ? Colors.white : theme.primaryColor)
                    .withValues(alpha: 0.2),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: (isGlassy ? Colors.black : theme.primaryColor).withValues(
              alpha: isGlassy ? 0.2 : 0.3,
            ),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: (isGlassy || isModernDark) ? 10 : 0,
            sigmaY: (isGlassy || isModernDark) ? 10 : 0,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.totalBalance,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color:
                        (isModernDark
                                ? theme.colorScheme.onSurface
                                : Colors.white)
                            .withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currency.format(totalBalance),
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: isModernDark ? theme.primaryColor : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 36,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    // Income section
                    Expanded(
                      child: _buildSummaryItem(
                        context,
                        label: l10n.income,
                        amount: currency.format(income),
                        icon: Icons.arrow_downward,
                        textColor: isModernDark
                            ? theme.colorScheme.onSurface
                            : Colors.white,
                        iconBgColor: AppColors.income.withValues(alpha: 0.2),
                        iconColor: AppColors.income,
                      ),
                    ),
                    // Divider
                    Container(
                      width: 1,
                      height: 48,
                      color: (isModernDark ? theme.dividerColor : Colors.white)
                          .withValues(alpha: 0.2),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    // Expenses section
                    Expanded(
                      child: _buildSummaryItem(
                        context,
                        label: l10n.expenses,
                        amount: currency.format(expense),
                        icon: Icons.arrow_upward,
                        textColor: isModernDark
                            ? theme.colorScheme.onSurface
                            : Colors.white,
                        iconBgColor: AppColors.expense.withValues(alpha: 0.2),
                        iconColor: AppColors.expense,
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

  Widget _buildSummaryItem(
    BuildContext context, {
    required String label,
    required String amount,
    required IconData icon,
    required Color textColor,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                amount,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
