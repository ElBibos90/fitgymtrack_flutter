import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../repository/auth_repository.dart';
import '../models/login_response.dart';
import '../../../core/services/global_connectivity_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/di/dependency_injection.dart';
import '../../workouts/bloc/active_workout_bloc.dart';

// ============================================================================
// AUTH EVENTS
// ============================================================================

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;

  const AuthLoginRequested({
    required this.username,
    required this.password,
  });

  @override
  List<Object> get props => [username, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String username;
  final String password;
  final String email;
  final String name;

  const AuthRegisterRequested({
    required this.username,
    required this.password,
    required this.email,
    required this.name,
  });

  @override
  List<Object> get props => [username, password, email, name];
}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested({required this.email});

  @override
  List<Object> get props => [email];
}

class AuthPasswordResetConfirmRequested extends AuthEvent {
  final String token;
  final String code;
  final String newPassword;

  const AuthPasswordResetConfirmRequested({
    required this.token,
    required this.code,
    required this.newPassword,
  });

  @override
  List<Object> get props => [token, code, newPassword];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthStatusChecked extends AuthEvent {
  const AuthStatusChecked();
}

class AuthStateReset extends AuthEvent {
  const AuthStateReset();
}

class PendingWorkoutDetected extends AuthEvent {
  final Map<String, dynamic> pendingWorkout;
  
  const PendingWorkoutDetected({required this.pendingWorkout});
  
  @override
  List<Object> get props => [pendingWorkout];
}

class RestorePendingWorkoutRequested extends AuthEvent {
  final Map<String, dynamic> pendingWorkout;
  
  const RestorePendingWorkoutRequested({required this.pendingWorkout});
  
  @override
  List<Object> get props => [pendingWorkout];
}

class DismissPendingWorkoutRequested extends AuthEvent {
  const DismissPendingWorkoutRequested();
}

class WorkoutCompleted extends AuthEvent {
  const WorkoutCompleted();
}

// ============================================================================
// AUTH STATES
// ============================================================================

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  final String token;

  const AuthAuthenticated({
    required this.user,
    required this.token,
  });

  @override
  List<Object> get props => [user, token];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthLoginSuccess extends AuthState {
  final User user;
  final String token;

  const AuthLoginSuccess({
    required this.user,
    required this.token,
  });

  @override
  List<Object> get props => [user, token];
}

class AuthRegisterSuccess extends AuthState {
  final String message;

  const AuthRegisterSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

class AuthPasswordResetEmailSent extends AuthState {
  final String message;
  final String? token;

  const AuthPasswordResetEmailSent({
    required this.message,
    this.token,
  });

  @override
  List<Object?> get props => [message, token];
}

class AuthPasswordResetSuccess extends AuthState {
  final String message;

  const AuthPasswordResetSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object> get props => [message];
}

class PendingWorkoutPrompt extends AuthState {
  final Map<String, dynamic> pendingWorkout;
  final String message;

  const PendingWorkoutPrompt({
    required this.pendingWorkout,
    required this.message,
  });

  @override
  List<Object> get props => [pendingWorkout, message];
}





// ============================================================================
// AUTH BLOC
// ============================================================================

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  
  // 🔧 FIX: Flag per prevenire chiamate multiple per lo stesso allenamento pending
  bool _isProcessingPendingWorkout = false;
  int? _lastPendingWorkoutId;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {

    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthPasswordResetConfirmRequested>(_onPasswordResetConfirmRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthStatusChecked>(_onStatusChecked);
    on<AuthStateReset>(_onStateReset);
    on<PendingWorkoutDetected>(_onPendingWorkoutDetected);
    on<RestorePendingWorkoutRequested>(_onRestorePendingWorkoutRequested);
    on<DismissPendingWorkoutRequested>(_onDismissPendingWorkoutRequested);
    on<WorkoutCompleted>(_onWorkoutCompleted);
    on<CheckPendingWorkoutAuth>(_onCheckPendingWorkout);
  }

  /// 🌐 NUOVO: Handler per quando viene rilevato un allenamento in sospeso
  Future<void> _onPendingWorkoutDetected(
    PendingWorkoutDetected event,
    Emitter<AuthState> emit,
  ) async {
    final workoutId = event.pendingWorkout['allenamento_id'] as int;
    
    // 🔧 FIX: Prevenisci chiamate multiple per lo stesso allenamento
    if (_isProcessingPendingWorkout && _lastPendingWorkoutId == workoutId) {
      //debugPrint('[CONSOLE] [auth_bloc] ⚠️ Already processing pending workout $workoutId, skipping duplicate call');
      return;
    }
    
    //debugPrint('[CONSOLE] [auth_bloc] 📱 Emitting PendingWorkoutPrompt for workout: $workoutId');
    
    // 🔧 FIX: Reset del flag precedente e marca come in elaborazione
    _isProcessingPendingWorkout = false;
    _lastPendingWorkoutId = null;
    
    // 🔧 FIX: Marca come in elaborazione
    _isProcessingPendingWorkout = true;
    _lastPendingWorkoutId = workoutId;
    
    emit(PendingWorkoutPrompt(
      pendingWorkout: event.pendingWorkout,
      message: 'Hai un allenamento in sospeso. Vuoi riprenderlo?',
    ));
  }

  /// 🌐 NUOVO: Handler per ripristinare l'allenamento in sospeso
  Future<void> _onRestorePendingWorkoutRequested(
    RestorePendingWorkoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    //debugPrint('[CONSOLE] [auth_bloc] 🔄 Restoring pending workout...');
    
    try {
      final activeWorkoutBloc = getIt<ActiveWorkoutBloc>();
      // 🔧 FIX: Usa RestorePendingWorkout invece di RestoreOfflineWorkout
      // Questo evita conflitti con la logica degli allenamenti offline
      activeWorkoutBloc.add(RestorePendingWorkout(event.pendingWorkout));
      
      // Non cambiare lo stato, lascia che l'AuthWrapper gestisca la navigazione
      // Lo stato rimane quello corrente (autenticato)
    } catch (e) {
      //debugPrint('[CONSOLE] [auth_bloc] ❌ Error restoring pending workout: $e');
      emit(AuthError(message: 'Errore nel ripristino dell\'allenamento: $e'));
    }
  }

  /// 🌐 NUOVO: Handler per ignorare l'allenamento in sospeso
  Future<void> _onDismissPendingWorkoutRequested(
    DismissPendingWorkoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    //debugPrint('[CONSOLE] [auth_bloc] ❌ Dismissing pending workout...');
    
    // 🔧 FIX: Reset del flag per permettere nuovi controlli
    _isProcessingPendingWorkout = false;
    _lastPendingWorkoutId = null;
    
    // 🔧 FIX: Emetti AuthInitial per tornare allo stato normale
    // Questo rimuove PendingWorkoutPrompt e permette all'utente di continuare
    emit(const AuthInitial());
  }

  /// 🌐 NUOVO: Handler per quando un allenamento viene completato
  Future<void> _onWorkoutCompleted(
    WorkoutCompleted event,
    Emitter<AuthState> emit,
  ) async {
    //debugPrint('[CONSOLE] [auth_bloc] ✅ Workout completed, clearing PendingWorkoutPrompt state...');
    
    // 🔧 FIX: Reset del flag per permettere nuovi controlli
    _isProcessingPendingWorkout = false;
    _lastPendingWorkoutId = null;
    
    // 🔧 FIX: Emetti AuthInitial per tornare allo stato normale
    // Questo rimuove PendingWorkoutPrompt e permette all'utente di continuare
    emit(const AuthInitial());
  }

  /// 🌐 NUOVO: Handler per controllare allenamenti in sospeso
  Future<void> _onCheckPendingWorkout(
    CheckPendingWorkoutAuth event,
    Emitter<AuthState> emit,
  ) async {
    //debugPrint('[CONSOLE] [auth_bloc] 🔍 Checking pending workout for user: ${event.userId}');
    
    try {
      final activeWorkoutBloc = getIt<ActiveWorkoutBloc>();
      
      // Aggiungi listener temporaneo per gestire lo stato PendingWorkoutFound
      StreamSubscription? subscription;
      subscription = activeWorkoutBloc.stream.listen((state) {
        if (state is PendingWorkoutFound) {
          //debugPrint('[CONSOLE] [auth_bloc] 📱 Pending workout found: ${state.pendingWorkout['allenamento_id']}');
          // Emetti evento per mostrare il prompt all'utente
          add(PendingWorkoutDetected(pendingWorkout: state.pendingWorkout));
          // Cancella il listener dopo averlo usato
          subscription?.cancel();
        }
      });
      
      // Controlla se ci sono allenamenti in sospeso
      activeWorkoutBloc.add(CheckPendingWorkout(event.userId));
      
      //debugPrint('[CONSOLE] [auth_bloc] ✅ Pending workout check initiated');
    } catch (e) {
      //debugPrint('[CONSOLE] [auth_bloc] ❌ Error checking pending workouts: $e');
    }
  }

  /// 🌐 Sincronizza i dati offline dopo un login riuscito
  Future<void> _syncOfflineDataAfterLogin() async {
    try {
      //debugPrint('[CONSOLE] [auth_bloc] 🌐 Syncing offline data after successful login...');
      final globalConnectivity = getIt<GlobalConnectivityService>();
      await globalConnectivity.forceSync();
      //debugPrint('[CONSOLE] [auth_bloc] ✅ Offline data sync completed after login');
    } catch (e) {
      //debugPrint('[CONSOLE] [auth_bloc] ❌ Error syncing offline data after login: $e');
    }
  }

  /// 🔥 Registra token FCM per l'utente dopo login riuscito
  Future<void> _registerFCMTokenAfterLogin(int userId) async {
    try {
      //debugPrint('[CONSOLE] [FCM] 🔥 Registering FCM token for user $userId...');
      final firebaseService = FirebaseService();
      await firebaseService.registerTokenForUser(userId);
      //debugPrint('[CONSOLE] [FCM] ✅ FCM token registered successfully for user $userId');
    } catch (e) {
      //debugPrint('[CONSOLE] [FCM] ❌ Error registering FCM token for user $userId: $e');
    }
  }

  /// 🔥 Pulisce token FCM quando l'utente fa logout
  Future<void> _clearFCMTokenOnLogout(int userId) async {
    try {
      //debugPrint('[CONSOLE] [FCM] 🔥 Clearing FCM token for user $userId...');
      final firebaseService = FirebaseService();
      await firebaseService.clearTokenForUser(userId);
      //debugPrint('[CONSOLE] [FCM] ✅ FCM token cleared successfully for user $userId');
    } catch (e) {
      //debugPrint('[CONSOLE] [FCM] ❌ Error clearing FCM token for user $userId: $e');
    }
  }



  Future<void> _onLoginRequested(
      AuthLoginRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());

    final result = await _authRepository.login(event.username, event.password);

    result.fold(
      onSuccess: (response) {
        if (response.token != null && response.user != null) {
          // 🌐 Sincronizza dati offline dopo login riuscito
          _syncOfflineDataAfterLogin();
          
          // 🔥 Registra token FCM per l'utente
          _registerFCMTokenAfterLogin(response.user!.id);
          
          // 🔧 FIX: Controlla workout pending automaticamente dopo login
          Future.delayed(const Duration(milliseconds: 500), () {
            add(CheckPendingWorkoutAuth(response.user!.id));
          });
          
          emit(AuthLoginSuccess(
            user: response.user!,
            token: response.token!,
          ));
        } else {
          final errorMessage = response.error ?? response.message;
          emit(AuthError(message: errorMessage.isNotEmpty ? errorMessage : "Errore sconosciuto"));
        }
      },
      onFailure: (exception, message) {
        emit(AuthError(message: message ?? exception?.toString() ?? "Errore sconosciuto"));
      },
    );
  }

  Future<void> _onRegisterRequested(
      AuthRegisterRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());

    final result = await _authRepository.register(
      event.username,
      event.password,
      event.email,
      event.name,
    );

    result.fold(
      onSuccess: (response) {
        if (response.success) {
          emit(AuthRegisterSuccess(message: response.message));
        } else {
          final errorMessage = response.message.isNotEmpty
              ? response.message
              : "Si è verificato un errore durante la registrazione";
          emit(AuthError(message: errorMessage));
        }
      },
      onFailure: (exception, message) {
        emit(AuthError(message: message ?? exception?.toString() ?? "Errore sconosciuto"));
      },
    );
  }

  Future<void> _onPasswordResetRequested(
      AuthPasswordResetRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());

    final result = await _authRepository.requestPasswordReset(event.email);

    result.fold(
      onSuccess: (response) {
        if (response.success) {
          emit(AuthPasswordResetEmailSent(
            message: response.message,
            token: response.token,
          ));
        } else {
          emit(AuthError(message: response.message));
        }
      },
      onFailure: (exception, message) {
        emit(AuthError(message: message ?? exception?.toString() ?? "Errore sconosciuto"));
      },
    );
  }

  Future<void> _onPasswordResetConfirmRequested(
      AuthPasswordResetConfirmRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());

    final result = await _authRepository.confirmPasswordReset(
      event.token,
      event.code,
      event.newPassword,
    );

    result.fold(
      onSuccess: (response) {
        if (response.success) {
          emit(AuthPasswordResetSuccess(message: response.message));
        } else {
          emit(AuthError(message: response.message));
        }
      },
      onFailure: (exception, message) {
        emit(AuthError(message: message ?? exception?.toString() ?? "Errore sconosciuto"));
      },
    );
  }

  Future<void> _onLogoutRequested(
      AuthLogoutRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());

    // 🔥 Pulisci token FCM prima del logout
    try {
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser != null) {
        await _clearFCMTokenOnLogout(currentUser.id);
      }
    } catch (e) {
      //debugPrint('[CONSOLE] [FCM] ❌ Error clearing FCM token during logout: $e');
    }


    final result = await _authRepository.logout();

    result.fold(
      onSuccess: (_) {
        emit(const AuthUnauthenticated());
      },
      onFailure: (exception, message) {
        emit(const AuthUnauthenticated());
      },
    );
  }

  Future<void> _onStatusChecked(
      AuthStatusChecked event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());

    try {
      //debugPrint('[CONSOLE] [auth_bloc]🔍 Checking authentication status...');
      
      // 🔧 FIX: Prima controlla se c'è un token salvato
      final hasToken = await _authRepository.sessionService.isAuthenticated();
      if (!hasToken) {
        //debugPrint('[CONSOLE] [auth_bloc]❌ No token found, user not authenticated');
        emit(const AuthUnauthenticated());
        return;
      }

      // 🔧 FIX: Valida il token con il server (sempre, per sicurezza)
      //debugPrint('[CONSOLE] [auth_bloc]🌐 Validating token with server...');
      final isValid = await _authRepository.sessionService.validateTokenWithServer();
      
      if (isValid) {
        // Token valido, recupera i dati utente
        final user = await _authRepository.getCurrentUser();
        final token = await _authRepository.sessionService.getAuthToken();

        if (user != null && token != null) {
          //debugPrint('[CONSOLE] [auth_bloc]✅ Token valid, user authenticated: ${user.username}');
          
          // 🔥 Registra token FCM per l'utente già autenticato
          _registerFCMTokenAfterLogin(user.id);
          
          // 🔧 FIX: Controlla workout pending anche per token già validi
          Future.delayed(const Duration(milliseconds: 500), () {
            add(CheckPendingWorkoutAuth(user.id));
          });
          
          emit(AuthAuthenticated(user: user, token: token));
        } else {
          //debugPrint('[CONSOLE] [auth_bloc]❌ User data missing, clearing session');
          await _authRepository.sessionService.clearSession();
          emit(const AuthUnauthenticated());
        }
      } else {
        // Token scaduto o invalido, pulisci la sessione
        //debugPrint('[CONSOLE] [auth_bloc]❌ Token invalid/expired, clearing session');
        await _authRepository.sessionService.clearSession();
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      //debugPrint('[CONSOLE] [auth_bloc]❌ Authentication check failed: $e');
      // In caso di errore, pulisci la sessione per sicurezza
      try {
        await _authRepository.sessionService.clearSession();
      } catch (clearError) {
        //debugPrint('[CONSOLE] [auth_bloc]❌ Error clearing session: $clearError');
      }
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onStateReset(
      AuthStateReset event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthInitial());
  }

  void resetState() {
    add(const AuthStateReset());
  }

  void checkAuthStatus() {
    add(const AuthStatusChecked());
  }

  void login(String username, String password) {
    add(AuthLoginRequested(username: username, password: password));
  }

  void register(String username, String password, String email, String name) {
    add(AuthRegisterRequested(
      username: username,
      password: password,
      email: email,
      name: name,
    ));
  }

  void requestPasswordReset(String email) {
    add(AuthPasswordResetRequested(email: email));
  }

  void confirmPasswordReset(String token, String code, String newPassword) {
    add(AuthPasswordResetConfirmRequested(
      token: token,
      code: code,
      newPassword: newPassword,
    ));
  }

  void logout() {
    add(const AuthLogoutRequested());
  }
}

// ============================================================================
// SEPARATE BLOCS FOR SPECIFIC FLOWS
// ============================================================================

class RegisterBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  RegisterBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {

    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthStateReset>(_onStateReset);
  }

  Future<void> _onRegisterRequested(
      AuthRegisterRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());

    final result = await _authRepository.register(
      event.username,
      event.password,
      event.email,
      event.name,
    );

    result.fold(
      onSuccess: (response) {
        if (response.success) {
          emit(AuthRegisterSuccess(message: response.message));
        } else {
          final errorMessage = response.message.isNotEmpty
              ? response.message
              : "Si è verificato un errore durante la registrazione";
          emit(AuthError(message: errorMessage));
        }
      },
      onFailure: (exception, message) {
        emit(AuthError(message: message ?? exception?.toString() ?? "Errore sconosciuto"));
      },
    );
  }

  Future<void> _onStateReset(
      AuthStateReset event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthInitial());
  }

  void register(String username, String password, String email, String name) {
    add(AuthRegisterRequested(
      username: username,
      password: password,
      email: email,
      name: name,
    ));
  }

  void resetState() {
    add(const AuthStateReset());
  }
}

/// 🌐 NUOVO: Estensione per AuthBloc con metodo checkPendingWorkout
extension AuthBlocExtension on AuthBloc {
  void checkPendingWorkout(int userId) {
    //debugPrint('[CONSOLE] [auth_bloc] 🔍 Public check for pending workouts for user: $userId');
    add(CheckPendingWorkoutAuth(userId));
  }
}

/// 🌐 NUOVO: Evento per controllare allenamenti in sospeso
class CheckPendingWorkoutAuth extends AuthEvent {
  final int userId;
  
  const CheckPendingWorkoutAuth(this.userId);
  
  @override
  List<Object> get props => [userId];
}

class PasswordResetBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  PasswordResetBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {

    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthPasswordResetConfirmRequested>(_onPasswordResetConfirmRequested);
    on<AuthStateReset>(_onStateReset);
  }

  Future<void> _onPasswordResetRequested(
      AuthPasswordResetRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());

    final result = await _authRepository.requestPasswordReset(event.email);

    result.fold(
      onSuccess: (response) {
        if (response.success) {
          emit(AuthPasswordResetEmailSent(
            message: response.message,
            token: response.token,
          ));
        } else {
          emit(AuthError(message: response.message));
        }
      },
      onFailure: (exception, message) {
        emit(AuthError(message: message ?? exception?.toString() ?? "Errore sconosciuto"));
      },
    );
  }

  Future<void> _onPasswordResetConfirmRequested(
      AuthPasswordResetConfirmRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());

    final result = await _authRepository.confirmPasswordReset(
      event.token,
      event.code,
      event.newPassword,
    );

    result.fold(
      onSuccess: (response) {
        if (response.success) {
          emit(AuthPasswordResetSuccess(message: response.message));
        } else {
          emit(AuthError(message: response.message));
        }
      },
      onFailure: (exception, message) {
        emit(AuthError(message: message ?? exception?.toString() ?? "Errore sconosciuto"));
      },
    );
  }

  Future<void> _onStateReset(
      AuthStateReset event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthInitial());
  }

  void requestPasswordReset(String email) {
    add(AuthPasswordResetRequested(email: email));
  }

  void confirmPasswordReset(String token, String code, String newPassword) {
    add(AuthPasswordResetConfirmRequested(
      token: token,
      code: code,
      newPassword: newPassword,
    ));
  }

  void resetState() {
    add(const AuthStateReset());
  }
}