import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'auth.dart';
import 'datarepo.dart';

class LogDetailsScreen extends StatelessWidget {
  final DateTime logDate;

  const LogDetailsScreen({super.key, required this.logDate});

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd.MM.yyyy', 'sr_RS');
    final authState = context.read<AuthCubit>().state;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detalji Loga'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: authState.userId == null
          ? const Center(child: Text('Nisi prijavljen'))
          : FutureBuilder<Map<String, dynamic>?>(
              future: RepositoryProvider.of<DataRepository>(context)
                  .fetchLogForDate(authState.userId!, logDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Greška: ${snapshot.error}'));
                }

                final logData = snapshot.data;
                final dailyLog = logData?['daily'];
                final mentalLog = logData?['mental'];
                final physicalLog = logData?['physical'];

                if (dailyLog == null && mentalLog == null && physicalLog == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_busy, size: 80, color: Colors.grey),
                        const SizedBox(height: 20),
                        Text(
                          'Nema podataka za ${dateFormatter.format(logDate)}',
                          style: const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Header
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 24),
                            const SizedBox(width: 10),
                            Text(
                              dateFormatter.format(logDate),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Mental Log Section
                      if (mentalLog != null) ...[
                        _buildSectionTitle('Mentalni Log', Icons.psychology, Colors.purple),
                        const SizedBox(height: 15),
                        _buildInfoCard([
                          _buildInfoRow('Raspoloženje', '${mentalLog['mood'] ?? 'N/A'}/4', Icons.mood),
                          _buildInfoRow('Skor', '${mentalLog['score'] ?? 'N/A'}/100', Icons.star),
                          if (mentalLog['note'] != null && mentalLog['note'].toString().isNotEmpty)
                            _buildInfoRow('Beleška', mentalLog['note'], Icons.note),
                        ]),
                        const SizedBox(height: 30),
                      ],

                      // Physical Log Section
                      if (physicalLog != null) ...[
                        _buildSectionTitle('Fizički Log', Icons.fitness_center, Colors.blue),
                        const SizedBox(height: 15),
                        _buildInfoCard([
                          _buildInfoRow('Nivo aktivnosti', '${physicalLog['activity_level'] ?? 'N/A'}/4', Icons.local_fire_department),
                          _buildInfoRow('Koraci', NumberFormat('#,###').format(physicalLog['steps'] ?? 0), Icons.directions_walk),
                          _buildInfoRow('Trening', physicalLog['workout_done'] == true ? 'Da ✓' : 'Ne', Icons.sports_gymnastics),
                        ]),
                        const SizedBox(height: 30),
                      ],

                      // Daily Summary
                      if (dailyLog != null) ...[
                        _buildSectionTitle('Dnevni Pregled', Icons.summarize, Colors.orange),
                        const SizedBox(height: 15),
                        _buildInfoCard([
                          if (dailyLog['mental_mood'] != null)
                            _buildInfoRow('Mentalno', '${dailyLog['mental_mood']}/4', Icons.psychology),
                          if (dailyLog['physical_score'] != null)
                            _buildInfoRow('Fizički skor', '${dailyLog['physical_score']}/100', Icons.fitness_center),
                        ]),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
