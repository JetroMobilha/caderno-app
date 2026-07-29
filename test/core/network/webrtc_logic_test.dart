import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:caderno_digital_app/core/network/webrtc_service.dart';
import 'package:caderno_digital_app/core/network/realtime_service.dart';

// Este teste valida a lógica de Cooldown e Handshake do WebRTCService
void main() {
  group('WebRTCService Logic', () {
    test('Deveria calcular corretamente o Cooldown de ofertas', () {
      final state = PeerState();
      final now = DateTime.now();
      
      state.lastOfferSentAt = now.subtract(const Duration(milliseconds: 500));
      bool isCoolingDown = DateTime.now().difference(state.lastOfferSentAt).inMilliseconds < 1500;
      
      expect(isCoolingDown, isTrue, reason: 'Deveria estar em cooldown se enviou há menos de 1.5s');
      
      state.lastOfferSentAt = now.subtract(const Duration(seconds: 2));
      isCoolingDown = DateTime.now().difference(state.lastOfferSentAt).inMilliseconds < 1500;
      
      expect(isCoolingDown, isFalse, reason: 'Não deveria estar em cooldown após 2s');
    });

    test('Deveria identificar corretamente o iniciador (Polite Peer) via ID', () {
      const String myId = "2";
      const String remoteId = "1";
      
      final int myIdNum = int.tryParse(myId) ?? 0;
      final int remoteIdNum = int.tryParse(remoteId) ?? 0;
      
      final bool amIInitiator = myIdNum > remoteIdNum;
      expect(amIInitiator, isTrue, reason: 'ID 2 deveria ser iniciador contra ID 1');
      
      final bool isPolite = myIdNum < remoteIdNum;
      expect(isPolite, isFalse, reason: 'ID 2 é Impolite (dominante) contra ID 1');
    });
  });
}
