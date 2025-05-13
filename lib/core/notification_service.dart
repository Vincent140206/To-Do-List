import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:io' show Platform;
import '../core/event.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Getter to check initialization status
  bool get isInitialized => _isInitialized;

  Future<bool> init() async {
    if (_isInitialized) {
      print("ℹ️ Notification service already initialized");
      return true;
    }

    // Initialize timezone data
    tz_data.initializeTimeZones();

    // Set Jakarta timezone - this is crucial for correct scheduling
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      print("✅ Timezone set to Asia/Jakarta");
    } catch (e) {
      print('❌ Error setting timezone: $e');
      // Fallback to local device timezone
      tz.setLocalLocation(tz.local);
      print("⚠️ Falling back to local timezone: ${tz.local.name}");
    }

    // Android notification channel setup - IMPROVED
    final AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS notification settings
    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    bool initSuccess = false;
    try {
      // Initialize with explicit selection response handling
      initSuccess = await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
          print('👆 Notification tapped: ${notificationResponse.payload}');
          // Handle notification tap here
        },
      ) ?? false;

      if (initSuccess) {
        print('✅ Notifications plugin successfully initialized');
        _isInitialized = true;

        // Immediately request permissions after initialization
        await _requestPermissions();

        // Create notification channels for Android
        if (Platform.isAndroid) {
          await _setupNotificationChannels();
        }
      } else {
        print('⚠️ Notifications plugin initialization returned null');
      }
    } catch (e) {
      print('❌ Error initializing notifications plugin: $e');
      return false;
    }

    return initSuccess;
  }

  // Create notification channels for Android
  Future<void> _setupNotificationChannels() async {
    // Create main event reminder channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'event_reminder_channel',  // id
      'Event Reminders',         // name
      description: 'Notifications for calendar events',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Create test notification channel
    const AndroidNotificationChannel testChannel = AndroidNotificationChannel(
      'test_channel',          // id
      'Test Notifications',     // name
      description: 'Channel for testing notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    try {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(testChannel);

      print("📢 Android notification channels created successfully");
    } catch (e) {
      print("❌ Error creating notification channels: $e");
    }
  }

  // Separate method for requesting permissions
  Future<void> _requestPermissions() async {
    // iOS permissions
    if (Platform.isIOS) {
      print("🔒 Requesting iOS notification permissions");
      final bool? result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: true, // For important notifications
      );
      print("📱 iOS permissions ${result == true ? 'granted' : 'denied or not determined'}");
    }

    // Android permissions - check for exact alarms on Android 12+
    if (Platform.isAndroid) {
      print("🔒 Checking Android notification permissions");
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        try {
          // Check if we can schedule exact notifications
          final bool? granted = await androidImplementation.areNotificationsEnabled();
          print("📱 Android notifications enabled: ${granted == true ? 'yes' : 'no'}");

          // Check for exact scheduling permission
          final bool? exactAlarmsAllowed = await androidImplementation.canScheduleExactNotifications();
          print("⏰ Android exact alarms permission: ${exactAlarmsAllowed == true ? 'granted' : 'denied'}");

          // Request notification permission on Android 13+ (API level 33+)
          final bool? permissionGranted = await androidImplementation.requestNotificationsPermission();
          print("🔔 Android notification permission request result: ${permissionGranted == true ? 'granted' : 'denied'}");

          // If exact alarms not allowed, we should inform the user to enable them in settings
          if (exactAlarmsAllowed == false) {
            print("⚠️ Exact alarms not allowed. User should enable this in system settings");
            // Here you would typically show a dialog to the user instructing them to
            // go to Settings > Apps > Your App > Advanced > Alarms & reminders
          }
        } catch (e) {
          print("❌ Error checking Android notification permissions: $e");
        }
      }
    }
  }

  // Fixed schedule notification method
  Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Ensure service is initialized
    if (!_isInitialized) {
      print("⚠️ Notification service not initialized, initializing now...");
      bool initResult = await init();
      if (!initResult) {
        print("❌ Failed to initialize notification service");
        return false;
      }
    }

    // Detailed logging for debugging
    print("📅 Scheduling notification #$id");
    print("📅 Title: $title");
    print("📅 Body: $body");
    print("📅 Scheduled for: $scheduledDate");
    print("📅 Current time: ${DateTime.now()}");

    // IMPORTANT FIX: Check if date is in the past
    final now = DateTime.now();
    if (scheduledDate.isBefore(now)) {
      print("⚠️ Error: Cannot schedule notification for past time");
      print("⚠️ Scheduled: $scheduledDate");
      print("⚠️ Current: $now");
      return false;
    }

    // Add a small buffer if the time is very soon (flaky on some devices)
    if (scheduledDate.difference(now).inSeconds < 10) {
      print("⚠️ Warning: Scheduled time too close to now, adding buffer");
      scheduledDate = now.add(const Duration(seconds: 10));
      print("⚠️ Adjusted time: $scheduledDate");
    }

    try {
      // IMPORTANT: Use local timezone for proper scheduling
      final location = tz.local;
      print("🌍 Using timezone: ${location.name}");

      // Create a proper TZDateTime using the device's timezone
      final scheduledTzDateTime = tz.TZDateTime.from(scheduledDate, location);

      // Debug time information in detail
      final currentTzTime = tz.TZDateTime.now(location);
      print("🕒 Original DateTime: $scheduledDate");
      print("🕒 TZDateTime: $scheduledTzDateTime");
      print("🕒 Current TZ time: $currentTzTime");
      print("🕒 Time until notification: ${scheduledTzDateTime.difference(currentTzTime).inMinutes} minutes");

      // Double-check that the time is still valid after conversion
      if (scheduledTzDateTime.isBefore(currentTzTime)) {
        print("❌ Error: After timezone conversion, scheduled time is in the past!");
        return false;
      }

      // Android notification details - IMPROVED
      AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'event_reminder_channel',
        'Event Reminders',
        channelDescription: 'Notifications for calendar events',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        channelShowBadge: true,
        fullScreenIntent: true,
        // Add an icon and color to make notification more visible
        color: const Color.fromARGB(255, 255, 0, 0), // Red color
        // Using default sound
        // Add actions if needed
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction('open', 'Open App'),
        ],
      );

      // iOS notification details - IMPROVED
      DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
        // Make it critical - helps with delivery
        interruptionLevel: InterruptionLevel.critical,
      );

      NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      // IMPORTANT FIX: Use zonedSchedule with precise settings
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTzDateTime,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // This is crucial
        // Remove the uiLocalNotificationDateInterpretation parameter
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload ?? 'event_$id',
      );

      String formattedTime = "${scheduledTzDateTime.hour.toString().padLeft(2, '0')}:${scheduledTzDateTime.minute.toString().padLeft(2, '0')}";
      print("✅ Notification #$id successfully scheduled for $formattedTime");

      // FIX: Immediately also schedule a "backup" notification 1 minute later
      // This helps on devices with aggressive battery optimization
      try {
        final backupTime = scheduledTzDateTime.add(const Duration(minutes: 1));
        final backupId = id + 100000; // Use a different ID

        await flutterLocalNotificationsPlugin.zonedSchedule(
          backupId,
          title, // Same title
          "$body (reminder)", // Slightly modified body
          backupTime,
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          // Remove the uiLocalNotificationDateInterpretation parameter
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payload ?? 'event_backup_$id',
        );
        print("✅ Backup notification #$backupId scheduled for 1 minute later");
      } catch (e) {
        print("⚠️ Error scheduling backup notification: $e");
        // Continue anyway - main notification is more important
      }

      return true;
    } catch (e) {
      print("❌ Error scheduling notification: $e");
      return false;
    }
  }

  // Improved test notification method with immediate and delayed notifications
  Future<bool> testNotification() async {
    if (!_isInitialized) {
      print("⚠️ Notification service not initialized, initializing now...");
      bool initResult = await init();
      if (!initResult) {
        print("❌ Failed to initialize notification service");
        return false;
      }
    }

    print("🧪 Sending test notification at ${DateTime.now()}");

    try {
      // First, send an immediate notification
      final immediateId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Create notification details with high priority
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'Channel for testing notifications',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        fullScreenIntent: true,
        autoCancel: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
      );

      DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        interruptionLevel: InterruptionLevel.critical,
      );

      NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show immediate notification
      await flutterLocalNotificationsPlugin.show(
        immediateId,
        'Immediate Test Notification',
        'This notification should appear immediately',
        platformDetails,
        payload: 'test_immediate_$immediateId',
      );

      print("✅ Immediate test notification #$immediateId sent");

      // Schedule notifications for future times as additional tests
      final times = [10, 30, 60]; // seconds
      int count = 0;

      for (int seconds in times) {
        final futureTime = DateTime.now().add(Duration(seconds: seconds));
        final delayedId = immediateId + (++count);

        bool scheduled = await scheduleNotification(
          id: delayedId,
          title: 'Delayed Test ($seconds sec)',
          body: 'This notification was scheduled $seconds seconds after test',
          scheduledDate: futureTime,
          payload: 'test_delayed_${seconds}s',
        );

        if (scheduled) {
          print("✅ Delayed test notification #$delayedId scheduled for $seconds seconds from now");
        } else {
          print("❌ Failed to schedule delayed test notification for $seconds seconds");
        }
      }

      return true;
    } catch (e) {
      print("❌ Error in test notification sequence: $e");
      return false;
    }
  }

  // Method to show notification for updated event
  Future<bool> showUpdatedNotification(Event event) async {
    DateTime eventDateTime = DateTime.parse(event.key);
    String formattedTime = "${eventDateTime.hour.toString().padLeft(2, '0')}:${eventDateTime.minute.toString().padLeft(2, '0')}";

    // Cancel previous notification (if any)
    await flutterLocalNotificationsPlugin.cancel(eventDateTime.millisecondsSinceEpoch ~/ 1000);

    // Schedule new notification
    return await scheduleNotification(
      id: eventDateTime.millisecondsSinceEpoch ~/ 1000,
      title: '${event.title}',
      body: 'Event at $formattedTime',
      scheduledDate: eventDateTime,
      payload: 'event_${event.key}',
    );
  }

  // Method to cancel all notifications
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    print("✅ All notifications canceled");
  }

  // Method to cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    print("✅ Notification with ID $id canceled");
  }

  // Get pending notification requests
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final List<PendingNotificationRequest> pendingNotifications =
      await flutterLocalNotificationsPlugin.pendingNotificationRequests();

      print("📋 Found ${pendingNotifications.length} pending notifications");

      // Log details of each pending notification
      if (pendingNotifications.isNotEmpty) {
        for (var notification in pendingNotifications) {
          print("📌 ID: ${notification.id}");
          print("   Title: ${notification.title}");
          print("   Body: ${notification.body}");
          print("   Payload: ${notification.payload}");
        }
      }

      return pendingNotifications;
    } catch (e) {
      print("❌ Error retrieving pending notifications: $e");
      return [];
    }
  }
}