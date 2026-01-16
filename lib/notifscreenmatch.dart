import 'package:flutter/material.dart';
import 'datarepo.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final DataRepository _repo = DataRepository();

  // Sigurna provera datuma (hendluje null i loše formate)
  bool _isToday(String? dateString) {
    if (dateString == null || dateString.isEmpty) return false;
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      return date.year == now.year && date.month == now.month && date.day == now.day;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text("RealTalk", 
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 15), 
            child: Icon(Icons.notifications, color: Colors.black)
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _repo.fetchNotifications(),
        builder: (context, snapshot) {
          // 1. Dok se podaci učitavaju
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }

          // 2. Ako se desi greška u komunikaciji sa Supabase
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 50, color: Colors.red),
                    const SizedBox(height: 10),
                    Text("Greška: ${snapshot.error}", textAlign: TextAlign.center),
                    TextButton(onPressed: () => setState(() {}), child: const Text("Pokušaj ponovo"))
                  ],
                ),
              ),
            );
          }

          final allNotifs = snapshot.data ?? [];

          // FILTRIRANJE
          final newNotifs = allNotifs.where((n) => 
              _isToday(n['created_at']) && n['status'] == 'waiting'
          ).toList();

          final oldNotifs = allNotifs.where((n) => 
              !_isToday(n['created_at']) || n['status'] == 'accepted'
          ).toList();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ListView(
              children: [
                // SEKCIJA: NEW
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text("New", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                
                if (newNotifs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text("Nema novih zahteva", style: TextStyle(color: Colors.grey)),
                  ),

                // Mapiranje podataka iz baze
                ...newNotifs.map((n) => _buildNotifItem(
                      n['sender_name'] ?? "Korisnik", 
                      n['id'].toString(), 
                      n['status'] ?? "waiting"
                    )),

                // Primeri (da ekran ne bude prazan)
                _buildNotifItem("Marko (Demo)", "ex-new-1", "waiting"),

                // SEKCIJA: OLD
                const Padding(
                  padding: EdgeInsets.only(top: 30, bottom: 10),
                  child: Text("Old", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                
                ...oldNotifs.map((n) => _buildNotifItem(
                      n['sender_name'] ?? "Korisnik", 
                      n['id'].toString(), 
                      n['status'] ?? "accepted"
                    )),

                // Primeri za Old sekciju
                _buildNotifItem("Dusi Viber (Demo)", "ex-old-1", "accepted"),
                _buildNotifItem("Petar (Demo)", "ex-old-2", "waiting"),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotifItem(String name, String id, String status) {
    bool isAccepted = status == 'accepted';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[400], 
        borderRadius: BorderRadius.circular(20)
      ),
      child: Row(
        children: [
          const Icon(Icons.account_circle_outlined, size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              name, 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          if (isAccepted)
            const Icon(Icons.check_circle, color: Colors.black)
          else
            IconButton(
              icon: const Icon(Icons.add_task, color: Colors.black),
              onPressed: () async {
                if (!id.startsWith("ex-")) {
                  await _repo.acceptNotification(id);
                  setState(() {}); // Osvežava FutureBuilder
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Ovo je demo stavka"))
                  );
                }
              },
            ),
        ],
      ),
    );
  }
}