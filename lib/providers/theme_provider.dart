import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier{
  ThemeMode _themeMode = ThemeMode.light; 

  ThemeMode get themeMode => _themeMode;

  ThemeProvider(){
    _loadFromPrefs();   
  }

  void toggleTheme(bool isDark){
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _saveToPrefs();
    notifyListeners();
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> _loadFromPrefs()async {
    final prefs = await SharedPreferences.getInstance();  
    final isDark = prefs.getBool('isDark') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> _saveToPrefs()async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _themeMode == ThemeMode.dark);  
  }
}