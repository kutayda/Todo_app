import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Provider yerine GetX geldi
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/todo_model.dart';
import '../controllers/todo_controller.dart'; // Provider yerine Controller geldi
import '../l10n/app_localizations.dart';
import 'notification_helper.dart';

class DialogHelpers {
  
  static void showAddDialog(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    
    // 1. GETX BAĞLANTISI: Hafızadaki TodoController'ı buluyoruz
    final todoController = Get.find<TodoController>();

    final titleController = TextEditingController();
    final descController = TextEditingController();
    
    // 2. Oku: Provider yerine Controller'dan tarihi al (ve .value ekle)
    DateTime selectedDateTime = todoController.selectedDate.value;
    final now = DateTime.now();

    // Geçmiş zaman seçiliyse 5 dakika sonrasını öner
    if (selectedDateTime.isBefore(now)) {
      selectedDateTime = now.add(const Duration(minutes: 5));
    }
    
    int priority = 2; 
    Category selectedCategory = Category.general; 

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final dateFormat = isEnglish ? 'dd MMM yyyy - h:mm a' : 'dd MMM yyyy - HH:mm';

          return AlertDialog(
            title: Text(loc.newTask),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, decoration: InputDecoration(labelText: loc.title), autofocus: true),
                  TextField(controller: descController, decoration: InputDecoration(labelText: loc.description)),
                  const SizedBox(height: 20),
                  
                  DropdownButtonFormField<Category>(
                    initialValue: selectedCategory,
                    decoration: InputDecoration(labelText: "Kategori", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    items: Category.values.map((Category cat) {
                      return DropdownMenuItem<Category>(value: cat, child: Row(children: [Icon(cat.icon, color: cat.color, size: 20), const SizedBox(width: 10), Text(cat.name)]));
                    }).toList(),
                    onChanged: (Category? newValue) { if (newValue != null) setDialogState(() => selectedCategory = newValue); },
                  ),
                  const SizedBox(height: 15),

                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(context: context, initialDate: selectedDateTime, firstDate: DateTime.now(), lastDate: DateTime(2030), locale: Localizations.localeOf(context));
                      if (pickedDate != null) {
                        // ignore: use_build_context_synchronously
                        final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(selectedDateTime), builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: !isEnglish), child: child!));
                        if (pickedTime != null) { setDialogState(() { selectedDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute); }); }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Icon(Icons.access_time, color: Colors.deepPurple), Text(DateFormat(dateFormat, Localizations.localeOf(context).toString()).format(selectedDateTime), style: const TextStyle(fontWeight: FontWeight.bold))]),
                    ),
                  ),
                  const SizedBox(height: 15),

                  DropdownButton<int>(
                    value: priority, isExpanded: true,
                    // SİHİR BURADA: Emojiler yeni renk paletine (Turuncu ve Mavi) güncellendi.
                    items: [
                      DropdownMenuItem(value: 1, child: Text("🟠 ${loc.highPriority}")), 
                      DropdownMenuItem(value: 2, child: Text("🔵 ${loc.mediumPriority}")), 
                      DropdownMenuItem(value: 3, child: Text("🟢 ${loc.lowPriority}"))
                    ],
                    onChanged: (val) => setDialogState(() => priority = val!),
                  ),
                ],
              ),
            ),
            actions: [
              // Navigator.pop yerine GetX navigasyonu
              TextButton(onPressed: () => Get.back(), child: Text(loc.cancel)),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isEmpty) return;
                  if (selectedDateTime.isBefore(DateTime.now())) {
                     // 3. Eski ScaffoldMessenger yerine Get.snackbar
                     Get.snackbar("Hata", "⚠️ ${loc.pastTimeError}", backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                    return; 
                  }
                  
                  final newTodo = Todo(
                    id: const Uuid().v4(),
                    title: titleController.text,
                    description: descController.text,
                    deadline: selectedDateTime,
                    priority: priority,
                    category: selectedCategory,
                  );
                  
                  // 4. Ekleme işlemini Controller üzerinden yap
                  todoController.addTodo(newTodo);
                  
                  // BİLDİRİM KUR (UTC)
                  NotificationHelper().scheduleNotification(
                    id: newTodo.id.hashCode,
                    title: "Hatırlatıcı: ${newTodo.title}",
                    body: "Zamanı geldi!",
                    scheduledTime: selectedDateTime,
                  );

                  Get.back(); // Dialog'u kapat
                },
                child: Text(loc.add),
              )
            ],
          );
        },
      ),
    );
  }

  static void showEditDialog(BuildContext context, Todo todo) {
    final loc = AppLocalizations.of(context)!;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    
    // Controller'ı bul
    final todoController = Get.find<TodoController>();

    final titleController = TextEditingController(text: todo.title);
    final descController = TextEditingController(text: todo.description);
    DateTime selectedDateTime = todo.deadline;
    int priority = todo.priority;
    Category selectedCategory = todo.category;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final dateFormat = isEnglish ? 'dd MMM yyyy - h:mm a' : 'dd MMM yyyy - HH:mm';
          return AlertDialog(
            title: Text(loc.editTask),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, decoration: InputDecoration(labelText: loc.title)),
                  TextField(controller: descController, decoration: InputDecoration(labelText: loc.description)),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<Category>(
                    initialValue: selectedCategory,
                    decoration: InputDecoration(labelText: "Kategori", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    items: Category.values.map((Category cat) { return DropdownMenuItem<Category>(value: cat, child: Row(children: [Icon(cat.icon, color: cat.color, size: 20), const SizedBox(width: 10), Text(cat.name)])); }).toList(),
                    onChanged: (Category? newValue) { if (newValue != null) setDialogState(() => selectedCategory = newValue); },
                  ),
                  const SizedBox(height: 15),
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(context: context, initialDate: selectedDateTime, firstDate: DateTime(2020), lastDate: DateTime(2030), locale: Localizations.localeOf(context));
                      if (pickedDate != null) {
                        // ignore: use_build_context_synchronously
                        final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(selectedDateTime), builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: !isEnglish), child: child!));
                        if (pickedTime != null) { setDialogState(() { selectedDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute); }); }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Icon(Icons.edit_calendar, color: Colors.blueAccent), Text(DateFormat(dateFormat, Localizations.localeOf(context).toString()).format(selectedDateTime), style: const TextStyle(fontWeight: FontWeight.bold))]),
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButton<int>(
                    value: priority, isExpanded: true,
                    // SİHİR BURADA: Emojiler yeni renk paletine (Turuncu ve Mavi) güncellendi.
                    items: [
                      DropdownMenuItem(value: 1, child: Text("🟠 ${loc.highPriority}")), 
                      DropdownMenuItem(value: 2, child: Text("🔵 ${loc.mediumPriority}")), 
                      DropdownMenuItem(value: 3, child: Text("🟢 ${loc.lowPriority}"))
                    ],
                    onChanged: (val) => setDialogState(() => priority = val!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: Text(loc.cancel)),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isEmpty) return;
                  if (selectedDateTime != todo.deadline && selectedDateTime.isBefore(DateTime.now())) {
                     Get.snackbar("Hata", loc.pastTimeError, backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
                     return;
                  }
                  final updatedTodo = Todo(id: todo.id, title: titleController.text, description: descController.text, deadline: selectedDateTime, priority: priority, isCompleted: todo.isCompleted, category: selectedCategory);
                  
                  // Güncelleme işlemi Controller üzerinden
                  todoController.updateTodo(updatedTodo);
                  
                  // BİLDİRİMİ GÜNCELLE
                  NotificationHelper().cancelNotification(todo.id.hashCode);
                  NotificationHelper().scheduleNotification(id: updatedTodo.id.hashCode, title: "Hatırlatıcı: ${updatedTodo.title}", body: "Zamanı geldi!", scheduledTime: selectedDateTime);

                  Get.back();
                },
                child: Text(loc.save),
              )
            ],
          );
        },
      ),
    );
  }

  static void showOptions(BuildContext context, Todo todo) {
    final loc = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10), Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))), const SizedBox(height: 20),
              Text(todo.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
              ListTile(leading: const Icon(Icons.edit, color: Colors.blue), title: Text(loc.editTask), onTap: () { Get.back(); showEditDialog(context, todo); }),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(loc.delete),
                onTap: () {
                  Get.back(); // Önce alttan çıkan BottomSheet'i kapat
                  
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  // SONRA ONAY PENCERESİNİ AÇ
                  Get.defaultDialog(
                    title: "Görevi Sil",
                    middleText: "Bu görevi silmek istediğine emin misin?",
                    textCancel: "İptal",
                    textConfirm: "Evet, Sil",
                    confirmTextColor: Colors.white,
                    buttonColor: Colors.red,
                    cancelTextColor: isDark ? Colors.white : Colors.black,
                    onConfirm: () {
                      Get.find<TodoController>().deleteTodo(todo.id);
                      NotificationHelper().cancelNotification(todo.id.hashCode);
                      Get.back(); // Dialog'u kapat
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}