import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'todo_model.g.dart';


@HiveType(typeId: 1)
enum Category {
  @HiveField(0)
  work,
  @HiveField(1)
  personal,
  @HiveField(2)
  school,
  @HiveField(3)
  general,
}

extension CategoryExtension on Category {
  String get name {
    switch (this) {
      case Category.work: return 'İş';
      case Category.personal: return 'Kişisel';
      case Category.school: return 'Okul';
      case Category.general: return 'Genel';
    }
  }

  Color get color {
    switch (this) {
      case Category.work: return Colors.blueAccent;
      case Category.personal: return Colors.purpleAccent;
      case Category.school: return Colors.orangeAccent;
      case Category.general: return Colors.grey;
    }
  }
  
  IconData get icon {
     switch (this) {
      case Category.work: return Icons.work;
      case Category.personal: return Icons.person;
      case Category.school: return Icons.school;
      case Category.general: return Icons.circle;
    }
  }
}


@HiveType(typeId: 0)
class Todo {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final DateTime deadline;
  
  @HiveField(4)
  final int priority;
  
  @HiveField(5)
  bool isCompleted;

  @HiveField(6, defaultValue: Category.general) 
  final Category category;

  Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.priority,
    this.isCompleted = false,
    this.category = Category.general,
  });


  Map<String,dynamic> toMap(){
    return {
      'id': id,
      'title': title,
      'description': description,
      'deadline': deadline.toIso8601String(),
      'priority': priority,
      'isCompleted': isCompleted,
      'category': category.name,
    };
  }


  factory Todo.fromMap(Map<String,dynamic> map){
    return Todo(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      deadline: DateTime.parse(map['deadline']),
      priority: map['priority'],
      isCompleted: map['isCompleted'],
      category: Category.values.firstWhere((cat) => cat.name == map['category']),
    );
  }



  bool get isOverdue {
    if (isCompleted) return false;
    final now = DateTime.now();

    final currentMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final taskMinute = DateTime(deadline.year, deadline.month, deadline.day, deadline.hour, deadline.minute);
    return taskMinute.isBefore(currentMinute);
  }
}