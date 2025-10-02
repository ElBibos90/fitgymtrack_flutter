// lib/features/notifications/bloc/notification_bloc.dart

import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import '../models/notification_models.dart';
import '../repositories/notification_repository.dart';

// ============================================================================
// EVENTS
// ============================================================================

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotificationsEvent extends NotificationEvent {
  final int page;
  final bool refresh;

  const LoadNotificationsEvent({
    this.page = 1,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [page, refresh];
}

class MarkAsReadEvent extends NotificationEvent {
  final int notificationId;

  const MarkAsReadEvent(this.notificationId);

  @override
  List<Object> get props => [notificationId];
}

class SendNotificationEvent extends NotificationEvent {
  final SendNotificationRequest request;

  const SendNotificationEvent(this.request);

  @override
  List<Object> get props => [request];
}

class LoadSentNotificationsEvent extends NotificationEvent {
  final int page;
  final bool refresh;

  const LoadSentNotificationsEvent({
    this.page = 1,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [page, refresh];
}

class RefreshUnreadCountEvent extends NotificationEvent {
  const RefreshUnreadCountEvent();
}

class ClearNotificationsEvent extends NotificationEvent {
  const ClearNotificationsEvent();
}

// ============================================================================
// STATES
// ============================================================================

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationLoaded extends NotificationState {
  final List<Notification> notifications;
  final int unreadCount;
  final NotificationPagination? pagination;
  final bool hasReachedMax;

  const NotificationLoaded({
    required this.notifications,
    required this.unreadCount,
    this.pagination,
    this.hasReachedMax = false,
  });

  @override
  List<Object?> get props => [notifications, unreadCount, pagination, hasReachedMax];

  NotificationLoaded copyWith({
    List<Notification>? notifications,
    int? unreadCount,
    NotificationPagination? pagination,
    bool? hasReachedMax,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      pagination: pagination ?? this.pagination,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }
}

class SentNotificationsLoaded extends NotificationState {
  final List<Notification> notifications;
  final NotificationPagination? pagination;
  final bool hasReachedMax;

  const SentNotificationsLoaded({
    required this.notifications,
    this.pagination,
    this.hasReachedMax = false,
  });

  @override
  List<Object?> get props => [notifications, pagination, hasReachedMax];

  SentNotificationsLoaded copyWith({
    List<Notification>? notifications,
    NotificationPagination? pagination,
    bool? hasReachedMax,
  }) {
    return SentNotificationsLoaded(
      notifications: notifications ?? this.notifications,
      pagination: pagination ?? this.pagination,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError(this.message);

  @override
  List<Object> get props => [message];
}

class NotificationSent extends NotificationState {
  final String message;

  const NotificationSent(this.message);

  @override
  List<Object> get props => [message];
}

class NotificationMarkedAsRead extends NotificationState {
  final int notificationId;

  const NotificationMarkedAsRead(this.notificationId);

  @override
  List<Object> get props => [notificationId];
}

// ============================================================================
// BLOC
// ============================================================================

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repository;
  static const MethodChannel _badgeChannel = MethodChannel('flutter_badge_channel');

  NotificationBloc({required NotificationRepository repository})
      : _repository = repository,
        super(const NotificationInitial()) {
    
    on<LoadNotificationsEvent>(_onLoadNotifications);
    on<MarkAsReadEvent>(_onMarkAsRead);
    on<SendNotificationEvent>(_onSendNotification);
    on<LoadSentNotificationsEvent>(_onLoadSentNotifications);
    on<RefreshUnreadCountEvent>(_onRefreshUnreadCount);
    on<ClearNotificationsEvent>(_onClearNotifications);
  }

  /// Carica le notifiche dell'utente
  Future<void> _onLoadNotifications(
    LoadNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      if (event.refresh || state is NotificationInitial) {
        emit(const NotificationLoading());
      }

      final response = await _repository.getUserNotifications(
        page: event.page,
        limit: 20,
      );

      if (response.success) {
        final notifications = response.notifications;
        final unreadCount = notifications.where((n) => n.isUnread).length;
        
        if (event.page == 1 || state is NotificationInitial) {
          emit(NotificationLoaded(
            notifications: notifications,
            unreadCount: unreadCount,
            pagination: response.pagination,
            hasReachedMax: notifications.length < 20,
          ));
          
          // Aggiorna badge iOS
          await _updateiOSBadge(unreadCount);
        } else if (state is NotificationLoaded) {
          final currentState = state as NotificationLoaded;
          final updatedNotifications = [
            ...currentState.notifications,
            ...notifications,
          ];
          
          final newUnreadCount = updatedNotifications.where((n) => n.isUnread).length;
          
          emit(currentState.copyWith(
            notifications: updatedNotifications,
            unreadCount: newUnreadCount,
            pagination: response.pagination,
            hasReachedMax: notifications.length < 20,
          ));
          
          // Aggiorna badge iOS
          await _updateiOSBadge(newUnreadCount);
        }
      } else {
        emit(const NotificationError('Errore nel caricamento delle notifiche'));
      }
    } catch (e) {
      emit(NotificationError('Errore: ${e.toString()}'));
    }
  }

  /// Marca una notifica come letta
  Future<void> _onMarkAsRead(
    MarkAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repository.markAsRead(event.notificationId);

      if (state is NotificationLoaded) {
        final currentState = state as NotificationLoaded;
        final updatedNotifications = currentState.notifications.map((notification) {
          if (notification.id == event.notificationId) {
            return Notification(
              id: notification.id,
              title: notification.title,
              message: notification.message,
              type: notification.type,
              priority: notification.priority,
              status: 'read',
              createdAt: notification.createdAt,
              readAt: DateTime.now().toIso8601String(),
              isBroadcast: notification.isBroadcast,
              senderName: notification.senderName,
              senderUsername: notification.senderUsername,
            );
          }
          return notification;
        }).toList();

        final unreadCount = updatedNotifications.where((n) => n.isUnread).length;

        emit(currentState.copyWith(
          notifications: updatedNotifications,
          unreadCount: unreadCount,
        ));

        // Aggiorna badge iOS
        await _updateiOSBadge(unreadCount);
      }
    } catch (e) {
      emit(NotificationError('Errore nel marcare la notifica come letta: ${e.toString()}'));
    }
  }

  /// Invia una notifica
  Future<void> _onSendNotification(
    SendNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final response = await _repository.sendNotification(event.request);

      if (response.success) {
        emit(NotificationSent(response.message));
      } else {
        emit(NotificationError('Errore nell\'invio della notifica'));
      }
    } catch (e) {
      emit(NotificationError('Errore nell\'invio: ${e.toString()}'));
    }
  }

  /// Carica le notifiche inviate
  Future<void> _onLoadSentNotifications(
    LoadSentNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      if (event.refresh) {
        emit(const NotificationLoading());
      }

      final response = await _repository.getSentNotifications(
        page: event.page,
        limit: 20,
      );

      if (response.success) {
        final notifications = response.notifications;
        
        if (event.page == 1) {
          emit(SentNotificationsLoaded(
            notifications: notifications,
            pagination: response.pagination,
            hasReachedMax: notifications.length < 20,
          ));
        } else if (state is SentNotificationsLoaded) {
          final currentState = state as SentNotificationsLoaded;
          final updatedNotifications = [
            ...currentState.notifications,
            ...notifications,
          ];
          
          emit(currentState.copyWith(
            notifications: updatedNotifications,
            pagination: response.pagination,
            hasReachedMax: notifications.length < 20,
          ));
        }
      } else {
        emit(const NotificationError('Errore nel caricamento delle notifiche inviate'));
      }
    } catch (e) {
      emit(NotificationError('Errore: ${e.toString()}'));
    }
  }

  /// Aggiorna il conteggio delle notifiche non lette
  Future<void> _onRefreshUnreadCount(
    RefreshUnreadCountEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final unreadCount = await _repository.getUnreadCount();

      if (state is NotificationLoaded) {
        final currentState = state as NotificationLoaded;
        emit(currentState.copyWith(unreadCount: unreadCount));
      }
    } catch (e) {
      // Non emettiamo errori per il refresh del conteggio
      // per non disturbare l'utente
    }
  }

  /// Pulisce le notifiche
  void _onClearNotifications(
    ClearNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) {
    emit(const NotificationInitial());
  }

  /// Aggiorna il badge iOS con il conteggio notifiche non lette
  Future<void> _updateiOSBadge(int unreadCount) async {
    try {
      // Solo per iOS
      if (Platform.isIOS) {
        //print('[CONSOLE] [NOTIFICATIONS] 📱 Updating iOS badge to: $unreadCount');
        
        // Usa MethodChannel per comunicare con iOS
        await _badgeChannel.invokeMethod('setBadgeCount', {'count': unreadCount});
              
        //print('[CONSOLE] [NOTIFICATIONS] 📱 iOS badge updated successfully to: $unreadCount');
      }
    } catch (e) {
      print('[CONSOLE] [NOTIFICATIONS] ❌ Error updating iOS badge: $e');
    }
  }
}
