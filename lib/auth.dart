import 'package:flutter_bloc/flutter_bloc.dart';

class AuthState {
  final bool isLoggedIn;
  final String? userId; // Added this
  final String? userName;
  final String? joinDate;

  AuthState({
    required this.isLoggedIn, 
    this.userId, // Added this
    this.userName, 
    this.joinDate
  });
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthState(isLoggedIn: false));

  void login() {
    // We add a mock userId here so other screens can use it
    emit(AuthState(
      isLoggedIn: true, 
      userId: "user_12345", // Mock ID
      userName: "Duši Viber", 
      joinDate: "2009.03.07."
    ));
  }

  void logout() => emit(AuthState(isLoggedIn: false));
}