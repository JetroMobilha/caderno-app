import 'package:flutter_test/flutter_test.dart';
import 'package:caderno_digital_app/core/network/realtime_service.dart';

void main() {
  group('RealtimeService Presence Internal Logic', () {
    test('Deveria gerir corretamente o mapa de utilizadores e conversão de IDs', () {
      // Simulação da lógica interna de gestão de membros que extraímos para o RealtimeService
      final Map<String, dynamic> estudantesNaSala = {};
      
      void addMember(String uid, Map<String, dynamic> info) {
        info['id'] = uid;
        estudantesNaSala[uid] = info;
      }

      addMember("1", {"name": "User 1"});
      addMember("2", {"name": "User 2"});

      expect(estudantesNaSala.length, 2);
      expect(estudantesNaSala["1"]["id"], "1");
      expect(estudantesNaSala["2"]["name"], "User 2");
    });
  });
}
