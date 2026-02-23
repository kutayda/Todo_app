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
import '../controllers/todo_controller.dart'; // Yeni Controller'ımız eklendi

// 1. StatefulWidget yerine StatelessWidget kullanıyoruz.
class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  // 2. DEPENDENCY INJECTION: Controller'ı UI'a bağlıyoruz
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
          // TEMA BUTONU (Provider ile kalmasında sorun yok)
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
          
          // DİL BUTONU (Provider ile kalmasında sorun yok)
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

          // ÇIKIŞ YAP BUTONU
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
          // 1. TAKVİM (Obx ile sarıldı, çünkü selectedDate ve todos değişecek)
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
                // SİHİR BURADA: Arama kutusu doluysa X butonunu göster, boşsa gizle
                suffixIcon: Obx(() => todoController.searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          searchController.clear(); // Kutuyu temizle
                          todoController.uptadeSearchQuery(''); // Listeyi eski haline getir
                          FocusScope.of(context).unfocus(); // Klavyeyi kapat
                        },
                      )
                    : const SizedBox.shrink(), // Boşluk (Görünmez widget)
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

          // 2. GÖREV LİSTESİ (Obx ile sarıldı)
          Expanded(
            child: Obx(() {
              final dailyTodos =
                  todoController.filteredDailyTodos;
              // Liste boşsa
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

              // Listeyi Göster
              return ListView.builder(
                itemCount: dailyTodos.length,
                itemBuilder: (context, index) {
                  final todo = dailyTodos[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      // Checkbox
                      leading: Checkbox(
                        value: todo.isCompleted,
                        onChanged: (_) {
                          todoController.toggleTodoStatus(todo);
                        },
                      ),
                      // Başlık
                      title: Text(
                        todo.title,
                        style: TextStyle(
                          decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                          color: todo.isCompleted ? Colors.grey : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            todo.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              // Kategori İkonu ve İsmi
                              Icon(todo.category.icon, size: 14, color: todo.category.color),
                              const SizedBox(width: 4),
                              Text(todo.category.name, style: TextStyle(fontSize: 12, color: todo.category.color)),
                              const SizedBox(width: 12),
                              // Öncelik Durumu
                              Text(
                                todo.priority == 1 ? "🔴 Yüksek" : todo.priority == 2 ? "🟠 Orta" : "🟢 Düşük",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // SİLME BUTONU (Onay Pencereli)
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // GetX'in süper kolay Dialog penceresi:

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
                              Get.back(); // Dialog'u kapat
                            },
                          );
                        },
                      ),
                      // Düzenleme Dialog'unu Çağırma
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