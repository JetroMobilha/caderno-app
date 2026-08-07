import 'package:flutter_test/flutter_test.dart';
import 'package:caderno_digital_app/features/canvas/models/audio_stream_buffer.dart';

void main() {
  group('AudioStreamBuffer Tests', () {
    late AudioStreamBuffer buffer;

    setUp(() {
      buffer = AudioStreamBuffer(msgId: 'test_msg', senderId: 'user_1');
    });

    test('should order segments correctly even if they arrive out of order', () {
      // Act
      buffer.addSegment(2, 'url_2');
      buffer.addSegment(0, 'url_0');
      buffer.addSegment(1, 'url_1');

      // Assert
      expect(buffer.popNext(), 'url_0');
      expect(buffer.popNext(), 'url_1');
      expect(buffer.popNext(), 'url_2');
      expect(buffer.popNext(), isNull);
    });

    test('isReadyToStart should be true after 1 segment', () {
      expect(buffer.isReadyToStart, isFalse);
      
      buffer.addSegment(0, 'url_0');
      expect(buffer.isReadyToStart, isTrue);
    });

    test('isReadyToStart should be true if finalized even with 1 segment', () {
      buffer.addSegment(0, 'url_0', isFinal: true);
      expect(buffer.isReadyToStart, isTrue);
    });

    test('hasMoreToPlay logic', () {
      buffer.addSegment(0, 'url_0');
      expect(buffer.hasMoreToPlay, isTrue); // Not finalized, could be more

      buffer.addSegment(1, 'url_1', isFinal: true);
      expect(buffer.hasMoreToPlay, isTrue);

      buffer.popNext(); // 0
      buffer.popNext(); // 1
      
      expect(buffer.hasMoreToPlay, isFalse); // Finalized and all played
    });

    test('buffer starvation handling', () {
      buffer.addSegment(0, 'url_0');
      
      expect(buffer.popNext(), 'url_0');
      expect(buffer.popNext(), isNull); // Segment 1 missing
      
      buffer.addSegment(1, 'url_1');
      expect(buffer.popNext(), 'url_1');
    });
  });
}
