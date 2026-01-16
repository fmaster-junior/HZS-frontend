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

  AppState({
    required this.mentalScore,
    required this.currentPollIndex,
    required this.lastDateCompleted,
    this.isLoading = false,
    this.fullName = "Loading...",
    this.joinDate = "---",
    this.streak = 0,
    this.averageMood = 0.0,
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
    );
  }
}

class AppCubit extends Cubit<AppState> {
  final DataRepository _repo; // Inject Repository

  AppCubit(this._repo) : super(AppState(
    mentalScore: 50, 
    currentPollIndex: 0, 
    lastDateCompleted: ""
  ));

  final List<String> questions = ["Mood?", "Energy?", "Focus?", "Calm?"];

  // 1. FETCH DATA (Call this after Login)
  Future<void> loadUserData(String userId) async {
    emit(state.copyWith(isLoading: true));

    final profile = await _repo.fetchUserProfile(userId);

    if (profile != null) {
      emit(state.copyWith(
        isLoading: false,
        fullName: profile['full_name'] ?? "User",
        // Extract date YYYY-MM-DD
        joinDate: profile['created_at']?.substring(0, 10) ?? "2024", 
        streak: profile['streak'] ?? 0,
        averageMood: (profile['average_mood'] ?? 0).toDouble(),
      ));
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

    emit(state.copyWith(
      mentalScore: newScore,
      currentPollIndex: nextIndex,
      lastDateCompleted: dateTrack,
    ));
  }

  void resetPoll() {
    emit(state.copyWith(currentPollIndex: 0));
  }
}