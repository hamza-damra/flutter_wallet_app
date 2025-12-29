import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../core/models/category_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/localization/translation_helper.dart';
import '../../core/utils/direction_helper.dart';
import '../../core/utils/icon_helper.dart';
import '../../services/firestore_service.dart';
import 'add_edit_category_screen.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.categories, style: theme.textTheme.headlineSmall),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddCategory(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return _buildEmptyState(context, l10n, theme);
          }

          // Group categories by type
          final expenseCategories = categories
              .where((c) => c.type == 'expense')
              .toList();
          final incomeCategories = categories
              .where((c) => c.type == 'income')
              .toList();

          return ListView(
            padding: const EdgeInsetsDirectional.all(20),
            children: [
              // Expense Categories
              if (expenseCategories.isNotEmpty) ...[
                Text(
                  l10n.expenseCategories,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ...expenseCategories.map(
                  (category) => _buildCategoryTile(context, category),
                ),
                const SizedBox(height: 24),
              ],

              // Income Categories
              if (incomeCategories.isNotEmpty) ...[
                Text(
                  l10n.incomeCategories,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ...incomeCategories.map(
                  (category) => _buildCategoryTile(context, category),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('${l10n.error}: $err')),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              l10n.noCategoriesFound,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tapToAddCategory,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, CategoryModel category) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isIncome = category.type == 'income';
    final typeText = isIncome ? l10n.incomeType : l10n.expenseType;
    final localizedName = TranslationHelper.getCategoryName(
      context,
      category.name,
    );

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _navigateToEditCategory(context, category),
        child: Container(
          padding: const EdgeInsetsDirectional.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.button),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsetsDirectional.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconHelper.getIcon(category.icon),
                  color: isIncome ? AppColors.income : AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizedName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      typeText.toUpperCase(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: isIncome ? AppColors.income : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Direction-aware chevron
              DirectionalIcon(Icons.chevron_right, color: Colors.grey),
            ],
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
