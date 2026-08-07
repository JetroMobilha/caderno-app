import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:caderno_digital_app/core/network/api_service.dart';
import 'package:caderno_digital_app/core/services/ai_assistant_service.dart';

import 'ai_assistant_service_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  late AIAssistantService aiService;
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
    aiService = AIAssistantService(apiService: mockApiService);
  });

  group('AIAssistantService - searchInNotebooks', () {
    test('should return a list of AIQueryResult when status code is 200', () async {
      // Arrange
      final mockResponse = {
        'results': [
          {
            'text': 'Result 1',
            'notebook_id': 1,
            'page_number': 1,
            'confidence': 0.9,
          },
          {
            'text': 'Result 2',
            'notebook_id': 2,
            'page_number': 5,
            'confidence': 0.7,
          }
        ]
      };

      when(mockApiService.post(any, any)).thenAnswer(
        (_) async => http.Response(jsonEncode(mockResponse), 200),
      );

      // Act
      final results = await aiService.searchInNotebooks('query');

      // Assert
      expect(results.length, 2);
      expect(results[0].text, 'Result 1');
      expect(results[0].confidence, 0.9);
      expect(results[1].pageNumber, 5);
      verify(mockApiService.post('/ai/search', any)).called(1);
    });

    test('should return empty list when status code is not 200', () async {
      // Arrange
      when(mockApiService.post(any, any)).thenAnswer(
        (_) async => http.Response('Error', 500),
      );

      // Act
      final results = await aiService.searchInNotebooks('query');

      // Assert
      expect(results, isEmpty);
    });

    test('should return empty list on exception', () async {
      // Arrange
      when(mockApiService.post(any, any)).thenThrow(Exception('Network error'));

      // Act
      final results = await aiService.searchInNotebooks('query');

      // Assert
      expect(results, isEmpty);
    });
  });

  group('AIAssistantService - generateSummary', () {
    test('should return summary string when status code is 200', () async {
      // Arrange
      final mockResponse = {'summary': 'This is a summary'};

      when(mockApiService.post(any, any)).thenAnswer(
        (_) async => http.Response(jsonEncode(mockResponse), 200),
      );

      // Act
      final summary = await aiService.generateSummary(notebookId: 123);

      // Assert
      expect(summary, 'This is a summary');
      verify(mockApiService.post('/ai/summarize', {'notebook_id': 123})).called(1);
    });

    test('should return null when status code is not 200', () async {
      // Arrange
      when(mockApiService.post(any, any)).thenAnswer(
        (_) async => http.Response('Error', 404),
      );

      // Act
      final summary = await aiService.generateSummary(pageId: 456);

      // Assert
      expect(summary, isNull);
    });
  });
}
