import 'package:supabase_flutter/supabase_flutter.dart';

// Repo je privatan, mrzi me da pravim .env
const String supabaseUrl = 'https://tjyckflwdlocmuhevryv.supabase.co/';
const String supabaseAnonKey = 'sb_publishable_pBhssx2LoSQ5CsSppdI1_w_cNkjtEpC';

class DataRepository {
  final SupabaseClient supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);

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

  // === NEW DAILY LOGGING METHODS ===

  // Check if user has logged today
  Future<bool> hasDailyLogForDate(String userId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0]; // YYYY-MM-DD
      final response = await supabase
          .from('daily_logs')
          .select()
          .eq('user_id', userId)
          .eq('log_date', dateStr)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Create or update daily log
  Future<void> upsertDailyLog(
    String userId,
    DateTime logDate, {
    int? mentalMood,
    int? physicalScore,
  }) async {
    final dateStr = logDate.toIso8601String().split('T')[0];

    print(
      'upsertDailyLog called: userId=$userId, date=$dateStr, mentalMood=$mentalMood, physicalScore=$physicalScore',
    );

    try {
      // Check if exists
      final existing = await supabase
          .from('daily_logs')
          .select()
          .eq('user_id', userId)
          .eq('log_date', dateStr)
          .maybeSingle();

      if (existing != null) {
        // Update
        print('Updating existing daily log: ${existing['id']}');
        final result = await supabase
            .from('daily_logs')
            .update({
              if (mentalMood != null) 'mental_mood': mentalMood,
              if (physicalScore != null) 'physical_score': physicalScore,
            })
            .eq('id', existing['id'])
            .select();
        print('Update result: $result');
      } else {
        // Insert
        print('Inserting new daily log');
        final result = await supabase.from('daily_logs').insert({
          'user_id': userId,
          'log_date': dateStr,
          if (mentalMood != null) 'mental_mood': mentalMood,
          if (physicalScore != null) 'physical_score': physicalScore,
        }).select();
        print('Insert result: $result');
      }
    } catch (e, stackTrace) {
      print('Error in upsertDailyLog: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Create mental log
  Future<void> createMentalLog(
    String userId,
    DateTime logDate,
    int mood,
    int score,
    String note,
  ) async {
    final dateStr = logDate.toIso8601String().split('T')[0];
    print(
      'createMentalLog: userId=$userId, date=$dateStr, mood=$mood, score=$score',
    );
    try {
      final result = await supabase.from('mental_logs').insert({
        'user_id': userId,
        'log_date': dateStr,
        'mood': mood,
        'score': score,
        'note': note,
      }).select();
      print('Mental log insert result: $result');
    } catch (e, stackTrace) {
      print('Error in createMentalLog: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Create physical log
  Future<void> createPhysicalLog(
    String userId,
    DateTime logDate,
    int activityLevel,
    int steps,
    bool workoutDone,
  ) async {
    final dateStr = logDate.toIso8601String().split('T')[0];
    print(
      'createPhysicalLog: userId=$userId, date=$dateStr, activityLevel=$activityLevel, steps=$steps',
    );
    try {
      final result = await supabase.from('physical_logs').insert({
        'user_id': userId,
        'log_date': dateStr,
        'activity_level': activityLevel,
        'steps': steps,
        'workout_done': workoutDone,
      }).select();
      print('Physical log insert result: $result');
    } catch (e, stackTrace) {
      print('Error in createPhysicalLog: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Fetch logs for date range (for graphs)
  Future<List<Map<String, dynamic>>> fetchMentalLogsRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final start = startDate.toIso8601String().split('T')[0];
    final end = endDate.toIso8601String().split('T')[0];

    final response = await supabase
        .from('mental_logs')
        .select()
        .eq('user_id', userId)
        .gte('log_date', start)
        .lte('log_date', end)
        .order('log_date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchPhysicalLogsRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final start = startDate.toIso8601String().split('T')[0];
    final end = endDate.toIso8601String().split('T')[0];

    final response = await supabase
        .from('physical_logs')
        .select()
        .eq('user_id', userId)
        .gte('log_date', start)
        .lte('log_date', end)
        .order('log_date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // Fetch all dates with logs (for calendar)
  Future<List<DateTime>> fetchDatesWithLogs(String userId) async {
    final response = await supabase
        .from('daily_logs')
        .select('log_date')
        .eq('user_id', userId)
        .order('log_date', ascending: false);

    return (response as List).map((item) {
      return DateTime.parse(item['log_date']);
    }).toList();
  }

  // Fetch log details for a specific date
  Future<Map<String, dynamic>?> fetchLogForDate(
    String userId,
    DateTime date,
  ) async {
    final dateStr = date.toIso8601String().split('T')[0];

    // Fetch daily log
    final dailyLog = await supabase
        .from('daily_logs')
        .select()
        .eq('user_id', userId)
        .eq('log_date', dateStr)
        .maybeSingle();

    // Fetch mental log
    final mentalLog = await supabase
        .from('mental_logs')
        .select()
        .eq('user_id', userId)
        .eq('log_date', dateStr)
        .maybeSingle();

    // Fetch physical log
    final physicalLog = await supabase
        .from('physical_logs')
        .select()
        .eq('user_id', userId)
        .eq('log_date', dateStr)
        .maybeSingle();

    return {'daily': dailyLog, 'mental': mentalLog, 'physical': physicalLog};
  }

  Future<void> acceptNotification(String notifId) async {
    await supabase
        .from('notifications')
        .update({'status': 'accepted'})
        .eq('id', notifId);
  }

  // 2. Delete old notifications (Run this when screen opens)
  Future<void> cleanOldNotifications() async {
    final threeDaysAgo = DateTime.now()
        .subtract(const Duration(days: 3))
        .toIso8601String();

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

  // Update user profile with averages and streak
  Future<void> updateUserProfile(
    String userId, {
    double? averageMood,
    double? averagePhysical,
    int? streak,
    int? growth,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (averageMood != null) updates['average_mood'] = averageMood;
      if (averagePhysical != null)
        updates['average_physical'] = averagePhysical;
      if (streak != null) updates['streak'] = streak;
      if (growth != null) updates['growth'] = growth;

      if (updates.isNotEmpty) {
        await supabase.from('profiles').update(updates).eq('id', userId);
      }
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  // Calculate and update average mood
  Future<void> calculateAndUpdateAverageMood(String userId) async {
    try {
      // Get last 30 days of mental logs
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final logs = await fetchMentalLogsRange(
        userId,
        thirtyDaysAgo,
        DateTime.now(),
      );

      if (logs.isNotEmpty) {
        final totalMood = logs.fold<double>(
          0,
          (sum, log) => sum + ((log['mood'] as num?) ?? 0).toDouble(),
        );
        final averageMood = totalMood / logs.length;
        await updateUserProfile(userId, averageMood: averageMood);
      }
    } catch (e) {
      print('Error calculating average mood: $e');
    }
  }

  // Calculate and update average physical
  Future<void> calculateAndUpdateAveragePhysical(String userId) async {
    try {
      // Get last 30 days of physical logs
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final logs = await fetchPhysicalLogsRange(
        userId,
        thirtyDaysAgo,
        DateTime.now(),
      );

      if (logs.isNotEmpty) {
        final totalActivity = logs.fold<double>(
          0,
          (sum, log) => sum + ((log['activity_level'] as num?) ?? 0).toDouble(),
        );
        final averagePhysical = totalActivity / logs.length;
        await updateUserProfile(userId, averagePhysical: averagePhysical);
      }
    } catch (e) {
      print('Error calculating average physical: $e');
    }
  }

  // Calculate streak
  Future<int> calculateStreak(String userId) async {
    try {
      final response = await supabase
          .from('daily_logs')
          .select('log_date')
          .eq('user_id', userId)
          .order('log_date', ascending: false);

      final logs = List<Map<String, dynamic>>.from(response);
      if (logs.isEmpty) return 0;

      int streak = 0;
      DateTime expectedDate = DateTime.now();

      for (var log in logs) {
        final logDate = DateTime.parse(log['log_date']);
        final expectedDateStr = expectedDate.toIso8601String().split('T')[0];
        final logDateStr = logDate.toIso8601String().split('T')[0];

        if (logDateStr == expectedDateStr) {
          streak++;
          expectedDate = expectedDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      await updateUserProfile(userId, streak: streak);
      return streak;
    } catch (e) {
      print('Error calculating streak: $e');
      return 0;
    }
  }

  // Fetch matching users based on mood (1 with 4, 2 with 3)
  Future<List<Map<String, dynamic>>> fetchMatchingUsers(String userId) async {
    try {
      // Get current user's average mood
      final userProfile = await fetchUserProfile(userId);
      final userMood = userProfile?['average_mood'] ?? 0;

      // Determine target mood range
      double targetMoodMin, targetMoodMax;
      if (userMood >= 1 && userMood < 1.5) {
        // User mood ~1, match with ~4
        targetMoodMin = 3.5;
        targetMoodMax = 4.0;
      } else if (userMood >= 1.5 && userMood < 2.5) {
        // User mood ~2, match with ~3
        targetMoodMin = 2.5;
        targetMoodMax = 3.5;
      } else if (userMood >= 2.5 && userMood < 3.5) {
        // User mood ~3, match with ~2
        targetMoodMin = 1.5;
        targetMoodMax = 2.5;
      } else {
        // User mood ~4, match with ~1
        targetMoodMin = 1.0;
        targetMoodMax = 1.5;
      }

      final response = await supabase
          .from('profiles')
          .select()
          .neq('id', userId)
          .gte('average_mood', targetMoodMin)
          .lte('average_mood', targetMoodMax)
          .order('average_mood', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching matching users: $e');
      return [];
    }
  }

  // Send invite notification
  Future<void> sendInviteNotification(
    String fromUserId,
    String toUserId,
    String fromUsername,
  ) async {
    try {
      await supabase.from('notifications').insert({
        'user_id': toUserId,
        'type': 'invite',
        'message': '$fromUsername invited you!',
        'from_user_id': fromUserId,
        'status': 'waiting',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error sending notification: $e');
      rethrow;
    }
  }

  // Delete user account
  Future<void> deleteUserAccount(String userId) async {
    try {
      // Delete user's profile from the profiles table
      // The database should have CASCADE DELETE set up for related logs and notifications
      // If not, you may need to delete those manually first
      await supabase
          .from('profiles')
          .delete()
          .eq('id', userId);
      
      print('User profile deleted successfully');
    } catch (e) {
      print('Error deleting user account: $e');
      rethrow;
    }
  }
}
