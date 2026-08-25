import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:caderno_digital_app/core/network/sync_provider.dart';
import 'package:caderno_digital_app/core/network/realtime_service.dart';
import 'package:caderno_digital_app/features/auth/models/user_model.dart';
import 'package:caderno_digital_app/features/auth/repositories/auth_repository.dart';
import 'package:caderno_digital_app/core/network/api_service.dart';
import 'package:caderno_digital_app/core/database/app_database.dart' hide User;
import 'package:caderno_digital_app/features/subjects/controllers/subjects_controller.dart';
import '../providers/auth_providers.dart';
import 'auth_state.dart';

class AuthController extends Notifier<AuthState> {
  late AuthRepository _authRepository;
  final ApiService _apiService = ApiService();
  late AppDatabase _db;

  @override
  AuthState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    _db = ref.watch(appDatabaseProvider);
    return AuthState();
  }

  void setUser(User user, {String? newToken}) {
    state = state.copyWith(
      currentUser: user,
      token: newToken,
      clearError: true,
    );
  }

  void clearError() {
    if (state.authErrorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  void _connectToPrivateRadar(int userId) {
    ref.read(realtimeServiceProvider).listenToUserAccount(userId, () {
      debugPrint('⚡ [Auth] A tua conta mudou noutro ecrã! A disparar Sync...');
      ref.read(subjectsProvider.notifier).syncManuallyWithCloud();
    });
  }

  Future<bool> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('sanctum_token');
    final String? cachedUser = prefs.getString('cached_user');

    if (cachedUser != null && token != null) {
      final user = User.fromJson(jsonDecode(cachedUser));
      state = state.copyWith(currentUser: user, token: token);

      if (user.id != null) {
        _connectToPrivateRadar(user.id!);
      }
      return true;
    }
    return false;
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _authRepository.login(email, password);
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final String token = responseData['access_token'];
        final Map<String, dynamic> userMap = responseData['user'];
        final user = await _syncUserToSqlite(userMap);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sanctum_token', token);
        await prefs.setString('cached_user', jsonEncode(user.toJson()));

        if (user.id != null) {
          _connectToPrivateRadar(user.id!);
        }

        state = state.copyWith(currentUser: user, token: token, isLoading: false);
        
        // Sync em background
        unawaited(ref.read(appSyncServiceProvider).syncAll(metadataOnly: true));
        return true;
      } else {
        final String error = responseData['message'] ?? 'Credenciais inválidas.';
        state = state.copyWith(authErrorMessage: error, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(authErrorMessage: 'Erro de sistema: Falha ao comunicar com o servidor.', isLoading: false);
    }
    return false;
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _authRepository.register(name, email, password);
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final String token = responseData['token']?.toString() ?? responseData['access_token']?.toString() ?? '';
        final Map<String, dynamic> userMap = responseData['user'] ?? {};
        final user = await _syncUserToSqlite(userMap);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sanctum_token', token);
        await prefs.setString('cached_user', jsonEncode(user.toJson()));

        if (user.id != null) {
          _connectToPrivateRadar(user.id!);
        }

        state = state.copyWith(currentUser: user, token: token, isLoading: false);
        unawaited(ref.read(appSyncServiceProvider).syncAll(metadataOnly: true));
        return true;
      } else {
        final String error = responseData['message'] ?? 'Erro ao criar conta.';
        state = state.copyWith(authErrorMessage: error, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(authErrorMessage: 'Erro de sistema.', isLoading: false);
    }
    return false;
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      await ref.read(appSyncServiceProvider).syncAll(forced: true, metadataOnly: false);
    } catch (e) {
      debugPrint('🚨 [Auth] Erro na sincronização final: $e');
    }

    try {
      await _authRepository.logout();
    } catch (_) {}

    ref.read(realtimeServiceProvider).disconnect();

    if (!kIsWeb) {
      try {
        final tempDir = Directory.systemTemp;
        tempDir.listSync().forEach((file) {
          if (file is File && file.path.contains('sync_img_')) file.deleteSync();
        });
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _db.clearAllData();

    state = AuthState(); // Reset completo
  }

  Future<User> _syncUserToSqlite(Map<String, dynamic> userJson) async {
    final int sId = userJson['id'] is int ? userJson['id'] : int.parse(userJson['id'].toString());
    final String email = userJson['email'] ?? '';
    final String name = userJson['name'] ?? '';
    final String? avatar = userJson['avatar'];
    final String plan = userJson['plan_type'] ?? 'free';

    final existing = await (_db.select(_db.users)..where((t) => t.email.equals(email))).getSingleOrNull();

    int localId;
    if (existing != null) {
      localId = existing.id;
      await (_db.update(_db.users)..where((t) => t.id.equals(localId))).write(
        UsersCompanion(
          serverId: Value(sId),
          name: Value(name),
          avatar: Value(avatar),
          planType: Value(plan),
          syncedWithCloud: const Value(1),
        ),
      );
    } else {
      localId = await _db.into(_db.users).insert(
            UsersCompanion.insert(
              serverId: Value(sId),
              name: name,
              email: email,
              avatar: Value(avatar),
              planType: Value(plan),
              syncedWithCloud: const Value(1),
            ),
          );
    }

    return User(id: localId, serverId: sId, name: name, email: email, avatar: avatar, planType: plan);
  }

  Future<bool> sendRecoveryCode(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiService.forgotPassword(email);
      if (response.statusCode == 200) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(authErrorMessage: 'Não encontrámos nenhuma conta com este e-mail.', isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(authErrorMessage: 'Falha ao contactar o servidor.', isLoading: false);
    }
    return false;
  }

  Future<bool> resetPassword({required String email, required String code, required String newPassword}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiService.resetPassword(email: email, code: code, newPassword: newPassword);
      if (response.statusCode == 200) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        final data = jsonDecode(response.body);
        state = state.copyWith(authErrorMessage: data['message'] ?? 'Código PIN inválido ou expirado.', isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(authErrorMessage: 'Erro ao comunicar com o servidor.', isLoading: false);
    }
    return false;
  }

  Future<bool> updateProfile({required String name, required dynamic imageFile}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiService.updateProfile(name: name, imageFile: imageFile);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> userMap = responseData['user'];
        final user = await _syncUserToSqlite(userMap);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_user', jsonEncode(user.toJson()));

        state = state.copyWith(currentUser: user, isLoading: false);
        return true;
      } else {
        state = state.copyWith(authErrorMessage: responseData['message'] ?? 'Erro ao atualizar perfil.', isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(authErrorMessage: 'Falha no motor interno ou perda de ligação à rede.', isLoading: false);
    }
    return false;
  }
}

final authProvider = NotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});
