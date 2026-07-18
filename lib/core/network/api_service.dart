import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
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
  // 🔐 GESTÃO DO COFRE DE SESSÃO
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

  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
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
  Future<http.Response> post(String endpoint, Map<String, dynamic> body, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);
    debugPrint('🛫 POST $url');
    debugPrint('📦 DADOS: ${jsonEncode(body)}');

    final response = await http.post(url, headers: headers, body: jsonEncode(body));

    debugPrint('🛬 RESPOSTA [${response.statusCode}]: ${response.body}');
    return response;
  }

  Future<http.Response> get(String endpoint, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);

    debugPrint('🛫 GET $url');

    final response = await http.get(url, headers: headers);

    debugPrint('🛬 RESPOSTA [${response.statusCode}]: ${response.body}');
    return response;
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);

    debugPrint('🔄 PUT $url');
    debugPrint('📦 DADOS: ${jsonEncode(body)}');

    final response = await http.put(url, headers: headers, body: jsonEncode(body));

    debugPrint('🛬 RESPOSTA [${response.statusCode}]: ${response.body}');
    return response;
  }

  Future<http.Response> delete(String endpoint, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);

    debugPrint('🗑️ DELETE $url');

    final response = await http.delete(url, headers: headers);
    return response;
  }

  // 🚀 O NOVO MÉTODO (Delete com Payload no Body - Usado no Unshare)
  Future<http.Response> deleteWithBody(String endpoint, Map<String, dynamic> body, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);
    debugPrint('🗑️ DELETE (With Body) $url');

    final request = http.Request('DELETE', url);
    request.headers.addAll(headers);
    request.body = jsonEncode(body);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    debugPrint('🛬 RESPOSTA [${response.statusCode}]: ${response.body}');
    return response;
  }

  // =========================================================================
  // 🚪 SERVIÇOS DE AUTENTICAÇÃO
  // =========================================================================
  Future<void> logout() async {
    try {
      await post('/logout', {}, requireAuth: true);
    } catch (e) {
      debugPrint('🚨 Erro a avisar o servidor do logout: $e');
    } finally {
      await deleteToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      debugPrint('🛑 Tokens locais eliminados com sucesso!');
    }
  }

  Future<http.Response> forgotPassword(String email) async {
    return await post('/forgot-password', {'email': email.trim()}, requireAuth: false);
  }

  Future<http.Response> resetPassword({required String email, required String code, required String newPassword}) async {
    return await post(
      '/reset-password',
      {'email': email.trim(), 'code': code.trim(), 'password': newPassword, 'password_confirmation': newPassword},
      requireAuth: false,
    );
  }

  Future<http.Response> updateProfile({required String name, dynamic imageFile}) async {
    final String? token = await getToken();
    final Uri url = Uri.parse('$baseUrl/user/update');
    final request = http.MultipartRequest('POST', url);

    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });

    request.fields['name'] = name;

    if (imageFile != null) {
      if (kIsWeb) {
        final XFile file = imageFile as XFile;
        final bytes = await file.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'avatar',
          bytes,
          filename: file.name,
          contentType: MediaType('image', file.name.split('.').last.toLowerCase().replaceAll('jpg', 'jpeg')),
        );
        request.files.add(multipartFile);
      } else {
        final String path = (imageFile is XFile) ? imageFile.path : imageFile.toString();
        String fileName = path.split('\\').last.split('/').last;
        String extension = fileName.split('.').last.toLowerCase();
        if (!['png', 'jpg', 'jpeg', 'gif'].contains(extension)) extension = 'jpeg';

        final multipartFile = await http.MultipartFile.fromPath(
          'avatar',
          path,
          filename: fileName,
          contentType: MediaType('image', extension),
        );
        request.files.add(multipartFile);
      }
    }

    debugPrint('📢 [API] 5. A disparar para o servidor Laravel...');
    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }
}