import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth.dart';
import 'editprofilescreen.dart';
import 'datarepo.dart';

class ProfileScreen extends StatefulWidget {
  final String name;
  final String date;

  const ProfileScreen({super.key, required this.name, required this.date});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double averageMood = 0;
  double averagePhysical = 0;
  int streak = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final authState = context.read<AuthCubit>().state;
    if (authState.userId == null) return;

    setState(() => isLoading = true);

    try {
      final repo = RepositoryProvider.of<DataRepository>(context);

      // Calculate and update averages
      await repo.calculateAndUpdateAverageMood(authState.userId!);
      await repo.calculateAndUpdateAveragePhysical(authState.userId!);

      // Calculate streak
      final calculatedStreak = await repo.calculateStreak(authState.userId!);

      // Fetch updated profile
      final profile = await repo.fetchUserProfile(authState.userId!);

      if (profile != null) {
        setState(() {
          averageMood = (profile['average_mood'] as num?)?.toDouble() ?? 0;
          averagePhysical =
              (profile['average_physical'] as num?)?.toDouble() ?? 0;
          streak = calculatedStreak;
        });
      }
    } catch (e) {
      print('Error loading profile data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  String _getMoodText() {
    if (averageMood >= 3.5) return "Odlično";
    if (averageMood >= 2.5) return "Dobro";
    if (averageMood >= 1.5) return "Osrednje";
    if (averageMood > 0) return "Loše";
    return "Nema podataka";
  }

  IconData _getMoodIcon() {
    if (averageMood >= 3.5) return Icons.sentiment_very_satisfied;
    if (averageMood >= 2.5) return Icons.sentiment_satisfied;
    if (averageMood >= 1.5) return Icons.sentiment_neutral;
    if (averageMood > 0) return Icons.sentiment_dissatisfied;
    return Icons.help_outline;
  }

  String _getGrowthText() {
    if (streak >= 30) return "Neverovatno! 🚀";
    if (streak >= 14) return "Odličan napredak! 💪";
    if (streak >= 7) return "Nastavi tako! ⭐";
    if (streak >= 3) return "Dobar početak! 🌱";
    return "Počni danas! 💫";
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final displayName = authState.userName ?? widget.name;
        final joinDate = authState.joinDate ?? widget.date;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                "Hi ${displayName.split(' ').first}!",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // User Header Card
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(50), // Pill shape
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person_outline,
                        size: 50,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(joinDate, style: const TextStyle(fontSize: 18)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Stats Row
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    _buildStatCard(
                      "Raspoloženje",
                      _getMoodIcon(),
                      _getMoodText(),
                      averageMood > 0
                          ? "${averageMood.toStringAsFixed(1)}/4"
                          : "",
                    ),
                    const SizedBox(width: 15),
                    _buildStreakCard(
                      "Niz dana",
                      streak.toString(),
                      _getGrowthText(),
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              // Physical Stats Card
              if (!isLoading && averagePhysical > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.fitness_center,
                        size: 50,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Fizička aktivnost",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "${(averagePhysical * 25).toStringAsFixed(0)}/100",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Edit Profile Button
              _buildActionButton(
                "Edit Profile",
                Icons.edit,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                ).then((_) => _loadProfileData()),
              ),

              const SizedBox(height: 15),

              // Sign Out Button
              _buildActionButton(
                "Sign out",
                Icons.logout,
                () => context.read<AuthCubit>().signOut(),
              ),
            ],
          ),
        );
      },
    );
  }

  // The square card for Mood
  Widget _buildStatCard(
    String title,
    IconData icon,
    String subtitle, [
    String? extraText,
  ]) {
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
            Text(
              title,
              style: const TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const Spacer(),
            Icon(icon, size: 80, color: Colors.black),
            const Spacer(),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (extraText != null && extraText.isNotEmpty)
              Text(
                extraText,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
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
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const Spacer(),
            Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  size: 90,
                  color: Colors.black,
                ),
                Positioned(
                  bottom: 15,
                  child: Text(
                    count,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              footer,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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
            Text(
              text,
              style: const TextStyle(fontSize: 20, color: Colors.black54),
            ),
            Icon(icon, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}
