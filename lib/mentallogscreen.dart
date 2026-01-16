import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'auth.dart';
import 'datarepo.dart';

class MentalLogScreen extends StatefulWidget {
  final DateTime logDate;

  const MentalLogScreen({super.key, required this.logDate});

  @override
  State<MentalLogScreen> createState() => _MentalLogScreenState();
}

class _MentalLogScreenState extends State<MentalLogScreen> {
  int mood = 2; // 1-4 scale
  final TextEditingController noteController = TextEditingController();
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

  Future<void> _saveMentalLog() async {
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
        'Saving mental log: mood=$mood, score=${mood * 25}, date=${widget.logDate}',
      );

      // Save mental log (mood 1-4, score calculated as mood * 25)
      await repo.createMentalLog(
        authState.userId!,
        selectedDate,
        mood,
        mood * 25, // Convert 1-4 to 25-100 scale
        noteController.text,
      );

      print('Mental log saved, updating daily log...');

      // Update daily log with mental mood
      await repo.upsertDailyLog(
        authState.userId!,
        selectedDate,
        mentalMood: mood,
      );

      // Update averages and streak
      await repo.calculateAndUpdateAverageMood(authState.userId!);
      await repo.calculateStreak(authState.userId!);

      print('Daily log updated successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mentalni log uspešno sačuvan!')),
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

  Widget _buildMoodButton(int value, String emoji, String label) {
    final isSelected = mood == value;
    return GestureDetector(
      onTap: () => setState(() => mood = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.grey[200],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd.MM.yyyy', 'sr_RS');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mentalni Log'),
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
                    color: Colors.purple[50],
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
                      const Icon(Icons.edit, size: 18, color: Colors.purple),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // MOOD SLIDER (1-4)
              const Text(
                'Kako se osećaš?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMoodButton(1, '😢', 'Loše'),
                  _buildMoodButton(2, '😐', 'Osrednje'),
                  _buildMoodButton(3, '🙂', 'Dobro'),
                  _buildMoodButton(4, '😄', 'Odlično'),
                ],
              ),
              const SizedBox(height: 15),
              Center(
                child: Text(
                  'Izabrano: ${['Loše', 'Osrednje', 'Dobro', 'Odlično'][mood - 1]}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // NOTE TEXT FIELD
              const Text(
                'Dodaj belešku (opciono)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: noteController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Kako se osećaš? Šta ti je na umu?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),

              const SizedBox(height: 40),

              // SAVE BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveMentalLog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Sačuvaj Mentalni Log',
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
