import 'package:flutter_bloc/flutter_bloc.dart';
import 'datarepo.dart';

class FitnessState {
  final List<DateTime> selectedDates;
  final List<double> weeklyData;
  final bool isLoading;
  final List<DateTime> datesWithLogs; // For calendar marking

  FitnessState({
    required this.selectedDates, 
    required this.weeklyData,
    this.isLoading = false,
    this.datesWithLogs = const [],
  });

  factory FitnessState.initial() => FitnessState(
    selectedDates: [],
    weeklyData: [0, 0, 0, 0, 0, 0, 0],
  );

  FitnessState copyWith({
    List<DateTime>? selectedDates, 
    List<double>? weeklyData,
    bool? isLoading,
    List<DateTime>? datesWithLogs,
  }) {
    return FitnessState(
      selectedDates: selectedDates ?? this.selectedDates,
      weeklyData: weeklyData ?? this.weeklyData,
      isLoading: isLoading ?? this.isLoading,
      datesWithLogs: datesWithLogs ?? this.datesWithLogs,
    );
  }
}

class FitnessCubit extends Cubit<FitnessState> {
  final DataRepository _repo;

  FitnessCubit(this._repo) : super(FitnessState.initial());

  // Logic to handle calendar interaction
  void selectDate(DateTime date) {
    // Mock: generate data based on day of month
    final newData = List.generate(7, (i) => ((date.day + i) % 15 + 5).toDouble());
    emit(state.copyWith(selectedDates: [date], weeklyData: newData));
  }

  // Logic to save steps to Supabase
  Future<void> syncSteps(String userId, int steps) async {
    emit(state.copyWith(isLoading: true));
    await _repo.logPhysicalActivity(userId, steps);
    emit(state.copyWith(isLoading: false));
  }

  // Load weekly physical data
  Future<void> loadWeeklyPhysicalData(String userId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday
    final endDate = startOfWeek.add(const Duration(days: 6)); // Sunday

    final logs = await _repo.fetchPhysicalLogsRange(userId, startOfWeek, endDate);

    // Create a map of date -> activity_level (convert to 0-100 scale)
    final Map<String, double> activityMap = {};
    for (var log in logs) {
      if (log['log_date'] != null && log['activity_level'] != null) {
        activityMap[log['log_date']] = (log['activity_level'] as num).toDouble() * 10;
      }
    }

    // Fill in the weekly data (7 days from Monday to Sunday)
    final List<double> weeklyData = [];
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];
      weeklyData.add(activityMap[dateStr] ?? 0);
    }

    emit(state.copyWith(weeklyData: weeklyData));
  }

  // Load dates with logs for calendar marking
  Future<void> loadDatesWithLogs(String userId) async {
    final dates = await _repo.fetchDatesWithLogs(userId);
    emit(state.copyWith(datesWithLogs: dates));
  }
}