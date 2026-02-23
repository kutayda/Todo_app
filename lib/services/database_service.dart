import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo_app/models/todo_model.dart';

class DatabaseService {
  final String uid;
  DatabaseService({required this.uid});

  CollectionReference get todosRef {
    return FirebaseFirestore.instance
    .collection("users")
    .doc(uid)
    .collection("todos");
  }

  Future<void> addTodo(Todo todo){
    return todosRef.doc(todo.id).set(todo.toMap());
  }

Stream<List<Todo>> get todos {
    // 1. Boruyu dinle (Stream başlat)
    return todosRef.snapshots().map((snapshot) {
      
      
      return snapshot.docs.map((doc) {
        
        
        final data = doc.data() as Map<String, dynamic>;

        return Todo.fromMap(data); 

      }).toList(); 
    });
  }

  Future<void> updateTodo(Todo todo) {
    return todosRef.doc(todo.id).set(todo.toMap());
  }
  
  Future<void> deleteTodo(String id){
    return todosRef.doc(id).delete();
  }

}