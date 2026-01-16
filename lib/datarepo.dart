import 'package:supabase_flutter/supabase_flutter.dart';
class DataRepository {
  final SupabaseClient supabase = Supabase.instance.client;

  // 1. Fetch User Profile (Matches your 'profiles' table)
  Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      //print('Error fetching profile: $e');
      return null;
    }
  }

  // 2. Log Mental Data (Matches your 'mental_logs' table)
  Future<void> logMentalHealth(String userId, int score, String note) async {
    await supabase.from('mental_logs').insert({
      'user_id': userId,
      'score': score,
      'note': note,
      'log_date': DateTime.now().toIso8601String(),
    });
    // Optional: Trigger a recalculation of average mood on backend or locally
  }

  // 3. Log Physical Data (Matches your 'physical_logs' table)
  Future<void> logPhysicalActivity(String userId, int steps) async {
    await supabase.from('physical_logs').insert({
      'user_id': userId,
      'steps': steps,
      'log_date': DateTime.now().toIso8601String(),
    });
  }
  Future<void> acceptNotification(String notifId) async {
    await supabase
        .from('notifications')
        .update({'status': 'accepted'})
        .eq('id', notifId);
  }

  // 2. Delete old notifications (Run this when screen opens)
  Future<void> cleanOldNotifications() async {
    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3)).toIso8601String();
    
    // Deletes items older than 3 days
    await supabase
        .from('notifications')
        .delete()
        .lt('created_at', threeDaysAgo)
        .eq('status', 'waiting'); 
  }
  // Inside datarepo.dart
Future<List<Map<String, dynamic>>> fetchNotifications() async {
  // Logic to get notifications from Supabase
  final response = await supabase
      .from('notifications')
      .select()
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
}
}