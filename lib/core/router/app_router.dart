// lib/core/router/app_router.dart - FIX PARAMETERS ERROR

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../di/dependency_injection.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/payments/bloc/stripe_bloc.dart';

// Screen imports
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/workouts/presentation/screens/workout_plans_screen.dart';
import '../../features/workouts/presentation/screens/create_workout_screen.dart';
import '../../features/workouts/presentation/screens/edit_workout_screen.dart';
import '../../features/workouts/presentation/screens/active_workout_screen.dart';
import '../../features/subscription/presentation/screens/subscription_screen.dart';
import '../../features/payments/presentation/screens/stripe_payment_screen.dart';
import '../../features/feedback/presentation/screens/feedback_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/security_settings_screen.dart';
import '../../shared/widgets/faq_screen.dart';
import '../../shared/widgets/auth_wrapper.dart';
import '../../features/workouts/presentation/screens/workout_details_screen.dart';
import '../../features/workouts/presentation/screens/workout_history_screen.dart';
import '../../features/workouts/presentation/screens/workout_plan_details_screen.dart';
import '../../features/templates/presentation/screens/templates_screen.dart';
import '../../features/templates/presentation/screens/template_details_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/courses/presentation/screens/courses_list_screen.dart';
import '../../features/courses/presentation/screens/course_detail_screen.dart';
import '../../features/courses/presentation/screens/my_courses_screen.dart';
import '../../features/courses/bloc/courses_bloc.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter() {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      observers: [
        getIt<RouteObserver<ModalRoute<void>>>(),
      ],
      routes: [
        // ============================================================================
        // AUTH ROUTES
        // ============================================================================

        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) {
            return BlocConsumer<AuthBloc, AuthState>(
              listener: (context, authState) {
                if (authState is AuthAuthenticated ||
                    authState is AuthLoginSuccess) {
                  context.go('/dashboard');
                } else if (authState is AuthUnauthenticated ||
                    authState is AuthError) {
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
            // Estrai il parametro tab dalla query string
            final tabParam = state.uri.queryParameters['tab'];
            final tabIndex = tabParam != null ? int.tryParse(tabParam) : null;
            
            return AuthWrapper(
              authenticatedChild: HomeScreen(
                initialTab: tabIndex,
              ),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),

        GoRoute(
          path: '/feedback',
          name: 'feedback',
          builder: (context, state) {
            return AuthWrapper(
              authenticatedChild: const FeedbackScreen(),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),

        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) {
            return AuthWrapper(
              authenticatedChild: const ProfileScreen(),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),

        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) {
            return AuthWrapper(
              authenticatedChild: const SettingsScreen(),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),

        GoRoute(
          path: '/settings/security',
          name: 'security-settings',
          builder: (context, state) {
            return AuthWrapper(
              authenticatedChild: const SecuritySettingsScreen(),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),

        GoRoute(
          path: '/faq',
          name: 'faq',
          builder: (context, state) {
            return AuthWrapper(
              authenticatedChild: const FAQScreen(),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),

        GoRoute(
          path: '/notifications',
          name: 'notifications',
          builder: (context, state) {
            return AuthWrapper(
              authenticatedChild: const NotificationsScreen(),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),

        // ============================================================================
        // TEMPLATE ROUTES
        // ============================================================================

        GoRoute(
          path: '/templates',
          name: 'templates',
          builder: (context, state) {
            return AuthWrapper(
              authenticatedChild: const TemplatesScreen(),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),

        GoRoute(
          path: '/template-details/:templateId',
          name: 'template-details',
          builder: (context, state) {
            final templateId = int.tryParse(state.pathParameters['templateId'] ?? '');
            if (templateId == null) {
              return const Scaffold(
                body: Center(
                  child: Text('ID template non valido'),
                ),
              );
            }

            return AuthWrapper(
              authenticatedChild: TemplateDetailsScreen(templateId: templateId),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),

        // ============================================================================
        // SUBSCRIPTION ROUTES
        // ============================================================================

        GoRoute(
          path: '/subscription',
          name: 'subscription',
          builder: (context, state) {
            return AuthWrapper(
              authenticatedChild: const SubscriptionScreen(),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),

        // ============================================================================
        // 💳 STRIPE PAYMENT ROUTES - FIX: Rimosso parametro 'parameters'
        // ============================================================================

        GoRoute(
          path: '/payment/subscription',
          name: 'stripe-subscription-payment',
          builder: (context, state) {
            return AuthWrapper(
              authenticatedChild: BlocProvider(
                create: (context) => getIt<StripeBloc>(),
                child: const StripePaymentScreen(
                  paymentType: 'subscription',
                  // 🔧 FIX: Rimosso 'parameters: parameters' - parametro non definito
                ),
              ),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),

        GoRoute(
          path: '/payment/donation',
          name: 'stripe-donation-payment',
          builder: (context, state) {
            return AuthWrapper(
              authenticatedChild: BlocProvider(
                create: (context) => getIt<StripeBloc>(),
                child: const StripePaymentScreen(
                  paymentType: 'donation',
                  // 🔧 FIX: Rimosso 'parameters: parameters' - parametro non definito
                ),
              ),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),

        // ============================================================================
        // COURSES ROUTES
        // ============================================================================
        
        GoRoute(
          path: '/courses',
          name: 'courses',
          builder: (context, state) {
            return AuthWrapper(
              authenticatedChild: BlocProvider(
                create: (context) => getIt<CoursesBloc>(),
                child: const CoursesListScreen(),
              ),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),
        
        GoRoute(
          path: '/courses/:courseId',
          name: 'course-detail',
          builder: (context, state) {
            final courseId = int.tryParse(state.pathParameters['courseId'] ?? '');
            if (courseId == null) {
              return const Scaffold(
                body: Center(child: Text('ID corso non valido')),
              );
            }
            return AuthWrapper(
              authenticatedChild: BlocProvider(
                create: (context) => getIt<CoursesBloc>(),
                child: CourseDetailScreen(courseId: courseId),
              ),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),
        
        GoRoute(
          path: '/my-courses',
          name: 'my-courses',
          builder: (context, state) {
            return AuthWrapper(
              authenticatedChild: BlocProvider(
                create: (context) => getIt<CoursesBloc>(),
                child: const MyCoursesScreen(),
              ),
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
          path: '/workouts/details/:workoutId',
          name: 'workout-details',
          builder: (context, state) {
            final workoutId = int.tryParse(state.pathParameters['workoutId'] ?? '');
            if (workoutId == null) {
              return const Scaffold(
                body: Center(
                  child: Text('ID allenamento non valido'),
                ),
              );
            }
            return AuthWrapper(
              authenticatedChild: WorkoutDetailsScreen(
                workoutId: workoutId,
                workoutName: 'Dettagli Allenamento',
                workoutDate: DateTime.now(),
              ),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),

        GoRoute(
          path: '/workouts/plan/:planId',
          name: 'workout-plan-details',
          builder: (context, state) {
            final planId = int.tryParse(state.pathParameters['planId'] ?? '');
            final planName = state.uri.queryParameters['name'] ?? 'Dettagli Scheda';
            
            if (planId == null) {
              return const Scaffold(
                body: Center(
                  child: Text('ID scheda non valido'),
                ),
              );
            }
            return AuthWrapper(
              authenticatedChild: WorkoutPlanDetailsScreen(
                workoutPlanId: planId,
                workoutPlanName: planName,
              ),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),

        GoRoute(
          path: '/workouts/:schedaId/start',
          name: 'active-workout',
          builder: (context, state) {
            final schedaId = int.tryParse(
                state.pathParameters['schedaId'] ?? '');
            if (schedaId == null) {
              return const Scaffold(
                body: Center(
                  child: Text('ID scheda non valido'),
                ),
              );
            }

            final schedaNome = state.uri.queryParameters['nome'];

            return AuthWrapper(
              authenticatedChild: ActiveWorkoutScreen(
                schedaId: schedaId,
                schedaNome: schedaNome,
              ),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),

        // ============================================================================
        // WORKOUT HISTORY ROUTES
        // ============================================================================

        GoRoute(
          path: '/workouts/history',
          name: 'workout-history',
          builder: (context, state) {
            return AuthWrapper(
              authenticatedChild: const WorkoutHistoryScreen(),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),


        // ============================================================================
        // SUCCESS/ERROR PAGES
        // ============================================================================

        GoRoute(
          path: '/payment/success',
          name: 'payment-success',
          builder: (context, state) {
            return AuthWrapper(
              authenticatedChild: Scaffold(
                appBar: AppBar(
                  title: const Text('Pagamento Completato'),
                  automaticallyImplyLeading: false,
                ),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 80,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Pagamento Completato!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Il tuo pagamento è stato elaborato con successo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            OutlinedButton(
                              onPressed: () => context.go('/subscription'),
                              child: const Text('Vai agli Abbonamenti'),
                            ),
                            ElevatedButton(
                              onPressed: () => context.go('/dashboard'),
                              child: const Text('Dashboard'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              unauthenticatedChild: const LoginScreen(),
            );
          },
        ),

        GoRoute(
          path: '/payment/error',
          name: 'payment-error',
          builder: (context, state) {
            return AuthWrapper(
              authenticatedChild: Scaffold(
                appBar: AppBar(
                  title: const Text('Errore Pagamento'),
                  automaticallyImplyLeading: false,
                ),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Errore nel Pagamento',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Si è verificato un problema durante l\'elaborazione del pagamento. '
                              'Puoi riprovare in qualsiasi momento.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            OutlinedButton(
                              onPressed: () => context.go('/subscription'),
                              child: const Text('Torna agli Abbonamenti'),
                            ),
                            ElevatedButton(
                              onPressed: () => context.go('/dashboard'),
                              child: const Text('Dashboard'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
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

        final isOnAuthPage = ['/login', '/register', '/forgot-password']
            .contains(state.matchedLocation) ||
            state.matchedLocation.startsWith('/reset-password');

        if ((authState is AuthAuthenticated || authState is AuthLoginSuccess) &&
            isOnAuthPage) {
          return '/dashboard';
        }

        if ((authState is AuthUnauthenticated || authState is AuthError) &&
            !isOnAuthPage && state.matchedLocation != '/splash') {
          return '/login';
        }

        return null;
      },

      // ============================================================================
      // ERROR HANDLING
      // ============================================================================

      errorBuilder: (context, state) =>
          Scaffold(
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
                    style: Theme
                        .of(context)
                        .textTheme
                        .headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'La pagina richiesta non esiste.',
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodyMedium,
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