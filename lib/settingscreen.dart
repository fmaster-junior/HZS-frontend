import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'editprofilescreen.dart';
import 'auth.dart';
import 'datarepo.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false; // Lokalno stanje za toggle
  final _dataRepo = DataRepository();
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Settings",
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // SEKCIJA: APPEARANCE
            _buildSectionTitle("Appearance"),
            _buildSettingTile(
              icon: _isDarkMode ? Icons.dark_mode : Icons.light_mode,
              title: "Dark Mode",
              trailing: Switch(
                value: _isDarkMode,
                activeColor: Colors.black,
                onChanged: (value) {
                  setState(() {
                    _isDarkMode = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 30),

            // SEKCIJA: ACCOUNT
            _buildSectionTitle("Account Settings"),
            _buildSettingTile(
              icon: Icons.person_outline,
              title: "Edit Profile",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // SEKCIJA: DANGER ZONE
            _buildSectionTitle("Danger Zone"),
            _buildSettingTile(
              icon: Icons.delete_forever,
              title: "Delete Account",
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () => _showDeleteDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  // Pomoćni widget za naslove sekcija
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // Pomoćni widget za stavke u podešavanjima
  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[850] : Colors.grey[400],
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? (_isDarkMode ? Colors.white : Colors.black)),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? (_isDarkMode ? Colors.white : Colors.black),
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: trailing ?? Icon(Icons.chevron_right, color: _isDarkMode ? Colors.grey : Colors.black54),
        onTap: onTap,
      ),
    );
  }

  // Method to delete user account
  Future<void> _deleteAccount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: CircularProgressIndicator(
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        );
      }

      // Delete user profile from Supabase
      await _dataRepo.deleteUserAccount(user.id);

      // Sign out the user
      if (mounted) {
        await context.read<AuthCubit>().signOut();
      }

      // Close loading dialog and navigate to login
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
            title: const Text("Error", style: TextStyle(color: Colors.red)),
            content: Text(
              "Failed to delete account: $e",
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }

  // DIJALOG ZA POTVRDU BRISANJA
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
        title: const Text("Delete Account?", style: TextStyle(color: Colors.red)),
        content: Text(
          "Are you sure you want to permanently delete your account? This action cannot be undone.",
          style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _deleteAccount();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}