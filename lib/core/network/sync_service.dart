import 'dart:convert';
import 'package:flutter/foundation.dart'; // 🚀 IMPORTANTE: O Escudo que deteta o Chrome (kIsWeb)
import 'package:sqflite/sqflite.dart';
import '../../features/notebooks/models/local_page_model.dart';
import '../database/database_helper.dart';
import '../services/local_database_service.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ApiService _apiService = ApiService();

  // =========================================================================
  // 🚀 A ANTENA GLOBAL: Rádio para avisar qualquer ecrã que o ID da Nuvem chegou!
  // Emite um Map onde a Chave é o [client_id] e o Valor é o [server_id].
  // =========================================================================
  static final ValueNotifier<Map<int, int>> syncedPagesRadio = ValueNotifier({});

  // 🚀 INICIAR OPERAÇÃO PUSH
  Future<void> pushOfflineData() async {
    // 🌐 ESCUDO WEB: No Chrome não existe SQLite local. Os dados já nascem na nuvem!
    if (kIsWeb) {
      print('🌐 [Web] Operação PUSH ignorada: O Chrome opera 100% online.');
      return;
    }

    final db = await _dbHelper.database;

    try {
      // 1. RECOLHA DE TROPAS: Procurar disciplinas que ainda não foram para a nuvem
      final List<Map<String, dynamic>> unsyncedSubjects = await db.query(
        'subjects',
        where: 'synced_with_cloud = ?',
        whereArgs: [0],
      );

      if (unsyncedSubjects.isEmpty) {
        print('✅ Tudo sincronizado. Nada a enviar.');
        return;
      }

      // 2. DISPARO PARA A NUVEM: Formatar em JSON e enviar para o Laravel
      final payload = {
        'subjects': unsyncedSubjects,
      };

      final response = await _apiService.post('/sync/push', payload);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> syncedSubjectsData = responseData['synced_subjects'];

        // 3. ATUALIZAÇÃO LOCAL: Dizer ao SQLite os IDs oficiais e marcar como sincronizado
        for (var item in syncedSubjectsData) {
          final int clientId = item['client_id'];
          final int serverId = item['server_id'];

          await db.update(
            'subjects',
            {
              'server_id': serverId,
              'synced_with_cloud': 1, // 🚀 Missão Cumprida!
            },
            where: 'id = ?',
            whereArgs: [clientId],
          );
        }

        print('☁️ Sincronização PUSH concluída com sucesso!');
      } else {
        print('🚨 Servidor recusou a sincronização: ${response.statusCode}');
      }
    } catch (e) {
      print('🚨 Erro crítico na Sincronização PUSH: $e');
    }
  }

  // 📥 INICIAR OPERAÇÃO PULL (Rastreio Inteligente por Timestamp)
  Future<bool> pullSubjects() async {
    if (kIsWeb) return false;

    final db = await _dbHelper.database;
    final prefs = await SharedPreferences.getInstance();

    // 🚀 LER O ÚLTIMO CARIMBO: Vai buscar a data do último rastreio guardada no disco
    final String? lastSynced = prefs.getString('last_subjects_sync');

    try {
      // Constrói o link. Se houver carimbo, anexa-o à rota: ex: /sync/pull?last_synced_at=2026-07-01...
      final String endpoint = lastSynced != null
          ? '/sync/pull?last_synced_at=$lastSynced'
          : '/sync/pull';

      final response = await _apiService.get(endpoint);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> serverSubjects = responseData['subjects'];
        final String? serverTime = responseData['server_time'];

        if (serverSubjects.isEmpty) {
          print('📡 [Rastreio] Nenhuma novidade detetada na nuvem.');
          // Mesmo sem dados novos, atualiza o tempo com o do servidor para precisão
          if (serverTime != null) await prefs.setString('last_subjects_sync', serverTime);
          return false; // Não houve alterações
        }

        print('📡 [Rastreio] Detetadas ${serverSubjects.length} novidades na nuvem! A processar...');

        for (var serverSub in serverSubjects) {
          final existing = await db.query(
            'subjects',
            where: 'server_id = ?',
            whereArgs: [serverSub['id']],
          );

          if (existing.isEmpty) {
            await db.insert('subjects', {
              'server_id': serverSub['id'],
              'user_id': serverSub['user_id'],
              'name': serverSub['name'],
              'color': serverSub['color'],
              'icon': serverSub['icon'],
              'synced_with_cloud': 1,
            });
          } else {
            await db.update('subjects', {
              'name': serverSub['name'],
              'color': serverSub['color'],
              'icon': serverSub['icon'],
              'synced_with_cloud': 1,
            }, where: 'server_id = ?', whereArgs: [serverSub['id']]);
          }
        }

        // 🚀 GRAVAR NOVO CARIMBO: Guarda a hora do servidor para o próximo ciclo automático
        if (serverTime != null) {
          await prefs.setString('last_subjects_sync', serverTime);
        }

        return true; // Dados novos injetados com sucesso!
      }
    } catch (e) {
      print('🚨 Erro no rastreio automático PULL: $e');
    }
    return false;
  }

  // =========================================================================
  // 📤 FASE 2: ENVIAR CADERNOS PENDENTES (PUSH BLINDADO COM TRADUTOR)
  // =========================================================================
  Future<void> pushNotebooks() async {
    if (kIsWeb) return;
    final db = await _dbHelper.database;

    try {
      // 1. Procura cadernos não sincronizados no SQLite
      final List<Map<String, dynamic>> unsynced = await db.query(
        'notebooks',
        where: 'synced_with_cloud = ?',
        whereArgs: [0],
      );

      if (unsynced.isEmpty) {
        debugPrint('✅ [Sync] Todos os cadernos já estão na nuvem.');
        return;
      }

      debugPrint('📡 [Sync] A processar ${unsynced.length} cadernos para envio...');

      final List<Map<String, dynamic>> payloadNotebooks = [];

      for (var notebookRow in unsynced) {
        final int localNotebookId = notebookRow['id'];
        final int localSubjectId = notebookRow['subject_id'];

        // =====================================================================
        // 🚀 O TRADUTOR TÁTICO DE IDs (Local -> Nuvem)
        // =====================================================================
        // Consulta o SQLite para descobrir qual é o ID oficial desta Disciplina no Laravel
        final subjectQuery = await db.query(
          'subjects',
          columns: ['server_id'],
          where: 'id = ?',
          whereArgs: [localSubjectId],
        );

        // Se a disciplina ainda não tiver subido para a nuvem, o caderno não pode ir!
        if (subjectQuery.isEmpty || subjectQuery.first['server_id'] == null) {
          debugPrint('⚠️ [Sync] A disciplina local $localSubjectId ainda não subiu para a nuvem. Caderno $localNotebookId adiado.');
          continue;
        }

        // Capturamos o ID verdadeiro gerado pelo servidor da nuvem!
        final int officialServerSubjectId = subjectQuery.first['server_id'] as int;

        // Criamos uma cópia mutável do mapa para podermos alterar os dados
        final Map<String, dynamic> notebookMap = Map<String, dynamic>.from(notebookRow);

        // 🎯 O TIRO DE PRECISÃO: Substituímos o ID do Windows pelo ID da Nuvem!
        notebookMap['subject_id'] = officialServerSubjectId;

        payloadNotebooks.add(notebookMap);
      }

      // Se todos os cadernos foram adiados à espera das disciplinas, abortamos
      if (payloadNotebooks.isEmpty) {
        debugPrint('⏳ [Sync] Nenhum caderno pronto para envio (a aguardar sincronização das disciplinas).');
        return;
      }

      debugPrint('📦 [Sync] A disparar ${payloadNotebooks.length} cadernos traduzidos para o Laravel...');

      // 2. Dispara o pacote para a rota da nuvem
      final response = await _apiService.post('/sync/notebooks/push', {
        'notebooks': payloadNotebooks,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> syncedList = data['synced_notebooks'] ?? [];

        // 3. Atualiza o SQLite com os IDs oficiais do servidor
        for (var item in syncedList) {
          await db.update(
            'notebooks',
            {
              'server_id': item['server_id'],
              'synced_with_cloud': 1, // 🚀 Missão Cumprida!
            },
            where: 'id = ?',
            whereArgs: [item['client_id']],
          );
        }
        debugPrint('☁️ [Sync] Cadernos sincronizados com sucesso!');
      } else {
        debugPrint('🚨 [Sync] Falha no servidor ao processar cadernos: ${response.statusCode} | ${response.body}');
      }
    } catch (e) {
      debugPrint('🚨 [Sync] Erro crítico no PUSH dos cadernos: $e');
    }
  }

  // =========================================================================
  // 📥 FASE 2.1: RECEBER CADERNOS DA NUVEM (PULL COM TRADUTOR INVERSO)
  // =========================================================================
  Future<bool> pullNotebooks() async {
    if (kIsWeb) return false; // Chrome opera online-only, ignora o SQLite

    final db = await _dbHelper.database;
    final prefs = await SharedPreferences.getInstance();

    // ⏰ RELÓGIO DE DELTA SYNC: Pega na data da última sincronização de cadernos
    final String? lastSynced = prefs.getString('last_notebooks_sync');

    try {
      // Constrói o link dinâmico: se já sincronizou antes, pede só as novidades
      final String endpoint = lastSynced != null
          ? '/sync/notebooks/pull?last_synced_at=$lastSynced'
          : '/sync/notebooks/pull';

      debugPrint('📡 [Sync Pull] A varrer nuvem em busca de cadernos ($endpoint)...');

      final response = await _apiService.get(endpoint);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> serverNotebooks = responseData['notebooks'] ?? [];
        final String? serverTime = responseData['server_time'];

        if (serverNotebooks.isEmpty) {
          debugPrint('📡 [Sync Pull] Nenhum caderno novo detetado na nuvem.');
          // Atualiza o timestamp mesmo vazio para manter o relógio alinhado
          if (serverTime != null) await prefs.setString('last_notebooks_sync', serverTime);
          return false; // UI não precisa de atualizar
        }

        debugPrint('📥 [Sync Pull] Detetados ${serverNotebooks.length} cadernos novos na nuvem! A processar...');

        for (var sNet in serverNotebooks) {
          // ===================================================================
          // 🧲 O TRADUTOR INVERSO (Nuvem -> Local)
          // ===================================================================
          // O Laravel envia o ID da disciplina dele (server_id).
          // Temos de descobrir qual é o ID incremental do nosso SQLite local!
          final subjectQuery = await db.query(
            'subjects',
            columns: ['id'],
            where: 'server_id = ?',
            whereArgs: [sNet['subject_id']],
          );

          // Proteção relacional: Se a disciplina mãe ainda não existe no telemóvel,
          // ignoramos o caderno até que a disciplina seja descarregada.
          if (subjectQuery.isEmpty) {
            debugPrint('⚠️ [Sync Pull] A disciplina mãe (Server ID: ${sNet['subject_id']}) ainda não existe localmente. Caderno "${sNet['title']}" adiado.');
            continue;
          }

          final int localSubjectId = subjectQuery.first['id'] as int;

          // Verifica se este caderno já foi guardado localmente (pelo server_id oficial)
          final existing = await db.query(
            'notebooks',
            where: 'server_id = ?',
            whereArgs: [sNet['id']],
          );

          // Prepara o pacote de dados estritamente alinhado com o teu CREATE TABLE notebooks!
          final Map<String, dynamic> notebookData = {
            'server_id': sNet['id'],
            'subject_id': localSubjectId, // 🎯 O ID LOCAL TRADUZIDO (Obrigatório!)
            'title': sNet['title'],
            'cover_type': sNet['cover_type'] ?? 'color',
            'color': sNet['color'],
            'cover_image': sNet['cover_image'],
            'line_type': sNet['line_type'] ?? 'ruled',
            'paper_size': sNet['paper_size'] ?? 'A4',
            'synced_with_cloud': 1, // 🚀 Carimbado: já veio da nuvem!
            // Converte a data do servidor para milissegundos (INTEGER), compatível com a tua coluna updated_at!
            'updated_at': sNet['updated_at'] != null
                ? DateTime.parse(sNet['updated_at'].toString()).millisecondsSinceEpoch
                : DateTime.now().millisecondsSinceEpoch,
          };

          if (existing.isEmpty) {
            // Se o caderno não existia, INSERE COM BLINDAGEM DE CONFLITO
            await db.insert(
              'notebooks',
              notebookData,
              conflictAlgorithm: ConflictAlgorithm.replace, // Evita crashes de UNIQUE constraint
            );
            debugPrint('✅ Caderno "${sNet['title']}" gravado no SQLite local.');
          } else {
            // Se já existia, ATUALIZA APENAS O ALVO CERTO
            await db.update(
              'notebooks',
              notebookData,
              where: 'server_id = ?',
              whereArgs: [sNet['id']],
            );
            debugPrint('🔄 Caderno "${sNet['title']}" atualizado no SQLite local.');
          }
        }

        // 🚀 GRAVA O NOVO CARIMBO DE TEMPO DO SERVIDOR
        if (serverTime != null) {
          await prefs.setString('last_notebooks_sync', serverTime);
        }

        return true; // Alerta o sistema que houve dados novos injetados!
      } else {
        debugPrint('🚨 [Sync Pull] O Laravel recusou o envio de cadernos: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🚨 [Sync Pull] Erro crítico ao processar o pull de cadernos: $e');
    }
    return false;
  }

  // =========================================================================
  // 📤 FASE 3: ENVIAR FOLHAS COM DESENHOS E FOTOS BASE64 (PUSH BLINDADO)
  // =========================================================================
  Future<void> pushPages() async {
    if (kIsWeb) return;
    final db = await _dbHelper.database;

    try {
      // 1. Procura as folhas não sincronizadas no SQLite
      final List<Map<String, dynamic>> unsyncedPages = await db.query(
        'pages',
        where: 'synced_with_cloud = ?',
        whereArgs: [0],
      );

      if (unsyncedPages.isEmpty) {
        debugPrint('✅ [Sync] Todas as folhas já estão na nuvem.');
        return;
      }

      debugPrint('📡 [Sync] A processar ${unsyncedPages.length} folhas para envio...');

      final localDb = LocalDatabaseService();
      final List<Map<String, dynamic>> payloadPages = [];

      for (var pageRow in unsyncedPages) {
        final int pageId = pageRow['id'];
        final int localNotebookId = pageRow['notebook_id'];

        // 🚀 1. CAPTURA EXPLÍCITA DO ID DA NUVEM DIRETAMENTE DO SQLITE!
        final int? officialServerPageId = pageRow['server_id'];

        final notebookQuery = await db.query(
          'notebooks',
          columns: ['server_id'],
          where: 'id = ?',
          whereArgs: [localNotebookId],
        );

        if (notebookQuery.isEmpty || notebookQuery.first['server_id'] == null) {
          debugPrint('⚠️ [Sync] O caderno local $localNotebookId ainda não subiu para a nuvem. Folha $pageId adiada.');
          continue;
        }

        final int officialServerNotebookId = notebookQuery.first['server_id'] as int;

        final allPages = await localDb.getFullPagesForNotebook(localNotebookId);
        final fullPage = allPages.firstWhere((p) => p.id == pageId, orElse: () => LocalPage.fromDatabaseMap(pageRow));

        final Map<String, dynamic> pageMap = fullPage.toMap();

        pageMap['notebook_id'] = officialServerNotebookId;
        pageMap['client_id'] = pageId;

        // 🎯 2. O TIRO DE PRECISÃO: Injetamos o ID do Servidor à força no pacote!
        pageMap['server_id'] = officialServerPageId;

        payloadPages.add(pageMap);
      }
      // Se todas as folhas foram adiadas à espera dos cadernos, abortamos aqui
      if (payloadPages.isEmpty) {
        debugPrint('⏳ [Sync] Nenhuma folha pronta para envio (a aguardar sincronização dos cadernos pais).');
        return;
      }

      debugPrint('📦 [Sync] A disparar ${payloadPages.length} folhas empacotadas para o Laravel...');

      // 2. Dispara o pacote para a nuvem
      final response = await _apiService.post('/sync/pages/push', {
        'pages': payloadPages,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> syncedList = data['synced_pages'] ?? [];

        // 🚀 Dicionário para guardar as atualizações e enviar pelo rádio
        Map<int, int> newIdsMap = {};

        // 🚀 A CORREÇÃO DO LOOP: Atualiza o SQLite com o ID Oficial E QUEBRA O LOOP!
        for (var item in syncedList) {
          // O item['client_id'] é o ID do SQLite local. Tem de vir perfeito do Laravel!
          if (item['client_id'] != null && item['server_id'] != null) {
            final int cId = item['client_id'];
            final int sId = item['server_id'];

            await db.update(
              'pages',
              {
                'server_id': sId, // O ID que o Laravel gerou (ex: 14)
                'page_number': item['page_number'], // O número final da folha
                'synced_with_cloud': 1, // 🛑 ISTO PARA O LOOP! O Radar não a apanha mais!
                'updated_at': DateTime.now().millisecondsSinceEpoch,
              },
              where: 'id = ?',
              whereArgs: [cId],
            );
            newIdsMap[cId] = sId;
          }
        }

        // 🚀 DISPARA O SINAL DE RÁDIO PARA O CANVAS (Se houver páginas atualizadas)
        if (newIdsMap.isNotEmpty) {
          syncedPagesRadio.value = Map.from(newIdsMap); // Força a notificação instantânea!
        }
        debugPrint('☁️ [Sync] ${syncedList.length} folhas atualizadas localmente. Loop travado!');
      } else {
        debugPrint('🚨 [Sync] Falha no servidor ao desempacotar folhas: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🚨 [Sync] Erro crítico no PUSH das folhas: $e');
    }
  }

  // =========================================================================
  // 📥 FASE 3.1: RECEBER FOLHAS E DESEMPACAOTAR DESENHOS (PULL BLINDADO)
  // =========================================================================
  Future<bool> pullPages() async {
    if (kIsWeb) return false;
    final db = await _dbHelper.database;
    final prefs = await SharedPreferences.getInstance();

    // ⏰ RELÓGIO DE DELTA SYNC: Pega na data da última sincronização de folhas
    final String? lastSynced = prefs.getString('last_pages_sync');

    try {
      final String endpoint = lastSynced != null
          ? '/sync/pages/pull?last_synced_at=$lastSynced'
          : '/sync/pages/pull';

      debugPrint('📡 [Sync Pull] A requisitar folhas à nuvem ($endpoint)...');
      final response = await _apiService.get(endpoint);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> serverPages = responseData['pages'] ?? [];
        final String? serverTime = responseData['server_time'];

        if (serverPages.isEmpty) {
          debugPrint('📡 [Sync Pull] Nenhuma folha nova detetada na nuvem.');
          if (serverTime != null) await prefs.setString('last_pages_sync', serverTime);
          return false;
        }

        debugPrint('📥 [Sync Pull] Detetadas ${serverPages.length} folhas na nuvem! A desempacotar...');

        for (var sPage in serverPages) {
          // ===================================================================
          // 🧲 1. TRADUTOR INVERSO DE CADERNOS (Nuvem -> Local)
          // ===================================================================
          final notebookQuery = await db.query(
            'notebooks',
            columns: ['id'],
            where: 'server_id = ?',
            whereArgs: [sPage['notebook_id']],
          );

          // Se o caderno mãe ainda não existe no dispositivo, adiamos a folha
          if (notebookQuery.isEmpty) {
            debugPrint('⚠️ [Sync Pull] Caderno mãe (Server ID: ${sPage['notebook_id']}) não encontrado localmente. Folha ${sPage['page_number']} adiada.');
            continue;
          }

          final int localNotebookId = notebookQuery.first['id'] as int;

          // Verifica se esta folha já existe localmente (pelo server_id ou par caderno+número)
          final existingPage = await db.query(
            'pages',
            columns: ['id'],
            where: 'server_id = ? OR (notebook_id = ? AND page_number = ?)',
            whereArgs: [sPage['id'], localNotebookId, sPage['page_number']],
          );

          int localPageId;
          final Map<String, dynamic> pageData = {
            'server_id': sPage['id'],
            'notebook_id': localNotebookId, // 🎯 ID LOCAL DO CADERNO TRADUZIDO!
            'page_number': sPage['page_number'],
            'is_landscape': (sPage['is_landscape'] == true || sPage['is_landscape'] == 1) ? 1 : 0,
            'header_data': sPage['header_data'],
            'footer_data': sPage['footer_data'],
            'synced_with_cloud': 1,
            'updated_at': sPage['updated_at'] != null
                ? DateTime.parse(sPage['updated_at'].toString()).millisecondsSinceEpoch
                : DateTime.now().millisecondsSinceEpoch,
          };

          // ===================================================================
          // 💾 2. GRAVAÇÃO DA FOLHA NO SQLITE
          // ===================================================================
          if (existingPage.isEmpty) {
            localPageId = await db.insert('pages', pageData, conflictAlgorithm: ConflictAlgorithm.replace);
            debugPrint('✅ Folha ${sPage['page_number']} gravada como nova (Local ID: $localPageId).');
          } else {
            localPageId = existingPage.first['id'] as int;
            await db.update('pages', pageData, where: 'id = ?', whereArgs: [localPageId]);
            debugPrint('🔄 Folha ${sPage['page_number']} atualizada (Local ID: $localPageId).');
          }

          // ===================================================================
          // 🎨 3. DESEMPACOTAMENTO DO CANVAS (Traços, Textos e Fotos)
          // ===================================================================
          // Para evitar duplicações quando re-sincronizamos, limpamos os traços antigos desta folha
          await db.delete('canvas_strokes', where: 'page_id = ?', whereArgs: [localPageId]);
          await db.delete('canvas_text_blocks', where: 'page_id = ?', whereArgs: [localPageId]);
          await db.delete('canvas_image_blocks', where: 'page_id = ?', whereArgs: [localPageId]);

          // 3.1 Injetar Traços Vetoriais (Strokes)
          final List<dynamic> strokes = sPage['stroke_data'] ?? [];
          for (var st in strokes) {
            await db.insert('canvas_strokes', {
              'client_stroke_id': st['id']?.toString() ?? uniqid(),
              'page_id': localPageId,
              'stroke_data': jsonEncode(st), // Guarda o JSON do traço (cor, espessura, pontos)
              'is_deleted': 0,
              'synced_with_cloud': 1,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }

          // 3.2 Injetar Blocos de Texto
          final List<dynamic> texts = sPage['text_data'] ?? [];
          for (var tx in texts) {
            await db.insert('canvas_text_blocks', {
              'client_text_id': tx['id']?.toString() ?? uniqid(),
              'page_id': localPageId,
              'text_data': jsonEncode(tx),
              'is_deleted': 0,
              'synced_with_cloud': 1,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }

          // 3.3 Injetar Blocos de Imagem (O URL público da nuvem fica no image_path!)
          final List<dynamic> images = sPage['image_data'] ?? [];
          for (var img in images) {
            await db.insert('canvas_image_blocks', {
              'client_image_id': img['id']?.toString() ?? uniqid(),
              'page_id': localPageId,
              'image_path': img['image_path'] ?? '',
              'pos_x': (img['dx'] as num?)?.toDouble() ?? 0.0,
              'pos_y': (img['dy'] as num?)?.toDouble() ?? 0.0,
              // 🚀 CORREÇÃO DO RAIO ENCOLHEDOR: Lemos 'width' e 'height' vindos do JSON!
              'scale': (img['width'] as num?)?.toDouble() ?? 300.0,    // Guarda a largura
              'rotation': (img['height'] as num?)?.toDouble() ?? 200.0, // Guarda a altura
              'is_deleted': 0,
              'synced_with_cloud': 1,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }

        if (serverTime != null) {
          await prefs.setString('last_pages_sync', serverTime);
        }
        return true;
      }
    } catch (e) {
      debugPrint('🚨 [Sync Pull] Erro crítico ao desempacotar páginas: $e');
    }
    return false;
  }

  // Helper rápido para gerar um ID temporário caso algum elemento venha sem ID da nuvem
  String uniqid() => DateTime.now().microsecondsSinceEpoch.toString();

  // =========================================================================
  // 🚀 COMANDO SUPREMO: SINCRONIZAÇÃO TOTAL (Ordem Relacional Blindada)
  // =========================================================================
  Future<void> syncAll() async {
    if (kIsWeb) return;

    debugPrint('🏁 [Sync General] A iniciar ofensiva de sincronização total...');

    // 1º ESCALÃO: Disciplinas (Push e depois Pull)
    await pushOfflineData();
    await pullSubjects();

    // 2º ESCALÃO: Cadernos (Envia os locais e depois puxa os da Nuvem!)
    await pushNotebooks();
    final bool novosCadernosChegaram = await pullNotebooks(); // 🚀 AGORA OPERACIONAL!

    // 3º ESCALÃO: Folhas, Desenhos e Imagens Base64
    await pushPages();
    final bool novasFolhasChegaram = await pullPages(); // 🚀 AGORA OPERACIONAL!

    debugPrint('🏆 [Sync General] Ciclo de Sincronização Concluído!');
  }

}