import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

// O Gestor de Estado do Utilizador
class UserNotifier extends StateNotifier<User?> {
  UserNotifier() : super(null);

  // 📥 Atualiza o utilizador (ex: após login ou edição de perfil)
  void setUser(User user) {
    state = user;
  }

  // 🚪 Limpa o utilizador (ex: após o Logout)
  void clearUser() {
    state = null;
  }
}

// O Rádio que a UI vai escutar
final userProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
  return UserNotifier();
});