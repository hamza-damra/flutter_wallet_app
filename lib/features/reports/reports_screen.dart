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

import '../../core/theme/theme_provider.dart';

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
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Theme-based background
          if (themeMode == AppThemeMode.glassy)
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

          // Decorative background elements
          if (themeMode != AppThemeMode.glassy) ...[
            Positioned(
              top: -60,
              right: -60,
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
          ],

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(
                  context,
                  l10n,
                  theme,
                  themeMode == AppThemeMode.glassy,
                ),
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
                          color: theme.scaffoldBackgroundColor,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDateRangePicker(
                                  context,
                                  l10n,
                                  reportState,
                                  theme,
                                  themeMode,
                                ),
                                const SizedBox(height: 32),
                                _buildSummarySection(
                                  context,
                                  l10n,
                                  summary,
                                  theme,
                                  themeMode,
                                ),
                                const SizedBox(height: 32),
                                _buildCategoriesBreakdown(
                                  context,
                                  l10n,
                                  summary,
                                  theme,
                                  themeMode,
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
                                  theme,
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
    bool isGlassy,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Text(
            l10n.reports,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
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
    ThemeData theme,
    AppThemeMode themeMode,
  ) {
    final dateFormat = DateFormat.yMMMMd(
      Localizations.localeOf(context).toString(),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: themeMode == AppThemeMode.glassy
            ? Border.all(color: Colors.white.withValues(alpha: 0.1))
            : null,
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _showDateRangePicker(context, state, theme),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    color: theme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${dateFormat.format(state.startDate)} - ${dateFormat.format(state.endDate)}',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: theme.primaryColor,
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
    ThemeData theme,
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
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.primaryColor,
              onPrimary: theme.colorScheme.onPrimary,
              onSurface: theme.colorScheme.onSurface,
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
    ThemeData theme,
    AppThemeMode themeMode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          l10n.reportSummary,
          theme,
          themeMode == AppThemeMode.glassy,
        ),
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
                theme: theme,
                themeMode: themeMode,
                l10n: l10n,
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
                theme: theme,
                themeMode: themeMode,
                l10n: l10n,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildNetBalanceCard(
          context,
          l10n,
          summary['netBalance'],
          theme,
          themeMode,
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
    required ThemeData theme,
    required AppThemeMode themeMode,
    required AppLocalizations l10n,
  }) {
    final isGlassy = themeMode == AppThemeMode.glassy;
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
              l10n.currencyFormat(amount),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isGlassy
                  ? Colors.white.withValues(alpha: 0.6)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
    ThemeData theme,
    AppThemeMode themeMode,
  ) {
    final color = balance >= 0 ? AppColors.income : AppColors.expense;
    final isGlassy = themeMode == AppThemeMode.glassy;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isGlassy
            ? Colors.white.withValues(alpha: 0.1)
            : theme.colorScheme.surface,
        gradient: isGlassy
            ? null
            : LinearGradient(
                colors: [
                  color.withValues(alpha: 0.1),
                  color.withValues(alpha: 0.05),
                ],
              ),
        borderRadius: BorderRadius.circular(20),
        border: isGlassy
            ? Border.all(color: Colors.white.withValues(alpha: 0.1))
            : Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.netBalance,
                style: TextStyle(
                  color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.currencyFormat(balance),
                style: theme.textTheme.headlineSmall?.copyWith(
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
    ThemeData theme,
    AppThemeMode themeMode,
  ) {
    final categoryTotals = summary['categoryTotals'] as Map<String, double>;
    final categoryIcons = summary['categoryIcons'] as Map<String, String>;
    final isGlassy = themeMode == AppThemeMode.glassy;

    if (categoryTotals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.categoriesBreakdown, theme, isGlassy),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isGlassy
                ? Colors.white.withValues(alpha: 0.1)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: isGlassy
                ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                : null,
            boxShadow: isGlassy
                ? null
                : [
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
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    IconHelper.getIcon(categoryIcons[e.key] ?? 'other'),
                    color: theme.primaryColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  TranslationHelper.getCategoryName(context, e.key),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isGlassy
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                  ),
                ),
                trailing: Text(
                  l10n.currencyFormat(e.value),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isGlassy
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme, bool isGlassy) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: isGlassy ? Colors.white : theme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
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
    ThemeData theme,
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
            icon: Icon(
              Icons.picture_as_pdf_rounded,
              color: theme.colorScheme.onPrimary,
            ),
            label: Text(
              l10n.shareAsPdf,
              style: TextStyle(color: theme.colorScheme.onPrimary),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
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
            icon: Icon(Icons.image_rounded, color: theme.primaryColor),
            label: Text(l10n.shareAsImage),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.primaryColor,
              side: BorderSide(color: theme.primaryColor),
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
                color: theme.primaryColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.bar_chart_rounded,
                  size: 64,
                  color: theme.primaryColor.withValues(alpha: 0.2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.noTransactions,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'No data found for the selected date range. Try picking a different range or add new transactions.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => _showDateRangePicker(
                context,
                ref.read(reportsControllerProvider),
                theme,
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
