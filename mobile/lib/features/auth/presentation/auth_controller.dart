import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/user_model.dart';
import '../../onboarding/presentation/onboarding_controller.dart';

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({this.isLoading = false, this.user, this.errorMessage});

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.login(email: email, password: password);
      ref.invalidate(onboardingControllerProvider);
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      final cleanMessage = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: cleanMessage);
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      ref.invalidate(onboardingControllerProvider);
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      final cleanMessage = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: cleanMessage);
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.logout();
      state = const AuthState();
      ref.invalidate(onboardingControllerProvider);
    } catch (_) {
      state = const AuthState();
      ref.invalidate(onboardingControllerProvider);
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
