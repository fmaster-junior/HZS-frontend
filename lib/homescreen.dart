import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:streak_calendar/streak_calendar.dart';
import 'app_cubit.dart';
import 'mentalscreen.dart';
import 'physicalscreen.dart';
import 'fitness_cubit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER ROW
            _buildHeader(context),

            const SizedBox(height: 30),
            const Text("Kalendar sa tvojim aktivnostima", 
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // 2. CALENDAR CARD (Listening to FitnessCubit)
            BlocBuilder<FitnessCubit, FitnessState>(
              builder: (context, state) {
                return _buildCalendarCard(context, state.selectedDates);
              },
            ),

            const SizedBox(height: 30),
            const Text("Napredak: Fizički (Crno) i Mentalni (Sivo)", 
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // 3. PROGRESS CHART (Listening to BOTH Cubits)
            BlocBuilder<FitnessCubit, FitnessState>(
              builder: (context, fitnessState) {
                return BlocBuilder<AppCubit, AppState>(
                  builder: (context, mentalState) {
                    // Logic: Get physical data from FitnessState
                    // Logic: Get mental data from AppState (MentalScreen updates this)
                    return _buildHomeChart(
                      fitnessState.weeklyData, 
                      // Here we use the score from AppCubit. 
                      // Note: Using placeholders for the rest of the week for now
                      [mentalState.mentalScore.toDouble(), 45, 55, 40, 65, 50, 75], 
                    );
                  },
                );
              },
            ),
            
            const SizedBox(height: 10),
            _buildLegend(), // Helpful addition to identify the two lines/bars
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.psychology, size: 40, color: Colors.black),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BrainScreen())),
        ),
        const Text("RealTalk", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FitnessScreen())),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.5)),
            child: const Icon(Icons.fitness_center, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarCard(BuildContext context, List<DateTime> selectedDates) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[350],
        borderRadius: BorderRadius.circular(20),
      ),
      child: CleanCalendar(
        enableDenseViewForDates: true,
        enableDenseSplashForDates: true,
        dateSelectionMode: DatePickerSelectionMode.singleOrMultiple,
        selectedDates: selectedDates,
        onSelectedDates: (List<DateTime> value) {
          if (value.isNotEmpty) {
            context.read<FitnessCubit>().selectDate(value.first);
          }
        },
        selectedDatesProperties: DatesProperties(
          datesDecoration: DatesDecoration(
            datesBorderRadius: 1000,
          ),
        ),
      ),
    );
  }

  Widget _buildHomeChart(List<double> physicalData, List<double> mentalData) {
    return Container(
      width: double.infinity,
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.grey[350], borderRadius: BorderRadius.circular(20)),
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: List.generate(7, (index) {
            return BarChartGroupData(
              x: index,
              barsSpace: 4, // Space between physical and mental bars
              barRods: [
                // Physical Bar (Black)
                BarChartRodData(
                  toY: physicalData.length > index ? physicalData[index] : 0,
                  color: Colors.black,
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                // Mental Bar (Grey)
                BarChartRodData(
                  toY: mentalData.length > index ? mentalData[index] : 0,
                  color: Colors.grey[600],
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem("Fizički", Colors.black),
        const SizedBox(width: 20),
        _legendItem("Mentalni", Colors.grey[600]!),
      ],
    );
  }

  Widget _legendItem(String text, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}