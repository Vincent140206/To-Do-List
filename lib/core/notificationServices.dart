import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/material.dart';

class NotificationServices {
  static final NotificationServices _instance = NotificationServices._internal();
  factory NotificationServices() => _instance;
  NotificationServices._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    await requestNotificationPermissions();
  }

  void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    await selectNotification(payload);
  }

  Future<void> requestNotificationPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future selectNotification(String? payload) async {
    if (payload != null) {
      print('Notification payload: $payload');
    }
  }

  Future<void> createNotificationChannel({
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) async {
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: const Color(0xFF0000FF),
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showSimpleNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'simple_channel',
          'Simple Notifications',
          channelDescription: 'Channel for simple notifications',
          importance: Importance.max,
          priority: Priority.high,
          color: Color(0xFF4CAF50),
          ledColor: Color(0xFF4CAF50),
          ledOnMs: 1000,
          ledOffMs: 500,
          enableLights: true,
          icon: 'notification_icon',
          largeIcon: DrawableResourceAndroidBitmap('app_icon'),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          subtitle: 'Simple Notification',
          badgeNumber: 1,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> showBigPictureNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final BigPictureStyleInformation bigPictureStyleInformation = BigPictureStyleInformation(
      const DrawableResourceAndroidBitmap('notification_large_icon'),
      largeIcon: const DrawableResourceAndroidBitmap('notification_large_icon'),
      contentTitle: title,
      summaryText: body,
      hideExpandedLargeIcon: false,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'big_picture_channel',
          'Big Picture Notifications',
          channelDescription: 'Channel for big picture notifications',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: bigPictureStyleInformation,
          color: const Color(0xFF2196F3),
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          attachments: [
            DarwinNotificationAttachment('notification_img.jpg')
          ],
        ),
      ),
      payload: payload,
    );
  }

  Future<void> showBigTextNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      body,
      htmlFormatBigText: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
      summaryText: 'Summary Text',
      htmlFormatSummaryText: true,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'big_text_channel',
          'Big Text Notifications',
          channelDescription: 'Channel for big text notifications',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: bigTextStyleInformation,
          color: const Color(0xFFFF5722),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          subtitle: 'Big Text Notification',
        ),
      ),
      payload: payload,
    );
  }

  Future<void> showNotificationWithActions({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'action_channel',
          'Action Notifications',
          channelDescription: 'Channel for notifications with actions',
          importance: Importance.max,
          priority: Priority.high,
          color: const Color(0xFF9C27B0),
          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction(
              'accept',
              'Terima',
              icon: DrawableResourceAndroidBitmap('ic_accept'),
            ),
            const AndroidNotificationAction(
              'decline',
              'Tolak',
              icon: DrawableResourceAndroidBitmap('ic_decline'),
              cancelNotification: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'actionable',
        ),
      ),
      payload: payload,
    );
  }

  Future<void> showGroupedNotifications({
    required String groupKey,
    required List<NotificationInfo> notifications,
  }) async {
    for (int i = 0; i < notifications.length; i++) {
      final NotificationInfo notification = notifications[i];
      await flutterLocalNotificationsPlugin.show(
        notification.id,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'grouped_channel',
            'Grouped Notifications',
            channelDescription: 'Channel for grouped notifications',
            importance: Importance.max,
            priority: Priority.high,
            groupKey: groupKey,
            setAsGroupSummary: false,
            color: const Color(0xFF3F51B5),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            threadIdentifier: 'thread_id',
          ),
        ),
        payload: notification.payload,
      );
    }

    await flutterLocalNotificationsPlugin.show(
      0,
      'Anda memiliki ${notifications.length} notifikasi baru',
      'Ketuk untuk melihat detail',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'grouped_channel',
          'Grouped Notifications',
          channelDescription: 'Channel for grouped notifications',
          importance: Importance.max,
          priority: Priority.high,
          groupKey: groupKey,
          setAsGroupSummary: true,
          color: const Color(0xFF3F51B5),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          threadIdentifier: 'thread_id',
        ),
      ),
    );
  }

  Future<void> showProgressNotification({
    required int id,
    required String title,
    required String body,
    required int progress,
    required int maxProgress,
    String? payload,
  }) async {
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'progress_channel',
          'Progress Notifications',
          channelDescription: 'Channel for progress notifications',
          importance: Importance.max,
          priority: Priority.high,
          onlyAlertOnce: true,
          showProgress: true,
          maxProgress: maxProgress,
          progress: progress,
          color: const Color(0xFFE91E63),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    Color notificationColor = const Color(0xFF4CAF50),
    String? soundName,
    bool enableVibration = true,
    bool enableLights = true,
    Color ledColor = const Color(0xFF4CAF50),
    int ledOnMs = 1000,
    int ledOffMs = 500,
    String? icon,
    String? largeIcon,
  }) async {
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'event_channel',
          'Event Notifications',
          channelDescription: 'Notifications for scheduled events',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          color: notificationColor,
          sound: soundName != null ? RawResourceAndroidNotificationSound(soundName) : null,
          enableVibration: enableVibration,
          enableLights: enableLights,
          ledColor: ledColor,
          ledOnMs: ledOnMs,
          ledOffMs: ledOffMs,
          icon: icon,
          largeIcon: largeIcon != null ? DrawableResourceAndroidBitmap(largeIcon) : null,
          styleInformation: BigTextStyleInformation(
            body,
            htmlFormatBigText: true,
            contentTitle: title,
            htmlFormatContentTitle: true,
          ),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: soundName != null ? soundName : null,
          badgeNumber: 1,
          subtitle: 'Event Notification',
        ),
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    print('Notification scheduled for: $scheduledDate');
  }

  Future<void> scheduleRepeatingNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required RepeatInterval repeatInterval,
    String? payload,
  }) async {
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'repeating_channel',
          'Repeating Notifications',
          channelDescription: 'Channel for repeating notifications',
          importance: Importance.max,
          priority: Priority.high,
          color: Color(0xFF009688),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: getDateTimeComponents(repeatInterval),
    );

    print('Repeating notification scheduled for: $scheduledDate');
  }

  DateTimeComponents? getDateTimeComponents(RepeatInterval interval) {
    switch (interval) {
      case RepeatInterval.daily:
        return DateTimeComponents.time;
      case RepeatInterval.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case RepeatInterval.monthly:
        return DateTimeComponents.dayOfMonthAndTime;
      case RepeatInterval.yearly:
        return DateTimeComponents.dateAndTime;
      default:
        return null;
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}

class NotificationInfo {
  final int id;
  final String title;
  final String body;
  final String? payload;

  NotificationInfo({
    required this.id,
    required this.title,
    required this.body,
    this.payload,
  });
}

enum RepeatInterval {
  daily,
  weekly,
  monthly,
  yearly,
}