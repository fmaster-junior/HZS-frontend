import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streak_calendar/streak_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'fitness_cubit.dart';

class FitnessScreen extends StatelessWidget {
  const FitnessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<FitnessCubit, FitnessState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 20),
                  const Text("Detaljna Aktivnost", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                  const SizedBox(height: 30),

                  // INTERACTIVE CALENDAR
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.grey[350], borderRadius: BorderRadius.circular(20)),
                    child: CleanCalendar(
                      enableDenseViewForDates: true,
                      dateSelectionMode: DatePickerSelectionMode.singleOrMultiple,
                      selectedDates: state.selectedDates,
                      onSelectedDates: (dates) => context.read<FitnessCubit>().selectDate(dates.first),
                      selectedDatesProperties: DatesProperties(
                        datesDecoration: DatesDecoration(
                          datesBackgroundColor: Colors.black,
                          datesTextColor: Colors.white,
                          datesBorderRadius: 100,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // DATA BOX
                  if (state.selectedDates.isNotEmpty)
                    _buildActivityDetailBox(state)
                  else
                    const Center(child: Text("Izaberi datum za detalje")),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityDetailBox(FitnessState state) {
    final date = state.selectedDates.first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Aktivnost: ${date.day}.${date.month}.${date.year}.", 
               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: 20,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: _buildTitles(),
                barGroups: state.weeklyData.asMap().entries.map((e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value, 
                      color: Colors.black, 
                      width: 18, 
                      backDrawRodData: BackgroundBarChartRodData(show: true, toY: 20, color: Colors.grey[400])
                    )
                  ],
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  FlTitlesData _buildTitles() {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
            return Text(days[value.toInt() % 7], style: const TextStyle(fontSize: 12));
          },
        ),
      ),
    );
  }
}