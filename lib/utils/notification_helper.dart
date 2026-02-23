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
    // Yerel konum ne olursa olsun UTC (Evrensel) saati baz alacağız.
    tz.setLocalLocation(tz.UTC);

    const AndroidInitializationSettings androidSettings =
        // Hata riskini sıfıra indirmek için Android'in kendi ikonunu kullanıyoruz
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

    await _notificationsPlugin.initialize(
      initSettings,
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
        'todo_channel_utc_final', // Kanal ID'si (Yeni)
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
    await _notificationsPlugin.show(
      id,
      title,
      body,
      _notificationDetails(),
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

      // Senin seçtiğin saati UTC'ye çevirip sisteme veriyoruz.
      // Bu sayede Emülatörün "Timezone" ayarı ne olursa olsun saat şaşmaz.
      final scheduledDateUTC = tz.TZDateTime.from(scheduledTime.toUtc(), tz.UTC);

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDateUTC,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      print("✅ Bildirim Kuruldu (UTC): $scheduledDateUTC");
    } catch (e) {
      print("❌ Bildirim Hatası: $e");
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}