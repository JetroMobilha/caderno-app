import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import 'package:caderno_digital_app/core/database/app_database.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});
