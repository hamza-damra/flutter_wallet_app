import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/models/transaction_model.dart';

class PdfGenerator {
  static Future<Uint8List> generateTransactionReport({
    required String userName,
    required DateTime startDate,
    required DateTime endDate,
    required List<TransactionModel> transactions,
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
    required Map<String, double> categoryTotals,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd');

    // Define colors from AppColors
    final primaryColor = PdfColor.fromInt(0xFF8B5A2B);
    final incomeColor = PdfColor.fromInt(0xFF4CAF50);
    final expenseColor = PdfColor.fromInt(0xFFE53935);
    final greyColor = PdfColors.grey700;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Financial Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'User: $userName',
                    style: pw.TextStyle(fontSize: 14, color: greyColor),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Date Range',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 32),

          // Summary Cards
          pw.Row(
            children: [
              _buildSummaryBox('Total Income', totalIncome, incomeColor),
              pw.SizedBox(width: 16),
              _buildSummaryBox('Total Expenses', totalExpense, expenseColor),
              pw.SizedBox(width: 16),
              _buildSummaryBox('Net Balance', netBalance, primaryColor),
            ],
          ),
          pw.SizedBox(height: 32),

          // Category Breakdown
          pw.Text(
            'Category Breakdown',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: greyColor,
            ),
          ),
          pw.Divider(),
          pw.SizedBox(height: 8),
          ...categoryTotals.entries.map(
            (e) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(e.key),
                  pw.Text(
                    '${e.value.toStringAsFixed(2)} ILS',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 32),

          // Transaction Table
          pw.Text(
            'Transaction Details',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: greyColor,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            headerDecoration: pw.BoxDecoration(color: primaryColor),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.center,
            },
            headers: ['Date', 'Title', 'Amount', 'Type'],
            data: transactions.map((tx) {
              return [
                dateFormat.format(tx.createdAt),
                tx.title,
                tx.amount.toStringAsFixed(2),
                tx.type.toUpperCase(),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSummaryBox(
    String title,
    double amount,
    PdfColor color,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: color, width: 1),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 4),
            pw.Text(
              amount.toStringAsFixed(2),
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
