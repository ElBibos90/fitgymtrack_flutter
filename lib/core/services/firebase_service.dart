// lib/core/services/firebase_service.dart

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/dio_client.dart';
import '../../features/notifications/bloc/notification_bloc.dart';
import '../../core/navigation/navigator_key.dart';
import '../../core/di/dependency_injection.dart';
import '../../features/auth/models/login_response.dart';
import '../../features/auth/bloc/auth_bloc.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  late FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Inizializza Firebase
  Future<void> initialize() async {
    try {
      // Inizializza Firebase Core
      await Firebase.initializeApp();
      
      // Inizializza Firebase Messaging dopo Firebase.initializeApp()
      _messaging = FirebaseMessaging.instance;
      
      // Configura notifiche locali
      await _setupLocalNotifications();
      
      // Configura Firebase Messaging
      await _setupFirebaseMessaging();
      
      // Ottieni e salva FCM token
      await _getFCMToken();
      
      if (kDebugMode) {
        //debugPrint('[CONSOLE] [FCM] 🔥 Firebase initialized successfully');
        //debugPrint('[CONSOLE] [FCM] 📱 FCM Token: $_fcmToken');
      }
    } catch (e) {
      if (kDebugMode) {
        //debugPrint('[CONSOLE] [FCM] ❌ Firebase initialization error: $e');
      }
      rethrow;
    }
  }

  /// Configura notifiche locali
  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Configura Firebase Messaging
  Future<void> _setupFirebaseMessaging() async {
    // Richiedi permessi
    await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      //debugPrint('[CONSOLE] [FCM] 📱 Notification permission requested');
    }

    // 🔥 NUOVO: Listener per refresh automatico token FCM
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      if (kDebugMode) {
        //debugPrint('[CONSOLE] [FCM] 🔄 Token refreshed automatically: ${newToken.substring(0, 20)}...');
      }
      
      // Aggiorna token locale
      _fcmToken = newToken;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', newToken);
      
      // Registra nuovo token se utente è loggato
      try {
        final currentUser = await _getCurrentUser();
        if (currentUser != null) {
          await registerTokenForUser(currentUser.id);
          if (kDebugMode) {
            //debugPrint('[CONSOLE] [FCM] ✅ New token registered for user ${currentUser.id}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          //debugPrint('[CONSOLE] [FCM] ❌ Error registering refreshed token: $e');
        }
      }
    });

    // Gestisci notifiche in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    
    // Avvia un timer per controllare le notifiche in foreground (iOS e Android)
    _startForegroundChecker();

    // Gestisci notifiche quando app è in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Gestisci notifiche quando app è chiusa
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
  }

  /// Ottiene e salva FCM token (solo localmente, non al server)
  Future<void> _getFCMToken() async {
    try {
      if (kDebugMode) {
        //debugPrint('[CONSOLE] [FCM] 📱 Attempting to get FCM token...');
      }
      
      // Prova a ottenere l'FCM token direttamente
      _fcmToken = await _messaging.getToken();
      
      if (_fcmToken != null) {
        // Salva token localmente
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
        
        if (kDebugMode) {
          //debugPrint('[CONSOLE] [FCM] 📱 FCM Token obtained and saved locally');
          //debugPrint('[CONSOLE] [FCM] 📱 Token: ${_fcmToken!.substring(0, 20)}...');
        }
      } else {
        if (kDebugMode) {
          //debugPrint('[CONSOLE] [FCM] ❌ FCM token is null');
        }
        
        // Su iOS, se l'FCM token è null, proviamo a ottenere l'APNs token
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          if (kDebugMode) {
            //debugPrint('[CONSOLE] [FCM] 📱 Trying to get APNs token for iOS...');
          }
          
          final apnsToken = await _messaging.getAPNSToken();
          if (apnsToken != null) {
            if (kDebugMode) {
              //debugPrint('[CONSOLE] [FCM] 📱 APNs token obtained, retrying FCM token...');
            }
            
            // Aspetta un po' e riprova l'FCM token
            await Future.delayed(const Duration(seconds: 2));
            _fcmToken = await _messaging.getToken();
            
            if (_fcmToken != null) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('fcm_token', _fcmToken!);
              if (kDebugMode) {
                //debugPrint('[CONSOLE] [FCM] 📱 FCM Token obtained after APNs token');
              }
            }
          } else {
            if (kDebugMode) {
              //debugPrint('[CONSOLE] [FCM] ❌ APNs token also null');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        //debugPrint('[CONSOLE] [FCM] ❌ Error getting FCM token: $e');
      }
    }
  }

  /// Invia FCM token al server (solo quando utente è loggato)
  Future<void> registerTokenForUser(int userId) async {
    try {
      if (_fcmToken == null) {
        // Se non abbiamo il token, proviamo a ottenerlo
        await _getFCMToken();
      }
      
      if (_fcmToken != null) {
        final dio = DioClient.getInstance();
        await dio.post(
          'https://fitgymtrack.com/api/firebase/register_token.php',
          data: {
            'fcm_token': _fcmToken!,
            'platform': defaultTargetPlatform.name,
            // ❌ RIMOSSO: user_id non più necessario (preso dal JWT token)
          },
        );
        
        if (kDebugMode) {
          //debugPrint('[CONSOLE] [FCM] 📱 FCM Token registered for user $userId');
        }
      } else {
        if (kDebugMode) {
          //debugPrint('[CONSOLE] [FCM] ⚠️ Cannot register token - FCM token is null');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        //debugPrint('[CONSOLE] [FCM] ❌ Error registering token for user $userId: $e');
      }
    }
  }

  /// Gestisce notifiche in foreground
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      //debugPrint('[CONSOLE] [FCM] 📱 Foreground message received: ${message.notification?.title}');
      //debugPrint('[CONSOLE] [FCM] 📱 Message data: ${message.data}');
      //debugPrint('[CONSOLE] [FCM] 📱 Platform: ${defaultTargetPlatform}');
    }

    // Mostra notifica locale
    _showLocalNotification(message);
    
    // Aggiorna il BLoC delle notifiche
    if (kDebugMode) {
      //debugPrint('[CONSOLE] [FCM] 📱 Calling _updateNotificationBlocImmediate...');
    }
    
    // Forza aggiornamento immediato del BLoC
    _updateNotificationBlocImmediate();
  }

  /// Gestisce notifiche in background
  void _handleBackgroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      //debugPrint('[CONSOLE] [FCM] 📱 Background message received: ${message.notification?.title}');
    }

    // Naviga alla schermata notifiche
    _navigateToNotifications();
    
    // Aggiorna il BLoC delle notifiche
    if (kDebugMode) {
      //debugPrint('[CONSOLE] [FCM] 📱 Calling _updateNotificationBloc...');
    }
    _updateNotificationBloc();
  }

  /// Mostra notifica locale
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'fitgymtrack_notifications',
      'FitGymTrack Notifications',
      channelDescription: 'Notifiche da FitGymTrack',
      importance: Importance.max,
      priority: Priority.high,
      groupKey: 'fitgymtrack_group',
      setAsGroupSummary: false,
      autoCancel: true,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    
    if (kDebugMode) {
      //debugPrint('[CONSOLE] [FCM] 📱 Showing local notification with ID: $notificationId');
      //debugPrint('[CONSOLE] [FCM] 📱 Title: ${message.notification?.title}');
      //debugPrint('[CONSOLE] [FCM] 📱 Body: ${message.notification?.body}');
    }
    
    await _localNotifications.show(
      notificationId,
      message.notification?.title ?? 'FitGymTrack',
      message.notification?.body ?? '',
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  /// Gestisce tap su notifica
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      //debugPrint('[CONSOLE] [FCM] 📱 Notification tapped: ${response.payload}');
    }

    // Naviga alla schermata notifiche
    _navigateToNotifications();
  }

  /// Naviga alla schermata notifiche
  void _navigateToNotifications() {
    // TODO: Implementare navigazione con GoRouter
    // GoRouter.of(context).go('/notifications');
  }

  /// Aggiorna il BLoC delle notifiche
  void _updateNotificationBloc() {
    try {
      if (kDebugMode) {
        //debugPrint('[CONSOLE] [FCM] 📱 _updateNotificationBloc called');
      }
      
      // SOLUZIONE ALTERNATIVA: Usa GetIt per ottenere il BLoC direttamente
      final notificationBloc = getIt<NotificationBloc>();
      if (kDebugMode) {
        //debugPrint('[CONSOLE] [FCM] 📱 BLoC obtained from GetIt');
      }
      
      if (notificationBloc != null) {
        if (kDebugMode) {
          //debugPrint('[CONSOLE] [FCM] 📱 Adding LoadNotificationsEvent...');
        }
        notificationBloc.add(const LoadNotificationsEvent());
        if (kDebugMode) {
          //debugPrint('[CONSOLE] [FCM] 📱 Notification BLoC updated successfully');
        }
      } else {
        if (kDebugMode) {
          //debugPrint('[CONSOLE] [FCM] ❌ BLoC is null, cannot update');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        //debugPrint('[CONSOLE] [FCM] ❌ Error updating notification BLoC: $e');
      }
    }
  }

  /// Aggiorna il BLoC delle notifiche immediatamente (per iOS)
  void _updateNotificationBlocImmediate() {
    try {
      // Prova a ottenere il BLoC dal context globale
      final context = navigatorKey.currentContext;
      if (context != null) {
        final notificationBloc = context.read<NotificationBloc>();
        notificationBloc.add(const LoadNotificationsEvent());
      } else {
        // Fallback a GetIt (silenzioso - è il comportamento normale)
        final notificationBloc = getIt<NotificationBloc>();
        if (notificationBloc != null) {
          notificationBloc.add(const LoadNotificationsEvent());
        }
      }
    } catch (e) {
      if (kDebugMode) {
        //debugPrint('[CONSOLE] [FCM] ❌ Error updating notification BLoC: $e');
      }
    }
  }

  /// Avvia il checker per le notifiche in foreground (iOS e Android)
  void _startForegroundChecker() {
    // Controlla le notifiche ogni 2 secondi quando l'app è in foreground
    Timer.periodic(const Duration(seconds: 2), (timer) {
      _updateNotificationBlocImmediate();
    });
  }



  /// Aggiorna FCM token
  Future<void> refreshToken() async {
    await _getFCMToken();
  }

  /// Sottoscrivi a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      if (kDebugMode) {
        //debugPrint('[CONSOLE] [FCM] 📱 Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        //debugPrint('[CONSOLE] [FCM] ❌ Error subscribing to topic: $e');
      }
    }
  }

  /// Disiscrivi da topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        //debugPrint('[CONSOLE] [FCM] 📱 Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        //debugPrint('[CONSOLE] [FCM] ❌ Error unsubscribing from topic: $e');
      }
    }
  }

  /// Pulisce il token FCM quando l'utente fa logout
  Future<void> clearTokenForUser(int userId) async {
    try {
      if (_fcmToken != null) {
        final dio = DioClient.getInstance();
        await dio.post(
          'https://fitgymtrack.com/api/firebase/clear_token.php',
          data: {
            'fcm_token': _fcmToken!,
            // ❌ RIMOSSO: user_id non più necessario (preso dal JWT token)
          },
        );
        
        if (kDebugMode) {
          //debugPrint('[CONSOLE] [FCM] 📱 FCM Token cleared for user $userId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        //debugPrint('[CONSOLE] [FCM] ❌ Error clearing token for user $userId: $e');
      }
    }
  }

  /// Ottiene l'utente corrente per il refresh del token
  Future<User?> _getCurrentUser() async {
    try {
      // Prova a ottenere l'utente dal context globale
      final context = navigatorKey.currentContext;
      if (context != null) {
        final authBloc = context.read<AuthBloc>();
        if (authBloc.state is AuthAuthenticated) {
          return (authBloc.state as AuthAuthenticated).user;
        }
      }
      
      // Fallback: prova a ottenere dai dati locali
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId != null) {
        // Qui potresti fare una chiamata API per ottenere i dati utente
        // Per ora restituiamo null e gestiamo l'errore nel listener
        return null;
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        //debugPrint('[CONSOLE] [FCM] ❌ Error getting current user: $e');
      }
      return null;
    }
  }
}
