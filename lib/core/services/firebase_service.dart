// lib/core/services/firebase_service.dart

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
        print('🔥 Firebase initialized successfully');
        print('📱 FCM Token: $_fcmToken');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase initialization error: $e');
      }
      rethrow;
    }
  }

  /// Configura notifiche locali
  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
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
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('📱 Notification permission status: ${settings.authorizationStatus}');
    }

    // Gestisci notifiche in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Gestisci notifiche quando app è in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Gestisci notifiche quando app è chiusa
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
  }

  /// Ottiene e salva FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      
      if (_fcmToken != null) {
        // Salva token localmente
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
        
        // Invia token al server
        await _sendTokenToServer(_fcmToken!);
        
        if (kDebugMode) {
          print('📱 FCM Token saved and sent to server');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting FCM token: $e');
      }
    }
  }

  /// Invia FCM token al server
  Future<void> _sendTokenToServer(String token) async {
    try {
      final dio = DioClient.getInstance();
      await dio.post(
        'https://fitgymtrack.com/api/firebase/register_token.php',
        data: {
          'fcm_token': token,
          'platform': defaultTargetPlatform.name,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending token to server: $e');
      }
    }
  }

  /// Gestisce notifiche in foreground
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('[NOTIFICHE] 📱 Foreground message received: ${message.notification?.title}');
    }

    // Mostra notifica locale
    _showLocalNotification(message);
    
    // Aggiorna il BLoC delle notifiche
    if (kDebugMode) {
      print('[NOTIFICHE] 📱 Calling _updateNotificationBloc...');
    }
    _updateNotificationBloc();
  }

  /// Gestisce notifiche in background
  void _handleBackgroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('[NOTIFICHE] 📱 Background message received: ${message.notification?.title}');
    }

    // Naviga alla schermata notifiche
    _navigateToNotifications();
    
    // Aggiorna il BLoC delle notifiche
    if (kDebugMode) {
      print('[NOTIFICHE] 📱 Calling _updateNotificationBloc...');
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
      print('[NOTIFICHE] 📱 Showing local notification with ID: $notificationId');
      print('[NOTIFICHE] 📱 Title: ${message.notification?.title}');
      print('[NOTIFICHE] 📱 Body: ${message.notification?.body}');
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
      print('📱 Notification tapped: ${response.payload}');
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
        print('[NOTIFICHE] 📱 _updateNotificationBloc called');
      }
      
      // SOLUZIONE ALTERNATIVA: Usa GetIt per ottenere il BLoC direttamente
      final notificationBloc = getIt<NotificationBloc>();
      if (kDebugMode) {
        print('[NOTIFICHE] 📱 BLoC obtained from GetIt');
      }
      
      if (notificationBloc != null) {
        if (kDebugMode) {
          print('[NOTIFICHE] 📱 Adding LoadNotificationsEvent...');
        }
        notificationBloc.add(const LoadNotificationsEvent());
        if (kDebugMode) {
          print('[NOTIFICHE] 📱 Notification BLoC updated successfully');
        }
      } else {
        if (kDebugMode) {
          print('[NOTIFICHE] ❌ BLoC is null, cannot update');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NOTIFICHE] ❌ Error updating notification BLoC: $e');
      }
    }
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
        print('📱 Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error subscribing to topic: $e');
      }
    }
  }

  /// Disiscrivi da topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('📱 Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error unsubscribing from topic: $e');
      }
    }
  }
}
