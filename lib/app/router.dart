import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_rider_app/features/about/presentation/pages/about_page.dart';
import 'package:taxi_rider_app/features/auth/presentation/pages/login_page.dart';
import 'package:taxi_rider_app/features/auth/presentation/pages/register_page.dart';
import 'package:taxi_rider_app/features/home_map/presentation/main_map_page.dart';

/// Notifies [GoRouter] when [FirebaseAuth] session changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = GoRouterRefreshStream(
    FirebaseAuth.instance.authStateChanges(),
  );
  ref.onDispose(refresh.dispose);

  return GoRouter(
    refreshListenable: refresh,
    initialLocation: '/login',
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final path = state.uri.path;
      final authRoutes = path == '/login' || path == '/register';
      if (user == null) {
        if (authRoutes) {
          return null;
        }
        return '/login';
      }
      if (authRoutes) {
        return '/home';
      }
      return null;
    },
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
        builder: (context, state) => const MainMapPage(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route error: ${state.error}'),
      ),
    ),
  );
});
