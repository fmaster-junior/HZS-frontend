import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final String? userId;
  final String? userName;
  final String? email;
  final String? joinDate;
  final String? errorMessage;

  AuthState({
    required this.isLoggedIn,
    this.isLoading = false,
    this.userId,
    this.userName,
    this.email,
    this.joinDate,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    String? userId,
    String? userName,
    String? email,
    String? joinDate,
    String? errorMessage,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      joinDate: joinDate ?? this.joinDate,
      errorMessage: errorMessage,
    );
  }
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthState(isLoggedIn: false)) {
    _checkCurrentSession();
  }

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> _checkCurrentSession() async {
    emit(state.copyWith(isLoading: true));
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        final user = session.user;
        emit(
          AuthState(
            isLoggedIn: true,
            userId: user.id,
            email: user.email,
            userName:
                user.userMetadata?['display_name'] ??
                user.email?.split('@').first,
            joinDate: _formatDate(user.createdAt),
          ),
        );
      } else {
        emit(AuthState(isLoggedIn: false));
      }
    } catch (e) {
      emit(AuthState(isLoggedIn: false));
    }
  }

  Future<void> signIn(String email, String password) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final user = response.user!;
        emit(
          AuthState(
            isLoggedIn: true,
            userId: user.id,
            email: user.email,
            userName:
                user.userMetadata?['display_name'] ??
                user.email?.split('@').first,
            joinDate: _formatDate(user.createdAt),
          ),
        );
      } else {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Sign in failed. Please try again.',
          ),
        );
      }
    } on AuthException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'An unexpected error occurred. Please try again.',
        ),
      );
    }
  }

  Future<void> signUp(String email, String password, String displayName, String fullName) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': displayName,
          'display_name': displayName,
          'full_name': fullName,
        },
      );

      if (response.user != null) {
        final user = response.user!;
        
        // Insert profile into profiles table
        // The 'id' column defaults to auth.uid() and 'created_at' defaults to now()
        // We only need to provide the required fields that don't have defaults
        try {
          await _supabase.from('profiles').upsert({
            'id': user.id,
            'username': displayName,
            'full_name': fullName,
          }, onConflict: 'id');
        } catch (e) {
          // Log error but continue - profile might already exist or will be created by trigger
          // ignore: avoid_print
          print('Profile insert error (may be expected): $e');
        }
        
        emit(
          AuthState(
            isLoggedIn: true,
            userId: user.id,
            email: user.email,
            userName: displayName,
            joinDate: _formatDate(user.createdAt),
          ),
        );
      } else {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Registration failed. Please try again.',
          ),
        );
      }
    } on AuthException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'An unexpected error occurred. Please try again.',
        ),
      );
    }
  }

  Future<void> signOut() async {
    emit(state.copyWith(isLoading: true));
    try {
      await _supabase.auth.signOut();
      emit(AuthState(isLoggedIn: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Sign out failed. Please try again.',
        ),
      );
    }
  }

  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}.';
    } catch (e) {
      return 'Unknown';
    }
  }
}
