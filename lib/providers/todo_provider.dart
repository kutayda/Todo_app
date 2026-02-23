import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/todo_model.dart';

class TodoProvider extends ChangeNotifier {
  // 1. Yerel Listemiz (Ekranda gösterilecek olan)
  List<Todo> _todos = [];

  // Dışarıya açılan kapı (Getter)
  List<Todo> get todos => _todos;

  // Seçili tarih (Takvim için)
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  // Canlı Yayın Aboneliği (İşi bitince iptal etmek için)
  StreamSubscription? _todosSubscription;

  // --- KURUCU METOT ---
  TodoProvider() {
    _subscribeToAuthChanges();
  }

  // 🔥 SİHİRLİ KISIM: Firestore'u Dinle
  void _subscribeToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // 1. Kullanıcı Giriş Yaptı:
        print("Kullanıcı değişti: ${user.email} - Veriler yükleniyor...");
        _initializeFirestore(user.uid);
      } else {
        // 2. Kullanıcı Çıkış Yaptı:
        print("Kullanıcı çıkış yaptı - Hafıza temizleniyor...");
        _clearData();
      }
    });
  }

  void _initializeFirestore(String uid) {
    _todosSubscription?.cancel();
    
    _todosSubscription = DatabaseService(uid: uid).todos.listen((snapshotData) {
      _todos = snapshotData;
      notifyListeners();
    });
  }

  
  void _clearData() {
    _todos = []; 
    _todosSubscription?.cancel();
    notifyListeners(); 
  }


  
  Future<void> addTodo(Todo todo) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await DatabaseService(uid: user.uid).addTodo(todo);
  }

  // Güncelleme
  Future<void> updateTodo(Todo todo) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await DatabaseService(uid: user.uid).updateTodo(todo);
  }

  // Silme
  Future<void> deleteTodo(String id) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await DatabaseService(uid: user.uid).deleteTodo(id);
  }

  // Tamamlandı / Tamamlanmadı Yapma (Toggle)
  Future<void> toggleTodoStatus(Todo todo) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final updatedTodo = Todo(
      id: todo.id,
      title: todo.title,
      description: todo.description,
      deadline: todo.deadline,
      priority: todo.priority,
      category: todo.category,
      isCompleted: !todo.isCompleted, // Tersi yap
    );

    await DatabaseService(uid: user.uid).updateTodo(updatedTodo);
  }


  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  // İki tarih aynı gün mü? (Yardımcı Fonksiyon)
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Seçili güne ait görevleri filtrele
  List<Todo> getEventsForDay(DateTime day) {
    return _todos.where((todo) => isSameDay(todo.deadline, day)).toList();
  }

  // --- BELLEK TEMİZLİĞİ ---
  @override
  void dispose() {
    _todosSubscription
        ?.cancel(); // Aboneliği iptal et (Hafıza sızıntısını önler)
    super.dispose();
  }
}
