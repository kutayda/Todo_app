import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'models/todo_model.dart';
import 'providers/theme_provider.dart';
import 'providers/local_provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'utils/notification_helper.dart';
import 'l10n/app_localizations.dart';

void main() async {
  // 1. Flutter engine ve widget'ları hazırla
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Firebase'i başlat (Null Safety uyumlu)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Hive (Yerel Veritabanı) kurulumu
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TodoAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(CategoryAdapter());
  await Hive.openBox<Todo>('todos_box');

  // 4. Bildirim sistemini başlat
  await NotificationHelper().init();

  runApp(
    MultiProvider(
      providers: [
        // Sadece Tema ve Dil provider'ları kaldı, TodoProvider'ı sildik.
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      // HATA BURADAYDI: child olarak GetMaterialApp değil, MyApp'i çağırmalıyız!
      child: const MyApp(), 
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumer3 yerine Consumer2 kullanıyoruz çünkü TodoProvider artık yok
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        
        return GetMaterialApp(
          title: 'Todo App Pro',
          debugShowCheckedModeBanner: false,

          // UYGULAMA İLK BURADAN BAŞLAR:
          home: const AuthWrapper(),

          // Tema Ayarları
          theme: ThemeData.light(useMaterial3: true),
          darkTheme: ThemeData.dark(useMaterial3: true),
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

          // Dil ve Yerelleştirme Ayarları
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('tr'),
            Locale('en'),
          ],
        );
      },
    );
  }
}

// --- AUTH WRAPPER ---
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // Giriş yapılmışsa GetX mimarisine uygun HomeScreen'i aç
          return HomeScreen(); 
        }

        // Kullanıcı yoksa AuthScreen'e yönlendir
        return const AuthScreen();
      },
    );
  }
}