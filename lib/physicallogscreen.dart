import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'auth.dart';
import 'datarepo.dart';

class PhysicalLogScreen extends StatefulWidget {
  final DateTime logDate;

  const PhysicalLogScreen({super.key, required this.logDate});

  @override
  State<PhysicalLogScreen> createState() => _PhysicalLogScreenState();
}

class _PhysicalLogScreenState extends State<PhysicalLogScreen> {
  int physicalScore = 50; // 1-100 scale
  int steps = 5000;
  bool workoutDone = false;
  bool isLoading = false;
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.logDate;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('sr', 'RS'),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _savePhysicalLog() async {
    final authState = context.read<AuthCubit>().state;
    if (authState.userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Greška: Nisi prijavljen')));
      return;
    }

    setState(() => isLoading = true);

    try {
      final repo = RepositoryProvider.of<DataRepository>(context);

      print(
        'Saving physical log: score=$physicalScore, steps=$steps, workout=$workoutDone, date=${widget.logDate}',
      );

      // Save physical log (activity_level derived from score)
      await repo.createPhysicalLog(
        authState.userId!,
        selectedDate,
        (physicalScore / 25).round(), // Convert 1-100 to 1-4 for activity_level
        steps,
        workoutDone,
      );

      print('Physical log saved, updating daily log...');

      // Update daily log with physical score
      await repo.upsertDailyLog(
        authState.userId!,
        selectedDate,
        physicalScore: physicalScore,
      );

      // Update averages and streak
      await repo.calculateAndUpdateAveragePhysical(authState.userId!);
      await repo.calculateStreak(authState.userId!);

      print('Daily log updated successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fizički log uspešno sačuvan!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Greška: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd.MM.yyyy', 'sr_RS');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Fizički Log'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // DATE DISPLAY
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          dateFormatter.format(selectedDate),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(Icons.edit, size: 18, color: Colors.blue),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // PHYSICAL SCORE SLIDER (1-100)
              const Text(
                'Fizički skor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Kako ocenjuješ svoje fizičko stanje?',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Text('😴', style: TextStyle(fontSize: 30)),
                  Expanded(
                    child: Slider(
                      value: physicalScore.toDouble(),
                      min: 1,
                      max: 100,
                      divisions: 99,
                      label: physicalScore.toString(),
                      activeColor: Colors.blue,
                      onChanged: (value) {
                        setState(() => physicalScore = value.toInt());
                      },
                    ),
                  ),
                  const Text('🏃', style: TextStyle(fontSize: 30)),
                ],
              ),
              Center(
                child: Text(
                  'Skor: $physicalScore/100',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // STEPS SLIDER
              const Text(
                'Broj koraka',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Slider(
                value: steps.toDouble(),
                min: 0,
                max: 30000,
                divisions: 60,
                label: steps.toString(),
                activeColor: Colors.blue,
                onChanged: (value) {
                  setState(() => steps = value.toInt());
                },
              ),
              Center(
                child: Text(
                  '${NumberFormat('#,###').format(steps)} koraka',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // WORKOUT DONE CHECKBOX
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: workoutDone,
                      activeColor: Colors.blue,
                      onChanged: (value) {
                        setState(() => workoutDone = value ?? false);
                      },
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Trenirao/la sam danas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (workoutDone)
                      const Icon(
                        Icons.fitness_center,
                        color: Colors.blue,
                        size: 30,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // SAVE BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _savePhysicalLog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Sačuvaj Fizički Log',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
