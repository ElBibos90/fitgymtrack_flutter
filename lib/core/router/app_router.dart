// lib/core/router/app_router.dart
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
import '../../features/workouts/presentation/screens/workout_plans_screen.dart';
import '../../features/workouts/presentation/screens/create_workout_screen.dart';
import '../../features/workouts/presentation/screens/edit_workout_screen.dart';
import '../../features/workouts/presentation/screens/active_workout_screen.dart';
import '../../features/workouts/bloc/active_workout_bloc.dart';
import '../../features/subscription/presentation/screens/subscription_screen.dart';
import '../../core/di/dependency_injection.dart';

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
            return BlocConsumer<AuthBloc, AuthState>(
              listener: (context, authState) {
                if (authState is AuthAuthenticated || authState is AuthLoginSuccess) {
                  context.go('/dashboard');
                } else if (authState is AuthUnauthenticated || authState is AuthError) {
                  context.go('/login');
                }
              },
              builder: (context, authState) {
                if (authState is AuthInitial) {
                  context.read<AuthBloc>().checkAuthStatus();
                }
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
              authenticatedChild: const HomeScreen(),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),

        // ============================================================================
        // 🔧 FIX: SUBSCRIPTION ROUTES con pulsante back corretto
        // ============================================================================

        GoRoute(
          path: '/subscription',
          name: 'subscription',
          builder: (context, state) {
            return AuthWrapper(
              authenticatedChild: SubscriptionScreenWrapper(), // 🔧 Nuovo wrapper
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),

        // ============================================================================
        // WORKOUT ROUTES
        // ============================================================================

        GoRoute(
          path: '/workouts',
          name: 'workouts',
          builder: (context, state) {
            return AuthWrapper(
              authenticatedChild: const WorkoutPlansScreen(),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),

        GoRoute(
          path: '/workouts/create',
          name: 'create-workout',
          builder: (context, state) {
            return AuthWrapper(
              authenticatedChild: const CreateWorkoutScreen(),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),

        GoRoute(
          path: '/workouts/edit/:id',
          name: 'edit-workout',
          builder: (context, state) {
            final workoutId = int.tryParse(state.pathParameters['id'] ?? '');
            if (workoutId == null) {
              return const Scaffold(
                body: Center(
                  child: Text('ID scheda non valido'),
                ),
              );
            }

            return AuthWrapper(
              authenticatedChild: EditWorkoutScreen(workoutId: workoutId),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),

        GoRoute(
          path: '/workouts/:id',
          name: 'workout-details',
          builder: (context, state) {
            final workoutId = int.tryParse(state.pathParameters['id'] ?? '');
            return AuthWrapper(
              authenticatedChild: Scaffold(
                appBar: AppBar(title: Text('Workout Details $workoutId')),
                body: const Center(child: Text('Workout Details - Coming Soon')),
              ),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),

        GoRoute(
          path: '/workouts/:id/start',
          name: 'start-workout',
          builder: (context, state) {
            final workoutId = int.tryParse(state.pathParameters['id'] ?? '');
            if (workoutId == null) {
              return const Scaffold(
                body: Center(
                  child: Text('ID scheda non valido'),
                ),
              );
            }

            return AuthWrapper(
              authenticatedChild: BlocProvider.value(
                value: getIt<ActiveWorkoutBloc>(),
                child: ActiveWorkoutScreen(
                  schedaId: workoutId,
                ),
              ),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),

        // ============================================================================
        // OTHER ROUTES
        // ============================================================================

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
      ],

      // ============================================================================
      // REDIRECT LOGIC
      // ============================================================================

      redirect: (context, state) {
        final authBloc = context.read<AuthBloc>();
        final authState = authBloc.state;

        final isOnAuthPage = ['/login', '/register', '/forgot-password'].contains(state.matchedLocation) ||
            state.matchedLocation.startsWith('/reset-password');

        if ((authState is AuthAuthenticated || authState is AuthLoginSuccess) && isOnAuthPage) {
          return '/dashboard';
        }

        if ((authState is AuthUnauthenticated || authState is AuthError) && !isOnAuthPage && state.matchedLocation != '/splash') {
          return '/login';
        }

        return null;
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

// ============================================================================
// 🔧 WRAPPER per SubscriptionScreen con pulsante back
// ============================================================================

class SubscriptionScreenWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SubscriptionScreen(
      onBack: () {
        // 🔧 FIX: Implementa la navigazione indietro corretta
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          // Se non può tornare indietro, va alla dashboard
          context.go('/dashboard');
        }
      },
    );
  }
}