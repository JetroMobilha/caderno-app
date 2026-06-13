import 'dart:convert';
import 'package:caderno/core/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final _apiService = ApiService();
  
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _apiService.post('/login', {
        'email': email,
        'password': password,
        'device_name': 'mobile_app', // Necessário para o Sanctum
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        await _storage.write(key: 'auth_token', value: _token);
        _setLoading(false);
        return true;
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['message'] ?? 'Erro ao fazer login';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erro de conexão com o servidor';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _apiService.post('/register', {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        await _storage.write(key: 'auth_token', value: _token);
        _setLoading(false);
        return true;
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['message'] ?? 'Erro ao criar conta';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erro de conexão com o servidor';
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _apiService.post('/logout', {});
    } catch (_) {}

    _token = null;
    await _storage.delete(key: 'auth_token');
    notifyListeners();
  }

  Future<void> checkAuth() async {
    _token = await _storage.read(key: 'auth_token');
    notifyListeners();
  }
}
