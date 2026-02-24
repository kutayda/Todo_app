import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:todo_app/l10n/app_localizations.dart';
import 'package:todo_app/models/todo_model.dart';
import 'package:todo_app/providers/local_provider.dart';
import 'package:todo_app/utils/notification_helper.dart';
import '../providers/theme_provider.dart';
import '../widgets/todo_calendar.dart';
import '../utils/dialog_helpers.dart';
import '../controllers/todo_controller.dart'; 

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final TodoController todoController = Get.put(TodoController());
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.appTitle),
        elevation: 0,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(themeProvider.isDarkMode
                    ? Icons.light_mode
                    : Icons.dark_mode),
                onPressed: () {
                  themeProvider.toggleTheme(!themeProvider.isDarkMode);
                },
              );
            },
          ),
          
          PopupMenuButton<String>(
            onSelected: (value) {
              final localeProvider =
                  Provider.of<LocaleProvider>(context, listen: false);
              if (value == 'tr') {
                localeProvider.setLocale(const Locale('tr'));
              } else {
                localeProvider.setLocale(const Locale('en'));
              }
            },
            icon: const Icon(Icons.language),
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                  value: 'tr', child: Row(children: [Text("🇹🇷 Türkçe")])),
              const PopupMenuItem(
                  value: 'en', child: Row(children: [Text("🇺🇸 English")])),
            ],
          ),

          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
            tooltip: 'Çıkış Yap',
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Çıkış Yap"),
                  content: const Text(
                      "Hesabından çıkış yapmak istediğine emin misin?"),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(result: false), // GetX Navigation
                      child: const Text("İptal"),
                    ),
                    TextButton(
                      onPressed: () => Get.back(result: true), // GetX Navigation
                      child: const Text("Evet, Çık",
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                await FirebaseAuth.instance.signOut();
              }
            },
          ),
        ],
      ),
      
      body: Column(
        children: [
          Obx(() => TodoCalendar(
                focusedDay: todoController.selectedDate.value,
                selectedDay: todoController.selectedDate.value,
                todos: todoController.todos, 
                onDaySelected: (selectedDay, focusedDay) {
                  todoController.setDate(selectedDay);
                },
              )),

          const Divider(),
          Padding(
            padding : const EdgeInsetsGeometry.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchController, // Controller'ı bağladık
              onChanged: (value) => todoController.uptadeSearchQuery(value),
              decoration: InputDecoration(
                hintText: "Görevlerde ara...",
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                suffixIcon: Obx(() => todoController.searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          searchController.clear(); 
                          todoController.uptadeSearchQuery(''); 
                          FocusScope.of(context).unfocus(); 
                        },
                      )
                    : const SizedBox.shrink(), 
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[800] 
                    : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // 2. GÖREV LİSTESİ (Obx)
          Expanded(
            child: Obx(() {
              final dailyTodos =
                  todoController.filteredDailyTodos;
              if (todoController.isLoading.value) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.blueAccent),  
                      SizedBox(height: 16),
                      Text("Sunucudan veriler çekiliyor...", style: TextStyle(color: Colors.grey)),
                    ],
                  )
                );
              }
              if (dailyTodos.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event_available,
                          size: 80, color: Colors.grey),
                      const SizedBox(height: 10),
                      Text(
                        "Bugün için görev yok 🎉",
                        style:
                            TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: dailyTodos.length,
                itemBuilder: (context, index) {
                  final todo = dailyTodos[index];

                  final bool isOverdue = todo.deadline.isBefore(DateTime.now()) && !todo.isCompleted;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: Checkbox(
                        value: todo.isCompleted,
                        onChanged: isOverdue ? null : (_) => todoController.toggleTodoStatus(todo),
                      ),
                      
                      // Başlık
                      title: Text(
                        todo.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                          color: todo.isCompleted ? Colors.grey : null,
                        ),
                      ),
                      
                      // Alt Başlık
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (todo.description.isNotEmpty) ...[
                            Text(
                              todo.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                          ],
                          Wrap(
                            spacing: 12.0, 
                            runSpacing: 4.0, 
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time, size: 14, color: isOverdue ? Colors.red : Colors.blueGrey),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${todo.deadline.hour.toString().padLeft(2, '0')}:${todo.deadline.minute.toString().padLeft(2, '0')}",
                                    style: TextStyle(
                                      fontSize: 12, 
                                      color: isOverdue ? Colors.red : Colors.blueGrey, 
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  if (isOverdue) ...[
                                    const SizedBox(width: 4),
                                    const Text(
                                      "(Gecikti)", 
                                      style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)
                                    ),
                                  ],
                                ],
                              ),

                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(todo.category.icon, size: 14, color: todo.category.color),
                                  const SizedBox(width: 4),
                                  Text(todo.category.name, style: TextStyle(fontSize: 12, color: todo.category.color)),
                                ],
                              ),
                              
                              Text(
                                todo.priority == 1 ? "🟠 Yüksek" : todo.priority == 2 ? "🔵 Orta" : "🟢 Düşük",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          Get.defaultDialog(
                            title: "Görevi Sil",
                            middleText: "Bu görevi silmek istediğine emin misin?",
                            textCancel: "İptal",
                            textConfirm: "Evet, Sil",
                            confirmTextColor: Colors.white,
                            buttonColor: Colors.red,
                            cancelTextColor: isDark ? Colors.white : Colors.black,
                            onConfirm: () {
                              todoController.deleteTodo(todo.id);
                              NotificationHelper().cancelNotification(todo.id.hashCode);
                              Get.back();
                            },
                          );
                        },
                      ),
                      
                      // Düzenleme
                      onTap: () {
                        DialogHelpers.showEditDialog(context, todo);
                      },
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),

      // BUTONLAR
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // TEST BUTONU (Bildirim Testi)
          FloatingActionButton(
            heroTag: "test_btn",
            backgroundColor: Colors.red,
            onPressed: () {
              NotificationHelper().showInstantNotification(
                id: 999,
                title: "Test Başarılı! 🎉",
                body: "Bildirimler çalışıyor!",
              );
            },
            child: const Icon(Icons.notifications_active),
          ),
          const SizedBox(height: 10),

          // EKLEME BUTONU
          FloatingActionButton(
            heroTag: "add_btn",
            onPressed: () => DialogHelpers.showAddDialog(context),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}