import 'package:flutter_test/flutter_test.dart';
import 'package:caderno/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  group('AuthProvider Tests', () {
    late AuthProvider authProvider;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      FlutterSecureStorage.setMockInitialValues({});
      authProvider = AuthProvider();
    });

    test('Estado inicial deve ser não autenticado', () {
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.token, null);
      expect(authProvider.isLoading, false);
    });
  });
}
