import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  // Varsayılan dil (İstersen 'en' yapabilirsin)
  Locale _locale = const Locale('tr'); 

  Locale get locale => _locale;

  // Dili değiştiren fonksiyon
  void setLocale(Locale locale) {
    if (!['en', 'tr'].contains(locale.languageCode)) return;
    
    _locale = locale;
    notifyListeners(); // Ekranı yenile!
  }
}