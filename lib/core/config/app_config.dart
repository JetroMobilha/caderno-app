import 'package:flutter/foundation.dart';

class AppConfig { 
  static bool enableAllLogs = true; // "Master switch" - Se false, cala tudo.

  static bool showSyncLogs = false; // Pushes/Pulls de dados JSON, Deltas, LWW
  static bool showMediaLogs = true; // Upload/Download de Imagens, PDFs, OCR e Áudios
  static bool showDbLogs = false; // Queries SQLite (CanvasRepository), Drift, IO
  static bool showCollabLogs = false; // WebSockets, Reverb, Presença, WebRTC
  static bool showCanvasLogs = false; // Renderização, Undo/Redo, Estados Locais
  static bool showApiLogs = true; // Requisições HTTP na ApiService
  static bool showTime = false;
}

class AppLog {
  static void sync(String msg) {
    if ( AppConfig.enableAllLogs && AppConfig.showSyncLogs) {
      debugPrint('🔄 [SYNC] $msg');
    }
  }

  static void media(String msg) {
    if ( AppConfig.enableAllLogs && AppConfig.showMediaLogs) {
      debugPrint('🖼️ [MEDIA] $msg');
    }
  }

  static void db(String msg) {
    if ( AppConfig.enableAllLogs && AppConfig.showDbLogs) {
      debugPrint('💾 [DB] $msg');
    }
  }

  static void time(String msg) {
    if ( AppConfig.enableAllLogs && AppConfig.showTime) {
      debugPrint('[TEMPO] $msg');
    }
  }

  static void collab(String msg) {
    if ( AppConfig.enableAllLogs && AppConfig.showCollabLogs) {
      debugPrint('📡 [COLLAB] $msg');
    }
  }

  static void canvas(String msg) {
    if ( AppConfig.enableAllLogs && AppConfig.showCanvasLogs) {
      debugPrint('✍️ [CANVAS] $msg');
    }
  }

  static void api(String msg) {
    if ( AppConfig.enableAllLogs && AppConfig.showApiLogs) {
      debugPrint('🌐 [API] $msg');
    }
  }

  static void error(String component, String msg, [dynamic error]) {
    if ( AppConfig.enableAllLogs) {
      debugPrint('🚨 [ERROR-$component] $msg ${error != null ? '=> $error' : ''}');
    }
  }
}
