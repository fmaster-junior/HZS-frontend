import 'package:flutter_bloc/flutter_bloc.dart';
import 'datarepo.dart';

class FitnessState {
  final List<DateTime> selectedDates;
  final List<double> weeklyData;
  final bool isLoading;

  FitnessState({
    required this.selectedDates, 
    required this.weeklyData,
    this.isLoading = false,
  });

  factory FitnessState.initial() => FitnessState(
    selectedDates: [],
    weeklyData: [0, 0, 0, 0, 0, 0, 0],
  );

  FitnessState copyWith({
    List<DateTime>? selectedDates, 
    List<double>? weeklyData,
    bool? isLoading,
  }) {
    return FitnessState(
      selectedDates: selectedDates ?? this.selectedDates,
      weeklyData: weeklyData ?? this.weeklyData,
      isLoading: isLoading ?? this.isLoading,
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
}