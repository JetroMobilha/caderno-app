import '../models/user_model.dart';

class AuthState {
  final User? currentUser;
  final String? token;
  final bool isLoading;
  final String? authErrorMessage;

  AuthState({
    this.currentUser,
    this.token,
    this.isLoading = false,
    this.authErrorMessage,
  });

  bool get isAuthenticated => token != null;

  AuthState copyWith({
    User? currentUser,
    String? token,
    bool? isLoading,
    String? authErrorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      authErrorMessage: clearError ? null : (authErrorMessage ?? this.authErrorMessage),
    );
  }
}
