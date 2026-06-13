import 'package:flutter_test/flutter_test.dart';
import 'package:caderno/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  group('AuthProvider Tests', () {
    late AuthProvider authProvider;

    setUp(() {
      // Nota: O flutter_secure_storage usa MethodChannels que precisam de um binding de teste
      TestWidgetsFlutterBinding.ensureInitialized();
      // Mockando o storage para evitar erros de plataforma durante testes unitários simples
      FlutterSecureStorage.setMockInitialValues({});
      authProvider = AuthProvider();
    });

    test('Estado inicial deve ser não autenticado', () {
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.token, null);
    });

    test('Login deve atualizar o token e estado de autenticação', () async {
      await authProvider.login('test@example.com', 'password123');
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.token, 'token_fake_123');
    });

    test('Logout deve limpar o token', () async {
      await authProvider.login('test@example.com', 'password123');
      await authProvider.logout();
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.token, null);
    });
  });
}
