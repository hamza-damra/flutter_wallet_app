import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/models/transaction_model.dart';
import '../debts/models/friend_model.dart';
import '../debts/models/debt_transaction_model.dart';

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
    // Debt data (optional)
    double totalBorrowed = 0,
    double totalLent = 0,
    double netDebt = 0,
    bool hasDebtData = false,
    bool isArabic = false,
    Map<String, String> categoryNameArMap = const {},
  }) async {
    // Load Unicode fonts for proper character rendering (supports Arabic and Latin)
    final arabicRegular = await PdfGoogleFonts.notoSansArabicRegular();
    final arabicBold = await PdfGoogleFonts.notoSansArabicBold();
    final latinRegular = await PdfGoogleFonts.notoSansRegular();
    final latinBold = await PdfGoogleFonts.notoSansBold();
    
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd');

    // Define colors from AppColors
    final primaryColor = PdfColor.fromInt(0xFF8B5A2B);
    final incomeColor = PdfColor.fromInt(0xFF4CAF50);
    final expenseColor = PdfColor.fromInt(0xFFE53935);
    final greyColor = PdfColors.grey700;
    
    // Create theme with font fallbacks for both Arabic and Latin characters
    final pdfTheme = isArabic
        ? pw.ThemeData.withFont(
            base: arabicRegular,
            bold: arabicBold,
            fontFallback: [latinRegular, latinBold],
          )
        : pw.ThemeData.withFont(
            base: latinRegular,
            bold: latinBold,
            fontFallback: [arabicRegular, arabicBold],
          );

    // Labels based on language
    final reportTitle = isArabic ? 'تقرير مالي' : 'Financial Report';
    final userLabel = isArabic ? 'المستخدم:' : 'User:';
    final dateRangeLabel = isArabic ? 'الفترة الزمنية' : 'Date Range';
    final totalIncomeLabel = isArabic ? 'إجمالي الدخل' : 'Total Income';
    final totalExpensesLabel = isArabic ? 'إجمالي المصاريف' : 'Total Expenses';
    final netBalanceLabel = isArabic ? 'صافي الرصيد' : 'Net Balance';
    final categoryBreakdownLabel = isArabic ? 'تفاصيل التصنيفات' : 'Category Breakdown';
    final debtSummaryLabel = isArabic ? 'ملخص الديون' : 'Debt Summary';
    final borrowedLabel = isArabic ? 'اقترضت' : 'Borrowed';
    final lentLabel = isArabic ? 'أقرضت' : 'Lent';
    final netDebtLabel = isArabic ? 'صافي الديون' : 'Net Debt';
    final othersOweYouLabel = isArabic ? 'الآخرون مدينون لك' : 'Others owe you';
    final youOweOthersLabel = isArabic ? 'أنت مدين للآخرين' : 'You owe others';
    final transactionDetailsLabel = isArabic ? 'تفاصيل المعاملات' : 'Transaction Details';
    final dateLabel = isArabic ? 'التاريخ' : 'Date';
    final titleLabel = isArabic ? 'العنوان' : 'Title';
    final amountLabel = isArabic ? 'المبلغ' : 'Amount';
    final typeLabel = isArabic ? 'النوع' : 'Type';
    final currencyLabel = isArabic ? 'شيكل' : 'ILS';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pdfTheme,
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    reportTitle,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '$userLabel $userName',
                    style: pw.TextStyle(fontSize: 14, color: greyColor),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: isArabic ? pw.CrossAxisAlignment.start : pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    dateRangeLabel,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                    style: const pw.TextStyle(fontSize: 12),
                    textDirection: pw.TextDirection.ltr,
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 32),

          // Summary Cards
          pw.Row(
            children: [
              _buildSummaryBox(totalIncomeLabel, totalIncome, incomeColor),
              pw.SizedBox(width: 16),
              _buildSummaryBox(totalExpensesLabel, totalExpense, expenseColor),
              pw.SizedBox(width: 16),
              _buildSummaryBox(netBalanceLabel, netBalance, primaryColor),
            ],
          ),
          pw.SizedBox(height: 32),

          // Category Breakdown
          pw.Text(
            categoryBreakdownLabel,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: greyColor,
            ),
          ),
          pw.Divider(),
          pw.SizedBox(height: 8),
          ...categoryTotals.entries.map(
            (e) {
              final categoryDisplayName = isArabic
                  ? _getArabicCategoryName(e.key, categoryNameArMap)
                  : e.key;
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      categoryDisplayName,
                      textDirection: _detectTextDirection(categoryDisplayName),
                    ),
                    pw.Text(
                      '${e.value.toStringAsFixed(2)} $currencyLabel',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      textDirection: _detectTextDirection('${e.value.toStringAsFixed(2)} $currencyLabel'),
                    ),
                  ],
                ),
              );
            },
          ),
          pw.SizedBox(height: 32),

          // Debt Summary (if available)
          if (hasDebtData) ...[
            pw.Text(
              debtSummaryLabel,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: greyColor,
              ),
            ),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                _buildSummaryBox(borrowedLabel, totalBorrowed, expenseColor),
                pw.SizedBox(width: 16),
                _buildSummaryBox(lentLabel, totalLent, incomeColor),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border.all(
                  color: netDebt >= 0 ? incomeColor : expenseColor,
                  width: 1,
                ),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(netDebtLabel, style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        netDebt >= 0 ? othersOweYouLabel : youOweOthersLabel,
                        style: pw.TextStyle(fontSize: 8, color: greyColor),
                      ),
                    ],
                  ),
                  pw.Text(
                    '${netDebt.abs().toStringAsFixed(2)} $currencyLabel',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: netDebt >= 0 ? incomeColor : expenseColor,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 32),
          ],

          // Transaction Table
          pw.Text(
            transactionDetailsLabel,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: greyColor,
            ),
          ),
          pw.SizedBox(height: 8),
          _buildTransactionTable(
            isArabic: isArabic,
            transactions: transactions,
            dateFormat: dateFormat,
            primaryColor: primaryColor,
            dateLabel: dateLabel,
            titleLabel: titleLabel,
            amountLabel: amountLabel,
            typeLabel: typeLabel,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSummaryBox(
    String title,
    double amount,
    PdfColor color, {
    String currencySuffix = '',
  }) {
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
              '${amount.toStringAsFixed(2)}$currencySuffix',
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

  static String _getArabicCategoryName(String categoryName, Map<String, String> categoryNameArMap) {
    // Check user-created category Arabic names first
    final arName = categoryNameArMap[categoryName];
    if (arName != null && arName.isNotEmpty) {
      return arName;
    }

    // Handle special cases like 'Debt' / 'debt' directly
    if (categoryName.toLowerCase() == 'debt') {
      return 'دين';
    }

    // Map system category keys/names to Arabic
    String targetKey = categoryName;
    if (!categoryName.startsWith('cat_')) {
      targetKey = _getCategoryKey(categoryName) ?? categoryName;
    }

    const arabicCategoryMap = {
      'cat_food': 'طعام وشراب',
      'cat_shopping': 'تسوق',
      'cat_transportation': 'مواصلات',
      'cat_entertainment': 'ترفيه',
      'cat_bills': 'فواتير',
      'cat_income': 'دخل',
      'cat_home': 'منزل',
      'cat_haircut': 'حلاقة',
      'cat_health': 'صحة',
      'cat_education': 'تعليم',
      'cat_travel': 'سفر',
      'cat_gift': 'هدايا',
      'cat_other': 'أخرى',
      'cat_salary': 'راتب',
      'cat_investment': 'استثمار',
      'cat_freelance': 'عمل حر',
      'cat_debt': 'دين',
    };

    return arabicCategoryMap[targetKey] ?? categoryName;
  }

  static String? _getCategoryKey(String name) {
    final normalized = name.toLowerCase().trim();
    const mapping = {
      'food': 'cat_food',
      'food & drinks': 'cat_food',
      'shopping': 'cat_shopping',
      'transportation': 'cat_transportation',
      'entertainment': 'cat_entertainment',
      'bills': 'cat_bills',
      'income': 'cat_income',
      'home': 'cat_home',
      'hair cut': 'cat_haircut',
      'haircut': 'cat_haircut',
      'health': 'cat_health',
      'education': 'cat_education',
      'travel': 'cat_travel',
      'gift': 'cat_gift',
      'other': 'cat_other',
      'salary': 'cat_salary',
      'investment': 'cat_investment',
      'freelance': 'cat_freelance',
      'debt': 'cat_debt',
    };
    return mapping[normalized];
  }

  static pw.TextDirection _detectTextDirection(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return pw.TextDirection.ltr;
    for (final codeUnit in trimmed.runes) {
      // Arabic Unicode ranges
      if ((codeUnit >= 0x0600 && codeUnit <= 0x06FF) ||
          (codeUnit >= 0x0750 && codeUnit <= 0x077F) ||
          (codeUnit >= 0x08A0 && codeUnit <= 0x08FF) ||
          (codeUnit >= 0xFB50 && codeUnit <= 0xFDFF) ||
          (codeUnit >= 0xFE70 && codeUnit <= 0xFEFF)) {
        return pw.TextDirection.rtl;
      }
      // Latin character found first
      if ((codeUnit >= 0x0041 && codeUnit <= 0x005A) ||
          (codeUnit >= 0x0061 && codeUnit <= 0x007A)) {
        return pw.TextDirection.ltr;
      }
    }
    return pw.TextDirection.ltr;
  }

  static pw.Widget _buildTransactionTable({
    required bool isArabic,
    required List<TransactionModel> transactions,
    required DateFormat dateFormat,
    required PdfColor primaryColor,
    required String dateLabel,
    required String titleLabel,
    required String amountLabel,
    required String typeLabel,
  }) {
    final headerTexts = isArabic
        ? [typeLabel, amountLabel, titleLabel, dateLabel]
        : [dateLabel, titleLabel, amountLabel, typeLabel];

    final headerCells = headerTexts.map((h) => pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        h,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
        ),
        textDirection: _detectTextDirection(h),
      ),
    )).toList();

    final dataRows = transactions.map((tx) {
      final typeText = isArabic
          ? (tx.type == 'income' ? 'دخل' : 'مصروف')
          : tx.type.toUpperCase();
      final displayTitle = isArabic && tx.titleAr != null && tx.titleAr!.isNotEmpty
          ? tx.titleAr!
          : tx.title;
      final cells = isArabic
          ? [typeText, tx.amount.toStringAsFixed(2), displayTitle, dateFormat.format(tx.createdAt)]
          : [dateFormat.format(tx.createdAt), displayTitle, tx.amount.toStringAsFixed(2), typeText];

      return pw.TableRow(
        children: cells.map((cell) => pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            cell,
            textDirection: _detectTextDirection(cell),
          ),
        )).toList(),
      );
    }).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: isArabic
          ? {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(2.5),
              3: const pw.FlexColumnWidth(1.5),
            }
          : {
              0: const pw.FlexColumnWidth(1.5),
              1: const pw.FlexColumnWidth(2.5),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
            },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: primaryColor),
          children: headerCells,
        ),
        ...dataRows,
      ],
    );
  }

  /// Generate a PDF report for a specific friend's debt transactions
  static Future<Uint8List> generateFriendDebtReport({
    required FriendModel friend,
    required List<DebtTransactionModel> transactions,
    required double owesMe,
    required double iOwe,
    required String userName,
    bool isArabic = false,
  }) async {
    // Load Unicode fonts for proper character rendering (supports Arabic and Latin)
    final arabicRegular = await PdfGoogleFonts.notoSansArabicRegular();
    final arabicBold = await PdfGoogleFonts.notoSansArabicBold();
    final latinRegular = await PdfGoogleFonts.notoSansRegular();
    final latinBold = await PdfGoogleFonts.notoSansBold();

    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd');

    // Define colors from AppColors
    final incomeColor = PdfColor.fromInt(0xFF4CAF50);
    final expenseColor = PdfColor.fromInt(0xFFE53935);
    final greyColor = PdfColors.grey700;
    final purpleColor = PdfColor.fromInt(0xFF9C27B0);

    // Create theme with font fallbacks for both Arabic and Latin characters
    final pdfTheme = pw.ThemeData.withFont(
      base: arabicRegular,
      bold: arabicBold,
      fontFallback: [latinRegular, latinBold],
    );

    // Get display name based on locale preference
    final friendDisplayName = (isArabic &&
            friend.nameAr != null &&
            friend.nameAr!.isNotEmpty)
        ? friend.nameAr!
        : friend.name;

    // Calculate net balance
    final netBalance = owesMe - iOwe;

    // Labels based on language
    final reportTitle = isArabic ? 'تقرير الديون' : 'Debt Report';
    final friendLabel = isArabic ? 'الصديق:' : 'Friend:';
    final phoneLabel = isArabic ? 'الهاتف:' : 'Phone:';
    final preparedForLabel = isArabic ? 'تم إعداده لـ:' : 'Prepared for:';
    final generatedOnLabel = isArabic ? 'تاريخ الإنشاء:' : 'Generated on:';
    final owesMeLabel = isArabic ? 'مدين لي' : 'Owes Me';
    final iOweLabel = isArabic ? 'أنا مدين' : 'I Owe';
    final netBalanceLabel = isArabic ? 'صافي الرصيد' : 'Net Balance';
    final summaryLabel = isArabic ? 'ملخص الديون' : 'Debt Summary';
    final transactionsLabel = isArabic ? 'سجل المعاملات' : 'Transaction History';
    final dateLabel = isArabic ? 'التاريخ' : 'Date';
    final typeLabel = isArabic ? 'النوع' : 'Type';
    final amountLabel = isArabic ? 'المبلغ' : 'Amount';
    final statusLabel = isArabic ? 'الحالة' : 'Status';
    final settledLabel = isArabic ? 'مسدد' : 'Settled';
    final pendingLabel = isArabic ? 'قائم' : 'Pending';
    final noTransactionsLabel = isArabic ? 'لا توجد معاملات' : 'No transactions';
    final currencyLabel = isArabic ? 'شيكل' : 'ILS';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pdfTheme,
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        build: (context) => [
          // Header - Title centered at top
          pw.Center(
            child: pw.Text(
              reportTitle,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: purpleColor,
              ),
            ),
          ),
          pw.SizedBox(height: 16),
          
          // Two columns: Friend info and User info on same line
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: isArabic
                ? [
                    // LEFT for Arabic: User info (prepared for, date)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(
                                  text: preparedForLabel,
                                  style: pw.TextStyle(fontSize: 11, color: greyColor),
                                ),
                                pw.TextSpan(
                                  text: ' ${userName.isNotEmpty ? userName : "المستخدم"}',
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(
                                  text: generatedOnLabel,
                                  style: pw.TextStyle(fontSize: 11, color: greyColor),
                                ),
                                pw.TextSpan(
                                  text: ' ${dateFormat.format(DateTime.now())}',
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 20),
                    // RIGHT for Arabic: Friend info
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            '$friendLabel $friendDisplayName',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          if (friend.phoneNumber != null && friend.phoneNumber!.isNotEmpty)
                            pw.Text(
                              '$phoneLabel ${friend.phoneNumber}',
                              style: pw.TextStyle(fontSize: 11, color: greyColor),
                            ),
                        ],
                      ),
                    ),
                  ]
                : [
                    // LEFT for English: Friend info
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '$friendLabel $friendDisplayName',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          if (friend.phoneNumber != null && friend.phoneNumber!.isNotEmpty)
                            pw.Text(
                              '$phoneLabel ${friend.phoneNumber}',
                              style: pw.TextStyle(fontSize: 11, color: greyColor),
                            ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 20),
                    // RIGHT for English: User info
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(
                                  text: preparedForLabel,
                                  style: pw.TextStyle(fontSize: 11, color: greyColor),
                                ),
                                pw.TextSpan(
                                  text: ' ${userName.isNotEmpty ? userName : "User"}',
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(
                                  text: generatedOnLabel,
                                  style: pw.TextStyle(fontSize: 11, color: greyColor),
                                ),
                                pw.TextSpan(
                                  text: ' ${dateFormat.format(DateTime.now())}',
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
          ),
          pw.SizedBox(height: 32),

          // Summary Section
          pw.Text(
            summaryLabel,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: greyColor,
            ),
          ),
          pw.Divider(color: purpleColor),
          pw.SizedBox(height: 12),

          // Summary Cards
          pw.Row(
            children: [
              _buildSummaryBox(owesMeLabel, owesMe, incomeColor, currencySuffix: ' $currencyLabel'),
              pw.SizedBox(width: 16),
              _buildSummaryBox(iOweLabel, iOwe, expenseColor, currencySuffix: ' $currencyLabel'),
            ],
          ),
          pw.SizedBox(height: 16),

          // Net Balance Card
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(
                color: netBalance >= 0 ? incomeColor : expenseColor,
                width: 2,
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      netBalanceLabel,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      netBalance >= 0
                          ? (isArabic ? 'مدين لك' : 'They owe you')
                          : (isArabic ? 'أنت مدين له' : 'You owe them'),
                      style: pw.TextStyle(fontSize: 10, color: greyColor),
                    ),
                  ],
                ),
                pw.Text(
                  '${netBalance.abs().toStringAsFixed(2)} $currencyLabel',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: netBalance >= 0 ? incomeColor : expenseColor,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 32),

          // Transaction History
          pw.Text(
            transactionsLabel,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: greyColor,
            ),
          ),
          pw.Divider(color: purpleColor),
          pw.SizedBox(height: 12),

          if (transactions.isEmpty)
            pw.Center(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(32),
                child: pw.Text(
                  noTransactionsLabel,
                  style: pw.TextStyle(color: greyColor),
                ),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              headerDecoration: pw.BoxDecoration(color: purpleColor),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellHeight: 28,
              cellAlignments: isArabic
                  ? {
                      0: pw.Alignment.center,
                      1: pw.Alignment.centerRight,
                      2: pw.Alignment.center,
                      3: pw.Alignment.centerRight,
                    }
                  : {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.center,
                      2: pw.Alignment.centerRight,
                      3: pw.Alignment.center,
                    },
              headers: isArabic
                  ? [statusLabel, amountLabel, typeLabel, dateLabel]
                  : [dateLabel, typeLabel, amountLabel, statusLabel],
              data: transactions.map((tx) {
                String typeText;
                switch (tx.type) {
                  case DebtEventType.lend:
                    typeText = isArabic ? 'أقرضت' : 'Lent';
                    break;
                  case DebtEventType.borrow:
                    typeText = isArabic ? 'اقترضت' : 'Borrowed';
                    break;
                  case DebtEventType.settlePay:
                    typeText = isArabic ? 'دفعت' : 'Paid';
                    break;
                  case DebtEventType.settleReceive:
                    typeText = isArabic ? 'استلمت' : 'Received';
                    break;
                }
                return isArabic
                    ? [
                        tx.settled ? settledLabel : pendingLabel,
                        '${tx.amount.toStringAsFixed(2)} $currencyLabel',
                        typeText,
                        dateFormat.format(tx.date),
                      ]
                    : [
                        dateFormat.format(tx.date),
                        typeText,
                        '${tx.amount.toStringAsFixed(2)} $currencyLabel',
                        tx.settled ? settledLabel : pendingLabel,
                      ];
              }).toList(),
            ),

          // Transaction notes (if any)
          if (transactions.any((tx) => tx.note != null && tx.note!.isNotEmpty)) ...[
            pw.SizedBox(height: 24),
            pw.Text(
              isArabic ? 'الملاحظات' : 'Notes',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: greyColor,
              ),
            ),
            pw.SizedBox(height: 8),
            ...transactions
                .where((tx) => tx.note != null && tx.note!.isNotEmpty)
                .map((tx) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: isArabic 
                              ? pw.CrossAxisAlignment.end 
                              : pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              dateFormat.format(tx.date),
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: greyColor,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              tx.note!,
                              style: const pw.TextStyle(fontSize: 10),
                              textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                            ),
                          ],
                        ),
                      ),
                    )),
          ],
        ],
      ),
    );

    return pdf.save();
  }
}
