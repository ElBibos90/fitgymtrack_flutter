import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/environment.dart';
import '../services/session_service.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';
import '../di/dependency_injection.dart';

class DioClient {
  static Dio? _instance;
  static SessionService? _sessionService;

  static Dio getInstance({SessionService? sessionService}) {
    // ✅ Se non viene passato SessionService, ottienilo da GetIt
    final currentSessionService = sessionService ?? getIt<SessionService>();
    
    if (_instance == null || currentSessionService != _sessionService) {
      _sessionService = currentSessionService;
      _instance = _createDio();
    }
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: Environment.baseUrl,
      connectTimeout: Environment.connectTimeout,
      receiveTimeout: Environment.receiveTimeout,
      sendTimeout: Environment.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'FitGymTrack Flutter App 1.0.0', // 🔒 Identifica l'app mobile
        'X-Platform': 'mobile', // 🔒 Header personalizzato per identificare la piattaforma
      },
      // ✅ FIX: Accetta codici 403 come risposte valide per gestire limiti account free
      validateStatus: (status) {
        return status != null && status < 500; // Accetta tutti i codici < 500 (incluso 403)
      },
    ));

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
        error: true,
      ));
    }

    if (_sessionService != null) {
      dio.interceptors.add(AuthInterceptor(_sessionService!));
    }

    dio.interceptors.add(ErrorInterceptor());

    return dio;
  }
}