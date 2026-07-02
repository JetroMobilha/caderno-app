import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Singleton Pattern: Garante que só existe 1 antena de internet na app toda
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static String get baseUrl {
    return 'http://127.0.0.1:8000/api';
  }

  static String get baseUrlImagem {
    return 'http://127.0.0.1/storage/';
  }
  // =========================================================================
  // 🔐 GESTÃO DO COFRE DE SESSÃO (Sanctum Token)
  // =========================================================================
  Future<void> saveToken(String token) async => await _storage.write(key: 'sanctum_token', value: token);
  Future<String?> getToken() async => await _storage.read(key: 'sanctum_token');
  Future<void> deleteToken() async => await _storage.delete(key: 'sanctum_token');

  Future<void> saveUserData(Map<String, dynamic> userMap) async => await _storage.write(key: 'user_data', value: jsonEncode(userMap));
  Future<Map<String, dynamic>?> getUserData() async {
    final str = await _storage.read(key: 'user_data');
    return str != null ? jsonDecode(str) : null;
  }

  // =========================================================================
  // 🛠️ MONTADOR DE CABEÇALHO UNIVERSAL (A Regra de Ouro do Laravel)
  // =========================================================================
  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json', // <--- OBRIGATÓRIO PARA O LARAVEL NÃO DEVOLVER HTML DE ERRO
    };

    if (requireAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // =========================================================================
  // 📡 MÉTODOS HTTP BLINDADOS
  // =========================================================================

  // POST (Para Login, Registo, Criar Cadernos)
  Future<http.Response> post(String endpoint, Map<String, dynamic> body, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);

    // 🕵️‍♂️ 1. LOG DE SAÍDA (O que o Flutter está a enviar)
    print('🛫 POST $url');
    print('📦 DADOS: ${jsonEncode(body)}');

    final response = await http.post(url, headers: headers, body: jsonEncode(body));

    // 🕵️‍♂️ 2. LOG DE ENTRADA (O que o Laravel respondeu)
    print('🛬 RESPOSTA [${response.statusCode}]: ${response.body}');

    return response;
  }

  // GET (Para Listar Disciplinas e Páginas)
  Future<http.Response> get(String endpoint, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);

    // 🕵️‍♂️ 1. LOG DE SAÍDA (O que o Flutter está a enviar)
    print('🛫 POST $url');
    print('📦 DADOS: ${jsonEncode(headers)}');

    final response = await http.get(url, headers: headers);

    // 🕵️‍♂️ 2. LOG DE ENTRADA (O que o Laravel respondeu)
    print('🛬 RESPOSTA [${response.statusCode}]: ${response.body}');

    return response;

  }

  // DELETE (Para Soft Delete de Cadernos)
  Future<http.Response> delete(String endpoint, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);

    return await http.delete(url, headers: headers);
  }

  // =========================================================================
  // 🚪 1. TERMINAR SESSÃO (LOGOUT)
  // =========================================================================
  Future<void> logout() async {
    try {
      // 1. Avisa o Laravel para destruir o token no servidor (Requer Auth)
      await post('/logout', {}, requireAuth: true);
    } catch (e) {
      print('🚨 Erro a avisar o servidor do logout: $e');
    } finally {
      // 2. INDEPENDENTEMENTE de o servidor responder ou não (ex: sem internet),
      // apagamos o token e os dados do utilizador do telemóvel!
      // NOTA: Usa os teus métodos exatos que limpam o SharedPreferences/SecureStorage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
    }
  }

  // =========================================================================
  // 🔑 2. PEDIR CÓDIGO DE RECUPERAÇÃO (FORGOT PASSWORD)
  // =========================================================================
  Future<http.Response> forgotPassword(String email) async {
    return await post(
      '/forgot-password',
      {'email': email.trim()},
      requireAuth: false, // Não precisa de token para pedir ajuda!
    );
  }

  // =========================================================================
  // 🔓 3. REDEFINIR A PALAVRA-PASSE (RESET PASSWORD)
  // =========================================================================
  Future<http.Response> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    return await post(
      '/reset-password',
      {
        'email': email.trim(),
        'code': code.trim(),
        'password': newPassword,
        'password_confirmation': newPassword, // Laravel exige esta confirmação
      },
      requireAuth: false,
    );
  }

  Future<http.Response> updateProfile({required String name, File? imageFile}) async {
    final url = Uri.parse('$baseUrl/user/update');
    final token = await getToken(); // Recupera o token guardado no login

    var request = http.MultipartRequest('POST', url);
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    request.fields['name'] = name;

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('avatar', imageFile.path));
    }

    final streamedResponse = await request.send();


    final response = await http.Response.fromStream(streamedResponse);

    // 🕵️‍♂️ 2. LOG DE ENTRADA (O que o Laravel respondeu)
    print('🛬 RESPOSTA [${response.statusCode}]: ${response.body}');

    return response;
  }
}