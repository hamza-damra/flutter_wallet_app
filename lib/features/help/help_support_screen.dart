import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

import '../../l10n/app_localizations.dart';
import '../../core/theme/theme_provider.dart';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final features = _getFeatures(isArabic);

    return Scaffold(
      extendBodyBehindAppBar: themeMode == AppThemeMode.glassy,
      appBar: AppBar(
        title: Text(l10n.helpSupport),
        backgroundColor: themeMode == AppThemeMode.glassy
            ? Colors.transparent
            : theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: Container(
        decoration: themeMode == AppThemeMode.glassy
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B),
                    theme.primaryColor.withValues(alpha: 0.3),
                  ],
                ),
              )
            : null,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Section
              _buildHeader(theme, themeMode, isArabic),
              const SizedBox(height: 24),
              
              // Features List
              ...features.map((feature) => _buildFeatureCard(
                context,
                theme,
                themeMode,
                feature,
              )),
              
              const SizedBox(height: 24),
              
              // Contact Section
              _buildContactSection(theme, themeMode, isArabic),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, AppThemeMode themeMode, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor,
            theme.primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isArabic ? 'مرحباً بك في المساعدة' : 'Welcome to Help Center',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'تعرف على جميع ميزات التطبيق'
                : 'Learn about all app features',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    ThemeData theme,
    AppThemeMode themeMode,
    FeatureItem feature,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: themeMode == AppThemeMode.glassy
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: _buildFeatureCardContent(theme, themeMode, feature),
              )
            : _buildFeatureCardContent(theme, themeMode, feature),
      ),
    );
  }

  Widget _buildFeatureCardContent(
    ThemeData theme,
    AppThemeMode themeMode,
    FeatureItem feature,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeMode == AppThemeMode.glassy
            ? Colors.white.withValues(alpha: 0.1)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: themeMode == AppThemeMode.glassy
            ? Border.all(color: Colors.white.withValues(alpha: 0.1))
            : null,
        boxShadow: themeMode != AppThemeMode.glassy
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: feature.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              feature.icon,
              color: feature.color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: themeMode == AppThemeMode.glassy
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  feature.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: themeMode == AppThemeMode.glassy
                        ? Colors.white.withValues(alpha: 0.7)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(ThemeData theme, AppThemeMode themeMode, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeMode == AppThemeMode.glassy
            ? Colors.white.withValues(alpha: 0.1)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: themeMode == AppThemeMode.glassy
            ? Border.all(color: Colors.white.withValues(alpha: 0.1))
            : null,
      ),
      child: Column(
        children: [
          Icon(
            Icons.support_agent_rounded,
            size: 48,
            color: theme.primaryColor,
          ),
          const SizedBox(height: 12),
          Text(
            isArabic ? 'هل تحتاج مساعدة إضافية؟' : 'Need more help?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeMode == AppThemeMode.glassy
                  ? Colors.white
                  : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'تواصل معنا على البريد الإلكتروني'
                : 'Contact us via email',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: themeMode == AppThemeMode.glassy
                  ? Colors.white.withValues(alpha: 0.7)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'hamzadamra321@gmail.com',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<FeatureItem> _getFeatures(bool isArabic) {
    return [
      FeatureItem(
        icon: Icons.account_balance_wallet_rounded,
        title: isArabic ? 'تتبع المعاملات' : 'Track Transactions',
        description: isArabic
            ? 'أضف وتتبع جميع معاملاتك المالية بسهولة. سجل الدخل والمصروفات مع التصنيفات والملاحظات.'
            : 'Add and track all your financial transactions easily. Record income and expenses with categories and notes.',
        color: Colors.blue,
      ),
      FeatureItem(
        icon: Icons.category_rounded,
        title: isArabic ? 'إدارة الفئات' : 'Manage Categories',
        description: isArabic
            ? 'أنشئ فئات مخصصة لتنظيم معاملاتك. اختر الأيقونات والألوان لكل فئة.'
            : 'Create custom categories to organize your transactions. Choose icons and colors for each category.',
        color: Colors.purple,
      ),
      FeatureItem(
        icon: Icons.people_rounded,
        title: isArabic ? 'إدارة الديون' : 'Debt Management',
        description: isArabic
            ? 'تتبع الأموال التي أقرضتها أو استعرتها من الأصدقاء. احتفظ بسجل واضح لجميع الديون.'
            : 'Track money you lent or borrowed from friends. Keep a clear record of all debts.',
        color: Colors.orange,
      ),
      FeatureItem(
        icon: Icons.pie_chart_rounded,
        title: isArabic ? 'التقارير والإحصائيات' : 'Reports & Statistics',
        description: isArabic
            ? 'اعرض تقارير مفصلة عن إنفاقك. حلل عاداتك المالية مع الرسوم البيانية.'
            : 'View detailed reports of your spending. Analyze your financial habits with charts.',
        color: Colors.teal,
      ),
      FeatureItem(
        icon: Icons.sync_rounded,
        title: isArabic ? 'المزامنة السحابية' : 'Cloud Sync',
        description: isArabic
            ? 'تتم مزامنة بياناتك تلقائياً مع السحابة. الوصول إلى بياناتك من أي جهاز.'
            : 'Your data is automatically synced to the cloud. Access your data from any device.',
        color: Colors.green,
      ),
      FeatureItem(
        icon: Icons.dark_mode_rounded,
        title: isArabic ? 'السمات المتعددة' : 'Multiple Themes',
        description: isArabic
            ? 'اختر من بين السمة الفاتحة والداكنة والزجاجية. خصص مظهر التطبيق حسب رغبتك.'
            : 'Choose from light, dark, and glassy themes. Customize the app appearance to your preference.',
        color: Colors.indigo,
      ),
      FeatureItem(
        icon: Icons.language_rounded,
        title: isArabic ? 'دعم اللغات' : 'Language Support',
        description: isArabic
            ? 'التطبيق يدعم اللغة العربية والإنجليزية. غيّر اللغة في أي وقت من الإعدادات.'
            : 'The app supports Arabic and English. Change the language anytime from settings.',
        color: Colors.pink,
      ),
      FeatureItem(
        icon: Icons.offline_bolt_rounded,
        title: isArabic ? 'العمل بدون إنترنت' : 'Offline Mode',
        description: isArabic
            ? 'استخدم التطبيق حتى بدون اتصال بالإنترنت. ستتم المزامنة عند الاتصال.'
            : 'Use the app even without internet connection. Data will sync when connected.',
        color: Colors.amber,
      ),
    ];
  }
}

class FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
