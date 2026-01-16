import 'package:flutter/material.dart';
import 'datarepo.dart';
import 'notifscreenmatch.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Replace with a real ID or logic to search for a user
    const String targetUserId = 'some_user_id'; 

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("RealTalk", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
  icon: const Icon(Icons.notifications_none, color: Colors.black),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  },
),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: DataRepository().fetchUserProfile(targetUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final profile = snapshot.data;
          final String name = profile?['full_name'] ?? "Korisnik";
          final int streak = profile?['streak'] ?? 0;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.black,
                  child: CircleAvatar(radius: 58, backgroundColor: Colors.white, child: Icon(Icons.person, size: 80, color: Colors.black)),
                ),
                const SizedBox(height: 10),
                Text("$name\nstatus", textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                Row(
                  children: [
                    _buildStatusCard("Mood lately", Icons.sentiment_satisfied_alt, "Happy"),
                    const SizedBox(width: 15),
                    _buildStatusCard("Flaming!!", Icons.local_fire_department, "$streak", subtitle: "WOW"),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(child: _buildButton("Invite")),
                    const SizedBox(width: 15),
                    Expanded(child: _buildButton("Next")),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(String title, IconData icon, String value, {String? subtitle}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Icon(icon, size: 60),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (subtitle != null) Text(subtitle, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(15)),
      child: Center(child: Text(text, style: const TextStyle(fontSize: 18, color: Colors.grey))),
    );
  }
}