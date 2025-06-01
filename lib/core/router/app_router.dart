import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../shared/widgets/auth_wrapper.dart';
import '../../main.dart'; // Per la Dashboard esistente

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter() {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      routes: [
        // ============================================================================
        // SPLASH & AUTH ROUTES
        // ============================================================================

        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) {
            // Controlla lo stato di autenticazione e reindirizza
            return BlocConsumer<AuthBloc, AuthState>(
              listener: (context, authState) {
                if (authState is AuthAuthenticated || authState is AuthLoginSuccess) {
                  context.go('/dashboard');
                } else if (authState is AuthUnauthenticated || authState is AuthError) {
                  context.go('/login');
                }
              },
              builder: (context, authState) {
                // Controlla automaticamente lo stato auth all'avvio
                if (authState is AuthInitial) {
                  context.read<AuthBloc>().checkAuthStatus();
                }

                // Splash screen esistente
                return const SplashScreen();
              },
            );
          },
        ),

        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),

        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),

        GoRoute(
          path: '/forgot-password',
          name: 'forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),

        GoRoute(
          path: '/reset-password/:token',
          name: 'reset-password',
          builder: (context, state) {
            final token = state.pathParameters['token'] ?? '';
            return ResetPasswordScreen(token: token);
          },
        ),

        // ============================================================================
        // PROTECTED ROUTES
        // ============================================================================

        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) {
            return AuthWrapper(
              authenticatedChild: const HomeScreen(), // Dalla Dashboard esistente
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),

        // ============================================================================
        // FUTURE ROUTES (placeholder)
        // ============================================================================

        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) {
            return AuthWrapper(
              authenticatedChild: const Scaffold(
                body: Center(child: Text('Profile Screen - Coming Soon')),
              ),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),

        GoRoute(
          path: '/workouts',
          name: 'workouts',
          builder: (context, state) {
            return AuthWrapper(
              authenticatedChild: const Scaffold(
                body: Center(child: Text('Workouts Screen - Coming Soon')),
              ),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),

        GoRoute(
          path: '/stats',
          name: 'stats',
          builder: (context, state) {
            return AuthWrapper(
              authenticatedChild: const Scaffold(
                body: Center(child: Text('Stats Screen - Coming Soon')),
              ),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),
      ],

      // ============================================================================
      // REDIRECT LOGIC
      // ============================================================================

      redirect: (context, state) {
        final authBloc = context.read<AuthBloc>();
        final authState = authBloc.state;

        final isOnAuthPage = ['/login', '/register', '/forgot-password'].contains(state.matchedLocation) ||
            state.matchedLocation.startsWith('/reset-password');

        // Se utente è autenticato e cerca di accedere a pagine auth, reindirizza alla dashboard
        if ((authState is AuthAuthenticated || authState is AuthLoginSuccess) && isOnAuthPage) {
          return '/dashboard';
        }

        // Se utente non è autenticato e cerca di accedere a pagine protette, reindirizza al login
        if ((authState is AuthUnauthenticated || authState is AuthError) && !isOnAuthPage && state.matchedLocation != '/splash') {
          return '/login';
        }

        return null; // Nessun redirect necessario
      },

      // ============================================================================
      // ERROR HANDLING
      // ============================================================================

      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Pagina non trovata',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'La pagina richiesta non esiste.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Torna alla Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}