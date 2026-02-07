import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

import '../../l10n/app_localizations.dart';
import '../../core/models/category_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/localization/translation_helper.dart';
import '../../core/utils/icon_helper.dart';
import '../../services/firestore_service.dart';
import '../../core/theme/theme_provider.dart';
import 'add_edit_category_screen.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
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
                      Color(0xFF2A2D3E),
                      Color(0xFF26293A),
                      Color(0xFF2B2E40),
                    ],
                  ),
                ),
              ),
            ),

          // Decorative background elements
          if (themeMode != AppThemeMode.glassy) ...[
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
                _buildAppBar(context, l10n, theme, themeMode),

                // Content
                Expanded(
                  child: categoriesAsync.when(
                    data: (categories) {
                      if (categories.isEmpty) {
                        return _buildEmptyState(
                          context,
                          l10n,
                          theme,
                          themeMode,
                        );
                      }
                      return _buildCategoriesList(
                        context,
                        categories,
                        l10n,
                        theme,
                        themeMode,
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) =>
                        _buildErrorState(context, l10n, err, theme, themeMode),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context, l10n, theme),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    AppThemeMode themeMode,
  ) {
    final isGlassy = themeMode == AppThemeMode.glassy;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Back button
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: isGlassy
                  ? ImageFilter.blur(sigmaX: 5, sigmaY: 5)
                  : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: Container(
                decoration: BoxDecoration(
                  color: isGlassy
                      ? Colors.white.withValues(alpha: 0.1)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: isGlassy
                      ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                      : null,
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
                  color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
                  onPressed: () => context.pop(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.categories,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isGlassy
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  l10n.manageCategories,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        (isGlassy ? Colors.white : theme.colorScheme.onSurface)
                            .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _navigateToAddCategory(context),
        backgroundColor: theme.primaryColor,
        elevation: 0,
        icon: Icon(Icons.add_rounded, color: theme.colorScheme.onPrimary),
        label: Text(
          l10n.addCategory,
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    AppThemeMode themeMode,
  ) {
    final isGlassy = themeMode == AppThemeMode.glassy;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated-like illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.primaryColor.withValues(alpha: 0.1),
                    theme.primaryColor.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isGlassy
                        ? Colors.white.withValues(alpha: 0.1)
                        : theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.category_rounded,
                    size: 40,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.noCategoriesFound,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.tapToAddCategory,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: (isGlassy ? Colors.white : theme.colorScheme.onSurface)
                    .withValues(alpha: 0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Quick action button
            ElevatedButton.icon(
              onPressed: () => _navigateToAddCategory(context),
              icon: Icon(Icons.add_rounded, color: theme.colorScheme.onPrimary),
              label: Text(
                l10n.addCategory,
                style: TextStyle(color: theme.colorScheme.onPrimary),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
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

  Widget _buildErrorState(
    BuildContext context,
    AppLocalizations l10n,
    Object err,
    ThemeData theme,
    AppThemeMode themeMode,
  ) {
    final isGlassy = themeMode == AppThemeMode.glassy;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              '${l10n.error}: $err',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: (isGlassy ? Colors.white : theme.colorScheme.onSurface)
                    .withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesList(
    BuildContext context,
    List<CategoryModel> categories,
    AppLocalizations l10n,
    ThemeData theme,
    AppThemeMode themeMode,
  ) {
    final expenseCategories = categories
        .where((c) => c.type == 'expense')
        .toList();
    final incomeCategories = categories
        .where((c) => c.type == 'income')
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      children: [
        // Summary Cards
        _buildSummaryRow(
          context,
          l10n,
          expenseCategories.length,
          incomeCategories.length,
          theme,
          themeMode,
        ),
        const SizedBox(height: 32),

        // Expense Categories Section
        if (expenseCategories.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            l10n.expenseCategories,
            AppColors.expense,
            expenseCategories.length,
            theme,
            themeMode,
          ),
          const SizedBox(height: 16),
          ...expenseCategories.asMap().entries.map(
            (entry) => _buildCategoryTile(
              context,
              entry.value,
              theme,
              entry.key,
              themeMode,
            ),
          ),
        ],

        // Spacer between sections
        if (expenseCategories.isNotEmpty && incomeCategories.isNotEmpty)
          const SizedBox(height: 32),

        // Income Categories Section
        if (incomeCategories.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            l10n.incomeCategories,
            AppColors.income,
            incomeCategories.length,
            theme,
            themeMode,
          ),
          const SizedBox(height: 16),
          ...incomeCategories.asMap().entries.map(
            (entry) => _buildCategoryTile(
              context,
              entry.value,
              theme,
              entry.key,
              themeMode,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    AppLocalizations l10n,
    int expenseCount,
    int incomeCount,
    ThemeData theme,
    AppThemeMode themeMode,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            context,
            icon: Icons.arrow_upward_rounded,
            label: l10n.expenseCategories,
            count: expenseCount,
            color: AppColors.expense,
            theme: theme,
            themeMode: themeMode,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            context,
            icon: Icons.arrow_downward_rounded,
            label: l10n.incomeCategories,
            count: incomeCount,
            color: AppColors.income,
            theme: theme,
            themeMode: themeMode,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required ThemeData theme,
    required AppThemeMode themeMode,
  }) {
    final isGlassy = themeMode == AppThemeMode.glassy;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: isGlassy
            ? ImageFilter.blur(sigmaX: 10, sigmaY: 10)
            : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isGlassy
                ? Colors.white.withValues(alpha: 0.05)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: themeMode == AppThemeMode.glassy
                ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                : null,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 16),
              Text(
                count.toString(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: (isGlassy ? Colors.white : theme.colorScheme.onSurface)
                      .withValues(alpha: 0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    Color color,
    int count,
    ThemeData theme,
    AppThemeMode themeMode,
  ) {
    final isGlassy = themeMode == AppThemeMode.glassy;
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTile(
    BuildContext context,
    CategoryModel category,
    ThemeData theme,
    int index,
    AppThemeMode themeMode,
  ) {
    final isIncome = category.type == 'income';
    final color = isIncome ? AppColors.income : AppColors.expense;
    final localizedName = TranslationHelper.getCategoryNameFromModel(
      context,
      category,
    );

    final isGlassy = themeMode == AppThemeMode.glassy;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 200 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: BackdropFilter(
          filter: isGlassy
              ? ImageFilter.blur(sigmaX: 5, sigmaY: 5)
              : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isGlassy
                  ? Colors.white.withValues(alpha: 0.05)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: themeMode == AppThemeMode.glassy
                  ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                  : null,
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
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: InkWell(
                onTap: () => _navigateToEditCategory(context, category),
                borderRadius: BorderRadius.circular(AppRadius.button),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icon container with gradient
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withValues(alpha: 0.15),
                              color.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          IconHelper.getIcon(category.icon),
                          color: color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Category name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizedName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isGlassy
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              TranslationHelper.getTransactionType(context, category.type),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Edit button
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.05,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color:
                              (isGlassy
                                      ? Colors.white
                                      : theme.colorScheme.onSurface)
                                  .withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToAddCategory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddEditCategoryScreen()),
    );
  }

  void _navigateToEditCategory(BuildContext context, CategoryModel category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditCategoryScreen(category: category),
      ),
    );
  }
}
