import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:caderno_digital_app/core/network/api_config.dart';
import 'package:caderno_digital_app/core/network/time_service.dart'; // 🚀 Novo
import 'package:caderno_digital_app/core/config/app_config.dart';
import 'package:caderno_digital_app/core/network/gzip_stub.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final TimeService _timeService = TimeService(); // 🚀

  static const Duration defaultTimeout = Duration(seconds: 10);

  static String get baseUrl {
    return ApiConfig.baseUrl;
  }

  static String get baseUrlImagem {
    return ApiConfig.storageUrl;
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
      'Accept-Encoding': 'gzip', // 🚀 Indica ao servidor que a app aceita JSON comprimido
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
  String _truncateLog(String text, {int maxLength = 500}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}... [TRUNCADO, total: ${text.length} chars]';
  }

  void _processTimeMetadata(http.Response response) {
     try {
       final Map<String, dynamic> data = jsonDecode(response.body);
       if (data.containsKey('meta') && data['meta'].containsKey('server_time')) {
          _timeService.updateOffset(serverTimeIso: data['meta']['server_time']);
       } else if (data.containsKey('server_time_ms')) {
          _timeService.updateOffset(serverTimeMs: data['server_time_ms']);
       }
     } catch (_) {}
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body, {bool requireAuth = true, bool compress = false}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);

    // 🚀 OTIMIZAÇÃO: Encode pesado em Isolate para payloads grandes
    final String bodyStr = await compute<Map<String, dynamic>, String>(
      (map) => jsonEncode(map),
      body,
    );

    AppLog.api('🛫 POST $url | Body: ${_truncateLog(bodyStr)}');

    dynamic requestBody = bodyStr;

    if (compress && !kIsWeb) {
      final List<int>? compressedBytes = await compute<String, List<int>?>(
        (str) => compressGzipBytes(str),
        bodyStr,
      );
      if (compressedBytes != null) {
        headers['Content-Encoding'] = 'gzip';
        requestBody = compressedBytes;
        AppLog.api('🗜️ [GZIP] Payload comprimido. Original: ${utf8.encode(bodyStr).length} bytes, Comprimido: ${compressedBytes.length} bytes.');
      }
    }

    final response = await http
        .post(url, headers: headers, body: requestBody)
        .timeout(defaultTimeout);

    _processTimeMetadata(response); // 🕒 Calibrar relógio
    AppLog.api('🛬 RESPOSTA [${response.statusCode}]: ${_truncateLog(response.body)}');
    return response;
  }

  Future<http.Response> get(String endpoint, {bool requireAuth = true}) async {
    final bool isAbsolute = endpoint.startsWith('http://') || endpoint.startsWith('https://');
    final url = isAbsolute ? Uri.parse(endpoint) : Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);

    AppLog.api('🛫 GET $url');

    final response = await http
        .get(url, headers: headers)
        .timeout(defaultTimeout);

    _processTimeMetadata(response); // 🕒 Calibrar relógio
    AppLog.api('🛬 RESPOSTA [${response.statusCode}]: ${_truncateLog(response.body)}');
    return response;
  }

  /// Método utilitário para buscar uma URL completa (útil para paginação)
  Future<http.Response> fetchUrl(String url, {bool requireAuth = true}) async {
    return get(url, requireAuth: requireAuth);
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);
    
    final String bodyStr = await compute<Map<String, dynamic>, String>(
      (map) => jsonEncode(map),
      body,
    );

    AppLog.api('🔄 PUT $url | Body: ${_truncateLog(bodyStr)}');

    final response = await http
        .put(url, headers: headers, body: bodyStr)
        .timeout(defaultTimeout);

    _processTimeMetadata(response);
    AppLog.api('🛬 RESPOSTA [${response.statusCode}]: ${_truncateLog(response.body)}');
    return response;
  }

  Future<http.Response> delete(String endpoint, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);

    AppLog.api('🗑️ DELETE $url');

    final response = await http
        .delete(url, headers: headers)
        .timeout(defaultTimeout);

    _processTimeMetadata(response);
    AppLog.api('🛬 RESPOSTA [${response.statusCode}]: ${_truncateLog(response.body)}');
    return response;
  }

  // 🚀 O NOVO MÉTODO (Delete com Payload no Body - Usado no Unshare)
  Future<http.Response> deleteWithBody(String endpoint, Map<String, dynamic> body, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);

    final String bodyStr = await compute<Map<String, dynamic>, String>(
      (map) => jsonEncode(map),
      body,
    );

    AppLog.api('🗑️ DELETE (With Body) $url | Body: ${_truncateLog(bodyStr)}');

    final request = http.Request('DELETE', url);
    request.headers.addAll(headers);
    request.body = bodyStr;

    final streamedResponse = await request.send().timeout(defaultTimeout);
    final response = await http.Response.fromStream(streamedResponse);
    
    _processTimeMetadata(response);
    AppLog.api('🛬 RESPOSTA [${response.statusCode}]: ${_truncateLog(response.body)}');
    return response;
  }

  // =========================================================================
  // 🚪 SERVIÇOS DE AUTENTICAÇÃO
  // =========================================================================
  Future<void> logout() async {
    try {
      await post('/logout', {}, requireAuth: true);
    } catch (e) {
      AppLog.error('API', 'Erro a avisar o servidor do logout', e);
    } finally {
      await deleteToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      AppLog.api('🛑 Tokens locais eliminados com sucesso!');
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

  Future<http.Response> updateProfile({
    required String name,
    dynamic imageFile,
    String? bio,
    String? institution,
    String? preferredColor,
    String? specialties,
  }) async {
    final String? token = await getToken();
    final Uri url = Uri.parse('$baseUrl/user/update');
    final request = http.MultipartRequest('POST', url);

    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });

    request.fields['name'] = name;
    if (bio != null) request.fields['bio'] = bio;
    if (institution != null) request.fields['institution'] = institution;
    if (preferredColor != null) request.fields['preferred_color'] = preferredColor;
    if (specialties != null) request.fields['specialties'] = specialties;

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

    AppLog.api('📢 A enviar dados atualizado do usuario para o servidor');
    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }
}