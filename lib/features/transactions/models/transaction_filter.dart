import '../../../core/models/transaction_model.dart';

enum DateRangeOption { all, today, yesterday, last7Days, last30Days, thisMonth, thisYear, custom }

class TransactionFilter {
  final String searchQuery;
  final String? typeFilter; // null = all, 'income', 'expense'
  final DateRangeOption dateRangeOption;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final double? minAmount;
  final double? maxAmount;
  final Set<String> selectedCategoryIds;

  const TransactionFilter({
    this.searchQuery = '',
    this.typeFilter,
    this.dateRangeOption = DateRangeOption.all,
    this.customStartDate,
    this.customEndDate,
    this.minAmount,
    this.maxAmount,
    this.selectedCategoryIds = const {},
  });

  bool get hasActiveFilters =>
      typeFilter != null ||
      dateRangeOption != DateRangeOption.all ||
      minAmount != null ||
      maxAmount != null ||
      selectedCategoryIds.isNotEmpty;

  int get activeFilterCount {
    int count = 0;
    if (typeFilter != null) count++;
    if (dateRangeOption != DateRangeOption.all) count++;
    if (minAmount != null || maxAmount != null) count++;
    if (selectedCategoryIds.isNotEmpty) count++;
    return count;
  }

  bool get hasSearchQuery => searchQuery.trim().isNotEmpty;

  TransactionFilter copyWith({
    String? searchQuery,
    String? Function()? typeFilter,
    DateRangeOption? dateRangeOption,
    DateTime? Function()? customStartDate,
    DateTime? Function()? customEndDate,
    double? Function()? minAmount,
    double? Function()? maxAmount,
    Set<String>? selectedCategoryIds,
  }) {
    return TransactionFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: typeFilter != null ? typeFilter() : this.typeFilter,
      dateRangeOption: dateRangeOption ?? this.dateRangeOption,
      customStartDate: customStartDate != null ? customStartDate() : this.customStartDate,
      customEndDate: customEndDate != null ? customEndDate() : this.customEndDate,
      minAmount: minAmount != null ? minAmount() : this.minAmount,
      maxAmount: maxAmount != null ? maxAmount() : this.maxAmount,
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
    );
  }

  /// Resolves the effective date range based on [dateRangeOption].
  ({DateTime? start, DateTime? end}) get effectiveDateRange {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    switch (dateRangeOption) {
      case DateRangeOption.all:
        return (start: null, end: null);
      case DateRangeOption.today:
        return (start: todayStart, end: now);
      case DateRangeOption.yesterday:
        final yesterdayStart = todayStart.subtract(const Duration(days: 1));
        return (start: yesterdayStart, end: todayStart);
      case DateRangeOption.last7Days:
        return (start: todayStart.subtract(const Duration(days: 7)), end: now);
      case DateRangeOption.last30Days:
        return (start: todayStart.subtract(const Duration(days: 30)), end: now);
      case DateRangeOption.thisMonth:
        return (start: DateTime(now.year, now.month, 1), end: now);
      case DateRangeOption.thisYear:
        return (start: DateTime(now.year, 1, 1), end: now);
      case DateRangeOption.custom:
        return (start: customStartDate, end: customEndDate);
    }
  }

  /// Apply all filters to a list of transactions. Performs search across
  /// title, titleAr, and categoryName fields (case-insensitive, RTL-safe).
  List<TransactionModel> apply(
    List<TransactionModel> transactions, {
    Map<String, String> categoryNameArMap = const {},
  }) {
    var result = transactions;

    // Search filter — matches title, titleAr, categoryName (localized)
    if (hasSearchQuery) {
      final query = searchQuery.trim().toLowerCase();
      result = result.where((tx) {
        if (tx.title.toLowerCase().contains(query)) return true;
        if (tx.titleAr != null && tx.titleAr!.toLowerCase().contains(query)) return true;
        if (tx.categoryName.toLowerCase().contains(query)) return true;
        // Also search the Arabic category name
        final arCatName = categoryNameArMap[tx.categoryName];
        if (arCatName != null && arCatName.toLowerCase().contains(query)) return true;
        return false;
      }).toList();
    }

    // Type filter
    if (typeFilter != null) {
      result = result.where((tx) => tx.type == typeFilter).toList();
    }

    // Date range filter
    final dateRange = effectiveDateRange;
    if (dateRange.start != null) {
      result = result.where((tx) =>
          tx.createdAt.isAfter(dateRange.start!) ||
          tx.createdAt.isAtSameMomentAs(dateRange.start!)).toList();
    }
    if (dateRange.end != null) {
      final endOfDay = DateTime(
        dateRange.end!.year,
        dateRange.end!.month,
        dateRange.end!.day,
        23, 59, 59, 999,
      );
      result = result.where((tx) =>
          tx.createdAt.isBefore(endOfDay) ||
          tx.createdAt.isAtSameMomentAs(endOfDay)).toList();
    }

    // Amount range filter
    if (minAmount != null) {
      result = result.where((tx) => tx.amount >= minAmount!).toList();
    }
    if (maxAmount != null) {
      result = result.where((tx) => tx.amount <= maxAmount!).toList();
    }

    // Category filter
    if (selectedCategoryIds.isNotEmpty) {
      result = result.where((tx) => selectedCategoryIds.contains(tx.categoryId)).toList();
    }

    return result;
  }

  static const empty = TransactionFilter();
}
