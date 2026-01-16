import 'package:flutter_bloc/flutter_bloc.dart';
import 'datarepo.dart'; // Import your repository

class AppState {
  // Existing Poll State
  final int mentalScore;
  final int currentPollIndex;
  final String lastDateCompleted;

  // New Database Profile State
  final bool isLoading;
  final String fullName;
  final String joinDate;
  final int streak;
  final double averageMood;

  // Weekly mental data for graphs
  final List<double> weeklyMentalData;

  // Weekly physical data for graphs
  final List<double> weeklyPhysicalData;

  AppState({
    required this.mentalScore,
    required this.currentPollIndex,
    required this.lastDateCompleted,
    this.isLoading = false,
    this.fullName = "Loading...",
    this.joinDate = "---",
    this.streak = 0,
    this.averageMood = 0.0,
    this.weeklyMentalData = const [0, 0, 0, 0, 0, 0, 0],
    this.weeklyPhysicalData = const [0, 0, 0, 0, 0, 0, 0],
  });

  bool get isPollLocked {
    if (lastDateCompleted.isEmpty) return false;
    final today = DateTime.now().toString().split(' ')[0];
    return lastDateCompleted == today;
  }

  AppState copyWith({
    int? mentalScore,
    int? currentPollIndex,
    String? lastDateCompleted,
    bool? isLoading,
    String? fullName,
    String? joinDate,
    int? streak,
    double? averageMood,
    List<double>? weeklyMentalData,
    List<double>? weeklyPhysicalData,
  }) {
    return AppState(
      mentalScore: mentalScore ?? this.mentalScore,
      currentPollIndex: currentPollIndex ?? this.currentPollIndex,
      lastDateCompleted: lastDateCompleted ?? this.lastDateCompleted,
      isLoading: isLoading ?? this.isLoading,
      fullName: fullName ?? this.fullName,
      joinDate: joinDate ?? this.joinDate,
      streak: streak ?? this.streak,
      averageMood: averageMood ?? this.averageMood,
      weeklyMentalData: weeklyMentalData ?? this.weeklyMentalData,
      weeklyPhysicalData: weeklyPhysicalData ?? this.weeklyPhysicalData,
    );
  }
}

class AppCubit extends Cubit<AppState> {
  final DataRepository _repo; // Inject Repository

  AppCubit(this._repo)
    : super(
        AppState(mentalScore: 50, currentPollIndex: 0, lastDateCompleted: ""),
      );

  final List<String> questions = ["Mood?", "Energy?", "Focus?", "Calm?"];

  // 1. FETCH DATA (Call this after Login)
  Future<void> loadUserData(String userId) async {
    emit(state.copyWith(isLoading: true));

    final profile = await _repo.fetchUserProfile(userId);

    if (profile != null) {
      emit(
        state.copyWith(
          isLoading: false,
          fullName: profile['full_name'] ?? "User",
          // Extract date YYYY-MM-DD
          joinDate: profile['created_at']?.substring(0, 10) ?? "2024",
          streak: profile['streak'] ?? 0,
          averageMood: (profile['average_mood'] ?? 0).toDouble(),
        ),
      );
    } else {
      emit(state.copyWith(isLoading: false));
    }
  }

  // 2. SUBMIT POLL (Updates Local State AND Database)
  Future<void> submitVote(int value, String userId) async {
    int newScore = (state.mentalScore + (value * 3)).clamp(0, 100);
    int nextIndex = state.currentPollIndex + 1;
    String dateTrack = state.lastDateCompleted;

    // If poll is finished
    if (nextIndex >= questions.length) {
      dateTrack = DateTime.now().toString().split(' ')[0]; // Lock locally

      // SEND TO DATABASE
      // We assume the score is the average or the final result
      await _repo.logMentalHealth(userId, newScore, "Daily Poll");
    }

    emit(
      state.copyWith(
        mentalScore: newScore,
        currentPollIndex: nextIndex,
        lastDateCompleted: dateTrack,
      ),
    );
  }

  void resetPoll() {
    emit(state.copyWith(currentPollIndex: 0));
  }

  // 3. LOAD WEEKLY MENTAL DATA
  Future<void> loadWeeklyMentalData(String userId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday
    final endDate = startOfWeek.add(const Duration(days: 6)); // Sunday

    final logs = await _repo.fetchMentalLogsRange(userId, startOfWeek, endDate);

    // Create a map of date -> score
    final Map<String, double> scoreMap = {};
    for (var log in logs) {
      if (log['log_date'] != null && log['score'] != null) {
        scoreMap[log['log_date']] = (log['score'] as num).toDouble();
      }
    }

    // Fill in the weekly data (7 days from Monday to Sunday)
    final List<double> weeklyData = [];
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];
      weeklyData.add(scoreMap[dateStr] ?? 0);
    }

    emit(state.copyWith(weeklyMentalData: weeklyData));
  }

  // 4. LOAD WEEKLY PHYSICAL DATA
  Future<void> loadWeeklyPhysicalData(String userId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday
    final endDate = startOfWeek.add(const Duration(days: 6)); // Sunday

    final logs = await _repo.fetchPhysicalLogsRange(
      userId,
      startOfWeek,
      endDate,
    );

    // Create a map of date -> score (activity_level * 25)
    final Map<String, double> scoreMap = {};
    for (var log in logs) {
      if (log['log_date'] != null && log['activity_level'] != null) {
        scoreMap[log['log_date']] = ((log['activity_level'] as num) * 25)
            .toDouble();
      }
    }

    // Fill in the weekly data (7 days from Monday to Sunday)
    final List<double> weeklyData = [];
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];
      weeklyData.add(scoreMap[dateStr] ?? 0);
    }

    emit(state.copyWith(weeklyPhysicalData: weeklyData));
  }
}
