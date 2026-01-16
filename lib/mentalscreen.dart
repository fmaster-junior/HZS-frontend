import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'pollscreen.dart';
import 'app_cubit.dart';

class BrainScreen extends StatelessWidget {
  const BrainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mental Health Details"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 30),

              // 1. MAIN CARD (Mental Score)
              BlocBuilder<AppCubit, AppState>(
                builder: (context, state) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[350],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text("Your mental score is:", 
                          style: TextStyle(fontSize: 22, color: Colors.black54)),
                        const SizedBox(height: 20),
                        Icon(
                          state.mentalScore > 75 ? Icons.sentiment_very_satisfied_outlined : Icons.sentiment_satisfied,
                          size: 120, color: Colors.black
                        ),
                        const SizedBox(height: 10),
                        Text(
                          state.mentalScore > 75 ? "Ecstatic" : "Feeling Good",
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "You have achieved\n${state.mentalScore} / 100",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // 2. POLL ENTRANCE CARD (With BloC Logic for Locking)
              BlocBuilder<AppCubit, AppState>(
                builder: (context, state) {
                  // This is the condition from our AppCubit
                  final bool isLocked = state.isPollLocked;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      // If locked, onTap is null which disables the button
                      onTap: isLocked 
                        ? null 
                        : () {
                            context.read<AppCubit>().resetPoll();
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PollScreen()),
                            );
                          },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 25),
                        decoration: BoxDecoration(
                          // Changes color to a darker grey if locked
                          color: isLocked ? Colors.grey[400] : Colors.grey[350],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                isLocked 
                                  ? "Check back tomorrow!\nDaily poll completed" 
                                  : "Tell us about your\nday and earn score",
                                style: TextStyle(
                                  fontSize: 20, 
                                  color: isLocked ? Colors.black26 : Colors.black54,
                                ),
                              ),
                            ),
                            Icon(
                              isLocked ? Icons.lock_outline : Icons.arrow_forward_ios, 
                              color: isLocked ? Colors.black26 : Colors.black54
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}