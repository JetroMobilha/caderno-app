import 'package:caderno/features/auth/presentation/pages/login_page.dart';
import 'package:caderno/features/auth/presentation/pages/register_page.dart';
import 'package:caderno/features/dashboard/presentation/pages/create_notebook_page.dart';
import 'package:caderno/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/create-notebook',
        builder: (context, state) => const CreateNotebookPage(),
      ),
    ],
  );
}
