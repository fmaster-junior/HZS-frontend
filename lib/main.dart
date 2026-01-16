import 'package:flutter/material.dart';
import 'homescreen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_cubit.dart';
import 'fitness_cubit.dart';
import 'profilescreen.dart';
import 'datarepo.dart';
import 'auth.dart';
import 'login.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'matchingscreen.dart';
import 'settingscreen.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:awesome_notifications/awesome_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date formatting for Serbian locale
  await initializeDateFormatting('sr_RS', null);
  try {
    await Supabase.initialize(
      url: 'https://tjyckflwdlocmuhevryv.supabase.co/',
      anonKey: 'sb_publishable_pBhssx2LoSQ5CsSppdI1_w_cNkjtEpC', // add your key here or use env
    ).timeout(const Duration(seconds: 6));
  } catch (e, st) {
    // If Supabase initialization fails or times out, log and continue so UI can load.
    // This prevents the native splash screen from hanging indefinitely.
    // Replace prints with proper logging if desired.
    // ignore: avoid_print
    print('Supabase.initialize failed or timed out: $e');
    // ignore: avoid_print
    print(st);
  }
  AwesomeNotifications().initialize(
    null, // icon can be null for default
    [
      NotificationChannel(
        channelKey: 'mental_health_channel',
        channelName: 'Mental Health Notifications',
        channelDescription: 'Motivational alerts based on score',
        defaultColor: Colors.grey,
        ledColor: Colors.white,
        importance: NotificationImportance.High,
      ),
    ],
  );
  final repo = DataRepository(); // Create the repo instance
  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DataRepository>.value(value: repo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => AppCubit(repo)), // Pass repo here
          BlocProvider(create: (context) => FitnessCubit(repo)),
          BlocProvider(create: (context) => AuthCubit()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Setting a global font and color theme to match the image
        scaffoldBackgroundColor: Colors.grey[300], // Light grey background
        primarySwatch: Colors.grey,
      ),
      home: const AuthWrapper(),
    );
  }
}

/// Wrapper that listens to auth state and shows Login or Main screen accordingly
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, AuthState state) {
        // Show loading indicator while checking session
        if (state.isLoading && !state.isLoggedIn) {
          return Scaffold(
            backgroundColor: Colors.grey[300],
            body: const Center(
              child: CircularProgressIndicator(color: Colors.black),
            ),
          );
        }

        // Show login screen if not logged in
        if (!state.isLoggedIn) {
          return const LoginScreen();
        }

        // Show main app if logged in
        return const MainFooterPage();
      },
    );
  }
}

class MainFooterPage extends StatefulWidget {
  const MainFooterPage({super.key});

  @override
  State<MainFooterPage> createState() => _MainFooterPageState();
}

class _MainFooterPageState extends State<MainFooterPage> {
  int _currentIndex = 2; // Start at index 2 (Home) to match the image

  // The list of screens to swap between
  final List<Widget> _screens = [
    const PlaceholderScreen(title: "Info Screen"), // Index 0
    const ProfileScreen(name: "Duši Viber", date: "2009.03.07."), // Index 1
    const HomeScreen(), // Index 2 (The Main UI)
    const SearchScreen(), // Index 3
    const SettingsScreen(), // Index 4
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body switches based on the index
      body: SafeArea(child: _screens[_currentIndex]),

      // THE FOOTER (Bottom Navigation Bar)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed, // Needed for 4+ items
        backgroundColor: Colors.grey[400], // Darker grey for footer
        selectedItemColor: Colors.black, // Active icon color
        unselectedItemColor: Colors.black54, // Inactive icon color
        showSelectedLabels: false, // Hiding labels to match image
        showUnselectedLabels: false,
        items: const [
          // 1. Info
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline, size: 28),
            label: 'Info',
          ),
          // 2. Profile
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 28),
            label: 'Profile',
          ),
          // 3. Home (Active)
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 28),
            label: 'Home',
          ),
          // 4. Search
          BottomNavigationBarItem(
            icon: Icon(Icons.search, size: 28),
            label: 'Search',
          ),
          // 5. Settings
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined, size: 28),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 70),

              // IKONA UMESTO KUTIJICE
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.black,
                child: Icon(
                  Icons.groups_rounded, // Ikona tima
                  size: 70,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              // NASLOV (Fmaster Team)
              Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),
              const Text(
                "Official Organization",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),

              const SizedBox(height: 40),

              // FIKSNE INFORMACIJE (Samo tekst)
              _buildTeamInfo(Icons.person, "Leader", "Dusi Viber"),
              _buildTeamInfo(Icons.code, "Project", "RealTalk App"),
              _buildTeamInfo(Icons.bolt, "Status", "Active"),
              _buildTeamInfo(Icons.public, "Region", "Serbia"),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  // Pomoćna funkcija za ispis informacija sa ikonicom
  Widget _buildTeamInfo(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54, size: 28),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
