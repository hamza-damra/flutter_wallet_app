import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ShareableReportCard extends StatelessWidget {
  final String userName;
  final DateTime startDate;
  final DateTime endDate;
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final String appName;
  final TextDirection textDirection;
  final String financialSummaryLabel;
  final String totalBalanceLabel;
  final String incomeLabel;
  final String expenseLabel;
  final String preparedForLabel;
  final String dateRange;

  const ShareableReportCard({
    super.key,
    required this.userName,
    required this.startDate,
    required this.endDate,
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    required this.appName,
    this.textDirection = TextDirection.ltr,
    required this.financialSummaryLabel,
    required this.totalBalanceLabel,
    required this.incomeLabel,
    required this.expenseLabel,
    required this.preparedForLabel,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: textDirection,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF3E2723), // Deep Brown
              AppColors.primary,
            ],
          ),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      financialSummaryLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    dateRange,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              totalBalanceLabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₪${netBalance.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    incomeLabel,
                    '₪${totalIncome.toStringAsFixed(2)}',
                    AppColors.income,
                    Icons.arrow_upward_rounded,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildInfoItem(
                    expenseLabel,
                    '₪${totalExpense.toStringAsFixed(2)}',
                    AppColors.expense,
                    Icons.arrow_downward_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Divider(color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  '$preparedForLabel $userName',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    String label,
    String amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    decoration: TextDecoration.none,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
