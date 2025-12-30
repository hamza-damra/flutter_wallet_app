import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'pdf_generator.dart';
import 'widgets/shareable_report_card.dart';
import '../../core/models/transaction_model.dart';
import 'package:intl/intl.dart' as intl;

class ReportsService {
  final ScreenshotController screenshotController = ScreenshotController();

  Future<Uint8List> captureReportCard({
    required String userName,
    required DateTime startDate,
    required DateTime endDate,
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
    required String appName,
    required TextDirection textDirection,
    required String financialSummaryLabel,
    required String totalBalanceLabel,
    required String incomeLabel,
    required String expenseLabel,
    required String preparedForLabel,
    required String dateRange,
  }) async {
    return await screenshotController.captureFromWidget(
      ShareableReportCard(
        userName: userName,
        startDate: startDate,
        endDate: endDate,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        netBalance: netBalance,
        appName: appName,
        textDirection: textDirection,
        financialSummaryLabel: financialSummaryLabel,
        totalBalanceLabel: totalBalanceLabel,
        incomeLabel: incomeLabel,
        expenseLabel: expenseLabel,
        preparedForLabel: preparedForLabel,
        dateRange: dateRange,
      ),
      delay: const Duration(milliseconds: 10),
    );
  }

  Future<void> shareAsPdf({
    required BuildContext context,
    required String userName,
    required DateTime startDate,
    required DateTime endDate,
    required List<TransactionModel> transactions,
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
    required Map<String, double> categoryTotals,
  }) async {
    final pdfBytes = await PdfGenerator.generateTransactionReport(
      userName: userName,
      startDate: startDate,
      endDate: endDate,
      transactions: transactions,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netBalance: netBalance,
      categoryTotals: categoryTotals,
    );

    final directory = await getTemporaryDirectory();
    final fileName =
        'financial_report_${intl.DateFormat('yyyy_MM_dd').format(startDate)}_to_${intl.DateFormat('yyyy_MM_dd').format(endDate)}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfBytes);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Financial Report'),
    );
  }

  Future<void> shareAsImage(Uint8List imageBytes) async {
    final directory = await getTemporaryDirectory();
    final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(imageBytes);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Financial Report Summary'),
    );
  }
}
