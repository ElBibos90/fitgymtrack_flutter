// lib/features/profile/bloc/profile_bloc.dart
// 🔧 FIXED: Null safety issues resolved

import 'dart:developer';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/user_profile_models.dart';
import '../repository/profile_repository.dart';

// ============================================================================
// EVENTS
// ============================================================================

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserProfile extends ProfileEvent {
  final int? userId; // null = current user

  const LoadUserProfile({this.userId});

  @override
  List<Object?> get props => [userId];
}

class UpdateUserProfile extends ProfileEvent {
  final UserProfile profile;
  final int? userId; // null = current user

  const UpdateUserProfile({
    required this.profile,
    this.userId,
  });

  @override
  List<Object?> get props => [profile, userId];
}

class CreateDefaultProfile extends ProfileEvent {
  final int userId;

  const CreateDefaultProfile({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class ResetProfileState extends ProfileEvent {
  const ResetProfileState();
}

// ============================================================================
// STATES
// ============================================================================

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  final String? message;

  const ProfileLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class ProfileLoaded extends ProfileState {
  final UserProfile profile;
  final bool isCurrentUser;

  const ProfileLoaded({
    required this.profile,
    this.isCurrentUser = true,
  });

  @override
  List<Object?> get props => [profile, isCurrentUser];

  ProfileLoaded copyWith({
    UserProfile? profile,
    bool? isCurrentUser,
  }) {
    return ProfileLoaded(
      profile: profile ?? this.profile,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }
}

class ProfileUpdating extends ProfileState {
  final UserProfile currentProfile;

  const ProfileUpdating({required this.currentProfile});

  @override
  List<Object?> get props => [currentProfile];
}

class ProfileUpdateSuccess extends ProfileState {
  final UserProfile profile;
  final String message;

  const ProfileUpdateSuccess({
    required this.profile,
    required this.message,
  });

  @override
  List<Object?> get props => [profile, message];
}

class ProfileError extends ProfileState {
  final String message;
  final Exception? exception;

  const ProfileError({
    required this.message,
    this.exception,
  });

  @override
  List<Object?> get props => [message, exception];
}

// ============================================================================
// BLOC
// ============================================================================

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _repository;

  ProfileBloc({required ProfileRepository repository})
      : _repository = repository,
        super(const ProfileInitial()) {

    log('[CONSOLE] [profile_bloc] 🏗️ ProfileBloc initialized');

    on<LoadUserProfile>(_onLoadUserProfile);
    on<UpdateUserProfile>(_onUpdateUserProfile);
    on<CreateDefaultProfile>(_onCreateDefaultProfile);
    on<ResetProfileState>(_onResetProfileState);
  }

  /// Carica il profilo utente
  Future<void> _onLoadUserProfile(
      LoadUserProfile event,
      Emitter<ProfileState> emit,
      ) async {
    log('[CONSOLE] [profile_bloc] 📡 Loading user profile${event.userId != null ? ' for user ${event.userId}' : ' for current user'}');

    emit(const ProfileLoading(message: 'Caricamento profilo...'));

    try {
      final result = await _repository.getUserProfile(userId: event.userId);

      result.fold(
        onSuccess: (profile) {
          log('[CONSOLE] [profile_bloc] ✅ Profile loaded successfully for user ${profile.userId}');
          emit(ProfileLoaded(
            profile: profile,
            isCurrentUser: event.userId == null,
          ));
        },
        onFailure: (exception, message) {
          log('[CONSOLE] [profile_bloc] ❌ Error loading profile: $message');
          // 🔧 FIX: Handle nullable message
          emit(ProfileError(
            message: message ?? 'Errore nel caricamento del profilo',
            exception: exception,
          ));
        },
      );
    } catch (e, stackTrace) {
      log('[CONSOLE] [profile_bloc] ❌ Unexpected error loading profile: $e');
      log('[CONSOLE] [profile_bloc] ❌ Stack trace: $stackTrace');
      emit(ProfileError(
        message: 'Errore imprevisto nel caricamento del profilo',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Aggiorna il profilo utente
  Future<void> _onUpdateUserProfile(
      UpdateUserProfile event,
      Emitter<ProfileState> emit,
      ) async {
    log('[CONSOLE] [profile_bloc] 📡 Updating user profile for user ${event.profile.userId}');

    // Mantieni il profilo corrente durante l'aggiornamento
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(ProfileUpdating(currentProfile: currentState.profile));
    } else {
      emit(ProfileUpdating(currentProfile: event.profile));
    }

    try {
      final result = await _repository.updateUserProfile(
        profile: event.profile,
        userId: event.userId,
      );

      result.fold(
        onSuccess: (updatedProfile) {
          log('[CONSOLE] [profile_bloc] ✅ Profile updated successfully');

          // Prima emetti il successo temporaneo
          emit(ProfileUpdateSuccess(
            profile: updatedProfile,
            message: 'Profilo aggiornato con successo',
          ));

          // Poi torna allo stato normale loaded
          emit(ProfileLoaded(
            profile: updatedProfile,
            isCurrentUser: event.userId == null,
          ));
        },
        onFailure: (exception, message) {
          log('[CONSOLE] [profile_bloc] ❌ Error updating profile: $message');
          // 🔧 FIX: Handle nullable message
          emit(ProfileError(
            message: message ?? 'Errore nell\'aggiornamento del profilo',
            exception: exception,
          ));
        },
      );
    } catch (e, stackTrace) {
      log('[CONSOLE] [profile_bloc] ❌ Unexpected error updating profile: $e');
      log('[CONSOLE] [profile_bloc] ❌ Stack trace: $stackTrace');
      emit(ProfileError(
        message: 'Errore imprevisto nell\'aggiornamento del profilo',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Crea un profilo predefinito
  Future<void> _onCreateDefaultProfile(
      CreateDefaultProfile event,
      Emitter<ProfileState> emit,
      ) async {
    log('[CONSOLE] [profile_bloc] 📡 Creating default profile for user ${event.userId}');

    emit(const ProfileLoading(message: 'Creazione profilo predefinito...'));

    try {
      final result = await _repository.createDefaultProfile(event.userId);

      result.fold(
        onSuccess: (profile) {
          log('[CONSOLE] [profile_bloc] ✅ Default profile created successfully');
          emit(ProfileLoaded(
            profile: profile,
            isCurrentUser: true,
          ));
        },
        onFailure: (exception, message) {
          log('[CONSOLE] [profile_bloc] ❌ Error creating default profile: $message');
          // 🔧 FIX: Handle nullable message
          emit(ProfileError(
            message: message ?? 'Errore nella creazione del profilo',
            exception: exception,
          ));
        },
      );
    } catch (e, stackTrace) {
      log('[CONSOLE] [profile_bloc] ❌ Unexpected error creating default profile: $e');
      log('[CONSOLE] [profile_bloc] ❌ Stack trace: $stackTrace');
      emit(ProfileError(
        message: 'Errore imprevisto nella creazione del profilo',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Reset dello stato
  void _onResetProfileState(
      ResetProfileState event,
      Emitter<ProfileState> emit,
      ) {
    log('[CONSOLE] [profile_bloc] 🔄 Resetting profile state');
    emit(const ProfileInitial());
  }

  /// Metodi helper per accesso rapido

  /// Ottiene il profilo corrente se disponibile
  UserProfile? get currentProfile {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      return currentState.profile;
    } else if (currentState is ProfileUpdating) {
      return currentState.currentProfile;
    } else if (currentState is ProfileUpdateSuccess) {
      return currentState.profile;
    }
    return null;
  }

  /// Verifica se un profilo è caricato
  bool get isProfileLoaded => state is ProfileLoaded;

  /// Verifica se è in corso un aggiornamento
  bool get isUpdating => state is ProfileUpdating;

  /// Verifica se c'è un errore
  bool get hasError => state is ProfileError;

  /// Ottiene il messaggio di errore se presente
  String? get errorMessage {
    final currentState = state;
    return currentState is ProfileError ? currentState.message : null;
  }
}