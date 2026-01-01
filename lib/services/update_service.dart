import 'dart:developer';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
          minimumFetchInterval: const Duration(hours: 1),
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

    log('UpdateService: App is up to date', name: 'UpdateService');
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
  Future<bool> checkAndPromptIfNeeded(BuildContext context) async {
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

      // For optional updates, check if we should prompt
      if (requirement == UpdateRequirement.optional) {
        if (!shouldPromptOptionalUpdate(updateInfo)) {
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
          final success = await openApkDownloadUrl(updateInfo.apkUrl);
          if (context.mounted) {
            Navigator.of(context).pop(UpdatePromptResult.update);
            if (!success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to open download link'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
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
        await skipVersion(updateInfo.latestVersionCode);
        return true;
      case UpdatePromptResult.later:
      case UpdatePromptResult.skip:
        return true;
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

class _UpdateDialogContentState extends State<_UpdateDialogContent> {
  bool _skipVersionChecked = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return PopScope(
      canPop: !widget.isForced,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.system_update,
                color: colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isArabic ? 'تحديث متوفر' : 'Update Available',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Version info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    _buildVersionRow(
                      isArabic ? 'الإصدار الحالي' : 'Current Version',
                      widget.installedVersion,
                      theme,
                    ),
                    const SizedBox(height: 8),
                    Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
                    const SizedBox(height: 8),
                    _buildVersionRow(
                      isArabic ? 'الإصدار الجديد' : 'New Version',
                      widget.updateInfo.latestVersionName,
                      theme,
                      isHighlighted: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Update message
              Text(
                widget.updateInfo.updateMessage.isNotEmpty
                    ? widget.updateInfo.updateMessage
                    : (isArabic
                          ? 'إصدار جديد متاح مع إصلاحات وتحسينات.'
                          : 'A new version is available with bug fixes and improvements.'),
                style: theme.textTheme.bodyMedium,
              ),

              // Force update warning
              if (widget.isForced) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isArabic
                              ? 'هذا التحديث مطلوب للاستمرار في استخدام التطبيق.'
                              : 'This update is required to continue using the app.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // "Don't remind for this version" checkbox (optional updates only)
              if (!widget.isForced) ...[
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    setState(() {
                      _skipVersionChecked = !_skipVersionChecked;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _skipVersionChecked,
                            onChanged: (value) {
                              setState(() {
                                _skipVersionChecked = value ?? false;
                              });
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isArabic
                                ? 'لا تذكرني بهذا الإصدار'
                                : 'Don\'t remind me for this version',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          // "Later" button (optional updates only)
          if (!widget.isForced)
            TextButton(
              onPressed: () {
                if (_skipVersionChecked) {
                  widget.onSkipVersion();
                } else {
                  widget.onLater();
                }
              },
              child: Text(
                isArabic ? 'لاحقاً' : 'Later',
                style: TextStyle(color: colorScheme.outline),
              ),
            ),
          // "Update" button
          ElevatedButton.icon(
            onPressed: widget.onUpdate,
            icon: const Icon(Icons.download_rounded, size: 20),
            label: Text(isArabic ? 'تحديث' : 'Update'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.end,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  Widget _buildVersionRow(
    String label,
    String version,
    ThemeData theme, {
    bool isHighlighted = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isHighlighted
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: isHighlighted
                ? Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  )
                : null,
          ),
          child: Text(
            'v$version',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isHighlighted ? theme.colorScheme.primary : null,
            ),
          ),
        ),
      ],
    );
  }
}
