import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../core/models/transaction_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/localization/localization_provider.dart';
import '../../core/utils/direction_helper.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'widgets/balance_card.dart';
import 'widgets/recent_transactions.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    ref.read(firestoreServiceProvider).seedDefaultCategories();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
    final transactionsAsync = ref.watch(transactionsProvider(user?.uid ?? ''));
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Calculate totals
    double totalBalance = 0;
    double income = 0;
    double expense = 0;
    List<TransactionModel> recentTransactions = [];

    transactionsAsync.whenData((transactions) {
      for (var tx in transactions) {
        if (tx.type == 'income') {
          income += tx.amount;
          totalBalance += tx.amount;
        } else {
          expense += tx.amount;
          totalBalance -= tx.amount;
        }
      }
      recentTransactions = transactions;
    });

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(context, user),
      body: SafeArea(
        child: SingleChildScrollView(
          // Use EdgeInsetsDirectional for horizontal padding
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context, user),
              const SizedBox(height: 20),

              // Categories Link Card
              GestureDetector(
                onTap: () => context.push('/categories'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsetsDirectional.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    boxShadow: AppShadows.button,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.grid_view, color: Colors.white),
                          const SizedBox(width: 12),
                          Text(
                            l10n.categories,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(51),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '9',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Balance Card
              BalanceCard(
                totalBalance: totalBalance,
                income: income,
                expense: expense,
              ),
              const SizedBox(height: 28),

              // Recent Transactions Header
              Text(
                l10n.recentTransactions,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              // Transactions List
              transactionsAsync.when(
                data: (_) => RecentTransactions(
                  transactions: recentTransactions,
                  onAddPressed: () => context.push('/new-transaction'),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) =>
                    Center(child: Text('${l10n.error}: $err')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, user) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Row(
      children: [
        // Menu Button
        GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.menu,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // User Info
        Expanded(
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: SvgPicture.asset(
                    'assets/illustrations/avatar_placeholder.svg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.welcome,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      user?.email?.split('@')[0] ?? 'User',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: isSmallScreen ? 16 : 18,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Add Button
        ElevatedButton.icon(
          onPressed: () => context.push('/new-transaction'),
          icon: const Icon(Icons.add, size: 18),
          label: Text(isSmallScreen ? '' : l10n.add),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: 10,
            ),
            minimumSize: const Size(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, user) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Determine current language name for subtitle
    final currentLocale = ref.watch(localizationProvider);
    String languageName = 'English';
    if (currentLocale.languageCode == 'ar') {
      languageName = 'العربية';
    }

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsetsDirectional.all(24),
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: SvgPicture.asset(
                        'assets/illustrations/avatar_placeholder.svg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.email?.split('@')[0] ?? 'User',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withAlpha(204),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items
            const SizedBox(height: 16),

            _buildDrawerItem(
              icon: Icons.person_outline,
              title: l10n.account,
              onTap: () {
                Navigator.pop(context);
                _showComingSoonSnackbar(l10n.account);
              },
            ),

            _buildDrawerItem(
              icon: Icons.language,
              title: l10n.language,
              subtitle: languageName,
              onTap: () {
                Navigator.pop(context);
                _showLanguageDialog();
              },
            ),

            _buildDrawerItem(
              icon: Icons.settings_outlined,
              title: l10n.appSettings,
              onTap: () {
                Navigator.pop(context);
                _showComingSoonSnackbar(l10n.appSettings);
              },
            ),

            _buildDrawerItem(
              icon: Icons.help_outline,
              title: l10n.helpSupport,
              onTap: () {
                Navigator.pop(context);
                _showComingSoonSnackbar(l10n.helpSupport);
              },
            ),

            _buildDrawerItem(
              icon: Icons.info_outline,
              title: l10n.about,
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog();
              },
            ),

            const Spacer(),

            // Logout Button
            Padding(
              padding: const EdgeInsetsDirectional.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmLogout();
                  },
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  label: Text(
                    l10n.logout,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsetsDirectional.symmetric(
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

            // Version
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 16),
              child: Text(
                '${l10n.version} 1.0.0',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            )
          : null,
      // Use direction-aware chevron icon
      trailing: DirectionalIcon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showComingSoonSnackbar(String feature) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.comingSoon(feature)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLanguageDialog() {
    final currentLocale = ref.read(localizationProvider);
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇺🇸'),
              title: Text(l10n.english),
              trailing: currentLocale.languageCode == 'en'
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                ref
                    .read(localizationProvider.notifier)
                    .setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇸🇦'),
              title: Text(l10n.arabic),
              trailing: currentLocale.languageCode == 'ar'
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                ref
                    .read(localizationProvider.notifier)
                    .setLocale(const Locale('ar'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.account_balance_wallet, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(l10n.appName),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.version} 1.0.0', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Text(
              l10n.aboutAppDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authServiceProvider).signOut();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}
