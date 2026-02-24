import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/todo_model.dart';

class TodoCalendar extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final Function(DateTime, DateTime) onDaySelected;
  final List<Todo> todos;

  const TodoCalendar({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    required this.todos,
  });

  // Zaman kontrolünü burada helper olarak tutuyoruz
  bool _isDeadlinePassed(DateTime deadline) {
    final now = DateTime.now();
    final currentMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final todoDeadlineMinute = DateTime(deadline.year, deadline.month, deadline.day, deadline.hour, deadline.minute);
    return currentMinute.isAfter(todoDeadlineMinute);
  }

  // Tarihleri karşılaştıran yardımcı fonksiyon
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final minDate = DateTime(now.year, now.month, now.day - 7);
    final maxDate = DateTime(now.year, now.month, now.day + 21);

    // KEY ekleyerek takvimi zorla yeniletiyoruz (Dakika değişimini yakalamak için)
    return TableCalendar(
      key: ValueKey("${now.year}-${now.month}-${now.day} ${now.hour}:${now.minute}"),
      locale: currentLocale,
      calendarFormat: CalendarFormat.week,
      availableCalendarFormats: const {CalendarFormat.week: 'Hafta'},
      firstDay: minDate,
      lastDay: maxDate,
      focusedDay: selectedDay,
      currentDay: DateTime.now(),
      selectedDayPredicate: (day) => _isSameDay(selectedDay, day),
      onDaySelected: onDaySelected,
      
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
      ),
      calendarStyle: const CalendarStyle(
        todayDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
        selectedDecoration: BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
      ),
      
      // Etkinlikleri (Noktaları) yükleyen kısım
      eventLoader: (day) => todos.where((t) => _isSameDay(t.deadline, day)).toList(),
      
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          if (events.isEmpty) return const SizedBox();
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: events.map((event) {
              final todo = event as Todo;
              final isDeadlinePassed = _isDeadlinePassed(todo.deadline);

              Color dotColor;
              if (todo.isCompleted) {
                dotColor = Colors.grey.shade300;
              } else if (isDeadlinePassed) {
                dotColor = Colors.red;
              } else {
                switch (todo.priority) {
                  case 1: dotColor = Colors.deepOrange; break;
                  case 2: dotColor = Colors.blue; break;
                  default: dotColor = Colors.green;
                }
              }
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                width: 7, height: 7,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}