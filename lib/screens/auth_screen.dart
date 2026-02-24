import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todo_app/controllers/aut_controller.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          // GetBuilder ile Controller'ı sayfaya bağlıyoruz!!!
          child: GetBuilder<AuthController>(
            init: AuthController(), // İlk açılışta Controller'ı başlatır
            builder: (controller) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    controller.isLogin ? "Hoş Geldin" : "Hesap Oluştur", 
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 30),
                  
                  TextField(
                    controller: controller.emailController,
                    decoration: const InputDecoration(labelText: "E-posta", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 15),
                  
                  TextField(
                    controller: controller.passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Şifre", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 25),
                  
                  // Yükleniyor durumuna göre buton veya animasyon gösterimi
                  controller.isLoading 
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: controller.submit,
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                        child: Text(controller.isLogin ? "Giriş Yap" : "Kayıt Ol"),
                      ),
                      
                  TextButton(
                    onPressed: controller.toggleAuthMode,
                    child: Text(controller.isLogin ? "Hesabın yok mu? Kayıt Ol" : "Zaten hesabın var mı? Giriş Yap"),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}