import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import '../../core/localization/translation_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/icon_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'reports_controller.dart';
import 'reports_service.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final ReportsService _reportsService = ReportsService();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final reportState = ref.watch(reportsControllerProvider);
    final summaryAsync = ref.watch(reportSummaryProvider);
    final user = ref.watch(authServiceProvider).currentUser;
    final profile = ref.watch(userProfileProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Decorative background elements
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.income.withValues(alpha: 0.03),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, l10n, theme),
                Expanded(
                  child: summaryAsync.when(
                    data: (summary) {
                      final hasData =
                          summary['totalIncome'] > 0 ||
                          summary['totalExpense'] > 0;

                      if (!hasData) {
                        return _buildEmptyReportsState(context, l10n, theme);
                      }

                      return Screenshot(
                        controller: _reportsService.screenshotController,
                        child: Container(
                          color: AppColors.background,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDateRangePicker(
                                  context,
                                  l10n,
                                  reportState,
                                ),
                                const SizedBox(height: 32),
                                _buildSummarySection(context, l10n, summary),
                                const SizedBox(height: 32),
                                _buildCategoriesBreakdown(
                                  context,
                                  l10n,
                                  summary,
                                ),
                                const SizedBox(height: 32),
                                _buildShareActions(
                                  context,
                                  l10n,
                                  profile?.getLocalizedName(
                                        Localizations.localeOf(
                                          context,
                                        ).languageCode,
                                      ) ??
                                      user?.email?.split('@')[0] ??
                                      'User',
                                  reportState,
                                  summary,
                                ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
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
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              color: AppColors.textPrimary,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Text(
            l10n.reports,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 48), // Placeholder for balance
        ],
      ),
    );
  }

  Widget _buildDateRangePicker(
    BuildContext context,
    AppLocalizations l10n,
    ReportState state,
  ) {
    final dateFormat = DateFormat.yMMMMd(
      Localizations.localeOf(context).toString(),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.selectDateRange,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _showDateRangePicker(context, state),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${dateFormat.format(state.startDate)} - ${dateFormat.format(state.endDate)}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker(
    BuildContext context,
    ReportState state,
  ) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: state.startDate,
        end: state.endDate,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref
          .read(reportsControllerProvider.notifier)
          .setDateRange(picked.start, picked.end);
    }
  }

  Widget _buildSummarySection(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, dynamic> summary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.reportSummary),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                icon: Icons.arrow_upward_rounded,
                label: l10n.totalIncome,
                amount: summary['totalIncome'],
                color: AppColors.income,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                context,
                icon: Icons.arrow_downward_rounded,
                label: l10n.totalExpenses,
                amount: summary['totalExpense'],
                color: AppColors.expense,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildNetBalanceCard(context, l10n, summary['netBalance']),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          FittedBox(
            child: Text(
              '₪${amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetBalanceCard(
    BuildContext context,
    AppLocalizations l10n,
    double balance,
  ) {
    final color = balance >= 0 ? AppColors.income : AppColors.expense;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.netBalance,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₪${balance.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Icon(
            balance >= 0
                ? Icons.account_balance_wallet_rounded
                : Icons.warning_rounded,
            color: color,
            size: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesBreakdown(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, dynamic> summary,
  ) {
    final categoryTotals = summary['categoryTotals'] as Map<String, double>;
    final categoryIcons = summary['categoryIcons'] as Map<String, String>;

    if (categoryTotals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.categoriesBreakdown),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: categoryTotals.entries.map((e) {
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    IconHelper.getIcon(categoryIcons[e.key] ?? 'other'),
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  TranslationHelper.getCategoryName(context, e.key),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Text(
                  '₪${e.value.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildShareActions(
    BuildContext context,
    AppLocalizations l10n,
    String userName,
    ReportState state,
    Map<String, dynamic> summary,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _reportsService.shareAsPdf(
              context: context,
              userName: userName,
              startDate: state.startDate,
              endDate: state.endDate,
              transactions: summary['transactions'],
              totalIncome: summary['totalIncome'],
              totalExpense: summary['totalExpense'],
              netBalance: summary['netBalance'],
              categoryTotals: summary['categoryTotals'],
            ),
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
            label: Text(l10n.shareAsPdf),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final dateFormat = DateFormat.yMMMMd(
                Localizations.localeOf(context).toString(),
              );

              final image = await _reportsService.captureReportCard(
                userName: userName,
                startDate: state.startDate,
                endDate: state.endDate,
                totalIncome: summary['totalIncome'],
                totalExpense: summary['totalExpense'],
                netBalance: summary['netBalance'],
                appName: l10n.appName,
                textDirection: Directionality.of(context),
                financialSummaryLabel: l10n.reportSummary,
                totalBalanceLabel: l10n.totalBalance,
                incomeLabel: l10n.income,
                expenseLabel: l10n.expenses,
                preparedForLabel: l10n.preparedFor,
                dateRange:
                    '${dateFormat.format(state.startDate)} - ${dateFormat.format(state.endDate)}',
              );
              await _reportsService.shareAsImage(image);
            },
            icon: const Icon(Icons.image_rounded, color: AppColors.primary),
            label: Text(l10n.shareAsImage),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyReportsState(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.bar_chart_rounded,
                  size: 64,
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.noTransactions,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'No data found for the selected date range. Try picking a different range or add new transactions.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => _showDateRangePicker(
                context,
                ref.read(reportsControllerProvider),
              ),
              icon: const Icon(Icons.date_range_rounded),
              label: const Text('Change Date Range'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
