// ignore_for_file: avoid_print

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io'; // Platform kontrolü için

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    // UTC HİLESİ İÇİN TEMEL AYAR
    tz.setLocalLocation(tz.UTC);

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@android:drawable/ic_menu_add');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 1. DÜZELTME: initializationSettings artık isimli parametre oldu
    // DOĞRU VE GÜNCEL KISIM
    await _notificationsPlugin.initialize(
      settings: initSettings, // SİHİRLİ KELİME: Sadece 'settings'
      onDidReceiveNotificationResponse: (details) {
        print("Bildirime tıklandı: ${details.payload}");
      },
    );

    // --- İZİNLERİ KULLANICIDAN İSTE ---
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
      }
    }
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'todo_channel_utc_final',
        'Görev Hatırlatıcıları',
        channelDescription: 'Zamanı gelen görevler için bildirim',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  Future<void> showInstantNotification(
      {required int id, required String title, required String body}) async {
    
    // 2. DÜZELTME: id, title ve body artık isimli parametre oldu
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _notificationDetails(),
    );
  }

  // --- KRİTİK FONKSİYON: UTC ZAMANLAMA ---
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      final now = DateTime.now();
      
      if (scheduledTime.isBefore(now)) {
        return;
      }

      final scheduledDateUTC = tz.TZDateTime.from(scheduledTime.toUtc(), tz.UTC);

      // 3. DÜZELTME: id, title, body ve scheduledDate isimli oldu. 
      // 4. DÜZELTME: 'uiLocalNotificationDateInterpretation' satırı tamamen silindi!
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDateUTC,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print("✅ Bildirim Kuruldu (UTC): $scheduledDateUTC");
    } catch (e) {
      print("❌ Bildirim Hatası: $e");
    }
  }

  Future<void> cancelNotification(int id) async {
    // 5. DÜZELTME: cancel metodundaki id bile isimli oldu
    await _notificationsPlugin.cancel(id: id);
  }
}