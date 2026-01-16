import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streak_calendar/streak_calendar.dart';
import 'physicallogscreen.dart';
import 'app_cubit.dart';
import 'datarepo.dart';
import 'auth.dart';

class FitnessScreen extends StatefulWidget {
  const FitnessScreen({super.key});

  @override
  State<FitnessScreen> createState() => _FitnessScreenState();
}

class _FitnessScreenState extends State<FitnessScreen> {
  double averageActivity = 0;
  int weeklyLogs = 0;
  int todayScore = 0;
  bool isLoading = true;
  List<DateTime> selectedDates = [];
  Map<String, dynamic>? selectedDayLog;

  @override
  void initState() {
    super.initState();
    _loadPhysicalStats();
  }

  Future<void> _loadPhysicalStats() async {
    final authState = context.read<AuthCubit>().state;
    if (authState.userId == null) return;

    setState(() => isLoading = true);

    try {
      final repo = RepositoryProvider.of<DataRepository>(context);
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endDate = startOfWeek.add(const Duration(days: 6));

      final logs = await repo.fetchPhysicalLogsRange(
        authState.userId!,
        startOfWeek,
        endDate,
      );

      if (logs.isNotEmpty) {
        final totalActivity = logs.fold<double>(
          0,
          (sum, log) =>
              sum + ((log['activity_level'] as num? ?? 0) * 25).toDouble(),
        );

        // Check today's activity
        final todayLog = logs.where((log) {
          final logDate = DateTime.parse(log['log_date']);
          return logDate.year == now.year &&
              logDate.month == now.month &&
              logDate.day == now.day;
        }).firstOrNull;

        setState(() {
          averageActivity = totalActivity / logs.length;
          weeklyLogs = logs.length;
          todayScore = todayLog != null
              ? ((todayLog['activity_level'] as num) * 25).toInt()
              : 0;
        });
      }
    } catch (e) {
      // Handle error silently
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _navigateToPhysicalLog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhysicalLogScreen(logDate: DateTime.now()),
      ),
    );

    if (result == true) {
      // Reload stats after logging
      _loadPhysicalStats();
      // Reload weekly data in AppCubit
      final authState = context.read<AuthCubit>().state;
      if (authState.userId != null) {
        await context.read<AppCubit>().loadWeeklyPhysicalData(
          authState.userId!,
        );
      }
    }
  }

  Future<void> _selectDate(DateTime date) async {
    setState(() {
      selectedDates = [date];
    });

    // Fetch log details for selected date
    final authState = context.read<AuthCubit>().state;
    if (authState.userId == null) return;

    try {
      final repo = RepositoryProvider.of<DataRepository>(context);
      final logData = await repo.fetchLogForDate(authState.userId!, date);
      setState(() {
        selectedDayLog = logData?['physical'];
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _editLogForDate() async {
    if (selectedDates.isEmpty) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhysicalLogScreen(logDate: selectedDates.first),
      ),
    );

    if (result == true) {
      // Reload stats and selected date after logging
      _loadPhysicalStats();
      _selectDate(selectedDates.first);
      // Reload weekly data in AppCubit
      final authState = context.read<AuthCubit>().state;
      if (authState.userId != null) {
        await context.read<AppCubit>().loadWeeklyPhysicalData(
          authState.userId!,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Fizička Aktivnost"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Today's Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Danas",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Icon(
                      todayScore >= 75
                          ? Icons.fitness_center
                          : todayScore >= 50
                          ? Icons.directions_walk
                          : todayScore > 0
                          ? Icons.airline_seat_recline_normal
                          : Icons.help_outline,
                      size: 80,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      todayScore > 0 ? '$todayScore/100' : 'Nije uneseno',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Nedeljni prosek',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            averageActivity.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'od 100',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Logova ove nedelje',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            weeklyLogs.toString(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'unosa',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Log Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _navigateToPhysicalLog,
                  icon: const Icon(Icons.add_circle_outline, size: 28),
                  label: const Text(
                    'Unesi Fizički Log',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Weekly Progress Chart
              BlocBuilder<AppCubit, AppState>(
                builder: (context, state) {
                  final hasData = state.weeklyPhysicalData.any((d) => d > 0);

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Nedeljni napredak",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        if (!hasData)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                "Još nema podataka\nPočni da unosiš logove!",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            height: 100,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(7, (index) {
                                final value = state.weeklyPhysicalData[index];
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      width: 30,
                                      height: (value / 100 * 80).clamp(5, 80),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      [
                                        'P',
                                        'U',
                                        'S',
                                        'Č',
                                        'P',
                                        'S',
                                        'N',
                                      ][index],
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Calendar Section
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: CleanCalendar(
                  enableDenseViewForDates: true,
                  dateSelectionMode: DatePickerSelectionMode.singleOrMultiple,
                  selectedDates: selectedDates,
                  onSelectedDates: (dates) {
                    if (dates.isNotEmpty) {
                      _selectDate(dates.first);
                    }
                  },
                  selectedDatesProperties: DatesProperties(
                    datesDecoration: DatesDecoration(
                      datesBackgroundColor: Colors.blue,
                      datesTextColor: Colors.white,
                      datesBorderRadius: 100,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Selected Date Details
              if (selectedDates.isNotEmpty && selectedDayLog != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Fizički Log: ${selectedDates.first.day}.${selectedDates.first.month}.${selectedDates.first.year}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: _editLogForDate,
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          const Text(
                            'Aktivnost: ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${(selectedDayLog!['activity_level'] ?? 0) * 25}/100',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text(
                            'Koraci: ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${selectedDayLog!['steps'] ?? 0}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text(
                            'Trening: ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            selectedDayLog!['workout_done'] == true
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: selectedDayLog!['workout_done'] == true
                                ? Colors.green
                                : Colors.red,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else if (selectedDates.isNotEmpty && selectedDayLog == null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Nema fizičkog loga za ovaj datum",
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _editLogForDate,
                        icon: const Icon(Icons.add),
                        label: const Text('Dodaj log'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
