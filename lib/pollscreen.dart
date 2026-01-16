import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_polls/flutter_polls.dart';
import 'app_cubit.dart';
import 'auth.dart'; // Kept to access the userId

class PollScreen extends StatelessWidget {
  const PollScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // LOGIC INTACT: Retrieve userId from AuthCubit
    final authState = context.read<AuthCubit>().state;
    final String userId = authState.userId ?? "guest_user";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Daily Check-in"), 
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          final cubit = context.read<AppCubit>();

          // REVERTED UI: Completion Screen from your previous file
          if (state.currentPollIndex >= cubit.questions.length) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                  const SizedBox(height: 20),
                  const Text("All done! Score updated.", style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Return to Details", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          // REVERTED UI: Main Poll structure with the kept userId logic
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: FlutterPolls(
              key: ValueKey(state.currentPollIndex), 
              pollId: state.currentPollIndex.toString(),
              onVoted: (PollOption pollOption, int newTotalVotes) async {
                // LOGIC INTACT: Pass the userId to cubit
                cubit.submitVote(int.parse(pollOption.id!), userId);
                return true;
              },
              pollTitle: Text(
                cubit.questions[state.currentPollIndex],
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              pollOptions: [
                PollOption(id: '1', title: const Text('1 - Poor'), votes: 0),
                PollOption(id: '2', title: const Text('2 - Okay'), votes: 0),
                PollOption(id: '3', title: const Text('3 - Good'), votes: 0),
                PollOption(id: '4', title: const Text('4 - Ecstatic'), votes: 0),
              ],
            ),
          );
        },
      ),
    );
  }
}