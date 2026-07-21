import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/sync_service.dart';
import '../../../core/network/realtime_service.dart'; // 🚀 O MOTOR REVERB AQUI
import '../../notebooks/controllers/notebooks_controller.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../../../core/network/api_service.dart';
import '../../../core/database/app_database.dart' hide User;
import '../../subjects/controllers/subjects_controller.dart'; // Para engatilhar o Refresh

class AuthController extends ChangeNotifier {
  final AuthRepository _authRepository;
  final ApiService _apiService = ApiService();
  final AppDatabase _db;

  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _authErrorMessage;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get authErrorMessage => _authErrorMessage;
  bool get isAuthenticated => _token != null;

  // Usa o Ref para avisar outros Providers
  final Ref ref;

  AuthController(this.ref, {AuthRepository? repository, AppDatabase? database}) 
      : _authRepository = repository ?? AuthRepository(),
        _db = database ?? AppDatabase.instance;

  void setUser(User user, {String? newToken}) {
    _currentUser = user;
    if (newToken != null) _token = newToken;
    _authErrorMessage = null;
    notifyListeners();
  }

  // =========================================================================
  // 🔌 O MOTOR DE WEBSOCKETS PRIVADOS (REVERB)
  // =========================================================================
  void _connectToPrivateRadar(int userId) {
    // Mal o login é feito, ele liga a antena da conta do utilizador!
    RealtimeService().listenToUserAccount(userId, () {
      debugPrint('⚡ [Auth] A tua conta mudou noutro ecrã! A disparar Sync...');
      ref.read(subjectsProvider.notifier).syncManuallyWithCloud();
    });
  }

  // =========================================================================
  // 💾 ARRANQUE: VERIFICAR SESSÃO
  // =========================================================================
  Future<bool> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('sanctum_token');

    final String? cachedUser = prefs.getString('cached_user');
    if (cachedUser != null && _token != null) {
      _currentUser = User.fromJson(jsonDecode(cachedUser));

      // 🚀 A app abriu e já tinha sessão? Liga os WebSockets imediatamente!
      if (_currentUser?.id != null) {
        _connectToPrivateRadar(_currentUser!.id!);
      }
    }

    notifyListeners();
    return isAuthenticated;
  }

  // =========================================================================
  // 🚪 LOGIN
  // =========================================================================
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _authErrorMessage = null;
    notifyListeners();

    try {
      debugPrint('🛫 [Auth] Tentativa de login para: $email');
      final response = await _authRepository.login(email, password);
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        debugPrint('✅ [Auth] Resposta 200 OK. Token recebido.');
        _token = responseData['access_token'];

        final Map<String, dynamic> userMap = responseData['user'];

        debugPrint('💾 [Auth] A sincronizar utilizador para SQLite...');
        _currentUser = await _syncUserToSqlite(userMap);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sanctum_token', _token!);
        await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));

        // 🚀 O utilizador acabou de entrar, liga os WebSockets Pessoais!
        if (_currentUser?.id != null) {
          _connectToPrivateRadar(_currentUser!.id!);
        }

        debugPrint('🔄 [Auth] A iniciar sincronização total pós-login...');
        await SyncService().syncAll();

        _isLoading = false;
        notifyListeners();
        return true;
      } else if (response.statusCode == 422) {
        final Map<String, dynamic> errors = responseData['errors'] ?? {};
        _authErrorMessage = errors.values.isNotEmpty ? errors.values.first[0] : 'Credenciais inválidas.';
      } else {
        _authErrorMessage = responseData['message'] ?? 'Credenciais inválidas.';
      }
    } catch (e, stackTrace) {
      debugPrint('🚨 [Auth Error] Falha crítica no processo de login: $e');
      debugPrint('$stackTrace');
      _authErrorMessage = 'Erro de sistema: Falha ao comunicar com o servidor.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // =========================================================================
  // 🚪 REGISTO
  // =========================================================================
  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _authErrorMessage = null;
    notifyListeners();

    try {
      final response = await _authRepository.register(name, email, password);
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _token = responseData['token']?.toString() ?? responseData['access_token']?.toString();

        final Map<String, dynamic> userMap = responseData['user'] ?? {};

        _currentUser = await _syncUserToSqlite(userMap);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sanctum_token', _token!);
        await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));

        // 🚀 O utilizador acabou de se registar, liga os WebSockets!
        if (_currentUser?.id != null) {
          _connectToPrivateRadar(_currentUser!.id!);
        }

        await SyncService().syncAll();

        _isLoading = false;
        notifyListeners();
        return true;
      } else if (response.statusCode == 422) {
        final Map<String, dynamic> errors = responseData['errors'] ?? {};
        _authErrorMessage = errors.values.isNotEmpty ? errors.values.first[0] : 'E-mail ou dados inválidos.';
      } else {
        _authErrorMessage = responseData['message'] ?? 'Erro ao criar conta no servidor.';
      }
    } catch (e) {
      _authErrorMessage = 'Erro de sistema: Não foi possível registar.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // =========================================================================
  // 👤 ATUALIZAR PERFIL
  // =========================================================================
  Future<bool> updateProfile({required String name, required dynamic imageFile}) async {
    _isLoading = true;
    _authErrorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.updateProfile(name: name, imageFile: imageFile);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> userMap = responseData['user'];

        _currentUser = await _syncUserToSqlite(userMap);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _authErrorMessage = responseData['message'] ?? 'Erro ao atualizar perfil.';
      }
    } catch (e, stackTrace) {
      debugPrint('🚨 [CONTROLLER ERRO NO UPDATE]: $e');
      _authErrorMessage = 'Falha no motor interno ou perda de ligação à rede.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> sendRecoveryCode(String email) async {
    _isLoading = true;
    _authErrorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.forgotPassword(email);
      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _authErrorMessage = 'Não encontrámos nenhuma conta com este e-mail.';
      }
    } catch (e) {
      _authErrorMessage = 'Falha ao contactar o servidor.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> resetPassword({required String email, required String code, required String newPassword}) async {
    _isLoading = true;
    _authErrorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.resetPassword(email: email, code: code, newPassword: newPassword);

      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _authErrorMessage = 'Código PIN inválido ou expirado.';
      }
    } catch (e) {
      _authErrorMessage = 'Erro ao comunicar com o servidor.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // =========================================================================
  // 🛑 LOGOUT
  // =========================================================================
  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } catch (e) {
      debugPrint('⚠️ Falha ao efetuar logout remoto, a forçar limpeza local...');
    }

    // 🚀 1. DESLIGAR MOTORES REALTIME
    RealtimeService().disconnect();

    // 🚀 2. LIMPAR CACHE DE FICHEIROS (Apenas Mobile/Desktop)
    if (!kIsWeb) {
      try {
        final tempDir = Directory.systemTemp;
        final List<FileSystemEntity> files = tempDir.listSync();
        for (var file in files) {
          if (file is File && file.path.contains('sync_img_')) {
            file.deleteSync();
          }
        }
        debugPrint('🧹 [Auth] Imagens temporárias eliminadas.');
      } catch (e) {
        debugPrint('⚠️ Erro ao limpar ficheiros temporários: $e');
      }
    }

    // 🚀 3. LIMPAR PREFERÊNCIAS E TOKEN
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _token = null;
    _currentUser = null;
    _authErrorMessage = null;

    // 🚀 4. LIMPAR BASE DE DADOS SQLITE
    try {
      await _db.clearAllData();
      debugPrint('🗄️ [Auth] Base de dados local limpa.');
    } catch (e) {
      debugPrint('🚨 [Segurança]: Erro ao tentar limpar a Base de Dados local: $e');
    }

    // 🚀 5. NOTIFICAR REATIVIDADE (PROVIDERS VÃO REAGIR AO USER=NULL)
    notifyListeners();
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

    return User(
      id: localId,
      serverId: sId,
      name: name,
      email: email,
      avatar: avatar,
      planType: plan,
    );
  }
}

// Passamos o 'ref' para dentro do provider para que ele possa aceder ao subjectsProvider e fazer a ponte!
final authProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController(ref);
});