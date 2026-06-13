import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  String? _token;

  String? get token => _token;
  bool get isAuthenticated => _token != null;

  Future<void> login(String email, String password) async {
    // Simulação de login
    await Future.delayed(const Duration(seconds: 1));
    _token = 'token_fake_123';
    await _storage.write(key: 'auth_token', value: _token);
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    await _storage.delete(key: 'auth_token');
    notifyListeners();
  }

  Future<void> checkAuth() async {
    _token = await _storage.read(key: 'auth_token');
    notifyListeners();
  }
}
