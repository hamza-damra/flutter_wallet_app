// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'My Wallet';

  @override
  String get loginTitle => 'Login to your account';

  @override
  String get loginButton => 'Login';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerButton => 'Register';

  @override
  String get emailHint => 'Email';

  @override
  String get passwordHint => 'Password';

  @override
  String get confirmPasswordHint => 'Confirm Password';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get welcomeBack => 'Welcome back! Please enter your details.';

  @override
  String get createAccountToStart =>
      'Create an account to start tracking your finances.';

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get enterYourPassword => 'Enter your password';

  @override
  String get createAPassword => 'Create a password';

  @override
  String get welcome => 'Welcome,';

  @override
  String get totalBalance => 'Total Balance';

  @override
  String get income => 'Income';

  @override
  String get expenses => 'Expenses';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get addTransaction => 'Add Transaction';

  @override
  String get categories => 'Categories';

  @override
  String get noTransactions => 'No transactions yet';

  @override
  String get startTrackingFinances =>
      'Start tracking your finances by adding your first transaction';

  @override
  String get add => 'Add';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get confirm => 'Confirm';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get done => 'Done';

  @override
  String get retry => 'Retry';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get sort => 'Sort';

  @override
  String get clear => 'Clear';

  @override
  String get reset => 'Reset';

  @override
  String get apply => 'Apply';

  @override
  String get category => 'Category';

  @override
  String get amount => 'Amount';

  @override
  String get title => 'Title';

  @override
  String get type => 'Type';

  @override
  String get date => 'Date';

  @override
  String get description => 'Description';

  @override
  String get notes => 'Notes';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get warning => 'Warning';

  @override
  String get info => 'Info';

  @override
  String get loading => 'Loading...';

  @override
  String get noData => 'No data available';

  @override
  String get noResults => 'No results found';

  @override
  String get connectionError => 'Connection error. Please check your internet.';

  @override
  String get unknownError => 'An unknown error occurred';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get account => 'Account';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get appSettings => 'App Settings';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get about => 'About';

  @override
  String get logout => 'Logout';

  @override
  String get version => 'Version';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get cat_food => 'Food & Drinks';

  @override
  String get cat_shopping => 'Shopping';

  @override
  String get cat_transportation => 'Transportation';

  @override
  String get cat_entertainment => 'Entertainment';

  @override
  String get cat_bills => 'Bills';

  @override
  String get cat_income => 'Income';

  @override
  String get cat_home => 'Home';

  @override
  String get cat_haircut => 'Hair Cut';

  @override
  String get cat_health => 'Health';

  @override
  String get cat_education => 'Education';

  @override
  String get cat_travel => 'Travel';

  @override
  String get cat_gift => 'Gift';

  @override
  String get cat_other => 'Other';

  @override
  String get cat_salary => 'Salary';

  @override
  String get cat_investment => 'Investment';

  @override
  String get cat_freelance => 'Freelance';

  @override
  String get newTransaction => 'New Transaction';

  @override
  String get enterAmount => 'Enter amount';

  @override
  String get enterTitle => 'Enter title';

  @override
  String get enterTitleEn => 'Title (English)';

  @override
  String get enterTitleAr => 'Title (Arabic)';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get expenseType => 'Expense';

  @override
  String get incomeType => 'Income';

  @override
  String get pleaseEnterTitle => 'Please enter a title';

  @override
  String get pleaseEnterAmount => 'Please enter a valid amount';

  @override
  String get pleaseSelectCategory => 'Please select a category';

  @override
  String get transactionAdded => 'Transaction added successfully';

  @override
  String get transactionUpdated => 'Transaction updated successfully';

  @override
  String get editTransaction => 'Edit Transaction';

  @override
  String get transactionDeleted => 'Transaction deleted successfully';

  @override
  String get addCategory => 'Add Category';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get enterCategoryName => 'Enter category name...';

  @override
  String get enterCategoryNameEn => 'Category Name (English)';

  @override
  String get enterCategoryNameAr => 'Category Name (Arabic)';

  @override
  String get addNewCategory => 'Add New Category';

  @override
  String get selectIcon => 'Select Icon';

  @override
  String get categoryAdded => 'Category added successfully';

  @override
  String get categoryUpdated => 'Category updated successfully';

  @override
  String get categoryDeleted => 'Category deleted successfully';

  @override
  String deleteCategoryConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get noCategoriesFound => 'No categories found';

  @override
  String get tapToAddCategory => 'Tap + to add your first category';

  @override
  String get expenseCategories => 'Expense Categories';

  @override
  String get incomeCategories => 'Income Categories';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String comingSoon(String feature) {
    return '$feature coming soon!';
  }

  @override
  String get aboutAppDescription =>
      'A simple and beautiful wallet app to track your income and expenses.';

  @override
  String get close => 'Close';

  @override
  String transactionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
      zero: 'No transactions',
    );
    return '$_temp0';
  }

  @override
  String categoryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categories',
      one: '1 category',
      zero: 'No categories',
    );
    return '$_temp0';
  }

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String daysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days ago',
      one: 'Yesterday',
      zero: 'Today',
    );
    return '$_temp0';
  }

  @override
  String currencyFormat(double amount) {
    final intl.NumberFormat amountNumberFormat = intl.NumberFormat.currency(
      locale: localeName,
      symbol: '₪',
      decimalDigits: 2,
    );
    final String amountString = amountNumberFormat.format(amount);

    return '$amountString';
  }

  @override
  String dateFormatFull(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String dateFormatShort(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get allCategories => 'All Categories';

  @override
  String get manageCategories => 'Manage Categories';

  @override
  String get viewAll => 'View All';

  @override
  String get seeMore => 'See More';

  @override
  String get showLess => 'Show Less';

  @override
  String get deleteTransactionConfirm =>
      'Are you sure you want to delete this transaction?';

  @override
  String get cannotBeUndone => 'This action cannot be undone.';

  @override
  String get amountValidation => 'Amount must be greater than 0';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get passwordResetSent => 'Password reset link sent to your email';

  @override
  String get deleteTransaction => 'Delete Transaction';

  @override
  String get transactionDetails => 'Transaction Details';

  @override
  String get reports => 'Reports';

  @override
  String get reportSummary => 'Report Summary';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get generatePdf => 'Generate PDF';

  @override
  String get shareAsImage => 'Share as Image';

  @override
  String get shareAsPdf => 'Share as PDF';

  @override
  String get netBalance => 'Net Balance';

  @override
  String get totalIncome => 'Total Income';

  @override
  String get totalExpenses => 'Total Expenses';

  @override
  String get categoriesBreakdown => 'Categories Breakdown';

  @override
  String get selectDateRange => 'Select Date Range';

  @override
  String get shareReport => 'Share Report';

  @override
  String get financialReport => 'Financial Report';

  @override
  String get preparedFor => 'Prepared for';

  @override
  String get profile => 'Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get phoneHint => 'Phone Number';

  @override
  String get displayNameHint => 'Full Name';

  @override
  String get nameArHint => 'Name (Arabic)';

  @override
  String get nameEnHint => 'Name (English)';

  @override
  String get updateProfile => 'Update Profile';

  @override
  String get profileUpdated => 'Profile updated successfully';

  @override
  String get appTheme => 'App Theme';

  @override
  String get classicTheme => 'Classic Premium';

  @override
  String get modernDarkTheme => 'Modern Dark';

  @override
  String get oceanBlueTheme => 'Ocean Blue';

  @override
  String get glassyTheme => 'Glassy Vivid';

  @override
  String get transactionId => 'Transaction ID';

  @override
  String get manageTransactions => 'Manage Transactions';

  @override
  String get thisMonth => 'This Month';

  @override
  String get lastMonth => 'Last Month';

  @override
  String get last30Days => 'Last 30 Days';

  @override
  String get thisYear => 'This Year';

  @override
  String get applyFilter => 'Apply Filter';

  @override
  String get updateAvailable => 'Update Available';

  @override
  String get updateNow => 'Update Now';

  @override
  String get later => 'Later';

  @override
  String get currentVersion => 'Current Version';

  @override
  String get newVersion => 'New Version';

  @override
  String get updateRequired =>
      'This update is required to continue using the app.';

  @override
  String get dontRemindVersion => 'Don\'t remind me for this version';

  @override
  String get updateMessage =>
      'A new version is available with bug fixes and improvements.';

  @override
  String get downloadFailed => 'Failed to open download link';
}
