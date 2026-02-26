import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';

class LocalNotifController extends GetxController {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void onInit() {
    super.onInit();
    _initNotifications();
  }

  // 1. BAŞLANGIÇ AYARLARI
  Future<void> _initNotifications() async {
    // Cihazın GERÇEK saat dilimini bul ve sisteme tanıt
    tz.initializeTimeZones();
    final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier)); // İŞTE ÇÖZÜM BURASI

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    // İzin İsteme
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  // 2. GÖREV ZAMANLAMA
  Future<void> scheduleTodoAlarm(int id, String title, String body, DateTime scheduledTime) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    // Artık saat kayması yok! Doğrudan cihazın kendi yerel saat dilimini kullanıyoruz.
    final scheduledDateLocal = tz.TZDateTime.from(scheduledTime, tz.local);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id, 
      title: title, 
      body: body,  
      scheduledDate: scheduledDateLocal, // GÜNCELLENDİ
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'todo_channel_v3', // Kanalı yeniledik ki eski hatalı ayarlar silinsin
          'Görev Bildirimleri', 
          channelDescription: 'Zamanı gelen görevler için hatırlatıcılar',
          importance: Importance.max, 
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true, 
          enableVibration: true, 
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
    );
    
    // Terminalde alarmın tam olarak hangi saate kurulduğunu göreceğiz
    print("🔔 Alarm Kuruldu! Görev: $title | Zaman: $scheduledDateLocal");
  }

  // Görev silinirse veya tamamlanırsa alarmı iptal etme
  Future<void> cancelAlarm(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
    print("🔕 Alarm İptal Edildi. ID: $id");
  }
  // --- HATA AYIKLAMA (DEBUG) İÇİN ANINDA BİLDİRİM ---
  // --- HATA AYIKLAMA (DEBUG) İÇİN ANINDA BİLDİRİM ---
  Future<void> showInstantTest() async {
    await flutterLocalNotificationsPlugin.show(
      id: 999, // DÜZELTİLDİ: id etiketi eklendi
      title: "🚀 Sistem Testi Başarılı!", // DÜZELTİLDİ: title etiketi eklendi
      body: "Eğer bunu görüyorsan, bildirim motoru ve ikonlar kusursuz çalışıyor!", // DÜZELTİLDİ: body etiketi eklendi
      notificationDetails: const NotificationDetails( // DÜZELTİLDİ: notificationDetails etiketi eklendi
        android: AndroidNotificationDetails(
          'test_channel_1',
          'Test Bildirimleri',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_launcher', // Sadece ic_launcher
        ),
      ),
    );
    print("🔥 ANINDA BİLDİRİM FIRLATILDI!");
  }
}