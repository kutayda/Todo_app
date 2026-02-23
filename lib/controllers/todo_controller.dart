import 'dart:async';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/todo_model.dart';
import '../services/database_service.dart';

// 1. Kural: ChangeNotifier yerine GetxController
class TodoController extends GetxController {
  
 
// ".obs" ekledik. Artık bu liste değiştiğinde ekran anında haberdar olacak.
  var todos = <Todo>[].obs; 
  var selectedDate = DateTime.now().obs;

  StreamSubscription? _todosSubscription;
  StreamSubscription? _authSubscription;

  // --- BAŞLANGIÇ (Eski Constructor yerine) ---
  @override
  void onInit() {
    super.onInit();
    _subscribeToAuthChanges(); 
  }

  void _subscribeToAuthChanges() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _initializeFirestore(user.uid);
      } else {
        _clearData();
      }
    });
  }

  void _initializeFirestore(String uid) {
    _todosSubscription?.cancel();
    _todosSubscription = DatabaseService(uid: uid).todos.listen((snapshotData) {
      todos.value = snapshotData; 
    });
  }

  void _clearData() {
    todos.clear(); 
    _todosSubscription?.cancel();
  }

  // --- EYLEMLER (ACTIONS) ---
  
  Future<void> addTodo(Todo todo) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await DatabaseService(uid: user.uid).addTodo(todo);
  }

  Future<void> updateTodo(Todo todo) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await DatabaseService(uid: user.uid).updateTodo(todo);
  }

  Future<void> deleteTodo(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await DatabaseService(uid: user.uid).deleteTodo(id);
  }

  Future<void> toggleTodoStatus(Todo todo) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final updatedTodo = Todo(
      id: todo.id,
      title: todo.title,
      description: todo.description,
      deadline: todo.deadline,
      priority: todo.priority,
      category: todo.category,
      isCompleted: !todo.isCompleted, 
    );
    await DatabaseService(uid: user.uid).updateTodo(updatedTodo);
  }

  // --- TAKVİM İŞLEMLERİ ---

  void setDate(DateTime date) {
    // Sadece değeri değiştiriyoruz, takvim anında güncellenecek!
    selectedDate.value = date; 
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
  
  List<Todo> getEventsForDay(DateTime day) {
    return todos.where((todo) => isSameDay(todo.deadline, day)).toList();
  }

  // --- BELLEK TEMİZLİĞİ (Eski dispose yerine) ---
  @override
  void onClose() {
    _todosSubscription?.cancel();
    _authSubscription?.cancel();
    super.onClose();
  }
}