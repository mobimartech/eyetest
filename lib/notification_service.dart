import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _notificationEnabledKey = 'daily_reminder_enabled';
  static const String _notificationTimeKey = 'daily_reminder_time';

  Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // onDidReceiveLocalNotification: (id, title, body, payload) async {
      //   // Handle iOS foreground notification
      // },
    );

    final initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        _handleNotificationTap(details);
      },
    );

    // Request permissions
    await _requestPermissions();

    // Check if notifications are enabled and schedule if needed
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_notificationEnabledKey) ?? false;
    if (isEnabled) {
      await scheduleDailyReminder();
    }
  }

  // Add this method to test scheduled notifications
  Future<void> scheduleTestNotificationIn10Seconds() async {
    final scheduledDate = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(seconds: 10));

    await _notifications.zonedSchedule(
      100, // Test notification ID
      '⏰ Scheduled Test',
      'This notification was scheduled 10 seconds ago!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_challenge_channel',
          'Daily Challenge Reminders',
          channelDescription:
              'Reminders to complete your daily vision challenge',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF049281),
          enableLights: true,
          ledColor: Color(0xFF049281),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidImplementation?.requestNotificationsPermission();
    }
  }

  Future<bool> isNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationEnabledKey) ?? false;
  }

  Future<void> setNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationEnabledKey, enabled);

    if (enabled) {
      await scheduleDailyReminder();
    } else {
      await cancelAllNotifications();
    }
  }

  Future<void> scheduleDailyReminder({int hour = 20, int minute = 0}) async {
    // Save notification time
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationTimeKey, '$hour:$minute');

    // Cancel existing notifications
    await _notifications.cancel(0);

    // Schedule notification
    await _notifications.zonedSchedule(
      0, // Notification ID
      '🎯 Daily Challenge Awaits!',
      'Complete today\'s vision challenge and maintain your streak 🔥',
      _nextInstanceOfTime(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_challenge_channel',
          'Daily Challenge Reminders',
          channelDescription:
              'Reminders to complete your daily vision challenge',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF049281),
          enableLights: true,
          ledColor: const Color(0xFF049281),
          ledOnMs: 1000,
          ledOffMs: 500,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the scheduled time is in the past, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  void _handleNotificationTap(NotificationResponse details) {
    // You can navigate to the daily challenge page here
    // This will be handled by your app's navigation logic
    print('Notification tapped: ${details.payload}');
  }

  // Show immediate test notification
  Future<void> showTestNotification() async {
    await _notifications.show(
      999,
      '🎯 Test Notification',
      'Your daily challenge notification will look like this!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_challenge_channel',
          'Daily Challenge Reminders',
          channelDescription:
              'Reminders to complete your daily vision challenge',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF049281),
          enableLights: true,
          ledColor: Color(0xFF049281),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
