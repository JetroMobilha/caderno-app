import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🚀 O NOVO COFRE UNIVERSAL

class ApiService {
  // Singleton Pattern: Garante que só existe 1 antena de internet na app toda
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static String get baseUrl {
    return 'http://35.205.132.251:8080/api';
  }

  static String get baseUrlImagem {
    return 'http://35.205.132.251:8080/storage/';
  }

  // =========================================================================
  // 🔐 GESTÃO DO COFRE DE SESSÃO (100% Compatível com Web, Android e Windows)
  // =========================================================================
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sanctum_token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sanctum_token');
  }

  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sanctum_token');
  }

  Future<void> saveUserData(Map<String, dynamic> userMap) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(userMap));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('user_data');
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

    debugPrint('🛫 POST $url');
    debugPrint('📦 DADOS: ${jsonEncode(body)}');

    final response = await http.post(url, headers: headers, body: jsonEncode(body));

    debugPrint('🛬 RESPOSTA [${response.statusCode}]: ${response.body}');
    return response;
  }

  // GET (Para Listar Disciplinas e Páginas)
  Future<http.Response> get(String endpoint, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);

    debugPrint('🛫 GET $url');

    final response = await http.get(url, headers: headers);

    debugPrint('🛬 RESPOSTA [${response.statusCode}]: ${response.body}');
    return response;
  }

  // =========================================================================
  // 🔄 ATUALIZAR DADOS (PUT)
  // =========================================================================
  Future<http.Response> put(String endpoint, Map<String, dynamic> body, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);

    debugPrint('🔄 PUT $url');
    debugPrint('📦 DADOS: ${jsonEncode(body)}');

    final response = await http.put(url, headers: headers, body: jsonEncode(body));

    debugPrint('🛬 RESPOSTA [${response.statusCode}]: ${response.body}');
    return response;
  }

  // =========================================================================
  // 🗑️ APAGAR DADOS (DELETE)
  // =========================================================================
  Future<http.Response> delete(String endpoint, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);

    debugPrint('🗑️ DELETE $url');

    final response = await http.delete(url, headers: headers);

    debugPrint('🛬 RESPOSTA [${response.statusCode}]: ${response.body}');
    return response;
  }

  // =========================================================================
  // 🚪 1. TERMINAR SESSÃO (LOGOUT)
  // =========================================================================
  Future<void> logout() async {
    try {
      // 1. Avisa o Laravel para destruir o token no servidor (Requer Auth)
      await post('/logout', {}, requireAuth: true);
    } catch (e) {
      debugPrint('🚨 Erro a avisar o servidor do logout: $e');
    } finally {
      // 2. Apaga as credenciais locais com Segurança Absoluta (Universal)
      await deleteToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      debugPrint('🛑 Tokens locais eliminados com sucesso!');
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
        'password_confirmation': newPassword,
      },
      requireAuth: false,
    );
  }

  // =========================================================================
  // 👤 4. ATUALIZAR PERFIL E AVATAR (MULTIPART / HÍBRIDO)
  // =========================================================================
  Future<http.Response> updateProfile({required String name, dynamic imageFile}) async {
    final String? token = await getToken();
    final Uri url = Uri.parse('$baseUrl/user/update');

    debugPrint('📢 [API] 1. A iniciar preparação do pedido Multipart...');
    final request = http.MultipartRequest('POST', url);

    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });

    request.fields['name'] = name;
    debugPrint('📢 [API] 2. Campo Nome anexado: $name');

    if (imageFile != null) {
      try {
        debugPrint('📢 [API] 3. Foto detetada! A processar ficheiro no Windows...');
        final String path = (imageFile is XFile) ? imageFile.path : imageFile.toString();
        debugPrint('📢 [API]    ↳ Caminho do ficheiro: $path');

        String fileName = path.split('\\').last.split('/').last; // Limpa barras de Windows e Unix
        String extension = fileName.split('.').last.toLowerCase();
        if (extension != 'png' && extension != 'jpg' && extension != 'jpeg' && extension != 'gif') {
          extension = 'jpeg';
        }
        debugPrint('📢 [API]    ↳ Nome: $fileName | Extensão forçada: $extension');

        final multipartFile = await http.MultipartFile.fromPath(
          'avatar',
          path,
          filename: fileName,
          // Se o editor reclamar de MediaType, comenta a linha abaixo por agora:
          contentType: MediaType('image', extension),
        );

        request.files.add(multipartFile);
        debugPrint('📢 [API] 4. Ficheiro anexado com sucesso ao pedido!');
      } catch (e, stack) {
        debugPrint('🚨 [API ERRO FATAL AO LER FICHEIRO]: $e');
        debugPrint(stack.toString());
        rethrow; // Força o erro a subir para ser visto!
      }
    }

    debugPrint('📢 [API] 5. A disparar para o servidor Laravel...');
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('📢 [API] 6. Resposta recebida! Status: ${response.statusCode}');
    debugPrint('📢 [API]    ↳ Corpo da resposta: ${response.body}');

    return response;
  }
}