import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/localization/localization_provider.dart';
import 'update_service.dart';

/// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log(
    'PushNotificationService: Background message received: ${message.messageId}',
    name: 'PushNotificationService',
  );
  // Handle background message silently
  // The actual update check will happen when user taps the notification
}

/// Provider for PushNotificationService
final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final updateService = ref.watch(updateServiceProvider);
  return PushNotificationService(prefs, updateService);
});

/// Service class for handling Firebase Cloud Messaging (FCM) push notifications
class PushNotificationService {
  static const String _fcmTokenKey = 'fcm_token';
  static const String _updateTopic = 'all';

  final SharedPreferences _prefs;
  final UpdateService _updateService;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Callback to trigger update check - set by the main app
  VoidCallback? _onUpdateNotificationReceived;

  // Store context for showing dialogs
  BuildContext? _context;

  PushNotificationService(this._prefs, this._updateService);

  /// Initialize FCM and set up message handlers
  Future<void> initialize() async {
    try {
      // Request notification permissions
      await _requestNotificationPermission();

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Get FCM token and subscribe to topics
      await _setupFCM();

      // Set up foreground message handler
      _setupForegroundHandler();

      // Set up message opened app handler
      _setupMessageOpenedHandler();

      // Handle initial message (if app was terminated and opened via notification)
      await _handleInitialMessage();

      log(
        'PushNotificationService: Initialized successfully',
        name: 'PushNotificationService',
      );
    } catch (e) {
      log(
        'PushNotificationService: Failed to initialize: $e',
        name: 'PushNotificationService',
      );
    }
  }

  /// Set the context for showing update dialogs
  void setContext(BuildContext context) {
    _context = context;
  }

  /// Set callback for when update notification is received
  void setOnUpdateNotificationReceived(VoidCallback callback) {
    _onUpdateNotificationReceived = callback;
  }

  /// Request notification permission (required for Android 13+)
  Future<void> _requestNotificationPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    log(
      'PushNotificationService: Permission status: ${settings.authorizationStatus}',
      name: 'PushNotificationService',
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      log(
        'PushNotificationService: Notification permission denied',
        name: 'PushNotificationService',
      );
    }
  }

  /// Set up FCM token and topic subscription
  Future<void> _setupFCM() async {
    try {
      // Get FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        await _prefs.setString(_fcmTokenKey, token);
        log(
          'PushNotificationService: FCM Token obtained (length: ${token.length})',
          name: 'PushNotificationService',
        );
      }

      // Subscribe to the "all" topic for update notifications
      await _messaging.subscribeToTopic(_updateTopic);
      log(
        'PushNotificationService: Subscribed to topic "$_updateTopic"',
        name: 'PushNotificationService',
      );

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        await _prefs.setString(_fcmTokenKey, newToken);
        log(
          'PushNotificationService: FCM Token refreshed',
          name: 'PushNotificationService',
        );
      });
    } catch (e) {
      log(
        'PushNotificationService: Error setting up FCM: $e',
        name: 'PushNotificationService',
      );
    }
  }

  /// Set up handler for foreground messages
  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log(
        'PushNotificationService: Foreground message received: ${message.messageId}',
        name: 'PushNotificationService',
      );

      // Check if this is an update notification
      if (_isUpdateNotification(message)) {
        log(
          'PushNotificationService: Update notification detected in foreground',
          name: 'PushNotificationService',
        );
        _handleUpdateNotification();
      }
    });
  }

  /// Set up handler for when app is opened from a notification
  void _setupMessageOpenedHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log(
        'PushNotificationService: App opened from notification: ${message.messageId}',
        name: 'PushNotificationService',
      );

      // Check if this is an update notification
      if (_isUpdateNotification(message)) {
        log(
          'PushNotificationService: Update notification opened',
          name: 'PushNotificationService',
        );
        _handleUpdateNotification();
      }
    });
  }

  /// Handle initial message when app was terminated and opened via notification
  Future<void> _handleInitialMessage() async {
    try {
      final initialMessage = await _messaging.getInitialMessage();

      if (initialMessage != null) {
        log(
          'PushNotificationService: App launched from notification: ${initialMessage.messageId}',
          name: 'PushNotificationService',
        );

        if (_isUpdateNotification(initialMessage)) {
          // Store flag to trigger update check after app initializes
          await _prefs.setBool('pending_update_check', true);
        }
      }
    } catch (e) {
      log(
        'PushNotificationService: Error handling initial message: $e',
        name: 'PushNotificationService',
      );
    }
  }

  /// Check if there's a pending update check (from initial message)
  Future<bool> hasPendingUpdateCheck() async {
    final pending = _prefs.getBool('pending_update_check') ?? false;
    if (pending) {
      await _prefs.remove('pending_update_check');
    }
    return pending;
  }

  /// Check if a message is an update notification
  bool _isUpdateNotification(RemoteMessage message) {
    // Check data payload for update type
    final data = message.data;
    if (data.containsKey('type') && data['type'] == 'update') {
      return true;
    }

    // Also check notification title/body for common update keywords
    final notification = message.notification;
    if (notification != null) {
      final title = notification.title?.toLowerCase() ?? '';
      final body = notification.body?.toLowerCase() ?? '';
      if (title.contains('update') ||
          title.contains('تحديث') ||
          body.contains('update') ||
          body.contains('تحديث')) {
        return true;
      }
    }

    return false;
  }

  /// Handle update notification by triggering update check
  void _handleUpdateNotification() {
    // Reset session flag to ensure dialog is shown
    _updateService.resetSessionFlag();

    // Trigger callback if set
    if (_onUpdateNotificationReceived != null) {
      _onUpdateNotificationReceived!();
    }

    // If we have a context, trigger update check directly
    if (_context != null && _context!.mounted) {
      _triggerUpdateCheck();
    }
  }

  /// Trigger update check with current context
  Future<void> _triggerUpdateCheck() async {
    if (_context != null && _context!.mounted) {
      await _updateService.checkAndPromptIfNeeded(_context!);
    }
  }

  /// Manually trigger update check (e.g., from app startup)
  Future<void> checkForUpdates(BuildContext context) async {
    _context = context;
    await _updateService.checkAndPromptIfNeeded(context);
  }

  /// Get the current FCM token
  String? getFcmToken() {
    return _prefs.getString(_fcmTokenKey);
  }

  /// Unsubscribe from update notifications
  Future<void> unsubscribeFromUpdates() async {
    try {
      await _messaging.unsubscribeFromTopic(_updateTopic);
      log(
        'PushNotificationService: Unsubscribed from topic "$_updateTopic"',
        name: 'PushNotificationService',
      );
    } catch (e) {
      log(
        'PushNotificationService: Error unsubscribing from topic: $e',
        name: 'PushNotificationService',
      );
    }
  }
}
