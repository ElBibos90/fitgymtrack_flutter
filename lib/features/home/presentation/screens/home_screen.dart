// lib/features/home/presentation/screens/home_screen.dart - VERSIONE OTTIMIZZATA

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../core/utils/api_request_debouncer.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/di/dependency_injection.dart';
import 'dart:async';
import 'package:get_it/get_it.dart';
import '../../../subscription/bloc/subscription_bloc.dart';
import '../../../workouts/presentation/screens/workout_plans_screen.dart';
import '../../../subscription/presentation/screens/subscription_screen.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/models/login_response.dart';
import '../../../workouts/bloc/workout_blocs.dart';
import '../../../workouts/bloc/workout_history_bloc.dart';
import '../../../workouts/bloc/active_workout_bloc.dart';
import '../widgets/dashboard_page.dart';
import '../../../stats/presentation/screens/freemium_stats_dashboard.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../notifications/presentation/widgets/notification_badge_icon.dart';
import '../../../notifications/presentation/widgets/modern_notification_menu.dart';
import '../../../notifications/bloc/notification_bloc.dart';
import '../../../../core/services/app_update_service.dart';
import '../../../../core/services/user_role_service.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../courses/presentation/screens/courses_list_screen.dart';
import '../../../courses/bloc/courses_bloc.dart';

/// 🚀 PERFORMANCE OPTIMIZED: Home Screen con caricamento sequenziale intelligente
class HomeScreen extends StatefulWidget {
  final int? initialTab;
  
  const HomeScreen({super.key, this.initialTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  int _previousIndex = 0;

  // 🚀 PERFORMANCE: Flag per controllo inizializzazione
  bool _isInitialDataLoaded = false;
  bool _isSubscriptionLoaded = false;
  bool _isWorkoutHistoryLoaded = false;

  // Controller per lazy loading delle tab
  final WorkoutTabController _workoutController = WorkoutTabController();

  // 🚀 PERFORMANCE: Map per tenere traccia dello stato di caricamento per tab
  final Map<int, bool> _tabInitialized = {
    0: false, // Dashboard
    1: false, // Workouts
    2: false, // Stats
    3: false, // Subscription
  };

  // Cache delle pagine per evitare ricostruzioni
  final Map<int, Widget> _cachedPages = {};
  int? _cachedUserId; // Traccia l'utente per cui è stata creata la cache
  
  // 🔧 FIX: Traccia l'utente per cui sono stati caricati i dati
  int? _lastLoadedUserId;

  /// 🎯 NUOVO: Lista delle pagine dinamica basata sul ruolo utente
  List<Widget Function()> _getPageBuilders(User? user) {
    final pages = [
      () => DashboardPage(
        onNavigateToWorkouts: () => _onTabTapped(1),
        onNavigateToAchievements: _handleAchievementsNavigation,
        onNavigateToProfile: _handleProfileNavigation,
        onNavigateToSubscription: () {
          // 🎯 NUOVO: Controlla se il tab abbonamento è disponibile
          if (UserRoleService.canSeeSubscriptionTab(user)) {
            // L'indice dipende da quante tab ci sono prima
            final subscriptionIndex = UserRoleService.canSeeCoursesTab(user) ? 4 : 3;
            _onTabTapped(subscriptionIndex);
          } else {
            print('[CONSOLE] [home_screen]❌ Subscription tab not available for user role');
          }
        },
      ),
      () => WorkoutPlansScreen(controller: _workoutController),
    ];
    
    // Aggiungi tab corsi solo per utenti palestra
    if (UserRoleService.canSeeCoursesTab(user)) {
      pages.add(() => BlocProvider(
        create: (context) => getIt<CoursesBloc>(),
        child: const CoursesListScreen(),
      ));
    }
    
    // Aggiungi sempre le statistiche
    pages.add(() => const FreemiumStatsDashboard());
    
    // Aggiungi tab abbonamento solo per utenti standalone
    if (UserRoleService.canSeeSubscriptionTab(user)) {
      pages.add(() => const SubscriptionScreen());
    }
    
    return pages;
  }

  /// 🎯 NUOVO: Lista dei tab dinamica basata sul ruolo utente
  List<BottomNavigationBarItem> _getNavItems(User? user) {
    final items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_rounded),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.fitness_center_rounded),
        label: 'Allenamenti',
      ),
    ];
    
    // Aggiungi tab corsi solo per utenti palestra
    if (UserRoleService.canSeeCoursesTab(user)) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.school_rounded),
        label: 'Corsi',
      ));
    }
    
    // Aggiungi sempre statistiche
    items.add(const BottomNavigationBarItem(
      icon: Icon(Icons.analytics_rounded),
      label: 'Statistiche',
    ));
    
    // Aggiungi tab abbonamento solo per utenti standalone
    if (UserRoleService.canSeeSubscriptionTab(user)) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.card_membership_rounded),
        label: 'Abbonamento',
      ));
    }
    
    return items;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    //print('[CONSOLE] [home_screen]🚀 HomeScreen initialized');

    // 🚀 PERFORMANCE: Inizializzazione sequenziale post-frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeSequentially();
        _checkForTabParameter();
      }
    });
  }

  /// Controlla se c'è un parametro tab iniziale
  void _checkForTabParameter() {
    if (widget.initialTab != null) {
      final tabIndex = widget.initialTab!;
      
      // 🎯 NUOVO: Ottieni utente per controllo ruoli
      final authState = context.read<AuthBloc>().state;
      User? currentUser;
      if (authState is AuthAuthenticated) {
        currentUser = authState.user;
      } else if (authState is AuthLoginSuccess) {
        currentUser = authState.user;
      }
      
      final navItems = _getNavItems(currentUser);
      if (tabIndex >= 0 && tabIndex < navItems.length) {
        // Aspetta un frame per permettere alla UI di inizializzarsi
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _onTabTapped(tabIndex);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // WorkoutTabController non ha dispose() - solo detach
    ApiRequestDebouncer.clearCache('home_screen'); // Pulisci cache specifica
    super.dispose();
  }

  /// 🚀 PERFORMANCE: Inizializzazione sequenziale intelligente
  Future<void> _initializeSequentially() async {
    try {
      //print('[CONSOLE] [home_screen]🚀 Starting sequential initialization...');

      // STEP 1: Verifica stato auth (già disponibile)
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated && authState is! AuthLoginSuccess) {
        print('[CONSOLE] [home_screen]❌ User not authenticated, skipping initialization');
        return;
      }

      int userId;
      if (authState is AuthAuthenticated) {
        userId = authState.user.id;
      } else if (authState is AuthLoginSuccess) {
        userId = authState.user.id;
      } else {
        return;
      }

      // 🔧 FIX: Se l'utente è cambiato, resetta i flag di caricamento
      if (_lastLoadedUserId != userId) {
        //print('[CONSOLE] [home_screen]🔄 User changed from $_lastLoadedUserId to $userId, resetting initialization flags');
        _isSubscriptionLoaded = false;
        _isWorkoutHistoryLoaded = false;
        _isInitialDataLoaded = false;
        _lastLoadedUserId = userId;
      }

      // Se i dati sono già stati caricati per questo utente, non ricaricarli
      if (_isInitialDataLoaded) {
        //print('[CONSOLE] [home_screen]⚡ Data already initialized for user $userId');
        return;
      }

      //print('[CONSOLE] [home_screen]👤 User authenticated: $userId');

      // STEP 2: Carica subscription (priorità alta - necessaria per UI)
      await _loadSubscriptionWithDebouncing();

      // STEP 3: Carica workout history (priorità media - può essere ritardato)
      _loadWorkoutHistoryAsync(userId);

      // STEP 4: Inizializza dashboard (priorità bassa)
      _initializeDashboard();

      _isInitialDataLoaded = true;
      //print('[CONSOLE] [home_screen]✅ Sequential initialization completed for user $userId');

      // 🔧 NUOVO: Controllo aggiornamenti in background (non bloccante)
      _scheduleBackgroundUpdateCheck();

    } catch (e) {
      print('[CONSOLE] [home_screen]❌ Initialization error: $e');
      // Non bloccare l'app per errori di inizializzazione
    }
  }

  /// 🔧 RIMOSSO: Controllo workout pending duplicato
  /// Il controllo viene fatto automaticamente dall'AuthBloc dopo il login

  /// 🌐 NUOVO: Avvia l'allenamento in sospeso
  void _startPendingWorkout(Map<String, dynamic> pendingWorkout) {
    try {
      //print('[CONSOLE] [home_screen] 🚀 Starting pending workout: ${pendingWorkout['allenamento_id']}');
      
      // Ottieni il Bloc degli allenamenti attivi
      final activeWorkoutBloc = getIt<ActiveWorkoutBloc>();
      //print('[CONSOLE] [home_screen] 🔍 ActiveWorkoutBloc obtained: ${activeWorkoutBloc.hashCode}');
      
      // Aggiungi listener per aspettare che l'allenamento sia ripristinato
      StreamSubscription? subscription;
      subscription = activeWorkoutBloc.stream.listen((state) {
        if (state is WorkoutSessionActive) {
          //print('[CONSOLE] [home_screen] ✅ Workout session active, navigating to active workout screen');
          // Naviga alla schermata dell'allenamento attivo con il schedaId corretto
          final schedaId = state.activeWorkout.schedaId;
          context.go('/workouts/$schedaId/start');
          // Cancella il listener
          subscription?.cancel();
        } else if (state is ActiveWorkoutError) {
          print('[CONSOLE] [home_screen] ❌ Error restoring workout: ${state.message}');
          // Cancella il listener
          subscription?.cancel();
        }
      });
      
      // Avvia l'allenamento in sospeso dal database
      //print('[CONSOLE] [home_screen] 📤 Dispatching RestorePendingWorkout event...');
      activeWorkoutBloc.add(RestorePendingWorkout(pendingWorkout));
      
      //print('[CONSOLE] [home_screen] ✅ Pending workout started successfully');
    } catch (e) {
      print('[CONSOLE] [home_screen] ❌ Error starting pending workout: $e');
    }
  }

  /// 🌐 NUOVO: Mostra dialog per allenamento in sospeso
  void _showPendingWorkoutDialog(BuildContext context, PendingWorkoutPrompt state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Allenamento in Sospeso'),
          content: Text(state.message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthBloc>().add(const DismissPendingWorkoutRequested());
              },
              child: const Text('Ignora'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Avvia direttamente l'allenamento in sospeso
                _startPendingWorkout(state.pendingWorkout);
              },
              child: const Text('Riprendi'),
            ),
          ],
        );
      },
    );
  }

  /// 🔧 OTTIMIZZATO: Programma controllo aggiornamenti in background
  void _scheduleBackgroundUpdateCheck() {
    // 🔧 FIX: Esegui dopo 3 secondi in background, non bloccante
    Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;
      
      try {
        //print('[CONSOLE] [home_screen]🔄 Background update check started...');
        
        final updateInfo = await AppUpdateService.checkForUpdates();
        
        if (updateInfo != null && mounted) {
          //print('[CONSOLE] [home_screen]📱 Update available in background');
          AppUpdateService.showUpdateDialog(context, updateInfo);
        } else {
          //print('[CONSOLE] [home_screen]ℹ️ No update available (background check)');
        }
      } catch (e) {
        print('[CONSOLE] [home_screen]❌ Background update check error: $e');
      }
    });
  }

  /// 🚀 PERFORMANCE: Carica notifiche iniziali
  Future<void> _loadInitialNotifications() async {
      try {
        //print('[CONSOLE] [home_screen]🔔 Loading initial notifications...');
        context.read<NotificationBloc>().add(const LoadNotificationsEvent());
      } catch (e) {
        print('[CONSOLE] [home_screen]❌ Error loading initial notifications: $e');
      }
    }

    // 🚀 PERFORMANCE: Carica subscription con debouncing DOPO validazione token
    Future<void> _loadSubscriptionWithDebouncing() async {
      try {
      //print('[CONSOLE] [home_screen]💳 Loading subscription with debouncing...');

      // 🔧 FIX: Verifica che l'utente sia autenticato prima di caricare subscription
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated && authState is! AuthLoginSuccess) {
        print('[CONSOLE] [home_screen]❌ User not authenticated, skipping subscription load');
        return;
      }

      // 🔧 FIX: Ottieni l'ID utente corrente
      int currentUserId;
      if (authState is AuthAuthenticated) {
        currentUserId = authState.user.id;
      } else if (authState is AuthLoginSuccess) {
        currentUserId = authState.user.id;
      } else {
        return;
      }

      // 🔧 FIX: Se l'utente è cambiato, resetta i flag di caricamento
      if (_lastLoadedUserId != currentUserId) {
        //print('[CONSOLE] [home_screen]🔄 User changed from $_lastLoadedUserId to $currentUserId, resetting load flags');
        _isSubscriptionLoaded = false;
        _isWorkoutHistoryLoaded = false;
        _isInitialDataLoaded = false;
        _lastLoadedUserId = currentUserId;
      }

      // Se l'abbonamento è già stato caricato per questo utente, non ricaricarlo
      if (_isSubscriptionLoaded) {
        //print('[CONSOLE] [home_screen]⚡ Subscription already loaded for user $currentUserId');
        return;
      }

      // 🔔 Carica anche le notifiche iniziali
      _loadInitialNotifications();

      await ApiRequestDebouncer.debounceRequest<void>(
        key: 'subscription_check_expired',
        request: () async {
          //print('[CONSOLE] [home_screen]🌐 Loading subscription (token already validated)...');
          context.read<SubscriptionBloc>().add(
            const LoadSubscriptionEvent(checkExpired: true),
          );
        },
      );

      _isSubscriptionLoaded = true;
      //print('[CONSOLE] [home_screen]✅ Subscription loaded successfully for user $currentUserId');
    } catch (e) {
      print('[CONSOLE] [home_screen]❌ Subscription loading error: $e');
    }
  }

  /// 🚀 PERFORMANCE: Carica workout history in background
  void _loadWorkoutHistoryAsync(int userId) {
    //print('[CONSOLE] [home_screen]📊 Loading workout history async...');

    // Se la workout history è già stata caricata per questo utente, non ricaricarla
    if (_isWorkoutHistoryLoaded && _lastLoadedUserId == userId) {
      //print('[CONSOLE] [home_screen]⚡ Workout history already loaded for user $userId');
      return;
    }

    // Non bloccare il main thread
    Future.microtask(() async {
      try {
        await ApiRequestDebouncer.debounceRequest<void>(
          key: 'workout_history_$userId',
          request: () async {
            context.read<WorkoutHistoryBloc>().add(
              GetWorkoutHistory(userId: userId),
            );
            // Non ritornare nulla, è void
          },
          delay: const Duration(milliseconds: 100), // Ritardo minimo
        );

        _isWorkoutHistoryLoaded = true;
        //print('[CONSOLE] [home_screen]✅ Workout history loaded async');
      } catch (e) {
        print('[CONSOLE] [home_screen]❌ Workout history async error: $e');
      }
    });
  }

  /// 🚀 PERFORMANCE: Inizializza dashboard quando necessario
  void _initializeDashboard() {
    if (_tabInitialized[0] == true) return;

    //print('[CONSOLE] [home_screen]📊 Initializing dashboard...');
    _tabInitialized[0] = true;

    // Marca dashboard come pronta
    if (mounted) {
      setState(() {
        // Trigger rebuild per mostrare dashboard
      });
    }
  }

  /// 🚀 PERFORMANCE: Lazy initialization per tab specifica
  void _initializeTabIfNeeded(int index) {
    if (_tabInitialized[index] == true) return;

    //print('[CONSOLE] [home_screen]🎯 Initializing tab $index...');

    // L'inizializzazione è già gestita dai BlocProvider
    // Non servono azioni specifiche per tab
    
    _tabInitialized[index] = true;
  }

  void _initializeWorkoutsTab() {
    //print('[CONSOLE] [home_screen]💪 Initializing workouts tab...');
    // Lazy load di workout blocs se necessario
  }

  void _initializeStatsTab() {
    //print('[CONSOLE] [home_screen]📈 Initializing stats tab...');
    // Lazy load di plateau bloc se necessario
  }

  void _initializeNotificationsTab() {
    //print('[CONSOLE] [home_screen]🔔 Initializing notifications tab...');
    // Carica le notifiche quando l'utente accede al tab
    context.read<NotificationBloc>().add(const LoadNotificationsEvent());
  }

  void _initializeSubscriptionTab() {
    //print('[CONSOLE] [home_screen]💳 Initializing subscription tab...');
    // Già caricato nell'inizializzazione sequenziale
  }

  /// 🚀 PERFORMANCE: Ottimizzato tab navigation
  void _onTabTapped(int index) {
    if (_selectedIndex == index) return; // Evita tap duplicati

    print('[CONSOLE] [home_screen]🎯 Tab tapped: $index');

    // 🎯 NUOVO: Controlla se il tab è valido per l'utente corrente
    final authState = context.read<AuthBloc>().state;
    User? currentUser;
    if (authState is AuthAuthenticated) {
      currentUser = authState.user;
    } else if (authState is AuthLoginSuccess) {
      currentUser = authState.user;
    }
    
    // 🔍 DEBUG: Log per verificare la navigazione
    //print('[CONSOLE] [Permessi]🔍 DEBUG NAVIGAZIONE:');
    //print('[CONSOLE] [Permessi] - User ID: ${currentUser?.id}');
    //print('[CONSOLE] [Permessi] - Role ID: ${currentUser?.roleId}');
    //print('[CONSOLE] [Permessi] - Tab clicked: $index');
    //print('[CONSOLE] [Permessi] - isGymUser: ${UserRoleService.isGymUser(currentUser)}');
    //print('[CONSOLE] [Permessi] - isStandaloneUser: ${UserRoleService.isStandaloneUser(currentUser)}');
    
    final pageBuilders = _getPageBuilders(currentUser);
    final navItems = _getNavItems(currentUser);
    
    //print('[CONSOLE] [Permessi] - Total pages: ${pageBuilders.length}');
    //print('[CONSOLE] [Permessi] - Total nav items: ${navItems.length}');
    //print('[CONSOLE] [Permessi] - Nav items: ${navItems.map((item) => item.label).toList()}');
    
    // 🔍 DEBUG: Verifica mapping dettagliato
    //print('[CONSOLE] [Permessi]🔍 DEBUG MAPPING:');
    for (int i = 0; i < navItems.length; i++) {
      //print('[CONSOLE] [Permessi] - Nav[$i]: ${navItems[i].label}');
    }
    //print('[CONSOLE] [Permessi]🔍 DEBUG PAGES:');
    //print('[CONSOLE] [Permessi] - Page[0]: Dashboard');
    //print('[CONSOLE] [Permessi] - Page[1]: WorkoutPlansScreen');
    if (UserRoleService.canSeeCoursesTab(currentUser)) {
      //print('[CONSOLE] [Permessi] - Page[2]: CoursesListScreen');
      //print('[CONSOLE] [Permessi] - Page[3]: FreemiumStatsDashboard');
    } else {
      //print('[CONSOLE] [Permessi] - Page[2]: FreemiumStatsDashboard');
      if (UserRoleService.canSeeSubscriptionTab(currentUser)) {
        //print('[CONSOLE] [Permessi] - Page[3]: SubscriptionScreen');
      }
    }
    
    if (index >= pageBuilders.length) {
      print('[CONSOLE] [home_screen]❌ Tab $index not available for user role');
      return;
    }

    // Inizializza tab se necessario
    _initializeTabIfNeeded(index);

    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = index;
    });

    _handleTabVisibilityChange(_previousIndex, index);
  }

  /// Ottieni page per index con lazy loading
  Widget _getPageForIndex(int index, User? user) {
    // 🔧 FIX: Pulisci cache se l'utente è cambiato
    // Questo risolve il problema del mapping sbagliato tra indici e pagine
    final userId = user?.id;
    if (_cachedUserId != userId) {
      _cachedPages.clear();
      _cachedUserId = userId;
      //print('[CONSOLE] [home_screen]🧹 Cache cleared for new user: $userId');
    }

    // Crea page e mettila in cache
    final pageBuilders = _getPageBuilders(user);
    if (index < pageBuilders.length) {
      final page = pageBuilders[index]();
      _cachedPages[index] = page;
      return page;
    }
    
    // Fallback se l'indice non è valido
    return const Center(child: Text('Pagina non trovata'));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if ((state is AuthAuthenticated || state is AuthLoginSuccess) && !_isInitialDataLoaded) {
          // Re-inizializza se auth cambia
          _initializeSequentially();
        } else if (state is PendingWorkoutPrompt) {
          //print('[CONSOLE] [home_screen] 📱 Showing pending workout prompt for workout: ${state.pendingWorkout['allenamento_id']}');
          _showPendingWorkoutDialog(context, state);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          // 🎯 NUOVO: Estrai utente per controllo ruoli
          User? currentUser;
          if (authState is AuthAuthenticated) {
            currentUser = authState.user;
          } else if (authState is AuthLoginSuccess) {
            currentUser = authState.user;
          }
          
          final pageBuilders = _getPageBuilders(currentUser);
          final navItems = _getNavItems(currentUser);
          
          return Scaffold(
            appBar: _buildAppBar(context),
            body: IndexedStack(
              index: _selectedIndex,
              children: List.generate(
                pageBuilders.length,
                (index) => _getPageForIndex(index, currentUser),
              ),
            ),
            bottomNavigationBar: _buildBottomNavigation(
              Theme.of(context).brightness == Brightness.dark,
              navItems: navItems,
            ),
          );
        },
      ),
    );
  }

  // ============================================================================
  // UI BUILDING METHODS (da codice esistente ma ottimizzati)
  // ============================================================================

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      elevation: 0,
      backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.indigo600, AppColors.green600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.fitness_center,
              color: Colors.white,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            'FitGymTrack',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
      actions: [
        // 🔔 Menu notifiche moderno
        ModernNotificationMenu(
          color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
          size: 24.0,
        ),
        IconButton(
          icon: Icon(
            Icons.settings,
            color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
          ),
          onPressed: _handleSettingsNavigation,
        ),
        IconButton(
          icon: Icon(
            Icons.logout,
            color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
          ),
          onPressed: _handleLogout,
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(bool isDarkMode, {required List<BottomNavigationBarItem> navItems}) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.indigo600,
        unselectedItemColor: isDarkMode ? Colors.white54 : AppColors.textSecondary,
        selectedFontSize: 12.sp,
        unselectedFontSize: 12.sp,
        items: navItems,
      ),
    );
  }

  // ============================================================================
  // EVENT HANDLERS (da codice esistente)
  // ============================================================================

  void _handleTabVisibilityChange(int previousIndex, int currentIndex) {
    if (currentIndex == 1) {
      _workoutController.onTabVisible();
      //print('[CONSOLE] [home_screen]👁️ Workout tab became visible');
    } else if (previousIndex == 1) {
      _workoutController.onTabHidden();
      //print('[CONSOLE] [home_screen]👁️ Workout tab became hidden');
    }
  }

  void _handleLogout() {
    context.read<AuthBloc>().add(const AuthLogoutRequested());
    // 🧹 Cache cleanup ora gestito automaticamente da SessionService.clearSession()
  }

  void _handleAchievementsNavigation() {
    //print('[CONSOLE] [home_screen]🏆 Navigate to achievements');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Achievement - Feature in arrivo!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleProfileNavigation() {
    //print('[CONSOLE] [home_screen]👤 Navigate to profile');
    // ✅ FIXED: Naviga alla ProfileScreen esistente
    context.push('/profile');
  }

  void _handleSettingsNavigation() {
    //print('[CONSOLE] [home_screen]⚙️ Navigate to settings');
    context.push('/settings');
  }

  /// ✅ Navigation helpers (da codice esistente)
  void navigateToWorkouts() {
    //print('[CONSOLE] [home_screen]🏋️ Navigating to workouts tab via callback');
    _onTabTapped(1);
  }

  void navigateToSubscription() {
    //print('[CONSOLE] [home_screen]💳 Navigating to subscription tab via callback');
    // Calcola indice dinamicamente in base al ruolo
    final authState = context.read<AuthBloc>().state;
    User? currentUser;
    if (authState is AuthAuthenticated) {
      currentUser = authState.user;
    } else if (authState is AuthLoginSuccess) {
      currentUser = authState.user;
    }
    
    final subscriptionIndex = UserRoleService.canSeeCoursesTab(currentUser) ? 4 : 3;
    _onTabTapped(subscriptionIndex);
  }

  void navigateToStats() {
    //print('[CONSOLE] [home_screen]📊 Navigating to stats tab via callback');
    // Calcola indice dinamicamente in base al ruolo
    final authState = context.read<AuthBloc>().state;
    User? currentUser;
    if (authState is AuthAuthenticated) {
      currentUser = authState.user;
    } else if (authState is AuthLoginSuccess) {
      currentUser = authState.user;
    }
    
    final statsIndex = UserRoleService.canSeeCoursesTab(currentUser) ? 3 : 2;
    _onTabTapped(statsIndex);
  }
}