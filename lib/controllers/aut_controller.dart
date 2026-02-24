import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';

class AuthController extends GetxController {
  bool isLogin = true; 
  bool isLoading = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Giriş/Kayıt modunu değiştiren fonksiyon
  void toggleAuthMode() {
    isLogin = !isLogin;
    update(); // UI'daki GetBuilder'a "Ekranı güncelle" komutu gönderir
  }

  // Formu Gönderme (Giriş veya Kayıt)
  Future<void> submit() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) return;

    isLoading = true;
    update(); // Yüklenme animasyonunu başlat

    try {
      if (isLogin) {
        await AuthService().signIn(emailController.text, passwordController.text);
      } else {
        await AuthService().signUp(emailController.text, passwordController.text);
      }
    } catch (e) {
      Get.snackbar(
        "Hata", 
        e.toString(), 
        backgroundColor: Colors.red, 
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading = false;
      update(); // İşlem bitince animasyonu durdur
    }
  }

  // Hafıza Yönetimi: Sayfa kapandığında TextField'ları RAM'den temizle
  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}