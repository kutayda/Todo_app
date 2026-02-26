import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class  NotificationController extends GetxController {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  @override
  void onInit(){
    super.onInit();
    requestPermission();
    listenToForegroundMessages();
  }

  void requestPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print("Kullanıcı bildirim izni: ${settings.authorizationStatus}");

    String? token = await messaging.getToken();
    print("FCM CİHAZ TOKEN'I: $token");
  }

  void listenToForegroundMessages(){
    FirebaseMessaging.onMessage.listen((RemoteMessage message){
      print("Ön planda mesaj geldi!");

      if(message.notification != null){
        Get.snackbar(
          message.notification!.title! ?? 'Yeni Bildirim',
          message.notification!.body! ?? '',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.blueAccent.withOpacity(0.9),
          colorText: Colors.white,
          icon: const Icon(Icons.notifications_active, color: Colors.white),
          duration: const Duration(seconds: 5),
        );
      }
    });
  }

   
}