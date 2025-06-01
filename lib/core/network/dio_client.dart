import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/environment.dart';
import '../services/session_service.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';

class DioClient {
  static Dio? _instance;
  static SessionService? _sessionService;

  static Dio getInstance({SessionService? sessionService}) {
    if (_instance == null || sessionService != _sessionService) {
      _sessionService = sessionService;
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