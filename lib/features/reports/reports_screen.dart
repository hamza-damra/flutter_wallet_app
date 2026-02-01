import 'dart:ui';
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
import 'widgets/date_range_selection_sheet.dart';

import '../../core/theme/theme_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  final ReportsService _reportsService = ReportsService();
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
  // Loading states for share buttons
  bool _isGeneratingPdf = false;
  bool _isGeneratingImage = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final reportState = ref.watch(reportsControllerProvider);
    final summaryAsync = ref.watch(reportSummaryProvider);
    final user = ref.watch(authServiceProvider).currentUser;
    final profile = ref.watch(userProfileProvider).value;
    final themeMode = ref.watch(themeProvider);
    final isGlassy = themeMode == AppThemeMode.glassy;

    return Scaffold(
      backgroundColor: isGlassy
          ? const Color(0xFF0A0E1A)
          : theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Enhanced Glassy Background with animated gradient orbs
          if (isGlassy) ...[
            // Base gradient
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0A0E1A),
                      Color(0xFF0F172A),
                      Color(0xFF1E1B4B),
                    ],
                  ),
                ),
              ),
            ),
            // Animated glowing orbs
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Top-right purple orb
                    Positioned(
                      top: -80,
                      right: -60,
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(
                                0xFF8B5CF6,
                              ).withValues(alpha: _pulseAnimation.value * 0.6),
                              const Color(
                                0xFF7C3AED,
                              ).withValues(alpha: _pulseAnimation.value * 0.3),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Bottom-left cyan orb
                    Positioned(
                      bottom: 100,
                      left: -80,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(
                                0xFF06B6D4,
                              ).withValues(alpha: _pulseAnimation.value * 0.5),
                              const Color(
                                0xFF0EA5E9,
                              ).withValues(alpha: _pulseAnimation.value * 0.2),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Center accent orb
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.35,
                      right: -100,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(
                                0xFFF472B6,
                              ).withValues(alpha: _pulseAnimation.value * 0.4),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],

          // Decorative background elements for non-glassy themes
          if (!isGlassy) ...[
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
                _buildAppBar(context, l10n, theme, isGlassy),
                Expanded(
                  child: summaryAsync.when(
                    data: (summary) {
                      final hasData =
                          summary['totalIncome'] > 0 ||
                          summary['totalExpense'] > 0 ||
                          (summary['hasDebtData'] ?? false);

                      if (!hasData) {
                        return _buildEmptyReportsState(
                          context,
                          l10n,
                          theme,
                          isGlassy,
                        );
                      }

                      return Screenshot(
                        controller: _reportsService.screenshotController,
                        child: Container(
                          color: isGlassy
                              ? Colors.transparent
                              : theme.scaffoldBackgroundColor,
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
                                _buildDebtSummarySection(
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
                                  isGlassy,
                                ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    loading: () => Center(
                      child: isGlassy
                          ? _buildGlassyLoadingIndicator()
                          : const CircularProgressIndicator(),
                    ),
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

  Widget _buildGlassyLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        strokeWidth: 3,
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
          // Back button with glassmorphism
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: isGlassy
                  ? ImageFilter.blur(sigmaX: 10, sigmaY: 10)
                  : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: Container(
                decoration: BoxDecoration(
                  color: isGlassy
                      ? Colors.white.withValues(alpha: 0.1)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: isGlassy
                      ? Border.all(color: Colors.white.withValues(alpha: 0.15))
                      : null,
                  boxShadow: isGlassy
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF8B5CF6,
                            ).withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
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
            ),
          ),
          // Title with gradient effect for glassy
          isGlassy
              ? ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFE0E7FF), Colors.white],
                  ).createShader(bounds),
                  child: Text(
                    l10n.reports,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
              : Text(
                  l10n.reports,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
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
    final isGlassy = themeMode == AppThemeMode.glassy;
    final dateFormat = DateFormat.yMMMMd(
      Localizations.localeOf(context).toString(),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: isGlassy
            ? ImageFilter.blur(sigmaX: 15, sigmaY: 15)
            : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isGlassy
                ? Colors.white.withValues(alpha: 0.08)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: isGlassy
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.5,
                  )
                : null,
            boxShadow: isGlassy
                ? [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: isGlassy
                          ? const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                            )
                          : null,
                      color: isGlassy
                          ? null
                          : theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.date_range_rounded,
                      color: isGlassy ? Colors.white : theme.primaryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.selectDateRange,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isGlassy
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _showDateRangePicker(context, state, theme),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: isGlassy
                        ? LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.1),
                              Colors.white.withValues(alpha: 0.05),
                            ],
                          )
                        : null,
                    color: isGlassy
                        ? null
                        : theme.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isGlassy
                          ? Colors.white.withValues(alpha: 0.1)
                          : theme.primaryColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        color: isGlassy
                            ? const Color(0xFF8B5CF6)
                            : theme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${dateFormat.format(state.startDate)} - ${dateFormat.format(state.endDate)}',
                          style: TextStyle(
                            color: isGlassy
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isGlassy
                            ? const Color(0xFF8B5CF6)
                            : theme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker(
    BuildContext context,
    ReportState state,
    ThemeData theme,
  ) async {
    final picked = await showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DateRangeSelectionSheet(
        startDate: state.startDate,
        endDate: state.endDate,
      ),
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
    final isGlassy = themeMode == AppThemeMode.glassy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.reportSummary, theme, isGlassy),
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
                gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
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
                gradientColors: const [Color(0xFFF43F5E), Color(0xFFE11D48)],
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
    required List<Color> gradientColors,
    required ThemeData theme,
    required AppThemeMode themeMode,
    required AppLocalizations l10n,
  }) {
    final isGlassy = themeMode == AppThemeMode.glassy;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: isGlassy
            ? ImageFilter.blur(sigmaX: 10, sigmaY: 10)
            : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isGlassy
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  )
                : null,
            color: isGlassy ? null : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: isGlassy
                ? Border.all(color: Colors.white.withValues(alpha: 0.15))
                : null,
            boxShadow: isGlassy
                ? [
                    BoxShadow(
                      color: gradientColors[0].withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
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
                  gradient: isGlassy
                      ? LinearGradient(colors: gradientColors)
                      : null,
                  color: isGlassy ? null : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isGlassy
                      ? [
                          BoxShadow(
                            color: gradientColors[0].withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  color: isGlassy ? Colors.white : color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 16),
              FittedBox(
                child: Text(
                  l10n.currencyFormat(amount),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isGlassy
                        ? Colors.white
                        : theme.colorScheme.onSurface,
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
        ),
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
    final gradientColors = balance >= 0
        ? [const Color(0xFF10B981), const Color(0xFF059669)]
        : [const Color(0xFFF43F5E), const Color(0xFFE11D48)];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: isGlassy
            ? ImageFilter.blur(sigmaX: 12, sigmaY: 12)
            : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: isGlassy
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      gradientColors[0].withValues(alpha: 0.2),
                      gradientColors[1].withValues(alpha: 0.1),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.1),
                      color.withValues(alpha: 0.05),
                    ],
                  ),
            borderRadius: BorderRadius.circular(20),
            border: isGlassy
                ? Border.all(
                    color: gradientColors[0].withValues(alpha: 0.3),
                    width: 1.5,
                  )
                : Border.all(color: color.withValues(alpha: 0.2)),
            boxShadow: isGlassy
                ? [
                    BoxShadow(
                      color: gradientColors[0].withValues(alpha: 0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
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
                      color: isGlassy
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ShaderMask(
                    shaderCallback: isGlassy
                        ? (bounds) => LinearGradient(
                            colors: gradientColors,
                          ).createShader(bounds)
                        : (bounds) => LinearGradient(
                            colors: [color, color],
                          ).createShader(bounds),
                    child: Text(
                      l10n.currencyFormat(balance),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: isGlassy
                      ? LinearGradient(colors: gradientColors)
                      : null,
                  color: isGlassy ? null : color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  boxShadow: isGlassy
                      ? [
                          BoxShadow(
                            color: gradientColors[0].withValues(alpha: 0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  balance >= 0
                      ? Icons.account_balance_wallet_rounded
                      : Icons.warning_rounded,
                  color: isGlassy ? Colors.white : color,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
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

    // Category gradient colors for glassy mode
    final categoryColors = [
      [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
      [const Color(0xFF06B6D4), const Color(0xFF0891B2)],
      [const Color(0xFFF472B6), const Color(0xFFEC4899)],
      [const Color(0xFFFBBF24), const Color(0xFFF59E0B)],
      [const Color(0xFF10B981), const Color(0xFF059669)],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.categoriesBreakdown, theme, isGlassy),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: isGlassy
                ? ImageFilter.blur(sigmaX: 12, sigmaY: 12)
                : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: isGlassy
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                      )
                    : null,
                color: isGlassy ? null : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: isGlassy
                    ? Border.all(color: Colors.white.withValues(alpha: 0.15))
                    : null,
                boxShadow: isGlassy
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFF8B5CF6,
                          ).withValues(alpha: 0.15),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
              ),
              child: Column(
                children: categoryTotals.entries.toList().asMap().entries.map((
                  entry,
                ) {
                  final index = entry.key;
                  final e = entry.value;
                  final colors = categoryColors[index % categoryColors.length];

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: isGlassy
                          ? LinearGradient(
                              colors: [
                                colors[0].withValues(alpha: 0.1),
                                Colors.transparent,
                              ],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: isGlassy
                              ? LinearGradient(colors: colors)
                              : null,
                          color: isGlassy
                              ? null
                              : theme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          boxShadow: isGlassy
                              ? [
                                  BoxShadow(
                                    color: colors[0].withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          IconHelper.getIcon(categoryIcons[e.key] ?? 'other'),
                          color: isGlassy ? Colors.white : theme.primaryColor,
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
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: isGlassy
                              ? LinearGradient(
                                  colors: [
                                    colors[0].withValues(alpha: 0.2),
                                    colors[1].withValues(alpha: 0.1),
                                  ],
                                )
                              : null,
                          color: isGlassy
                              ? null
                              : theme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: isGlassy
                              ? Border.all(
                                  color: colors[0].withValues(alpha: 0.3),
                                )
                              : null,
                        ),
                        child: Text(
                          l10n.currencyFormat(e.value),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isGlassy ? colors[0] : theme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
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
          height: 20,
          decoration: BoxDecoration(
            gradient: isGlassy
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF8B5CF6), Color(0xFFF472B6)],
                  )
                : null,
            color: isGlassy ? null : theme.primaryColor,
            borderRadius: BorderRadius.circular(2),
            boxShadow: isGlassy
                ? [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(width: 12),
        isGlassy
            ? ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFE0E7FF), Colors.white],
                ).createShader(bounds),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            : Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
      ],
    );
  }

  Widget _buildDebtSummarySection(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, dynamic> summary,
    ThemeData theme,
    AppThemeMode themeMode,
  ) {
    final isGlassy = themeMode == AppThemeMode.glassy;
    final hasDebtData = summary['hasDebtData'] ?? false;
    
    if (!hasDebtData) {
      return const SizedBox.shrink();
    }

    final totalBorrowed = summary['totalBorrowed'] as double;
    final totalLent = summary['totalLent'] as double;
    final netDebtInPeriod = summary['netDebtInPeriod'] as double;

    // Colors for debt cards
    const borrowedColors = [Color(0xFFF43F5E), Color(0xFFE11D48)]; // Red - I owe
    const lentColors = [Color(0xFF10B981), Color(0xFF059669)]; // Green - They owe me

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.debtSummary, theme, isGlassy),
        const SizedBox(height: 16),
        
        // Borrowed and Lent cards
        Row(
          children: [
            Expanded(
              child: _buildDebtCard(
                context,
                icon: Icons.arrow_downward_rounded,
                label: l10n.totalBorrowed,
                amount: totalBorrowed,
                gradientColors: borrowedColors,
                theme: theme,
                isGlassy: isGlassy,
                l10n: l10n,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDebtCard(
                context,
                icon: Icons.arrow_upward_rounded,
                label: l10n.totalLent,
                amount: totalLent,
                gradientColors: lentColors,
                theme: theme,
                isGlassy: isGlassy,
                l10n: l10n,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Net debt card
        _buildNetDebtCard(
          context,
          l10n,
          netDebtInPeriod,
          theme,
          isGlassy,
        ),
      ],
    );
  }

  Widget _buildDebtCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required double amount,
    required List<Color> gradientColors,
    required ThemeData theme,
    required bool isGlassy,
    required AppLocalizations l10n,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: isGlassy
            ? ImageFilter.blur(sigmaX: 10, sigmaY: 10)
            : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isGlassy
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  )
                : null,
            color: isGlassy ? null : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: isGlassy
                ? Border.all(color: Colors.white.withValues(alpha: 0.15))
                : null,
            boxShadow: isGlassy
                ? [
                    BoxShadow(
                      color: gradientColors[0].withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: gradientColors[0].withValues(alpha: 0.1),
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
                  gradient: isGlassy
                      ? LinearGradient(colors: gradientColors)
                      : null,
                  color: isGlassy ? null : gradientColors[0].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isGlassy
                      ? [
                          BoxShadow(
                            color: gradientColors[0].withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  color: isGlassy ? Colors.white : gradientColors[0],
                  size: 18,
                ),
              ),
              const SizedBox(height: 12),
              FittedBox(
                child: Text(
                  l10n.currencyFormat(amount),
                  style: theme.textTheme.titleMedium?.copyWith(
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
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetDebtCard(
    BuildContext context,
    AppLocalizations l10n,
    double netDebt,
    ThemeData theme,
    bool isGlassy,
  ) {
    // Positive = others owe me, Negative = I owe others
    final isPositive = netDebt >= 0;
    final color = isPositive ? AppColors.income : AppColors.expense;
    final gradientColors = isPositive
        ? [const Color(0xFF10B981), const Color(0xFF059669)]
        : [const Color(0xFFF43F5E), const Color(0xFFE11D48)];
    final statusText = isPositive ? l10n.othersOweYou : l10n.youOweOthers;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: isGlassy
            ? ImageFilter.blur(sigmaX: 12, sigmaY: 12)
            : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isGlassy
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      gradientColors[0].withValues(alpha: 0.2),
                      gradientColors[1].withValues(alpha: 0.1),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.1),
                      color.withValues(alpha: 0.05),
                    ],
                  ),
            borderRadius: BorderRadius.circular(20),
            border: isGlassy
                ? Border.all(
                    color: gradientColors[0].withValues(alpha: 0.3),
                    width: 1.5,
                  )
                : Border.all(color: color.withValues(alpha: 0.2)),
            boxShadow: isGlassy
                ? [
                    BoxShadow(
                      color: gradientColors[0].withValues(alpha: 0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.netDebt,
                      style: TextStyle(
                        color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: isGlassy
                            ? Colors.white.withValues(alpha: 0.6)
                            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShaderMask(
                      shaderCallback: isGlassy
                          ? (bounds) => LinearGradient(
                              colors: gradientColors,
                            ).createShader(bounds)
                          : (bounds) => LinearGradient(
                              colors: [color, color],
                            ).createShader(bounds),
                      child: Text(
                        l10n.currencyFormat(netDebt.abs()),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: isGlassy
                      ? LinearGradient(colors: gradientColors)
                      : null,
                  color: isGlassy ? null : color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  boxShadow: isGlassy
                      ? [
                          BoxShadow(
                            color: gradientColors[0].withValues(alpha: 0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  color: isGlassy ? Colors.white : color,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareActions(
    BuildContext context,
    AppLocalizations l10n,
    String userName,
    ReportState state,
    Map<String, dynamic> summary,
    ThemeData theme,
    bool isGlassy,
  ) {
    return Column(
      children: [
        // PDF Share Button
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: isGlassy
                ? ImageFilter.blur(sigmaX: 10, sigmaY: 10)
                : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: isGlassy
                    ? const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                      )
                    : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isGlassy
                    ? [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: ElevatedButton(
                onPressed: _isGeneratingPdf
                    ? null
                    : () async {
                        setState(() => _isGeneratingPdf = true);
                        try {
                          // Don't await shareAsPdf - it waits for share dialog dismissal
                          _reportsService.shareAsPdf(
                            context: context,
                            userName: userName,
                            startDate: state.startDate,
                            endDate: state.endDate,
                            transactions: summary['transactions'],
                            totalIncome: summary['totalIncome'],
                            totalExpense: summary['totalExpense'],
                            netBalance: summary['netBalance'],
                            categoryTotals: summary['categoryTotals'],
                            totalBorrowed: summary['totalBorrowed'] ?? 0,
                            totalLent: summary['totalLent'] ?? 0,
                            netDebt: summary['netDebtInPeriod'] ?? 0,
                            hasDebtData: summary['hasDebtData'] ?? false,
                          );
                          // Small delay to show loading, then reset
                          await Future.delayed(const Duration(milliseconds: 500));
                        } finally {
                          if (mounted) setState(() => _isGeneratingPdf = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isGlassy
                      ? Colors.transparent
                      : theme.primaryColor,
                  disabledBackgroundColor: isGlassy
                      ? Colors.transparent
                      : theme.primaryColor.withValues(alpha: 0.7),
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isGeneratingPdf
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isGlassy ? Colors.white : theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              l10n.loading,
                              style: TextStyle(
                                color: isGlassy ? Colors.white : theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.picture_as_pdf_rounded,
                              color: isGlassy ? Colors.white : theme.colorScheme.onPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.shareAsPdf,
                              style: TextStyle(
                                color: isGlassy ? Colors.white : theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Image Share Button
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: isGlassy
                ? ImageFilter.blur(sigmaX: 10, sigmaY: 10)
                : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: isGlassy
                    ? LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.08),
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(16),
                border: isGlassy
                    ? Border.all(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                        width: 1.5,
                      )
                    : null,
              ),
              child: OutlinedButton(
                onPressed: _isGeneratingImage
                    ? null
                    : () async {
                        setState(() => _isGeneratingImage = true);
                        try {
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
                          // Don't await shareAsImage - it waits for share dialog dismissal
                          _reportsService.shareAsImage(image);
                          await Future.delayed(const Duration(milliseconds: 300));
                        } finally {
                          if (mounted) setState(() => _isGeneratingImage = false);
                        }
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: isGlassy ? Colors.white : theme.primaryColor,
                  disabledForegroundColor: isGlassy
                      ? Colors.white.withValues(alpha: 0.7)
                      : theme.primaryColor.withValues(alpha: 0.7),
                  side: isGlassy
                      ? BorderSide.none
                      : BorderSide(
                          color: _isGeneratingImage
                              ? theme.primaryColor.withValues(alpha: 0.5)
                              : theme.primaryColor,
                        ),
                  backgroundColor: isGlassy ? Colors.transparent : null,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isGeneratingImage
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isGlassy ? const Color(0xFF8B5CF6) : theme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              l10n.loading,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isGlassy ? Colors.white : theme.primaryColor,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_rounded,
                              color: isGlassy
                                  ? const Color(0xFF8B5CF6)
                                  : theme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.shareAsImage,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isGlassy ? Colors.white : theme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                ),
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
    bool isGlassy,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated empty state icon
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: isGlassy
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                          const Color(0xFFF472B6).withValues(alpha: 0.1),
                        ],
                      )
                    : null,
                color: isGlassy
                    ? null
                    : theme.primaryColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: isGlassy
                    ? Border.all(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                      )
                    : null,
                boxShadow: isGlassy
                    ? [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Icon(
                  Icons.bar_chart_rounded,
                  size: 64,
                  color: isGlassy
                      ? const Color(0xFF8B5CF6).withValues(alpha: 0.6)
                      : theme.primaryColor.withValues(alpha: 0.2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            isGlassy
                ? ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFE0E7FF), Colors.white],
                    ).createShader(bounds),
                    child: Text(
                      l10n.noTransactions,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Text(
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
                color: isGlassy
                    ? Colors.white.withValues(alpha: 0.6)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: isGlassy
                    ? ImageFilter.blur(sigmaX: 10, sigmaY: 10)
                    : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isGlassy
                        ? LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.15),
                              Colors.white.withValues(alpha: 0.08),
                            ],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    border: isGlassy
                        ? Border.all(
                            color: const Color(
                              0xFF8B5CF6,
                            ).withValues(alpha: 0.4),
                          )
                        : null,
                  ),
                  child: OutlinedButton.icon(
                    onPressed: () => _showDateRangePicker(
                      context,
                      ref.read(reportsControllerProvider),
                      theme,
                    ),
                    icon: Icon(
                      Icons.date_range_rounded,
                      color: isGlassy ? const Color(0xFF8B5CF6) : null,
                    ),
                    label: Text(
                      'Change Date Range',
                      style: TextStyle(
                        color: isGlassy ? Colors.white : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isGlassy ? Colors.white : null,
                      side: isGlassy ? BorderSide.none : null,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
