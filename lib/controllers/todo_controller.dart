import 'dart:async';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/todo_model.dart';
import '../services/database_service.dart';

// 1. Kural: ChangeNotifier yerine GetxController
class TodoController extends GetxController {
  
 
  var searchQuery = ''.obs;
  var todos = <Todo>[].obs; 
  var selectedDate = DateTime.now().obs;
  var isLoading = false.obs;

  StreamSubscription? _todosSubscription;
  StreamSubscription? _authSubscription;

  @override
  void onInit() {
    super.onInit();
    fetchTodosFromApi();
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

  Future<void> fetchTodosFromApi() async{
    try {
      isLoading.value = true;
      await Future.delayed(const Duration(seconds: 2));
    }catch(e){
      Get.snackbar("Bağlantı Hatası", "Sunucuya ulaşılamadı: $e");
    }finally{
      isLoading.value = false;
    }
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


  void setDate(DateTime date) {
    // Sadece değeri değiştiriyor
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

  // Arama metnini güncelleme 
  void uptadeSearchQuery(String query){
    searchQuery.value = query;
  }
  List<Todo> get filteredDailyTodos{
    if (searchQuery.value.isEmpty) {
      return getEventsForDay(selectedDate.value);
    }
    
    // 2. Durum: Eğer arama kutusu DOLUYSA, takvimi yoksay ve TÜM GÖREVLER (todos) içinde ara
    return todos.where((todo) =>
        todo.title.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
        todo.description.toLowerCase().contains(searchQuery.value.toLowerCase())
    ).toList();
  }
  @override
  void onClose() {
    _todosSubscription?.cancel();
    _authSubscription?.cancel();
    super.onClose();
  }
}