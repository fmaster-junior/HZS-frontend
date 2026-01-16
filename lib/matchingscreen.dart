import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'datarepo.dart';
import 'notifscreenmatch.dart';
import 'auth.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Map<String, dynamic>> matchingUsers = [];
  int currentUserIndex = 0;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMatchingUsers();
  }

  Future<void> _loadMatchingUsers() async {
    final authState = context.read<AuthCubit>().state;
    if (authState.userId == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final repo = RepositoryProvider.of<DataRepository>(context);

      // First update current user's averages
      await repo.calculateAndUpdateAverageMood(authState.userId!);

      // Fetch matching users
      final users = await repo.fetchMatchingUsers(authState.userId!);

      setState(() {
        matchingUsers = users;
        currentUserIndex = 0;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Greška pri učitavanju korisnika';
        isLoading = false;
      });
    }
  }

  void _nextUser() {
    if (currentUserIndex < matchingUsers.length - 1) {
      setState(() {
        currentUserIndex++;
      });
    } else {
      // Reload matching users
      _loadMatchingUsers();
    }
  }

  Future<void> _sendInvite() async {
    final authState = context.read<AuthCubit>().state;
    if (authState.userId == null || matchingUsers.isEmpty) return;

    final currentUser = matchingUsers[currentUserIndex];
    final repo = RepositoryProvider.of<DataRepository>(context);

    try {
      await repo.sendInviteNotification(
        authState.userId!,
        currentUser['id'],
        authState.userName ?? 'Korisnik',
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pozivnica poslata!')));
        _nextUser();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Greška pri slanju pozivnice')),
        );
      }
    }
  }

  String _getMoodText(double? mood) {
    if (mood == null || mood == 0) return "Nema podataka";
    if (mood >= 3.5) return "Odlično";
    if (mood >= 2.5) return "Dobro";
    if (mood >= 1.5) return "Osrednje";
    return "Loše";
  }

  IconData _getMoodIcon(double? mood) {
    if (mood == null || mood == 0) return Icons.help_outline;
    if (mood >= 3.5) return Icons.sentiment_very_satisfied;
    if (mood >= 2.5) return Icons.sentiment_satisfied;
    if (mood >= 1.5) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "RealTalk",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(errorMessage!, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadMatchingUsers,
                    child: const Text('Pokušaj ponovo'),
                  ),
                ],
              ),
            )
          : matchingUsers.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 100,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Nema korisnika za uparivanje",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Trenutno nema korisnika koji odgovaraju tvojim kriterijumima.",
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _loadMatchingUsers,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Osvezi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _buildUserCard(),
    );
  }

  Widget _buildUserCard() {
    final user = matchingUsers[currentUserIndex];
    final String name = user['full_name'] ?? user['username'] ?? "Korisnik";
    final int streak = user['streak'] ?? 0;
    final double? mood = (user['average_mood'] as num?)?.toDouble();
    final double? physical = (user['average_physical'] as num?)?.toDouble();
    final String? bio = user['bio'];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // User indicator
          Text(
            "Korisnik ${currentUserIndex + 1} od ${matchingUsers.length}",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),

          // Profile Picture
          const CircleAvatar(
            radius: 60,
            backgroundColor: Colors.black,
            child: CircleAvatar(
              radius: 58,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 80, color: Colors.black),
            ),
          ),
          const SizedBox(height: 10),

          // Name
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          // Bio
          if (bio != null && bio.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                bio,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          const SizedBox(height: 30),

          // Stats Row
          Row(
            children: [
              _buildStatusCard(
                "Raspoloženje",
                _getMoodIcon(mood),
                _getMoodText(mood),
              ),
              const SizedBox(width: 15),
              _buildStatusCard(
                "Niz dana",
                Icons.local_fire_department,
                streak.toString(),
                subtitle: streak > 0 ? "🔥" : "",
              ),
            ],
          ),

          const SizedBox(height: 15),

          // Physical Activity Card
          if (physical != null && physical > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    "Fizička aktivnost",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  const Icon(Icons.fitness_center, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    "${(physical * 25).toStringAsFixed(0)}/100",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

          const Spacer(),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _sendInvite,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Center(
                      child: Text(
                        "Pozovi",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: GestureDetector(
                  onTap: _nextUser,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Center(
                      child: Text(
                        "Sledeći",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    String title,
    IconData icon,
    String value, {
    String? subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Icon(icon, size: 60),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (subtitle != null && subtitle.isNotEmpty)
              Text(
                subtitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
