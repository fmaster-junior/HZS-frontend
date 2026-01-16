import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streak_calendar/streak_calendar.dart';
import 'mentallogscreen.dart';
import 'app_cubit.dart';
import 'datarepo.dart';
import 'auth.dart';

class BrainScreen extends StatefulWidget {
  const BrainScreen({super.key});

  @override
  State<BrainScreen> createState() => _BrainScreenState();
}

class _BrainScreenState extends State<BrainScreen> {
  double averageMood = 0;
  int weeklyLogs = 0;
  int todayMood = 0;
  bool isLoading = true;
  List<DateTime> selectedDates = [];
  Map<String, dynamic>? selectedDayLog;

  @override
  void initState() {
    super.initState();
    _loadMentalStats();
    _loadWeeklyData();
  }

  Future<void> _loadWeeklyData() async {
    final authState = context.read<AuthCubit>().state;
    if (authState.userId != null) {
      await context.read<AppCubit>().loadWeeklyMentalData(authState.userId!);
    }
  }

  Future<void> _loadMentalStats() async {
    final authState = context.read<AuthCubit>().state;
    if (authState.userId == null) return;

    setState(() => isLoading = true);

    try {
      final repo = RepositoryProvider.of<DataRepository>(context);
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endDate = startOfWeek.add(const Duration(days: 6));

      final logs = await repo.fetchMentalLogsRange(
        authState.userId!,
        startOfWeek,
        endDate,
      );

      if (logs.isNotEmpty) {
        final totalMood = logs.fold<double>(
          0,
          (sum, log) => sum + (log['mood'] as num? ?? 0).toDouble(),
        );

        // Check today's mood
        final todayLog = logs.where((log) {
          final logDate = DateTime.parse(log['log_date']);
          return logDate.year == now.year &&
              logDate.month == now.month &&
              logDate.day == now.day;
        }).firstOrNull;

        setState(() {
          averageMood = totalMood / logs.length;
          weeklyLogs = logs.length;
          todayMood = todayLog?['mood'] ?? 0;
        });
      }
    } catch (e) {
      // Handle error silently
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _navigateToMentalLog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MentalLogScreen(logDate: DateTime.now()),
      ),
    );

    if (result == true) {
      // Reload stats after logging
      _loadMentalStats();
      // Reload weekly data in AppCubit
      final authState = context.read<AuthCubit>().state;
      if (authState.userId != null) {
        await context.read<AppCubit>().loadWeeklyMentalData(authState.userId!);
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
        selectedDayLog = logData?['mental'];
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
        builder: (context) => MentalLogScreen(logDate: selectedDates.first),
      ),
    );

    if (result == true) {
      // Reload stats and selected date after logging
      _loadMentalStats();
      _selectDate(selectedDates.first);
      // Reload weekly data in AppCubit
      final authState = context.read<AuthCubit>().state;
      if (authState.userId != null) {
        await context.read<AppCubit>().loadWeeklyMentalData(authState.userId!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Mentalno Zdravlje',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 400;
                final horizontalPadding = isSmallScreen ? 16.0 : 20.0;

                return SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(horizontalPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // Today's Status Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
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
                                todayMood == 4
                                    ? Icons.sentiment_very_satisfied
                                    : todayMood == 3
                                    ? Icons.sentiment_satisfied
                                    : todayMood == 2
                                    ? Icons.sentiment_neutral
                                    : todayMood == 1
                                    ? Icons.sentiment_dissatisfied
                                    : Icons.help_outline,
                                size: 80,
                                color: Colors.purple,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                todayMood > 0
                                    ? [
                                        'Loše',
                                        'Osrednje',
                                        'Dobro',
                                        'Odlično',
                                      ][todayMood - 1]
                                    : 'Nije uneseno',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
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
                                      averageMood.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'od 4',
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
                            onPressed: _navigateToMentalLog,
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 28,
                            ),
                            label: const Text(
                              'Unesi Mentalni Log',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
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
                            final hasData = state.weeklyMentalData.any(
                              (d) => d > 0,
                            );

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
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final barWidth =
                                            (constraints.maxWidth / 7) * 0.6;

                                        return SizedBox(
                                          height: 100,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: List.generate(7, (index) {
                                              final value =
                                                  state.weeklyMentalData[index];
                                              return Expanded(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 1,
                                                      ),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Container(
                                                        width: barWidth.clamp(
                                                          20,
                                                          35,
                                                        ),
                                                        height:
                                                            (value / 100 * 70)
                                                                .clamp(5, 70),
                                                        decoration: BoxDecoration(
                                                          color: Colors.purple,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                5,
                                                              ),
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
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }),
                                          ),
                                        );
                                      },
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
                            dateSelectionMode:
                                DatePickerSelectionMode.singleOrMultiple,
                            selectedDates: selectedDates,
                            onSelectedDates: (dates) {
                              if (dates.isNotEmpty) {
                                _selectDate(dates.first);
                              }
                            },
                            selectedDatesProperties: DatesProperties(
                              datesDecoration: DatesDecoration(
                                datesBackgroundColor: Colors.purple,
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
                              color: Colors.purple[50],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Mental Log: ${selectedDates.first.day}.${selectedDates.first.month}.${selectedDates.first.year}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.purple,
                                      ),
                                      onPressed: _editLogForDate,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    const Text(
                                      'Raspoloženje: ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      [
                                        'Loše',
                                        'Osrednje',
                                        'Dobro',
                                        'Odlično',
                                      ][(selectedDayLog!['mood'] ?? 1) - 1],
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Text(
                                      'Skor: ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${selectedDayLog!['score']}/100',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                if (selectedDayLog!['note'] != null &&
                                    selectedDayLog!['note']
                                        .toString()
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 15),
                                  const Text(
                                    'Beleška:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    selectedDayLog!['note'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        else if (selectedDates.isNotEmpty &&
                            selectedDayLog == null)
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
                                  "Nema mentalnog loga za ovaj datum",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton.icon(
                                  onPressed: _editLogForDate,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Dodaj log'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
