import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_service.dart';
import '../models/local_page_model.dart'; // Aponta para o ficheiro onde guardaste o LocalPage acima!

class PageRepository {
  // 🚀 RECRUTA A ANTENA CENTRAL BLINDADA (Singleton)
  final ApiService _apiService = ApiService();

  /// 📤 PUSH: Envia e salva uma folha (e os seus traços) no Quartel-General Laravel
  Future<bool> savePageToServer(LocalPage page) async {
    try {
      debugPrint('📡 [PageRepo] A disparar folha ${page.pageNumber} para a nuvem...');

      // O ApiService já gere a Base URL, os Headers e o Token Sanctum automaticamente!
      final response = await _apiService.post('/pages', page.toMap());

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        // Se o Laravel devolver o ID oficial recém-criado, atualizamos a memória
        if (responseData['id'] != null) {
          page.serverId = int.tryParse(responseData['id'].toString());
        }
        page.syncedWithCloud = 1;

        debugPrint('✅ [PageRepo] Folha ${page.pageNumber} sincronizada com sucesso!');
        return true;
      } else {
        debugPrint('🚨 [PageRepo] O servidor recusou a folha: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      // Falha silenciosa de rede para manter a filosofia Offline-First intacta
      debugPrint('📴 [PageRepo] Modo Offline: Não foi possível alcançar a nuvem. $e');
      return false;
    }
  }

  /// 📥 PULL: Procura e descarrega as folhas de um caderno guardadas no Laravel
  Future<List<LocalPage>> fetchPagesFromServer(int notebookId) async {
    try {
      debugPrint('📡 [PageRepo] A requisitar folhas do caderno $notebookId ao servidor...');

      final response = await _apiService.get('/notebooks/$notebookId/pages');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<LocalPage> pages = data.map((json) => LocalPage.fromMap(json)).toList();

        debugPrint('📥 [PageRepo] Recebidas ${pages.length} folhas da nuvem!');
        return pages;
      }
      return [];
    } catch (e) {
      debugPrint('🚨 [PageRepo] Erro ao descarregar folhas: $e');
      return [];
    }
  }
}