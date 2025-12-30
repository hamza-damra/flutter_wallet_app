import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/transaction_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class ReportState {
  final DateTime startDate;
  final DateTime endDate;
  final bool isLoading;

  ReportState({
    required this.startDate,
    required this.endDate,
    this.isLoading = false,
  });

  ReportState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    bool? isLoading,
  }) {
    return ReportState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ReportsController extends Notifier<ReportState> {
  @override
  ReportState build() {
    return ReportState(
      startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
      endDate: DateTime.now(),
    );
  }

  void setDateRange(DateTime start, DateTime end) {
    state = state.copyWith(startDate: start, endDate: end);
  }
}

final reportsControllerProvider =
    NotifierProvider<ReportsController, ReportState>(ReportsController.new);

final filteredTransactionsProvider = StreamProvider<List<TransactionModel>>((
  ref,
) {
  final reportState = ref.watch(reportsControllerProvider);
  final user = ref.watch(authServiceProvider).currentUser;

  if (user == null) return Stream.value([]);

  return ref
      .watch(firestoreServiceProvider)
      .getFilteredTransactions(
        user.uid,
        reportState.startDate,
        reportState.endDate,
      );
});

final reportSummaryProvider = Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final transactionsAsync = ref.watch(filteredTransactionsProvider);

  return transactionsAsync.whenData((transactions) {
    double totalIncome = 0;
    double totalExpense = 0;
    Map<String, double> categoryTotals = {};
    Map<String, String> categoryIcons = {};

    for (var tx in transactions) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }

      categoryTotals[tx.categoryName] =
          (categoryTotals[tx.categoryName] ?? 0) + tx.amount;
      categoryIcons[tx.categoryName] = tx.categoryIcon;
    }

    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'netBalance': totalIncome - totalExpense,
      'categoryTotals': categoryTotals,
      'categoryIcons': categoryIcons,
      'transactions': transactions,
    };
  });
});
