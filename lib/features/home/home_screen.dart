import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../core/models/transaction_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/localization/localization_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/sync_service.dart';
import '../../services/update_service.dart';
import 'widgets/balance_card.dart';
import 'widgets/recent_transactions.dart';
import '../../core/widgets/connectivity_indicator.dart';
import 'providers/home_stats_provider.dart';
import '../../core/constants/app_avatars.dart';
import '../help/help_support_screen.dart';

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
    // Seed check using currentUser if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authServiceProvider).currentUser;
      if (user != null) {
        ref.read(firestoreServiceProvider).seedDefaultCategories(user.uid);
      }

      // Check for updates on app launch
      ref.read(updateServiceProvider).checkAndPromptIfNeeded(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for sync conflicts
    ref.listen(syncConflictProvider, (previous, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
          ),
        );
        ref.read(syncConflictProvider.notifier).setMessage(null);
      }
    });

    final user = ref.watch(authServiceProvider).currentUser;
    final transactionsAsync = ref.watch(transactionsProvider(user?.uid ?? ''));
    final homeStatsAsync = ref.watch(homeStatsProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);

    // Get computed stats from reactive provider
    final stats = homeStatsAsync.value ?? const HomeStats();
    final totalBalance = stats.totalBalance;
    final income = stats.income;
    final expense = stats.expense;

    // Get recent transactions for display
    List<TransactionModel> recentTransactions = [];
    transactionsAsync.whenData((transactions) {
      recentTransactions = transactions;
    });

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: _buildDrawer(context, user),
      body: Stack(
        children: [
          // Theme-based background
          if (themeMode == AppThemeMode.glassy)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F172A),
                      Color(0xFF1E1B4B),
                      Color(0xFF312E81),
                    ],
                  ),
                ),
              ),
            ),

          // Decorative background elements
          if (themeMode != AppThemeMode.glassy) ...[
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.primaryColor.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              top: 400,
              left: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.income.withValues(alpha: 0.03),
                ),
              ),
            ),
          ] else ...[
            // Glassy Mesh Blobs
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.pink.withValues(alpha: 0.2),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withValues(alpha: 0.15),
                ),
              ),
            ),
          ],

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        _buildHeader(context, user),
                        const SizedBox(height: 32),

                        // Balance Card
                        GestureDetector(
                          onTap: () => context.push('/reports'),
                          child: BalanceCard(
                            totalBalance: totalBalance,
                            income: income,
                            expense: expense,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Categories Quick Access Card
                        GestureDetector(
                          onTap: () => context.push('/categories'),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(
                                alpha: themeMode == AppThemeMode.glassy
                                    ? 0.3
                                    : 1.0,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: themeMode == AppThemeMode.glassy
                                  ? Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                    )
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Icon Container
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.primaryColor.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.category_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Text Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.categories,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        l10n.manageCategories,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Arrow Indicator
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    color: theme.primaryColor,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Recent Transactions Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                l10n.recentTransactions,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  context.push('/transactions-history'),
                              child: Text(
                                l10n.viewAll,
                                style: TextStyle(color: theme.primaryColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Transactions List
                        transactionsAsync.when(
                          data: (_) => RecentTransactions(
                            transactions: recentTransactions,
                            onAddPressed: () =>
                                context.push('/new-transaction'),
                          ),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => Center(
                            child: Text(
                              '${l10n.error}: $err',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
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
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/new-transaction'),
          backgroundColor: theme.primaryColor,
          elevation: 0,
          icon: Icon(Icons.add_rounded, color: theme.colorScheme.onPrimary),
          label: Text(
            l10n.addTransaction,
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, user) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);
    final isGlassy = themeMode == AppThemeMode.glassy;

    final profile = ref.watch(userProfileProvider).value;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Menu button - professional design
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isGlassy
                    ? Colors.white.withValues(alpha: 0.1)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isGlassy
                      ? Colors.white.withValues(alpha: 0.15)
                      : theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
                boxShadow: isGlassy
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Icon(
                Icons.menu_rounded,
                size: 22,
                color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // User info section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.welcome,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isGlassy
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                profile?.getLocalizedName(
                      Localizations.localeOf(context).languageCode,
                    ) ??
                    user?.email?.split('@')[0] ??
                    'User',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              const ConnectivityIndicator(),
            ],
          ),
        ),
        // Profile action
        Row(
          children: [
            // Profile avatar
            GestureDetector(
              onTap: () => context.push('/profile'),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isGlassy
                        ? const Color(0xFF1E1B4B)
                        : theme.scaffoldBackgroundColor,
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: isGlassy
                        ? Colors.white.withValues(alpha: 0.1)
                        : theme.primaryColor.withValues(alpha: 0.1),
                    child: SvgPicture.asset(
                      'assets/illustrations/avatar_placeholder.svg',
                      width: 20,
                      height: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
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
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 24,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: ref
                .watch(userProfileProvider)
                .when(
                  data: (profile) => Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(4),
                        child: ClipOval(
                          child: profile?.photoUrl != null
                              ? AppAvatars.isAppAvatar(profile!.photoUrl)
                                  ? SvgPicture.asset(
                                      profile.photoUrl!,
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      profile.photoUrl!,
                                      fit: BoxFit.cover,
                                    )
                              : SvgPicture.asset(
                                  'assets/illustrations/avatar_placeholder.svg',
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profile?.getLocalizedName(
                              Localizations.localeOf(context).languageCode,
                            ) ??
                            user?.email?.split('@')[0] ??
                            'User',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  error: (err, _) =>
                      const Icon(Icons.error, color: Colors.white),
                ),
          ),

          // Menu Items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                children: [
                  _buildDrawerItem(
                    icon: Icons.person_outline,
                    title: l10n.profile,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/profile');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.analytics_outlined,
                    title: l10n.reports,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/reports');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.handshake_outlined,
                    title: l10n.debtsTitle,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/debts');
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
                      context.push('/settings');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_outline,
                    title: l10n.helpSupport,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpSupportScreen(),
                        ),
                      );
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
                ],
              ),
            ),
          ),

          // Logout Button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmLogout();
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: Text(l10n.logout),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.error.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),

          // Version
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              '${l10n.version} 1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            )
          : null,
      trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withValues(alpha: 0.5), size: 20),
      onTap: onTap,
    );
  }

  void _showLanguageDialog() {
    final currentLocale = ref.read(localizationProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final themeMode = ref.read(themeProvider);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: themeMode == AppThemeMode.glassy
                    ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                    : theme.colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: themeMode == AppThemeMode.glassy
                    ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.translate_rounded,
                      color: theme.primaryColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.selectLanguage,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: themeMode == AppThemeMode.glassy
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildLanguageItem(
                    context,
                    flag: '🇺🇸',
                    name: l10n.english,
                    isSelected: currentLocale.languageCode == 'en',
                    themeMode: themeMode,
                    onTap: () {
                      ref
                          .read(localizationProvider.notifier)
                          .setLocale(const Locale('en'));
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildLanguageItem(
                    context,
                    flag: '🇸🇦',
                    name: l10n.arabic,
                    isSelected: currentLocale.languageCode == 'ar',
                    themeMode: themeMode,
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
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageItem(
    BuildContext context, {
    required String flag,
    required String name,
    required bool isSelected,
    required VoidCallback onTap,
    required AppThemeMode themeMode,
  }) {
    final theme = Theme.of(context);
    final borderColor = isSelected
        ? theme.primaryColor
        : (themeMode == AppThemeMode.glassy
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.transparent);

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? theme.primaryColor.withValues(alpha: 0.1)
            : (themeMode == AppThemeMode.glassy
                  ? Colors.white.withValues(alpha: 0.05)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.02)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Text(flag, style: const TextStyle(fontSize: 24)),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? theme.primaryColor
                : (themeMode == AppThemeMode.glassy
                      ? Colors.white
                      : theme.colorScheme.onSurface),
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: theme.primaryColor)
            : null,
      ),
    );
  }

  void _showAboutDialog() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final themeMode = ref.read(themeProvider);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: themeMode == AppThemeMode.glassy
                    ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                    : theme.colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: themeMode == AppThemeMode.glassy
                    ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor,
                          theme.primaryColor.withValues(alpha: 0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.appName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: themeMode == AppThemeMode.glassy
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${l10n.version} 1.0.0',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: themeMode == AppThemeMode.glassy
                          ? Colors.white.withValues(alpha: 0.5)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeMode == AppThemeMode.glassy
                          ? Colors.white.withValues(alpha: 0.05)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      l10n.aboutAppDescription,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: themeMode == AppThemeMode.glassy
                            ? Colors.white.withValues(alpha: 0.8)
                            : theme.colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Developer Info Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor.withValues(alpha: 0.1),
                          theme.primaryColor.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'تم التطوير بواسطة'
                              : 'Developed by',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: themeMode == AppThemeMode.glassy
                                ? Colors.white.withValues(alpha: 0.6)
                                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Eng. Hamza Damra',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: themeMode == AppThemeMode.glassy
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 16,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'hamzadamra321@gmail.com',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: themeMode == AppThemeMode.glassy
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 16,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '0593690711',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: themeMode == AppThemeMode.glassy
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        l10n.close,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Reset session flag to allow manual check
                        ref.read(updateServiceProvider).resetSessionFlag();
                        // Check for updates
                        ref
                            .read(updateServiceProvider)
                            .checkAndPromptIfNeeded(context)
                            .then((shown) {
                              if (!shown && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      Localizations.localeOf(
                                                context,
                                              ).languageCode ==
                                              'ar'
                                          ? 'التطبيق محدث لأحدث إصدار'
                                          : 'App is up to date',
                                    ),
                                  ),
                                );
                              }
                            });
                      },
                      icon: Icon(
                        Icons.system_update,
                        color: themeMode == AppThemeMode.glassy
                            ? Colors.white
                            : theme.primaryColor,
                      ),
                      label: Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 'تحقق من التحديثات'
                            : 'Check for Updates',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: themeMode == AppThemeMode.glassy
                              ? Colors.white
                              : theme.primaryColor,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: themeMode == AppThemeMode.glassy
                              ? Colors.white.withValues(alpha: 0.2)
                              : theme.primaryColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmLogout() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final themeMode = ref.read(themeProvider);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: themeMode == AppThemeMode.glassy
                    ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                    : theme.colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: themeMode == AppThemeMode.glassy
                    ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.logout,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: themeMode == AppThemeMode.glassy
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.logoutConfirm,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: themeMode == AppThemeMode.glassy
                          ? Colors.white.withValues(alpha: 0.6)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: themeMode == AppThemeMode.glassy
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : theme.dividerColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            l10n.cancel,
                            style: TextStyle(
                              color: themeMode == AppThemeMode.glassy
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ref.read(authServiceProvider).signOut();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            l10n.logout,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
