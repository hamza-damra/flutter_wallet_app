import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/providers/currency_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/update_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isCheckingUpdate = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);
    final isGlassy = themeMode == AppThemeMode.glassy;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background blobs for visual depth
          if (isGlassy) ...[
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.purple.withValues(alpha: 0.15),
                      Colors.purple.withValues(alpha: 0.0),
                    ],
                  ),
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
                  gradient: RadialGradient(
                    colors: [
                      Colors.blue.withValues(alpha: 0.12),
                      Colors.blue.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.primaryColor.withValues(alpha: 0.05),
                ),
              ),
            ),
          ],

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, l10n, theme, isGlassy),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Theme Section
                        _buildSectionHeader(
                          theme,
                          l10n.appTheme,
                          Icons.palette_outlined,
                          isGlassy,
                        ),
                        const SizedBox(height: 16),
                        _buildEnhancedThemeCard(
                          context,
                          ref,
                          l10n,
                          theme,
                          themeMode,
                        ),
                        const SizedBox(height: 28),

                        // Currency Section
                        _buildSectionHeader(
                          theme,
                          l10n.localeName == 'ar' ? 'العملة' : 'Currency',
                          Icons.attach_money_outlined,
                          isGlassy,
                        ),
                        const SizedBox(height: 16),
                        _buildCurrencyCard(context, ref, theme, isGlassy),
                        const SizedBox(height: 28),

                        // App Updates Section
                        _buildSectionHeader(
                          theme,
                          'App Updates',
                          Icons.system_update_outlined,
                          isGlassy,
                        ),
                        const SizedBox(height: 16),
                        _buildUpdateSection(context, ref, theme, isGlassy),
                        const SizedBox(height: 28),

                        // About Section
                        _buildSectionHeader(
                          theme,
                          l10n.about,
                          Icons.info_outline,
                          isGlassy,
                        ),
                        const SizedBox(height: 16),
                        _buildAboutCard(context, l10n, theme, isGlassy),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    bool isGlassy,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isGlassy
                  ? Colors.white.withValues(alpha: 0.1)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: isGlassy
                  ? Border.all(color: Colors.white.withValues(alpha: 0.15))
                  : null,
              boxShadow: isGlassy
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.appSettings,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
              Text(
                'Customize your experience',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isGlassy
                      ? Colors.white.withValues(alpha: 0.7)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    String title,
    IconData icon,
    bool isGlassy,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isGlassy
                ? Colors.white.withValues(alpha: 0.1)
                : theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isGlassy ? Colors.white : theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedThemeCard(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ThemeData theme,
    AppThemeMode currentThemeMode,
  ) {
    final isGlassy = currentThemeMode == AppThemeMode.glassy;

    final themes = [
      _ThemeOption(
        mode: AppThemeMode.classic,
        name: l10n.classicTheme,
        primaryColor: AppColors.primary,
        secondaryColor: AppColors.primaryLight,
        icon: Icons.wb_sunny_outlined,
        description: 'Warm & elegant',
      ),
      _ThemeOption(
        mode: AppThemeMode.modernDark,
        name: l10n.modernDarkTheme,
        primaryColor: AppColors.darkPrimary,
        secondaryColor: AppColors.darkSurface,
        icon: Icons.dark_mode_outlined,
        description: 'Sleek & modern',
      ),
      _ThemeOption(
        mode: AppThemeMode.oceanBlue,
        name: l10n.oceanBlueTheme,
        primaryColor: AppColors.oceanPrimary,
        secondaryColor: AppColors.oceanSecondary,
        icon: Icons.water_outlined,
        description: 'Fresh & calm',
      ),
      _ThemeOption(
        mode: AppThemeMode.glassy,
        name: l10n.glassyTheme,
        primaryColor: AppColors.glassyPrimary,
        secondaryColor: Colors.pink,
        icon: Icons.blur_on,
        description: 'Premium glass',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(
          alpha: isGlassy ? 0.35 : 1.0,
        ),
        borderRadius: BorderRadius.circular(24),
        border: isGlassy
            ? Border.all(color: Colors.white.withValues(alpha: 0.15))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isGlassy ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Grid of theme options
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.15,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: themes.length,
              itemBuilder: (context, index) {
                final themeOption = themes[index];
                final isSelected = currentThemeMode == themeOption.mode;
                return _buildEnhancedThemeOption(
                  context,
                  ref,
                  themeOption,
                  isSelected,
                  isGlassy,
                  theme,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedThemeOption(
    BuildContext context,
    WidgetRef ref,
    _ThemeOption themeOption,
    bool isSelected,
    bool isGlassy,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: () => ref.read(themeProvider.notifier).setTheme(themeOption.mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    themeOption.primaryColor.withValues(alpha: 0.2),
                    themeOption.secondaryColor.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : (isGlassy
                    ? Colors.white.withValues(alpha: 0.05)
                    : theme.colorScheme.surface),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? themeOption.primaryColor
                : (isGlassy
                      ? Colors.white.withValues(alpha: 0.1)
                      : theme.colorScheme.outline.withValues(alpha: 0.15)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: themeOption.primaryColor.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Color preview with gradient
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themeOption.primaryColor,
                    themeOption.secondaryColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeOption.primaryColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                isSelected ? Icons.check_rounded : themeOption.icon,
                color: Colors.white,
                size: isSelected ? 24 : 20,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              themeOption.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isGlassy
                    ? Colors.white.withValues(alpha: isSelected ? 1 : 0.8)
                    : (isSelected
                          ? themeOption.primaryColor
                          : theme.colorScheme.onSurface),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              themeOption.description,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: isGlassy
                    ? Colors.white.withValues(alpha: 0.5)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateSection(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isGlassy,
  ) {
    final updateService = ref.watch(updateServiceProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(
          alpha: isGlassy ? 0.35 : 1.0,
        ),
        borderRadius: BorderRadius.circular(20),
        border: isGlassy
            ? Border.all(color: Colors.white.withValues(alpha: 0.15))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isGlassy ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.teal.shade400],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.verified_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Version ${updateService.getInstalledVersionName()}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isGlassy
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your app is up to date',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isGlassy
                            ? Colors.white.withValues(alpha: 0.7)
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCheckingUpdate
                  ? null
                  : () async {
                      setState(() {
                        _isCheckingUpdate = true;
                      });

                      try {
                        final updateService = ref.read(updateServiceProvider);
                        // Reset session flag to allow showing dialog
                        updateService.resetSessionFlag();

                        // DEBUG: Print detailed update check info
                        debugPrint('========================================');
                        debugPrint('DEBUG: Check for Updates pressed');
                        debugPrint(
                          'DEBUG: Installed Version Code: ${updateService.getInstalledVersionCode()}',
                        );
                        debugPrint(
                          'DEBUG: Installed Version Name: ${updateService.getInstalledVersionName()}',
                        );

                        // Fetch remote config and show debug info
                        final updateInfo = await updateService
                            .fetchRemoteUpdateInfo();
                        if (updateInfo != null) {
                          debugPrint(
                            'DEBUG: Remote Latest Version Code: ${updateInfo.latestVersionCode}',
                          );
                          debugPrint(
                            'DEBUG: Remote Latest Version Name: ${updateInfo.latestVersionName}',
                          );
                          debugPrint(
                            'DEBUG: Remote APK URL: ${updateInfo.apkUrl}',
                          );
                          debugPrint(
                            'DEBUG: Force Update: ${updateInfo.forceUpdate}',
                          );
                          debugPrint(
                            'DEBUG: Min Supported Version: ${updateInfo.minSupportedVersionCode}',
                          );
                          debugPrint(
                            'DEBUG: Update Message: ${updateInfo.updateMessage}',
                          );
                          debugPrint(
                            'DEBUG: Has Valid APK URL: ${updateInfo.hasValidApkUrl}',
                          );

                          final requirement = updateService
                              .getUpdateRequirement(updateInfo);
                          debugPrint('DEBUG: Update Requirement: $requirement');
                        } else {
                          debugPrint(
                            'DEBUG: Failed to fetch remote update info (returned null)',
                          );
                        }
                        debugPrint('========================================');

                        // Trigger update check
                        if (context.mounted) {
                          final shown = await updateService
                              .checkAndPromptIfNeeded(
                                context,
                                bypassCooldown: true,
                              );
                          debugPrint('DEBUG: Update dialog shown: $shown');
                          if (!shown && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Your app is up to date!'),
                                  ],
                                ),
                                backgroundColor: Colors.green.shade600,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        }
                      } catch (e, stackTrace) {
                        debugPrint('DEBUG: Error checking updates: $e');
                        debugPrint('DEBUG: Stack trace: $stackTrace');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error checking updates: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isCheckingUpdate = false;
                          });
                        }
                      }
                    },
              icon: _isCheckingUpdate
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 20),
              label: Text(
                _isCheckingUpdate ? 'Checking...' : 'Check for Updates',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isGlassy
                    ? Colors.white.withValues(alpha: 0.15)
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                foregroundColor: isGlassy
                    ? Colors.white
                    : theme.colorScheme.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isGlassy
                        ? Colors.white.withValues(alpha: 0.2)
                        : theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    bool isGlassy,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(
          alpha: isGlassy ? 0.35 : 1.0,
        ),
        borderRadius: BorderRadius.circular(20),
        border: isGlassy
            ? Border.all(color: Colors.white.withValues(alpha: 0.15))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isGlassy ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAboutItem(
            theme,
            Icons.info_outline,
            l10n.about,
            l10n.aboutAppDescription,
            isGlassy,
          ),
          Divider(
            color: isGlassy
                ? Colors.white.withValues(alpha: 0.1)
                : theme.colorScheme.outline.withValues(alpha: 0.1),
            height: 24,
          ),
          _buildAboutItem(
            theme,
            Icons.code_rounded,
            l10n.version,
            '1.0.0 (Build 1)',
            isGlassy,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutItem(
    ThemeData theme,
    IconData icon,
    String title,
    String subtitle,
    bool isGlassy,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isGlassy
                ? Colors.white.withValues(alpha: 0.1)
                : theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isGlassy ? Colors.white : theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isGlassy
                      ? Colors.white.withValues(alpha: 0.7)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isGlassy,
  ) {
    final currentCurrency = ref.watch(currencyProvider);
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.localeName == 'ar';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(
          alpha: isGlassy ? 0.35 : 1.0,
        ),
        borderRadius: BorderRadius.circular(20),
        border: isGlassy
            ? Border.all(color: Colors.white.withValues(alpha: 0.15))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isGlassy ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.teal.shade400],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  currentCurrency.symbol,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? currentCurrency.nameAr : currentCurrency.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isGlassy
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentCurrency.code,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isGlassy
                            ? Colors.white.withValues(alpha: 0.7)
                            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCurrencyPicker(context, ref, theme, isGlassy),
              icon: const Icon(Icons.swap_horiz_rounded, size: 20),
              label: Text(isArabic ? 'تغيير العملة' : 'Change Currency'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isGlassy
                    ? Colors.white.withValues(alpha: 0.15)
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                foregroundColor: isGlassy
                    ? Colors.white
                    : theme.colorScheme.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isGlassy
                        ? Colors.white.withValues(alpha: 0.2)
                        : theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isGlassy,
  ) {
    final currentCurrency = ref.read(currencyProvider);
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.localeName == 'ar';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: isGlassy
              ? const Color(0xFF1E1B4B).withValues(alpha: 0.95)
              : theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isArabic ? 'اختر العملة' : 'Select Currency',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: supportedCurrencies.length,
                itemBuilder: (context, index) {
                  final currency = supportedCurrencies[index];
                  final isSelected = currency.code == currentCurrency.code;
                  return ListTile(
                    onTap: () {
                      ref.read(currencyProvider.notifier).setCurrency(currency);
                      Navigator.pop(context);
                    },
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.primaryColor.withValues(alpha: 0.2)
                            : (isGlassy
                                ? Colors.white.withValues(alpha: 0.1)
                                : theme.colorScheme.surfaceContainerHighest),
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: theme.primaryColor, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          currency.symbol,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? theme.primaryColor
                                : (isGlassy
                                    ? Colors.white
                                    : theme.colorScheme.onSurface),
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      isArabic ? currency.nameAr : currency.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isGlassy ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      currency.code,
                      style: TextStyle(
                        color: isGlassy
                            ? Colors.white.withValues(alpha: 0.6)
                            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: theme.primaryColor)
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Helper class for theme options
class _ThemeOption {
  final AppThemeMode mode;
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;
  final String description;

  const _ThemeOption({
    required this.mode,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
    required this.description,
  });
}
