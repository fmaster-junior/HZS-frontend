import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth.dart';
class ProfileScreen extends StatelessWidget {
  final String name;
  final String date;

  const ProfileScreen({super.key, required this.name, required this.date});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text("Hi Duši!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          // User Header Card
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey[400], 
              borderRadius: BorderRadius.circular(50) // Pill shape
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 40, 
                  backgroundColor: Colors.white, 
                  child: Icon(Icons.person_outline, size: 50, color: Colors.black)
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(date, style: const TextStyle(fontSize: 18)),
                  ],
                )
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Stats Row
          Row(
            children: [
              _buildStatCard("Mood lately", Icons.sentiment_satisfied_alt, "Happy"),
              const SizedBox(width: 15),
              _buildStreakCard("You are on fire!", "9", "20% overall development since last month"),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Sign Out Button
          _buildActionButton(
            "Sign out", 
            Icons.logout, 
            () => context.read<AuthCubit>().logout()
          ),
        ],
      ),
    );
  }

// The square card for Mood
  Widget _buildStatCard(String title, IconData icon, String subtitle) {
    return Expanded(
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 18, color: Colors.black54)),
            const Spacer(),
            Icon(icon, size: 80, color: Colors.black),
            const Spacer(),
            Text(subtitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // The square card for the Fire/Streak
  Widget _buildStreakCard(String title, String count, String footer) {
    return Expanded(
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const Spacer(),
            Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.local_fire_department, size: 90, color: Colors.black),
                Positioned(
                  bottom: 15,
                  child: Text(count, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Spacer(),
            Text(footer, 
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildActionButton(String text, IconData icon, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
      decoration: BoxDecoration(
        color: Colors.grey[400], 
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: const TextStyle(fontSize: 20, color: Colors.black54)),
          Icon(icon, color: Colors.black54),
        ],
      ),
    ),
  );
}
  
  }