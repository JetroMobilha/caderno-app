import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../../../core/database/database_helper.dart';
import '../repositories/auth_repository.dart';
import '../../../core/network/api_service.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  final ApiService _apiService = ApiService();

  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _authErrorMessage;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get authErrorMessage => _authErrorMessage;
  bool get isAuthenticated => _token != null;

  void setUser(User user, {String? newToken}) {
    _currentUser = user;
    if (newToken != null) _token = newToken;
    _authErrorMessage = null;
    notifyListeners();
  }

  // =========================================================================
  // 🕵️ RASTREIO DE ARRANQUE
  // =========================================================================
  Future<bool> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('sanctum_token');

    final String? cachedUser = prefs.getString('cached_user');
    if (cachedUser != null && _token != null) {
      _currentUser = User.fromJson(jsonDecode(cachedUser));
    }

    notifyListeners();
    return isAuthenticated;
  }

  // =========================================================================
  // 🔐 EFETUAR LOGIN (Revisto com persistência automática no SQLite!)
  // =========================================================================
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _authErrorMessage = null;
    notifyListeners();

    try {
      final response = await _authRepository.login(email, password);
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _token = responseData['access_token'];

        // 🚀 PASSO TÁTICO: Sincroniza e grava o utilizador na tabela local do SQLite!
        final Map<String, dynamic> userMap = responseData['user'];
        _currentUser = await _syncUserToSqlite(userMap);

        // Guarda o cache de sessão rápida
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sanctum_token', _token!);
        await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));

        _isLoading = false;
        notifyListeners();
        return true;
      } else if (response.statusCode == 422) {
        final Map<String, dynamic> errors = responseData['errors'] ?? {};
        _authErrorMessage = errors.values.isNotEmpty ? errors.values.first[0] : 'Credenciais inválidas.';
      } else {
        _authErrorMessage = responseData['message'] ?? 'Credenciais inválidas.';
      }
    } catch (e) {
      _authErrorMessage = 'Erro de sistema: Falha ao comunicar com o servidor.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // =========================================================================
  // 📝 REGISTAR UTILIZADOR (Revisto com persistência automática no SQLite!)
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

        // 🚀 PASSO TÁTICO: Grava no SQLite local para obter o ID gerado pelo telemóvel
        final Map<String, dynamic> userMap = responseData['user'] ?? {};
        _currentUser = await _syncUserToSqlite(userMap);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sanctum_token', _token!);
        await prefs.setString('cached_user', jsonEncode(_currentUser!.toJson()));

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
  // 🖼️ ATUALIZAR PERFIL (Revisto com persistência automática no SQLite!)
  // =========================================================================
  Future<bool> updateProfile({required String name, required dynamic imageFile}) async {
    _isLoading = true;
    _authErrorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.updateProfile(
        name: name,
        imageFile: imageFile,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> userMap = responseData['user'];

        // 🚀 Atualiza a tabela local do SQLite também!
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

  // =========================================================================
  // 📨 PEDIR CÓDIGO DE RECUPERAÇÃO (Forgot Password)
  // =========================================================================
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
        _authErrorMessage = 'Não encontrámos nenhuma conta institucional com este e-mail.';
      }
    } catch (e) {
      _authErrorMessage = 'Falha ao contactar o quartel-general (Servidor).';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // =========================================================================
  // 🔑 REDEFINIR PALAVRA-PASSE (Reset Password)
  // =========================================================================
  Future<bool> resetPassword({required String email, required String code, required String newPassword}) async {
    _isLoading = true;
    _authErrorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );

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
  // 🛑 TERMINAR SESSÃO (Chama o teu clearAllData() oficial!)
  // =========================================================================
  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } catch (e) {
      debugPrint('⚠️ Falha ao efetuar logout remoto, a forçar limpeza local...');
    }

    _token = null;
    _currentUser = null;
    _authErrorMessage = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    try {
      // 💣 Ativa o teu Protocolo de Limpeza oficial do DatabaseHelper!
      await DatabaseHelper.instance.clearAllData();
    } catch (e) {
      debugPrint('🚨 [Segurança]: Erro ao tentar limpar a Base de Dados local: $e');
    }

    notifyListeners();
  }

  // =========================================================================
  // 🚀 O MOTOR SECRETO: GARANTE QUE O UTILIZADOR EXISTE NO SQLITE LOCAL
  // =========================================================================
  Future<User> _syncUserToSqlite(Map<String, dynamic> userJson) async {
    final db = await DatabaseHelper.instance.database;

    final int sId = userJson['id'] is int ? userJson['id'] : int.parse(userJson['id'].toString());
    final String email = userJson['email'] ?? '';
    final String name = userJson['name'] ?? '';
    final String? avatar = userJson['avatar'];
    final String plan = userJson['plan_type'] ?? 'free';

    // Procura se o e-mail já existe na tabela 'users' local
    final List<Map<String, dynamic>> existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    int localId;

    if (existing.isNotEmpty) {
      // Se já existe, atualiza os dados mantendo o ID local intacto
      localId = existing.first['id'] as int;
      await db.update(
        'users',
        {
          'server_id': sId,
          'name': name,
          'avatar': avatar,
          'plan_type': plan,
          'synced_with_cloud': 1,
        },
        where: 'id = ?',
        whereArgs: [localId],
      );
    } else {
      // Se é um utilizador novo no telemóvel, insere um registo novo
      localId = await db.insert(
        'users',
        {
          'server_id': sId,
          'name': name,
          'email': email,
          'avatar': avatar,
          'plan_type': plan,
          'synced_with_cloud': 1,
        },
      );
    }

    // Retorna o objeto User com os dois IDs preenchidos com total segurança!
    return User(
      id: localId, // 🧠 O ID auto-incrementado do telemóvel!
      serverId: sId, // ☁️ O ID vindo do Laravel!
      name: name,
      email: email,
      avatar: avatar,
      planType: plan,
    );
  }
}

final authProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController();
});