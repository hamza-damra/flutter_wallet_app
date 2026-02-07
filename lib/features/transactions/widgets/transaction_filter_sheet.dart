import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/models/category_model.dart';
import '../../../core/localization/translation_helper.dart';
import '../../../data/repositories/category_repository.dart';
import '../models/transaction_filter.dart';
import '../providers/transaction_filter_provider.dart';

class TransactionFilterSheet extends ConsumerStatefulWidget {
  const TransactionFilterSheet({super.key});

  @override
  ConsumerState<TransactionFilterSheet> createState() =>
      _TransactionFilterSheetState();
}

class _TransactionFilterSheetState
    extends ConsumerState<TransactionFilterSheet> {
  late TextEditingController _minController;
  late TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(transactionFilterProvider);
    _minController = TextEditingController(
      text: filter.minAmount?.toString() ?? '',
    );
    _maxController = TextEditingController(
      text: filter.maxAmount?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);
    final isGlassy = themeMode == AppThemeMode.glassy;
    final filter = ref.watch(transactionFilterProvider);
    final notifier = ref.read(transactionFilterProvider.notifier);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final categoryNameArMap = ref.watch(categoryNameArMapProvider);

    return Container(
      decoration: BoxDecoration(
        color: isGlassy
            ? const Color(0xFF1E293B)
            : theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isGlassy
                    ? Colors.white.withValues(alpha: 0.3)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.filterTransactions,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isGlassy
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (filter.hasActiveFilters)
                  TextButton(
                    onPressed: () => notifier.clearFilters(),
                    child: Text(
                      l10n.clearFilters,
                      style: TextStyle(
                        color: AppColors.expense,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction type
                  _buildSectionLabel(l10n.transactionType, theme, isGlassy),
                  const SizedBox(height: 8),
                  _buildTypeChips(filter, notifier, l10n, theme, isGlassy),
                  const SizedBox(height: 20),

                  // Date range
                  _buildSectionLabel(l10n.dateRange, theme, isGlassy),
                  const SizedBox(height: 8),
                  _buildDateRangeChips(
                      filter, notifier, l10n, theme, isGlassy),
                  const SizedBox(height: 20),

                  // Amount range
                  _buildSectionLabel(l10n.amountRange, theme, isGlassy),
                  const SizedBox(height: 8),
                  _buildAmountRange(
                      filter, notifier, l10n, theme, isGlassy),
                  const SizedBox(height: 20),

                  // Category filter
                  _buildSectionLabel(l10n.selectCategories, theme, isGlassy),
                  const SizedBox(height: 8),
                  categoriesAsync.when(
                    data: (categories) => _buildCategoryChips(
                      categories,
                      filter,
                      notifier,
                      theme,
                      isGlassy,
                      categoryNameArMap,
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 16),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: theme.colorScheme.onPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        l10n.apply,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, ThemeData theme, bool isGlassy) {
    return Text(
      label,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: isGlassy
            ? Colors.white.withValues(alpha: 0.8)
            : theme.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildTypeChips(
    TransactionFilter filter,
    TransactionFilterNotifier notifier,
    AppLocalizations l10n,
    ThemeData theme,
    bool isGlassy,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildChip(
          label: l10n.allTypes,
          isSelected: filter.typeFilter == null,
          onTap: () => notifier.setTypeFilter(null),
          theme: theme,
          isGlassy: isGlassy,
        ),
        _buildChip(
          label: l10n.incomeType,
          isSelected: filter.typeFilter == 'income',
          onTap: () => notifier.setTypeFilter('income'),
          theme: theme,
          isGlassy: isGlassy,
          selectedColor: AppColors.income,
        ),
        _buildChip(
          label: l10n.expenseType,
          isSelected: filter.typeFilter == 'expense',
          onTap: () => notifier.setTypeFilter('expense'),
          theme: theme,
          isGlassy: isGlassy,
          selectedColor: AppColors.expense,
        ),
      ],
    );
  }

  Widget _buildDateRangeChips(
    TransactionFilter filter,
    TransactionFilterNotifier notifier,
    AppLocalizations l10n,
    ThemeData theme,
    bool isGlassy,
  ) {
    final options = <(DateRangeOption, String)>[
      (DateRangeOption.all, l10n.allTypes),
      (DateRangeOption.today, l10n.today),
      (DateRangeOption.yesterday, l10n.yesterday),
      (DateRangeOption.last7Days, l10n.last7Days),
      (DateRangeOption.last30Days, l10n.last30DaysFilter),
      (DateRangeOption.thisMonth, l10n.thisMonthFilter),
      (DateRangeOption.thisYear, l10n.thisYearFilter),
      (DateRangeOption.custom, l10n.customRange),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            return _buildChip(
              label: opt.$2,
              isSelected: filter.dateRangeOption == opt.$1,
              onTap: () async {
                if (opt.$1 == DateRangeOption.custom) {
                  await _pickCustomDateRange(notifier, theme);
                } else {
                  notifier.setDateRange(opt.$1);
                }
              },
              theme: theme,
              isGlassy: isGlassy,
            );
          }).toList(),
        ),
        if (filter.dateRangeOption == DateRangeOption.custom &&
            filter.customStartDate != null &&
            filter.customEndDate != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${DateFormat.yMd(Localizations.localeOf(context).toString()).format(filter.customStartDate!)} — '
              '${DateFormat.yMd(Localizations.localeOf(context).toString()).format(filter.customEndDate!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isGlassy
                    ? Colors.white.withValues(alpha: 0.6)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickCustomDateRange(
    TransactionFilterNotifier notifier,
    ThemeData theme,
  ) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
      notifier.setDateRange(
        DateRangeOption.custom,
        start: picked.start,
        end: picked.end,
      );
    }
  }

  Widget _buildAmountRange(
    TransactionFilter filter,
    TransactionFilterNotifier notifier,
    AppLocalizations l10n,
    ThemeData theme,
    bool isGlassy,
  ) {
    final inputDecoration = InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true,
      fillColor: isGlassy
          ? Colors.white.withValues(alpha: 0.08)
          : theme.colorScheme.onSurface.withValues(alpha: 0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
      ),
    );

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _minController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
            ),
            decoration: inputDecoration.copyWith(
              hintText: l10n.minAmount,
              hintStyle: TextStyle(
                color: isGlassy
                    ? Colors.white.withValues(alpha: 0.4)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            onChanged: (val) {
              final min = double.tryParse(val);
              notifier.setAmountRange(
                min: min,
                max: filter.maxAmount,
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _maxController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
            ),
            decoration: inputDecoration.copyWith(
              hintText: l10n.maxAmount,
              hintStyle: TextStyle(
                color: isGlassy
                    ? Colors.white.withValues(alpha: 0.4)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            onChanged: (val) {
              final max = double.tryParse(val);
              notifier.setAmountRange(
                min: filter.minAmount,
                max: max,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips(
    List<CategoryModel> categories,
    TransactionFilter filter,
    TransactionFilterNotifier notifier,
    ThemeData theme,
    bool isGlassy,
    Map<String, String> categoryNameArMap,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final displayName = TranslationHelper.getCategoryDisplayName(
          context,
          cat.name,
          categoryNameArMap,
        );
        final isSelected = filter.selectedCategoryIds.contains(cat.id);
        return _buildChip(
          label: displayName,
          isSelected: isSelected,
          onTap: () => notifier.toggleCategory(cat.id),
          theme: theme,
          isGlassy: isGlassy,
        );
      }).toList(),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool isGlassy,
    Color? selectedColor,
  }) {
    final effectiveColor = selectedColor ?? theme.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveColor.withValues(alpha: 0.15)
              : (isGlassy
                  ? Colors.white.withValues(alpha: 0.08)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? effectiveColor
                : (isGlassy
                    ? Colors.white.withValues(alpha: 0.1)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.1)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isSelected
                ? effectiveColor
                : (isGlassy
                    ? Colors.white.withValues(alpha: 0.7)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
