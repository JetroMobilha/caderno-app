import 'package:flutter_test/flutter_test.dart';

/// Função utilitária pura que calcula o número de colunas com base na largura
int calculateCrossAxisCount(double width) {
  if (width < 600) return 2;     // Telemóvel
  if (width < 900) return 4;     // Tablet / Janela Pequena
  return 6;                      // Web / Monitor PC
}

void main() {
  group('Responsive Utils Tests |', () {
    test('Deve retornar 2 colunas para ecrãs de telemóvel (ex: 375px)', () {
      expect(calculateCrossAxisCount(375), 2);
    });

    test('Deve retornar 4 colunas para ecrãs de tablet (ex: 768px)', () {
      expect(calculateCrossAxisCount(768), 4);
    });

    test('Deve retornar 6 colunas para ecrãs de Web/Desktop (ex: 1280px)', () {
      expect(calculateCrossAxisCount(1280), 6);
    });
  });
}