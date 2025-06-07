// lib/features/subscription/repository/subscription_repository.dart
import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import '../../../core/utils/result.dart';
import '../../../core/network/api_client.dart';
import '../models/subscription_models.dart';

/// Repository per la gestione degli abbonamenti
class SubscriptionRepository {
  final ApiClient _apiClient;
  final Dio _dio;

  SubscriptionRepository({
    required ApiClient apiClient,
    required Dio dio,
  })  : _apiClient = apiClient,
        _dio = dio;

  /// Recupera l'abbonamento corrente dell'utente
  Future<Result<Subscription>> getCurrentSubscription() async {
    developer.log('Recupero abbonamento corrente', name: 'SubscriptionRepository');

    return Result.tryCallAsync(() async {
      // Chiamata API diretta usando Dio per flessibilità
      final response = await _dio.get('/android_subscription_api.php', queryParameters: {
        'action': 'current_subscription',
      });

      final data = response.data;

      if (data['success'] == true && data['data']?['subscription'] != null) {
        final subscriptionData = data['data']['subscription'];

        // Conversione dei campi booleani da int a bool se necessario
        final subscription = Subscription(
          id: subscriptionData['id'],
          userId: subscriptionData['user_id'],
          planId: subscriptionData['plan_id'],
          planName: subscriptionData['plan_name'] ?? 'Free',
          status: subscriptionData['status'] ?? 'active',
          price: (subscriptionData['price'] ?? 0.0).toDouble(),
          maxWorkouts: subscriptionData['max_workouts'],
          maxCustomExercises: subscriptionData['max_custom_exercises'],
          currentCount: subscriptionData['current_count'] ?? 0,
          currentCustomExercises: subscriptionData['current_custom_exercises'] ?? 0,
          advancedStats: _convertToBool(subscriptionData['advanced_stats']),
          cloudBackup: _convertToBool(subscriptionData['cloud_backup']),
          noAds: _convertToBool(subscriptionData['no_ads']),
          startDate: subscriptionData['start_date'],
          endDate: subscriptionData['end_date'],
          daysRemaining: subscriptionData['days_remaining'],
          computedStatus: subscriptionData['computed_status'],
        );

        developer.log(
          'Abbonamento recuperato: ${subscription.planName} - €${subscription.price}',
          name: 'SubscriptionRepository',
        );

        return subscription;
      } else {
        throw Exception(data['message'] ?? 'Errore nel recupero dell\'abbonamento');
      }
    });
  }

  /// Controlla le subscription scadute
  Future<Result<ExpiredCheckResponse>> checkExpiredSubscriptions() async {
    developer.log('Controllo subscription scadute', name: 'SubscriptionRepository');

    return Result.tryCallAsync(() async {
      final response = await _dio.get('/android_subscription_api.php', queryParameters: {
        'action': 'check_expired',
      });

      final data = response.data;

      if (data['success'] == true) {
        final expiredCheck = ExpiredCheckResponse(
          updatedCount: data['data']?['updated_count'] ?? 0,
        );

        developer.log(
          'Controllo scadenze completato: ${expiredCheck.updatedCount} aggiornamenti',
          name: 'SubscriptionRepository',
        );

        return expiredCheck;
      } else {
        throw Exception(data['message'] ?? 'Errore nel controllo delle scadenze');
      }
    });
  }

  /// Verifica i limiti di utilizzo per un tipo di risorsa
  Future<Result<ResourceLimits>> checkResourceLimits(String resourceType) async {
    developer.log('Verifica limiti per: $resourceType', name: 'SubscriptionRepository');

    return Result.tryCallAsync(() async {
      final response = await _dio.get('/android_resource_limits_api.php', queryParameters: {
        'resource_type': resourceType,
      });

      final data = response.data;

      if (data['success'] == true && data['data'] != null) {
        final limitData = data['data'];

        final resourceLimits = ResourceLimits(
          limitReached: limitData['limit_reached'] ?? false,
          currentCount: limitData['current_count'] ?? 0,
          maxAllowed: limitData['max_allowed'],
          remaining: limitData['remaining'] ?? 0,
          subscriptionStatus: limitData['subscription_status'],
          daysRemaining: limitData['days_remaining'],
        );

        developer.log(
          'Limiti verificati: ${resourceLimits.currentCount}/${resourceLimits.maxAllowed}',
          name: 'SubscriptionRepository',
        );

        return resourceLimits;
      } else {
        throw Exception(data['message'] ?? 'Errore nella verifica dei limiti');
      }
    });
  }

  /// Aggiorna il piano di abbonamento
  Future<Result<UpdatePlanResponse>> updatePlan(int planId) async {
    developer.log('Aggiornamento al piano ID: $planId', name: 'SubscriptionRepository');

    return Result.tryCallAsync(() async {
      final response = await _dio.post(
        '/android_update_plan_api.php',
        data: {'plan_id': planId},
      );

      final data = response.data;

      if (data['success'] == true && data['data'] != null) {
        final updateData = data['data'];

        final updateResponse = UpdatePlanResponse(
          success: updateData['success'] ?? true,
          message: updateData['message'] ?? 'Piano aggiornato con successo',
          planName: updateData['plan_name'] ?? 'Unknown',
        );

        developer.log(
          'Piano aggiornato: ${updateResponse.planName}',
          name: 'SubscriptionRepository',
        );

        return updateResponse;
      } else {
        throw Exception(data['message'] ?? 'Errore nell\'aggiornamento del piano');
      }
    });
  }

  /// Ottiene i piani di abbonamento disponibili
  Future<Result<List<SubscriptionPlan>>> getAvailablePlans() async {
    developer.log('Recupero piani disponibili', name: 'SubscriptionRepository');

    return Result.tryCallAsync(() async {
      final response = await _dio.get('/android_subscription_api.php', queryParameters: {
        'action': 'get_plans',
      });

      final data = response.data;

      if (data['success'] == true && data['data']?['plans'] != null) {
        final plansData = data['data']['plans'] as List;

        final plans = plansData.map((planData) {
          return SubscriptionPlan(
            id: planData['id'],
            name: planData['name'],
            price: (planData['price'] ?? 0.0).toDouble(),
            billingCycle: planData['billing_cycle'] ?? 'monthly',
            maxWorkouts: planData['max_workouts'],
            maxCustomExercises: planData['max_custom_exercises'],
            advancedStats: _convertToBool(planData['advanced_stats']),
            cloudBackup: _convertToBool(planData['cloud_backup']),
            noAds: _convertToBool(planData['no_ads']),
          );
        }).toList();

        developer.log(
          'Recuperati ${plans.length} piani disponibili',
          name: 'SubscriptionRepository',
        );

        return plans;
      } else {
        throw Exception(data['message'] ?? 'Errore nel recupero dei piani');
      }
    });
  }

  /// Verifica se l'utente può creare una nuova scheda
  Future<Result<bool>> canCreateWorkout() async {
    return checkResourceLimits('max_workouts').then((result) {
      return result.map((limits) => !limits.limitReached);
    });
  }

  /// Verifica se l'utente può creare un nuovo esercizio personalizzato
  Future<Result<bool>> canCreateCustomExercise() async {
    return checkResourceLimits('max_custom_exercises').then((result) {
      return result.map((limits) => !limits.limitReached);
    });
  }

  /// Converte valori int/string a bool per compatibilità API
  bool _convertToBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }
}