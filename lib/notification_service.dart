import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_timezone/flutter_timezone.dart'; // ADD THIS
import 'dart:io' show Platform;
import 'dart:math'; // For random time

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _notificationEnabledKey = 'daily_reminder_enabled';
  static const String _notificationTimeKey = 'daily_reminder_time';
  static const String _firstLaunchKey = 'is_first_launch';

  Future<void> initialize() async {
    // Initialize timezone data
    tz.initializeTimeZones();

    // CRITICAL FIX: Set local timezone using flutter_timezone 5.0.1 API
    try {
      // In v5.0.1, getLocalTimezone() returns TimezoneInfo object
      final TimezoneInfo timezoneInfo =
          await FlutterTimezone.getLocalTimezone();

      // Access the identifier property to get the timezone string
      final String timeZoneName = timezoneInfo.identifier;

      tz.setLocalLocation(tz.getLocation(timeZoneName));
      print('✅ Timezone set to: $timeZoneName');
    } catch (e) {
      print('⚠️ Error setting timezone: $e');
      // Fallback to UTC if error
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationTap(details);
      },
    );

    // Request permissions
    await _requestPermissions();

    // Auto-enable on first launch
    await _checkAndEnableFirstLaunch();
  }

  // Auto-enable notifications on first launch
  Future<void> _checkAndEnableFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool(_firstLaunchKey) ?? true;

    if (isFirstLaunch) {
      // First launch - enable notifications automatically
      await prefs.setBool(_notificationEnabledKey, true);
      await prefs.setBool(_firstLaunchKey, false);
      await scheduleDailyReminder();

      print('✅ First launch - notifications enabled automatically');
    } else {
      // Not first launch - check user preference
      final isEnabled = prefs.getBool(_notificationEnabledKey) ?? false;
      if (isEnabled) {
        await scheduleDailyReminder();
      }
    }
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

  // NOW CORRECTLY USES DEVICE'S LOCAL TIME
  Future<void> scheduleDailyReminder({int hour = 20, int minute = 0}) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    print('🕒 Current device time: $now');
    print('⏰ Notification will fire at: $scheduledDate (local time)');

    await _notifications.zonedSchedule(
      0,
      '🎯 Daily Challenge Awaits!',
      'Complete today\'s vision challenge and maintain your streak 🔥',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_challenge_channel',
          'Daily Challenge Reminders',
          channelDescription:
              'Reminders to complete your daily vision challenge',
          importance: Importance.max,
          priority: Priority.max,

          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF049281),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Repeats daily!
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _notificationTimeKey,
      scheduledDate.toIso8601String(),
    );

    print(
      '✅ Daily notification scheduled for ${hour}:${minute.toString().padLeft(2, '0')} local time (repeats every day)',
    );
  }

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
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF049281),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> scheduleTestNotificationIn10Seconds() async {
    final scheduledDate = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(seconds: 10));

    await _notifications.zonedSchedule(
      100,
      '🎯 Scheduled Test',
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
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF049281),
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

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  void _handleNotificationTap(NotificationResponse details) {
    print('Notification tapped: ${details.payload}');
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
