import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../repository/auth_repository.dart';
import '../models/login_response.dart';

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

// ============================================================================
// AUTH BLOC
// ============================================================================

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

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
      final isAuthenticated = await _authRepository.isAuthenticated();

      if (isAuthenticated) {
        final user = await _authRepository.getCurrentUser();
        final token = await _authRepository.sessionService.getAuthToken();

        if (user != null && token != null) {
          emit(AuthAuthenticated(user: user, token: token));
        } else {
          emit(const AuthUnauthenticated());
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
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