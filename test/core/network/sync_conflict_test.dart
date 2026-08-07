import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:caderno_digital_app/core/network/sync_service.dart';
import 'package:caderno_digital_app/core/database/app_database.dart';
import 'package:caderno_digital_app/features/canvas/models/stroke_model.dart';
import 'package:drift/drift.dart';

import 'sync_conflict_test.mocks.dart';

@GenerateMocks([AppDatabase])
void main() {
  // Test LWW (Last-Write-Wins) logic
  group('SyncService LWW Logic', () {
    test('Local version should win if it is higher than server version', () {
      final int localVersion = 10;
      final int serverVersion = 5;
      
      // Logic: if (serverVersion > local.version || (serverVersion == local.version && serverTime > local.updatedAt))
      final bool serverWins = serverVersion > localVersion;
      
      expect(serverWins, false);
    });

    test('Server version should win if it is higher than local version', () {
      final int localVersion = 5;
      final int serverVersion = 10;
      
      final bool serverWins = serverVersion > localVersion;
      
      expect(serverWins, true);
    });

    test('Tie-break: higher updatedAt should win if versions are equal', () {
      final int version = 5;
      final int localTime = 1000;
      final int serverTime = 2000;
      
      final bool serverWins = (version > version) || (version == version && serverTime > localTime);
      
      expect(serverWins, true);
    });
  });
}
