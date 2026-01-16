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
          : LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 400;
                return _buildUserCard(constraints, isSmallScreen);
              },
            ),
    );
  }

  Widget _buildUserCard(BoxConstraints constraints, bool isSmallScreen) {
    final user = matchingUsers[currentUserIndex];
    final String name = user['full_name'] ?? user['username'] ?? "Korisnik";
    final int streak = user['streak'] ?? 0;
    final double? mood = (user['average_mood'] as num?)?.toDouble();
    final double? physical = (user['average_physical'] as num?)?.toDouble();
    final String? bio = user['bio'];
    final horizontalPadding = isSmallScreen ? 16.0 : 20.0;
    final fontSize = isSmallScreen ? 16.0 : 18.0;
    final buttonSpacing = isSmallScreen ? 10.0 : 15.0;
    final verticalPadding = isSmallScreen ? 12.0 : 15.0;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(horizontalPadding),
        child: Column(
          children: [
            // Scrollable content area
            Expanded(
              child: SingleChildScrollView(
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
                    CircleAvatar(
                      radius: isSmallScreen ? 50 : 60,
                      backgroundColor: Colors.black,
                      child: CircleAvatar(
                        radius: isSmallScreen ? 48 : 58,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: isSmallScreen ? 60 : 80,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Name
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 20 : 24,
                        fontWeight: FontWeight.bold,
                      ),
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

                    SizedBox(height: isSmallScreen ? 20 : 30),

                    // Stats Row
                    Row(
                      children: [
                        _buildStatusCard(
                          "Raspoloženje",
                          _getMoodIcon(mood),
                          _getMoodText(mood),
                          isSmallScreen: isSmallScreen,
                        ),
                        SizedBox(width: isSmallScreen ? 10 : 15),
                        _buildStatusCard(
                          "Niz dana",
                          Icons.local_fire_department,
                          streak.toString(),
                          subtitle: streak > 0 ? "🔥" : "",
                          isSmallScreen: isSmallScreen,
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // Physical Activity Card
                    if (physical != null && physical > 0)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isSmallScreen ? 15 : 20),
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
                            Icon(
                              Icons.fitness_center,
                              size: isSmallScreen ? 30 : 40,
                            ),
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
                  ],
                ),
              ),
            ),

            // Fixed Action Buttons at bottom
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _sendInvite,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: verticalPadding),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Pozovi",
                            style: TextStyle(
                              fontSize: fontSize,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: buttonSpacing),
                Expanded(
                  child: GestureDetector(
                    onTap: _nextUser,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: verticalPadding),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Sledeći",
                            style: TextStyle(
                              fontSize: fontSize,
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    String title,
    IconData icon,
    String value, {
    String? subtitle,
    bool isSmallScreen = false,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 15 : 20),
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey,
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
            SizedBox(height: isSmallScreen ? 5 : 10),
            Icon(icon, size: isSmallScreen ? 40 : 60),
            SizedBox(height: isSmallScreen ? 5 : 10),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 14 : 18,
              ),
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
