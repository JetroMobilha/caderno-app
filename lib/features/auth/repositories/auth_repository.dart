import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/api_service.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();

  // Executa o pedido POST ao Laravel para Autenticar
  Future<http.Response> login(String email, String password) async {
    final payload = {
      'login_id': email,
      'password': password,
    };
    return await _apiService.post('/login', payload);
  }

  // Executa o pedido POST ao Laravel para Registar um Novo Aluno
  Future<http.Response> register(String name, String email, String password) async {
    final payload = {
      'name': name,
      'email': email,
      'password': password,
    };
    return await _apiService.post('/register', payload);
  }

  // Executa o pedido POST ao Laravel para Terminar Sessão (Logout)
  Future<http.Response> logout() async {
    return await _apiService.post('/logout', {});
  }
}