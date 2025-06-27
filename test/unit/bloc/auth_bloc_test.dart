import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:fitgymtrack/features/auth/bloc/auth_bloc.dart';
import 'package:fitgymtrack/features/auth/repository/auth_repository.dart';
import 'package:fitgymtrack/features/auth/models/login_response.dart';
import 'package:fitgymtrack/features/auth/models/register_response.dart';
import 'package:fitgymtrack/core/utils/result.dart';

import 'auth_bloc_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  group('🧪 AuthBloc Tests', () {
    late MockAuthRepository mockAuthRepository;
    late AuthBloc authBloc;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      authBloc = AuthBloc(authRepository: mockAuthRepository);
    });

    tearDown(() {
      authBloc.close();
    });

    group('Login', () {
      final loginResponse = LoginResponse(
        success: true,
        message: 'Login ok',
        token: 'test_token',
        user: User(
          id: 1,
          username: 'test_user',
          email: 'test@example.com',
          name: null,
          roleId: 1,
          roleName: 'user',
          trainer: null,
        ),
      );

      blocTest<AuthBloc, AuthState>(
        '✅ Emette [AuthLoading, AuthLoginSuccess] quando il login ha successo',
        build: () {
          when(mockAuthRepository.login('test_user', 'TestPassword123!'))
              .thenAnswer((_) async => Result.success(loginResponse));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthLoginRequested(
          username: 'test_user',
          password: 'TestPassword123!',
        )),
        expect: () => [
          const AuthLoading(),
          AuthLoginSuccess(
            user: loginResponse.user!,
            token: loginResponse.token!,
          ),
        ],
        verify: (_) {
          verify(mockAuthRepository.login('test_user', 'TestPassword123!')).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        '❌ Emette [AuthLoading, AuthError] quando il login fallisce',
        build: () {
          when(mockAuthRepository.login('test_user', 'wrong_password'))
              .thenAnswer((_) async => Result.error('Login failed', AuthException('Login failed')));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthLoginRequested(
          username: 'test_user',
          password: 'wrong_password',
        )),
        expect: () => [
          const AuthLoading(),
          const AuthError(message: 'Login failed'),
        ],
        verify: (_) {
          verify(mockAuthRepository.login('test_user', 'wrong_password')).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        '❌ Emette [AuthLoading, AuthError] quando il login lancia eccezione',
        build: () {
          when(mockAuthRepository.login('test_user', 'error_password'))
              .thenAnswer((_) async => Result.error('Network error', Exception('Network error')));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthLoginRequested(
          username: 'test_user',
          password: 'error_password',
        )),
        expect: () => [
          const AuthLoading(),
          const AuthError(message: 'Network error'),
        ],
        verify: (_) {
          verify(mockAuthRepository.login('test_user', 'error_password')).called(1);
        },
      );
    });

    group('Register', () {
      final registerResponse = RegisterResponse(
        success: true,
        message: 'Registrazione ok',
        userId: 2,
      );

      blocTest<AuthBloc, AuthState>(
        '✅ Emette [AuthLoading, AuthRegisterSuccess] quando la registrazione ha successo',
        build: () {
          when(mockAuthRepository.register('new_user', 'NewPassword123!', 'new@example.com', 'New User'))
              .thenAnswer((_) async => Result.success(registerResponse));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthRegisterRequested(
          username: 'new_user',
          password: 'NewPassword123!',
          email: 'new@example.com',
          name: 'New User',
        )),
        expect: () => [
          const AuthLoading(),
          AuthRegisterSuccess(message: 'Registrazione ok'),
        ],
        verify: (_) {
          verify(mockAuthRepository.register('new_user', 'NewPassword123!', 'new@example.com', 'New User')).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        '❌ Emette [AuthLoading, AuthError] quando la registrazione fallisce',
        build: () {
          when(mockAuthRepository.register('new_user', 'NewPassword123!', 'new@example.com', 'New User'))
              .thenAnswer((_) async => Result.error('Registration failed', AuthException('Registration failed')));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthRegisterRequested(
          username: 'new_user',
          password: 'NewPassword123!',
          email: 'new@example.com',
          name: 'New User',
        )),
        expect: () => [
          const AuthLoading(),
          const AuthError(message: 'Registration failed'),
        ],
        verify: (_) {
          verify(mockAuthRepository.register('new_user', 'NewPassword123!', 'new@example.com', 'New User')).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        '❌ Emette [AuthLoading, AuthError] quando la registrazione lancia eccezione',
        build: () {
          when(mockAuthRepository.register('new_user', 'NewPassword123!', 'new@example.com', 'New User'))
              .thenAnswer((_) async => Result.error('Network error', Exception('Network error')));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthRegisterRequested(
          username: 'new_user',
          password: 'NewPassword123!',
          email: 'new@example.com',
          name: 'New User',
        )),
        expect: () => [
          const AuthLoading(),
          const AuthError(message: 'Network error'),
        ],
        verify: (_) {
          verify(mockAuthRepository.register('new_user', 'NewPassword123!', 'new@example.com', 'New User')).called(1);
        },
      );
    });

    group('Logout', () {
      blocTest<AuthBloc, AuthState>(
        '✅ Emette [AuthLoading, AuthUnauthenticated] quando il logout ha successo',
        build: () {
          when(mockAuthRepository.logout())
              .thenAnswer((_) async => Result.success(null));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthLogoutRequested()),
        expect: () => [
          const AuthLoading(),
          const AuthUnauthenticated(),
        ],
        verify: (_) {
          verify(mockAuthRepository.logout()).called(1);
        },
      );
    });
  });
} 