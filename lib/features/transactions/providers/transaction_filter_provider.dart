import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_filter.dart';

/// Manages the current search/filter state for the transaction history screen.
final transactionFilterProvider =
    NotifierProvider<TransactionFilterNotifier, TransactionFilter>(
  TransactionFilterNotifier.new,
);

class TransactionFilterNotifier extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => TransactionFilter.empty;

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setTypeFilter(String? type) {
    state = state.copyWith(typeFilter: () => type);
  }

  void setDateRange(DateRangeOption option, {DateTime? start, DateTime? end}) {
    state = state.copyWith(
      dateRangeOption: option,
      customStartDate: () => start,
      customEndDate: () => end,
    );
  }

  void setAmountRange({double? min, double? max}) {
    state = state.copyWith(
      minAmount: () => min,
      maxAmount: () => max,
    );
  }

  void toggleCategory(String categoryId) {
    final current = Set<String>.from(state.selectedCategoryIds);
    if (current.contains(categoryId)) {
      current.remove(categoryId);
    } else {
      current.add(categoryId);
    }
    state = state.copyWith(selectedCategoryIds: current);
  }

  void clearFilters() {
    state = TransactionFilter(searchQuery: state.searchQuery);
  }

  void clearAll() {
    state = TransactionFilter.empty;
  }
}
