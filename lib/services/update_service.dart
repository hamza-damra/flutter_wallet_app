import 'dart:developer';
import 'dart:ui';

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/localization/localization_provider.dart';

/// Data class representing update information from Firebase Remote Config
class UpdateInfo {
  final String latestVersionName;
  final int latestVersionCode;
  final String apkUrl;
  final bool forceUpdate;
  final String updateMessage;
  final int minSupportedVersionCode;

  const UpdateInfo({
    required this.latestVersionName,
    required this.latestVersionCode,
    required this.apkUrl,
    required this.forceUpdate,
    required this.updateMessage,
    required this.minSupportedVersionCode,
  });

  factory UpdateInfo.fromRemoteConfig(FirebaseRemoteConfig config) {
    return UpdateInfo(
      latestVersionName: config.getString('latest_version_name'),
      latestVersionCode: config.getInt('latest_version_code'),
      apkUrl: config.getString('apk_url'),
      forceUpdate: config.getBool('force_update'),
      updateMessage: config.getString('update_message'),
      minSupportedVersionCode: config.getInt('min_supported_version_code'),
    );
  }

  /// Returns true if the APK URL is valid (HTTPS and non-empty)
  bool get hasValidApkUrl =>
      apkUrl.isNotEmpty && apkUrl.toLowerCase().startsWith('https://');
}

/// Enum representing the type of update required
enum UpdateRequirement {
  /// No update needed
  none,

  /// Optional update available - user can skip
  optional,

  /// Forced update required - user cannot continue
  forced,
}

/// Enum for update prompt result
enum UpdatePromptResult {
  /// User chose to update
  update,

  /// User chose to skip this update (optional update only)
  skip,

  /// User chose "later" for optional update
  later,

  /// User chose "don't remind for this version"
  skipVersion,
}

/// Provider for UpdateService
final updateServiceProvider = Provider<UpdateService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UpdateService(prefs);
});

/// Service class for handling app update checks and prompts
class UpdateService {
  static const String _skippedVersionCodeKey = 'skipped_version_code';
  static const String _lastPromptTimeKey = 'last_update_prompt_time';
  static const int _optionalPromptCooldownHours =
      24; // Don't nag more than once per day

  final SharedPreferences _prefs;
  FirebaseRemoteConfig? _remoteConfig;
  PackageInfo? _packageInfo;

  // Track if we've already shown the dialog in this session
  bool _hasShownDialogThisSession = false;

  UpdateService(this._prefs);

  /// Initialize the service and fetch remote config
  Future<void> initialize() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Set Remote Config settings
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 15),
          // DEBUG: Set to zero for testing immediate updates
          minimumFetchInterval: Duration.zero,
        ),
      );

      // Set default values for Remote Config
      await _remoteConfig!.setDefaults({
        'latest_version_name': '1.0.0',
        'latest_version_code': 1,
        'apk_url': '',
        'force_update': false,
        'update_message':
            'A new version is available with bug fixes and improvements.',
        'min_supported_version_code': 1,
      });

      // Fetch remote config
      await _remoteConfig!.fetchAndActivate();
      log(
        'UpdateService: Remote config initialized successfully',
        name: 'UpdateService',
      );
    } catch (e) {
      log(
        'UpdateService: Failed to initialize remote config: $e',
        name: 'UpdateService',
      );
    }
  }

  /// Get the installed version code (build number)
  int getInstalledVersionCode() {
    final buildNumber = _packageInfo?.buildNumber ?? '1';
    return int.tryParse(buildNumber) ?? 1;
  }

  /// Get the installed version name
  String getInstalledVersionName() {
    return _packageInfo?.version ?? '1.0.0';
  }

  /// Fetch remote update info from Firebase Remote Config
  Future<UpdateInfo?> fetchRemoteUpdateInfo() async {
    if (_remoteConfig == null) {
      await initialize();
    }

    if (_remoteConfig == null) {
      log('UpdateService: Remote config not available', name: 'UpdateService');
      return null;
    }

    try {
      // Try to fetch fresh config
      await _remoteConfig!.fetchAndActivate();
      return UpdateInfo.fromRemoteConfig(_remoteConfig!);
    } catch (e) {
      log(
        'UpdateService: Failed to fetch remote config: $e',
        name: 'UpdateService',
      );
      // Return cached values if available
      try {
        return UpdateInfo.fromRemoteConfig(_remoteConfig!);
      } catch (_) {
        return null;
      }
    }
  }

  /// Determine if an update should be prompted based on version codes
  UpdateRequirement getUpdateRequirement(UpdateInfo updateInfo) {
    final installedVersionCode = getInstalledVersionCode();

    // DEBUG LOGS
    log(
      '------------------------------------------------',
      name: 'UpdateService',
    );
    log('DEBUG: Checking for updates...', name: 'UpdateService');
    log(
      'DEBUG: Installed Version Code: $installedVersionCode',
      name: 'UpdateService',
    );
    log(
      'DEBUG: Remote Latest Version Code: ${updateInfo.latestVersionCode}',
      name: 'UpdateService',
    );
    log(
      'DEBUG: Remote Min Supported Code: ${updateInfo.minSupportedVersionCode}',
      name: 'UpdateService',
    );
    log(
      'DEBUG: Force Update Flag: ${updateInfo.forceUpdate}',
      name: 'UpdateService',
    );
    log(
      '------------------------------------------------',
      name: 'UpdateService',
    );

    // Check if installed version is below minimum supported - force update
    if (installedVersionCode < updateInfo.minSupportedVersionCode) {
      log(
        'UpdateService: Force update required (installed: $installedVersionCode < min: ${updateInfo.minSupportedVersionCode})',
        name: 'UpdateService',
      );
      return UpdateRequirement.forced;
    }

    // Check if a new version is available
    if (installedVersionCode < updateInfo.latestVersionCode) {
      // Check if force_update flag is set
      if (updateInfo.forceUpdate) {
        log(
          'UpdateService: Force update flag set (installed: $installedVersionCode < latest: ${updateInfo.latestVersionCode})',
          name: 'UpdateService',
        );
        return UpdateRequirement.forced;
      }

      log(
        'UpdateService: Optional update available (installed: $installedVersionCode < latest: ${updateInfo.latestVersionCode})',
        name: 'UpdateService',
      );
      return UpdateRequirement.optional;
    }

    log(
      'UpdateService: App is up to date (installed: $installedVersionCode >= latest: ${updateInfo.latestVersionCode})',
      name: 'UpdateService',
    );
    return UpdateRequirement.none;
  }

  /// Check if we should prompt for an optional update
  /// Respects "skip version" and cooldown preferences
  bool shouldPromptOptionalUpdate(UpdateInfo updateInfo) {
    final skippedVersionCode = _prefs.getInt(_skippedVersionCodeKey) ?? 0;

    // Don't prompt if user has skipped this specific version
    if (skippedVersionCode >= updateInfo.latestVersionCode) {
      log(
        'UpdateService: User has skipped version ${updateInfo.latestVersionCode}',
        name: 'UpdateService',
      );
      return false;
    }

    // Check cooldown period
    final lastPromptTimeMs = _prefs.getInt(_lastPromptTimeKey) ?? 0;
    final lastPromptTime = DateTime.fromMillisecondsSinceEpoch(
      lastPromptTimeMs,
    );
    final hoursSinceLastPrompt = DateTime.now()
        .difference(lastPromptTime)
        .inHours;

    if (hoursSinceLastPrompt < _optionalPromptCooldownHours) {
      log(
        'UpdateService: Within cooldown period ($hoursSinceLastPrompt hours since last prompt)',
        name: 'UpdateService',
      );
      return false;
    }

    return true;
  }

  /// Save that the user chose to skip a specific version
  Future<void> skipVersion(int versionCode) async {
    await _prefs.setInt(_skippedVersionCodeKey, versionCode);
    log(
      'UpdateService: Skipped version $versionCode saved',
      name: 'UpdateService',
    );
  }

  /// Record when update prompt was shown (for cooldown tracking)
  Future<void> recordPromptShown() async {
    await _prefs.setInt(
      _lastPromptTimeKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Open the APK download URL in browser or download manager
  Future<bool> openApkDownloadUrl(String url) async {
    if (!url.toLowerCase().startsWith('https://')) {
      log(
        'UpdateService: Invalid APK URL (not HTTPS): $url',
        name: 'UpdateService',
      );
      return false;
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        log('UpdateService: Opened APK download URL', name: 'UpdateService');
        return true;
      } else {
        log('UpdateService: Cannot launch URL: $url', name: 'UpdateService');
        return false;
      }
    } catch (e) {
      log('UpdateService: Failed to open URL: $e', name: 'UpdateService');
      return false;
    }
  }

  /// Main method to check for updates and prompt the user if needed
  /// Returns true if an update dialog was shown
  /// Set [bypassCooldown] to true for manual "Check for Updates" button clicks
  Future<bool> checkAndPromptIfNeeded(
    BuildContext context, {
    bool bypassCooldown = false,
  }) async {
    // Prevent showing multiple dialogs in a single session
    if (_hasShownDialogThisSession) {
      log(
        'UpdateService: Dialog already shown this session',
        name: 'UpdateService',
      );
      return false;
    }

    try {
      final updateInfo = await fetchRemoteUpdateInfo();
      if (updateInfo == null) {
        log('UpdateService: No update info available', name: 'UpdateService');
        return false;
      }

      // Validate APK URL
      if (!updateInfo.hasValidApkUrl) {
        log('UpdateService: Invalid or missing APK URL', name: 'UpdateService');
        return false;
      }

      final requirement = getUpdateRequirement(updateInfo);

      if (requirement == UpdateRequirement.none) {
        return false;
      }

      // For optional updates, check if we should prompt (unless bypassing cooldown)
      if (requirement == UpdateRequirement.optional && !bypassCooldown) {
        if (!shouldPromptOptionalUpdate(updateInfo)) {
          log(
            'UpdateService: Skipping optional update due to cooldown/skip',
            name: 'UpdateService',
          );
          return false;
        }
      }

      // Show the update dialog
      if (context.mounted) {
        _hasShownDialogThisSession = true;
        await recordPromptShown();

        // Re-check mounted after async operation
        if (!context.mounted) return false;

        final result = await _showUpdateDialog(
          context,
          updateInfo,
          requirement == UpdateRequirement.forced,
        );

        return _handleUpdateResult(result, updateInfo);
      }

      return false;
    } catch (e) {
      log(
        'UpdateService: Error checking for updates: $e',
        name: 'UpdateService',
      );
      return false;
    }
  }

  /// Show the update dialog and return the result
  Future<UpdatePromptResult?> _showUpdateDialog(
    BuildContext context,
    UpdateInfo updateInfo,
    bool isForced,
  ) async {
    // Import dynamically to avoid circular dependency
    return showDialog<UpdatePromptResult>(
      context: context,
      barrierDismissible: !isForced,
      builder: (context) => _UpdateDialogContent(
        updateInfo: updateInfo,
        installedVersion: getInstalledVersionName(),
        isForced: isForced,
        onUpdate: () async {
          // Close the initial dialog before starting download
          if (context.mounted) {
            Navigator.of(context).pop(UpdatePromptResult.update);
          }
          // Start the download and install process
          await _downloadAndInstallUpdate(context, updateInfo);
        },
        onLater: () {
          Navigator.of(context).pop(UpdatePromptResult.later);
        },
        onSkipVersion: () async {
          await skipVersion(updateInfo.latestVersionCode);
          if (context.mounted) {
            Navigator.of(context).pop(UpdatePromptResult.skipVersion);
          }
        },
      ),
    );
  }

  /// Handle the result from the update dialog
  Future<bool> _handleUpdateResult(
    UpdatePromptResult? result,
    UpdateInfo updateInfo,
  ) async {
    if (result == null) {
      return false;
    }

    switch (result) {
      case UpdatePromptResult.update:
        return true;
      case UpdatePromptResult.skipVersion:
        // Already handled in the dialog callback
        return true;
      case UpdatePromptResult.later:
      case UpdatePromptResult.skip:
        return true;
    }
  }

  Future<void> _downloadAndInstallUpdate(
    BuildContext context,
    UpdateInfo updateInfo,
  ) async {
    final dio = Dio();
    String? savePath;

    // Show progress dialog
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _DownloadProgressDialog(
          dio: dio,
          url: updateInfo.apkUrl,
          onDownloadComplete: (path) {
            savePath = path;
            Navigator.of(context).pop(); // Close progress dialog
          },
          onError: (e) {
            Navigator.of(context).pop(); // Close progress dialog
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Download failed: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      },
    ).then((_) async {
      // After dialog closes, if we have a path, try to install
      if (savePath != null) {
        log(
          'UpdateService: Install requested for: $savePath',
          name: 'UpdateService',
        );
        await _installApk(savePath!);
      }
    });
  }

  Future<void> _installApk(String path) async {
    try {
      final result = await OpenFilex.open(path);
      log(
        'UpdateService: OpenFilex result: ${result.type} - ${result.message}',
        name: 'UpdateService',
      );
      if (result.type != ResultType.done) {
        // Handle error if needed
      }
    } catch (e) {
      log('UpdateService: Error installing APK: $e', name: 'UpdateService');
    }
  }

  /// Reset the session flag (useful for testing or after app comes from background)
  void resetSessionFlag() {
    _hasShownDialogThisSession = false;
  }
}

/// Internal dialog content widget
class _UpdateDialogContent extends StatefulWidget {
  final UpdateInfo updateInfo;
  final String installedVersion;
  final bool isForced;
  final VoidCallback onUpdate;
  final VoidCallback onLater;
  final VoidCallback onSkipVersion;

  const _UpdateDialogContent({
    required this.updateInfo,
    required this.installedVersion,
    required this.isForced,
    required this.onUpdate,
    required this.onLater,
    required this.onSkipVersion,
  });

  @override
  State<_UpdateDialogContent> createState() => _UpdateDialogContentState();
}

class _UpdateDialogContentState extends State<_UpdateDialogContent>
    with SingleTickerProviderStateMixin {
  bool _skipVersionChecked = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: !widget.isForced,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF1E1B4B).withValues(alpha: 0.95),
                            const Color(0xFF312E81).withValues(alpha: 0.9),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.95),
                            Colors.grey.shade50.withValues(alpha: 0.95),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with gradient
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor,
                            theme.primaryColor.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Animated icon
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.system_update_alt_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isArabic
                                ? 'تحديث جديد متوفر!'
                                : 'Update Available!',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isArabic
                                ? 'نسخة أحدث جاهزة للتحميل'
                                : 'A newer version is ready to download',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Version comparison card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Current version
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        isArabic ? 'الحالي' : 'Current',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.6,
                                                    )
                                                  : Colors.grey.shade600,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.1,
                                                )
                                              : Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          'v${widget.installedVersion}',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.white.withValues(
                                                        alpha: 0.7,
                                                      )
                                                    : Colors.grey.shade700,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Arrow
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    color: theme.primaryColor,
                                    size: 28,
                                  ),
                                ),
                                // New version
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        isArabic ? 'الجديد' : 'New',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.primaryColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              theme.primaryColor.withValues(
                                                alpha: 0.2,
                                              ),
                                              theme.primaryColor.withValues(
                                                alpha: 0.1,
                                              ),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: theme.primaryColor
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Text(
                                          'v${widget.updateInfo.latestVersionName}',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: theme.primaryColor,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Update message
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: theme.primaryColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.updateInfo.updateMessage.isNotEmpty
                                        ? widget.updateInfo.updateMessage
                                        : (isArabic
                                              ? 'إصدار جديد مع تحسينات وإصلاحات.'
                                              : 'New version with improvements and fixes.'),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Force update warning
                          if (widget.isForced) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(
                                        alpha: 0.2,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.orange,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      isArabic
                                          ? 'هذا التحديث مطلوب للاستمرار.'
                                          : 'This update is required to continue.',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: Colors.orange.shade800,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Skip version checkbox (optional updates only)
                          if (!widget.isForced) ...[
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: () => setState(
                                () =>
                                    _skipVersionChecked = !_skipVersionChecked,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _skipVersionChecked
                                      ? theme.primaryColor.withValues(
                                          alpha: 0.1,
                                        )
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _skipVersionChecked
                                        ? theme.primaryColor.withValues(
                                            alpha: 0.3,
                                          )
                                        : (isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.1,
                                                )
                                              : Colors.grey.withValues(
                                                  alpha: 0.3,
                                                )),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: _skipVersionChecked
                                            ? theme.primaryColor
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: _skipVersionChecked
                                              ? theme.primaryColor
                                              : (isDark
                                                    ? Colors.white38
                                                    : Colors.grey),
                                          width: 2,
                                        ),
                                      ),
                                      child: _skipVersionChecked
                                          ? const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        isArabic
                                            ? 'لا تذكرني بهذا الإصدار'
                                            : "Don't remind me for this version",
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.grey.shade700,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),

                          // Buttons
                          // Buttons
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Update button (Primary Action)
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.primaryColor,
                                      theme.primaryColor.withValues(alpha: 0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.primaryColor.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: widget.onUpdate,
                                  icon: const Icon(
                                    Icons.download_rounded,
                                    size: 24,
                                  ),
                                  label: Text(
                                    isArabic ? 'تحديث الآن' : 'Update Now',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),

                              // Later button (Secondary Action - Optional only)
                              if (!widget.isForced) ...[
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: () {
                                    if (_skipVersionChecked) {
                                      widget.onSkipVersion();
                                    } else {
                                      widget.onLater();
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    side: BorderSide(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : Colors.grey.shade400,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    isArabic ? 'لاحقاً' : 'Later',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DownloadProgressDialog extends StatefulWidget {
  final Dio dio;
  final String url;
  final Function(String path) onDownloadComplete;
  final Function(dynamic error) onError;

  const _DownloadProgressDialog({
    required this.dio,
    required this.url,
    required this.onDownloadComplete,
    required this.onError,
  });

  @override
  State<_DownloadProgressDialog> createState() =>
      _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  double _progress = 0.0;
  String _statusMessage = 'Initializing...';
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _startDownload() async {
    _cancelToken = CancelToken();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/update.apk';

      // Clean up existing file if any
      final file = File(savePath);
      if (await file.exists()) {
        await file.delete();
      }

      if (mounted) {
        setState(() {
          _statusMessage = 'Downloading update...';
        });
      }

      await widget.dio.download(
        widget.url,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            if (mounted) {
              setState(() {
                _progress = received / total;
                final percent = (_progress * 100).toStringAsFixed(0);
                _statusMessage = 'Downloading... $percent%';
              });
            }
          }
        },
      );

      if (mounted) {
        widget.onDownloadComplete(savePath);
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        log('Download cancelled');
      } else {
        log('Download error: $e');
        if (mounted) {
          widget.onError(e);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false, // Prevent dismissing while downloading
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF1E1B4B).withValues(alpha: 0.9),
                          const Color(0xFF312E81).withValues(alpha: 0.8),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.95),
                          Colors.grey.shade100.withValues(alpha: 0.9),
                        ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with pulse effect (simulated statically)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_download_rounded,
                      color: theme.primaryColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Downloading Update',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _statusMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 8,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.primaryColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        _cancelToken?.cancel();
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: isDark ? Colors.white30 : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
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
}
