import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Request permissions for Android 13+
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  Future<void> scheduleMedicineReminder(int id, String medicineName, int hour, int minute) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    // Subtract 10 minutes
    scheduledDate = scheduledDate.subtract(const Duration(minutes: 10));

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'medicine_reminders',
      'Medicine Reminders',
      channelDescription: 'Notifications for taking medicine',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    // Initial pre-alarm 10 mins before
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id, // Unique ID per reminder/time combination
      'Time to take $medicineName!',
      'Your medicine is scheduled in 10 minutes.',
      scheduledDate,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );
    
    // Recurring alarm 30 mins after the scheduled time, in a naive way we can schedule it once.
    // For true repeating every 30 mins until cancelled, we would use periodicallyShow, 
    // but periodicallyShow doesn't accept a start time easily.
    // As a workaround, we will schedule a single follow-up 30 minutes later. 
    // We can use a different ID scheme (e.g. id + 10000).
    var followUpDate = scheduledDate.add(const Duration(minutes: 40)); // 10 mins before + 40 mins = 30 mins after
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id + 10000, 
      'Did you forget $medicineName?',
      'You missed your scheduled time 30 minutes ago.',
      followUpDate,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, 
    );
  }

  Future<void> cancelReminder(int id) async {
    // Cancel both the pre-alarm and the follow-up
    await flutterLocalNotificationsPlugin.cancel(id);
    await flutterLocalNotificationsPlugin.cancel(id + 10000);
  }

  Future<void> showLowStockNotification(int id, String medicineName, int remaining) async {
    await flutterLocalNotificationsPlugin.show(
      -id, // Keep inventory alerts separate from positive schedule IDs.
      'Low tablet inventory',
      '$medicineName: $remaining tablets left. A quarter or less of your supply remains.',
      const NotificationDetails(android: AndroidNotificationDetails(
        'low_stock',
        'Low tablet inventory',
        channelDescription: 'One alert when tablet stock reaches a quarter of the entered quantity',
        importance: Importance.high,
        priority: Priority.high,
      )),
    );
  }
}
