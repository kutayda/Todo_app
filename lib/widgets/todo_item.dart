// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo_model.dart';

class TodoItem extends StatelessWidget {
  final Todo todo;
  final Function(bool?) onStatusChanged;
  final VoidCallback onTap;

  const TodoItem({
    super.key,
    required this.todo,
    required this.onStatusChanged,
    required this.onTap,
  });

  // Zaman kontrolünü yapan fonksiyon
  bool _checkIsOverdue(DateTime deadline) {
    final now = DateTime.now();
    final currentMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final todoDeadlineMinute = DateTime(deadline.year, deadline.month, deadline.day, deadline.hour, deadline.minute);
    return currentMinute.isAfter(todoDeadlineMinute);
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    
    // 1. GÖRSEL İÇİN KONTROL (Ekran ilk çizildiğindeki durum)
    final bool isVisualOverdue = _checkIsOverdue(todo.deadline);
    
    final timePattern = currentLocale == 'en' ? 'h:mm a' : 'HH:mm';
    final timeString = DateFormat(timePattern, currentLocale).format(todo.deadline);

    Color priorityColor;
    TextStyle titleStyle;

    if (todo.isCompleted) {
      priorityColor = Colors.grey;
      titleStyle = TextStyle(color: Theme.of(context).disabledColor);
    } else if (isVisualOverdue && !todo.isCompleted) {
      priorityColor = Colors.red;
      titleStyle = const TextStyle(color: Colors.red, fontWeight: FontWeight.bold);
    } else {
      switch (todo.priority) {
        case 1: priorityColor = Colors.red; break;
        case 2: priorityColor = Colors.orange; break;
        default: priorityColor = Colors.green;
      }
      titleStyle = TextStyle(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
        fontWeight: FontWeight.w600,
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        onTap: onTap,
        leading: Container(width: 5, height: double.infinity, color: priorityColor),
        title: Row(
          children: [
            // Kategori Etiketi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: todo.category.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: todo.category.color.withOpacity(0.5)),
              ),
              child: Text(
                todo.category.name,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: todo.category.color,
                ),
              ),
            ),
            Expanded(child: Text(todo.title, style: titleStyle)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (isVisualOverdue && !todo.isCompleted)
               const Text("⚠️ Zamanı Geçti!", style: TextStyle(color: Colors.redAccent))
            else
               Text(todo.description),
            
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(timeString, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ],
        ),
        
        trailing: Checkbox(
          value: todo.isCompleted,
          activeColor: Colors.green,
          side: isVisualOverdue
              ? const BorderSide(color: Colors.redAccent, width: 2)
              : BorderSide(color: Theme.of(context).unselectedWidgetColor, width: 1.5),
          
          onChanged: (newValue) {
            final bool isRealTimeOverdue = _checkIsOverdue(todo.deadline);

            if (isRealTimeOverdue && !todo.isCompleted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("⚠️ Süresi geçtiği için durum değiştirilemez!"),
                  backgroundColor: Colors.redAccent,
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              onStatusChanged(newValue);
            }
          },
        ),
      ),
    );
  }
}