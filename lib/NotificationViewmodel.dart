import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_file_plus/open_file_plus.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static void initialize() {
    // Initialization setting for android
    const InitializationSettings initializationSettingsAndroid =
    InitializationSettings(
        android: AndroidInitializationSettings("@mipmap/ic_launcher"));
    _notificationsPlugin.initialize(
      initializationSettingsAndroid,
      onDidReceiveNotificationResponse: (details) {
        performAction(details.payload);
      },
    );
  }

  static void performAction(String? payload) {
    if(payload != null){
      print("Este es el payload que me llega: $payload");
      openFile(payload);
    }
  }

  static Future<void> openFile(filePath) async {
    await OpenFile.open(filePath);
  }

  static Future<void> display(String message, String title, String payload) async {
    // To display the notification in device
    try {
      print(message);
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
            "Channel Id",
            "Main Channel",
            groupKey: "gfg",
            color: Colors.green,
            importance: Importance.max,
            // different sound for
            // different notification
            playSound: true,
            priority: Priority.high),
      );
      await _notificationsPlugin.show(id, title, message, notificationDetails,payload: payload);
    } catch (e) {
      print(e.toString());
    }
  }
}