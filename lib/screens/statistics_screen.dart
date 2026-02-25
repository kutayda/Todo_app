// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/todo_controller.dart';
import '../models/todo_model.dart'; // Todo modelini listelemek için ekledik

class StatisticsScreen extends StatelessWidget {
  StatisticsScreen({super.key});

  final TodoController controller = Get.find<TodoController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("İstatistikler & Analiz"),
        elevation: 0,
      ),
      body: Obx(() {
        // --- 1. SADECE RAKAMLARI DEĞİL, LİSTELERİ DE HESAPLIYORUZ ---
        final totalList = controller.todos.toList();
        
        final completedList = controller.todos
            .where((t) => t.isCompleted).toList();
            
        final now = DateTime.now();
        final overdueList = controller.todos
            .where((t) => t.deadline.isBefore(now) && !t.isCompleted).toList();
            
        final pendingList = controller.todos
            .where((t) => !t.isCompleted && !t.deadline.isBefore(now)).toList();

        final progress = totalList.isEmpty ? 0.0 : completedList.length / totalList.length;

        if (totalList.isEmpty) {
          return const Center(child: Text("Henüz hiç görev eklemedin. İstatistikler burada görünecek!"));
        }

        // --- 2. EKRAN TASARIMI ---
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Genel İlerleme", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("%${(progress * 100).toStringAsFixed(1)} Tamamlandı", 
                              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                          Text("${completedList.length} / ${totalList.length} Görev"),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              const Text("Detaylı Özet (İncelemek için tıklayın)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 16),

              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    // Rakamlar yerine artık Listeleri (completedList vb.) gönderiyoruz
                    _buildStatCard("Tamamlanan", completedList, Colors.green, Icons.check_circle),
                    _buildStatCard("Bekleyen", pendingList, Colors.orange, Icons.hourglass_empty),
                    _buildStatCard("Geciken", overdueList, Colors.red, Icons.cancel),
                    _buildStatCard("Toplam", totalList, Colors.blueGrey, Icons.format_list_bulleted),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // --- 3. TIKLANABİLİR VE AÇILIR KUTUCUK (SİHİR BURADA) ---
  Widget _buildStatCard(String title, List<Todo> tasks, Color color, IconData icon) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // Kutuya tıklanınca ekranın altından liste açılır
        Get.bottomSheet(
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Get.theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("$title (${tasks.length})", 
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Get.back())
                  ],
                ),
                const Divider(),
                Expanded(
                  child: tasks.isEmpty
                      ? Center(child: Text("Bu kategoride görev bulunmuyor.", style: TextStyle(color: Colors.grey[600])))
                      : ListView.builder(
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final todo = tasks[index];
                            return ListTile(
                              leading: Icon(icon, color: color),
                              title: Text(todo.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("${todo.deadline.day.toString().padLeft(2,'0')}/${todo.deadline.month.toString().padLeft(2,'0')}/${todo.deadline.year} - ${todo.deadline.hour.toString().padLeft(2,'0')}:${todo.deadline.minute.toString().padLeft(2,'0')}"),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blueAccent),
                              onTap: () {
                                // 1. Paneli Kapat
                                Get.back(); 
                                // 2. İstatistik ekranını kapatıp Ana Sayfaya dön
                                Get.back(); 
                                // 3. Takvimi o görevin olduğu güne kaydır!
                                controller.setDate(todo.deadline); 
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          isScrollControlled: false, // Panelin ekranın yarısını kaplamasını sağlar
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              // tasks.length ile listenin boyutunu rakam olarak yazdırıyoruz
              Text(tasks.length.toString(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}