import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../../../core/database/database_helper.dart';
import '../repositories/auth_repository.dart';
import '../../../core/network/api_service.dart'; // 🚀 Acesso direto para upload multipart se necessário

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
  // 🔐 EFETUAR LOGIN
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
        _currentUser = User.fromJson(responseData['user']);

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
  // 📝 REGISTAR UTILIZADOR
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
        _currentUser = User.fromJson(responseData['user'] ?? {});

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
  // 📨 PEDIR CÓDIGO DE RECUPERAÇÃO (Forgot Password)
  // =========================================================================
  Future<bool> sendRecoveryCode(String email) async {
    _isLoading = true;
    _authErrorMessage = null;
    notifyListeners();

    try {
      // Consome o teu ApiService universal
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
  // 🖼️ ATUALIZAR PERFIL (Nome e Imagem Híbrida com XFile)
  // =========================================================================
  Future<bool> updateProfile({required String name, required dynamic imageFile}) async {
    _isLoading = true;
    _authErrorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.updateProfile(
        name: name,
        imageFile: imageFile, // Suporta XFile local e web
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> userMap = responseData['user'];
        _currentUser = User.fromJson(userMap);

        await _apiService.saveUserData(userMap);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _authErrorMessage = responseData['message'] ?? 'Erro ao atualizar perfil.';
      }
    } catch (e, stackTrace) {
      // 🚀 AGORA ELE GRITA O ERRO REAL NA CONSOLA:
      debugPrint('🚨 [CONTROLLER ERRO NO UPDATE]: $e');
      debugPrint('🚨 [RASTRO DO ERRO]: $stackTrace');

      _authErrorMessage = 'Falha no motor interno ou perda de ligação à rede.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // =========================================================================
  // 🛑 TERMINAR SESSÃO
  // =========================================================================
  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } catch (e) {

      debugPrint('⚠️ Falha ao efetuar logout remoto, a forçar limpeza local...');
      return;
    }

    // 1. Apaga a chave e os dados em cache (RAM)
    _token = null;
    _currentUser = null;
    _authErrorMessage = null;

    // 2. Limpa o SharedPreferences (Disco)
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // 🚀 Apaga tudo (token, utilizador, última disciplina)

    // 3. 💣 INCINERA A BASE DE DADOS LOCAL (Proteção de Privacidade)
    try {
      await DatabaseHelper.instance.clearAllData();
    } catch (e) {
      debugPrint('🚨 [Segurança]: Erro ao tentar limpar a Base de Dados local: $e');
    }

    notifyListeners();
  }
}

// 🚀 ANTENA DO RIVERPOD
final authProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController();
});