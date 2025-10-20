// lib/features/subscription/repository/subscription_repository.dart
import 'package:dio/dio.dart';

import '../../../core/utils/result.dart';
import '../models/subscription_models.dart';

/// Repository per la gestione degli abbonamenti
class SubscriptionRepository {
  final Dio _dio;

  SubscriptionRepository({
    required Dio dio,
  })  : _dio = dio;

  /// Recupera l'abbonamento corrente dell'utente
  Future<Result<Subscription>> getCurrentSubscription() async {
    //debugPrint('[CONSOLE] [subscription_repository]Recupero abbonamento corrente');

    return Result.tryCallAsync(() async {
      // Chiamata API diretta usando Dio per flessibilità
      final response = await _dio.get('/android_subscription_api.php', queryParameters: {
        'action': 'current_subscription',
      });

      final data = response.data;

      if (data['success'] == true && data['data']?['subscription'] != null) {
        final subscriptionData = data['data']['subscription'];

        // 🔧 FIX: Usa il parsing JSON automatico invece di costruzione manuale
        final subscription = Subscription.fromJson(subscriptionData);

        /*//debugPrint(
          'Abbonamento recuperato: ${subscription.planName} - €${subscription.price}'
        );*/

        return subscription;
      } else {
        throw Exception(data['message'] ?? 'Errore nel recupero dell\'abbonamento');
      }
    });
  }

  /// Controlla le subscription scadute
  Future<Result<ExpiredCheckResponse>> checkExpiredSubscriptions() async {
    //debugPrint('[CONSOLE] [subscription_repository]Controllo subscription scadute');

    return Result.tryCallAsync(() async {
      final response = await _dio.get('/android_subscription_api.php', queryParameters: {
        'action': 'check_expired',
      });

      final data = response.data;

      if (data['success'] == true) {
        final expiredCheck = ExpiredCheckResponse(
          updatedCount: _parseInt(data['data']?['updated_count']), // 🔧 FIX: Parsing robusto
        );

        /*//debugPrint(
          'Controllo scadenze completato: ${expiredCheck.updatedCount} aggiornamenti'
        );*/

        return expiredCheck;
      } else {
        throw Exception(data['message'] ?? 'Errore nel controllo delle scadenze');
      }
    });
  }

  /// Verifica i limiti di utilizzo per un tipo di risorsa
  Future<Result<ResourceLimits>> checkResourceLimits(String resourceType) async {
    //debugPrint('[CONSOLE] [subscription_repository]Verifica limiti per: $resourceType');

    return Result.tryCallAsync(() async {
      final response = await _dio.get('/android_resource_limits_api.php', queryParameters: {
        'resource_type': resourceType,
      });

      final data = response.data;

      if (data['success'] == true && data['data'] != null) {
        final limitData = data['data'];

        final resourceLimits = ResourceLimits(
          limitReached: _convertToBool(limitData['limit_reached']), // 🔧 FIX: Parsing robusto
          currentCount: _parseInt(limitData['current_count']), // 🔧 FIX: Parsing robusto
          maxAllowed: limitData['max_allowed'] != null ? _parseInt(limitData['max_allowed']) : null,
          remaining: _parseInt(limitData['remaining']), // 🔧 FIX: Parsing robusto
          subscriptionStatus: limitData['subscription_status'],
          daysRemaining: limitData['days_remaining'],
        );

        /*//debugPrint(
          'Limiti verificati: ${resourceLimits.currentCount}/${resourceLimits.maxAllowed}'
        );*/

        return resourceLimits;
      } else {
        throw Exception(data['message'] ?? 'Errore nella verifica dei limiti');
      }
    });
  }

  /// Aggiorna il piano di abbonamento
  Future<Result<UpdatePlanResponse>> updatePlan(int planId) async {
    //debugPrint('[CONSOLE] [subscription_repository]Aggiornamento al piano ID: $planId');

    return Result.tryCallAsync(() async {
      final response = await _dio.post(
        '/android_update_plan_api.php',
        data: {'plan_id': planId},
      );

      final data = response.data;

      if (data['success'] == true && data['data'] != null) {
        final updateData = data['data'];

        final updateResponse = UpdatePlanResponse(
          success: _convertToBool(updateData['success']), // 🔧 FIX: Parsing robusto
          message: updateData['message'] ?? 'Piano aggiornato con successo',
          planName: updateData['plan_name'] ?? 'Unknown',
        );

        /*//debugPrint(
          'Piano aggiornato: ${updateResponse.planName}'
        );*/

        return updateResponse;
      } else {
        throw Exception(data['message'] ?? 'Errore nell\'aggiornamento del piano');
      }
    });
  }

  /// Ottiene i piani di abbonamento disponibili
  Future<Result<List<SubscriptionPlan>>> getAvailablePlans() async {
    //debugPrint('[CONSOLE] [subscription_repository]Recupero piani disponibili');

    return Result.tryCallAsync(() async {
      final response = await _dio.get('/android_subscription_api.php', queryParameters: {
        'action': 'get_plans',
      });

      final data = response.data;

      if (data['success'] == true && data['data']?['plans'] != null) {
        final plansData = data['data']['plans'] as List;

        final plans = plansData.map((planData) {
          return SubscriptionPlan(
            id: _parseInt(planData['id']), // 🔧 FIX: Parsing robusto
            name: planData['name'] ?? 'Unknown',
            price: _parseDouble(planData['price']), // 🔧 FIX: Parsing robusto
            billingCycle: planData['billing_cycle'] ?? 'monthly',
            maxWorkouts: planData['max_workouts'] != null ? _parseInt(planData['max_workouts']) : null,
            maxCustomExercises: planData['max_custom_exercises'] != null ? _parseInt(planData['max_custom_exercises']) : null,
            advancedStats: _convertToBool(planData['advanced_stats']),
            cloudBackup: _convertToBool(planData['cloud_backup']),
            noAds: _convertToBool(planData['no_ads']),
          );
        }).toList();

        // print(
        //   'Recuperati ${plans.length} piani disponibili'
        // );

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

  // ============================================================================
  // 🔧 HELPER FUNCTIONS FOR ROBUST PARSING (DUPLICATI PER SICUREZZA)
  // ============================================================================

  /// Converte qualsiasi tipo a double in modo robusto
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        //debugPrint('[CONSOLE] [subscription_repository]Errore parsing double: $value');
        return 0.0;
      }
    }
    return 0.0;
  }

  /// Converte qualsiasi tipo a int in modo robusto
  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        try {
          return double.parse(value).toInt();
        } catch (e2) {
          //debugPrint('[CONSOLE] [subscription_repository]Errore parsing int: $value');
          return 0;
        }
      }
    }
    return 0;
  }

  /// Converte valori int/string a bool per compatibilità API
  bool _convertToBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final str = value.toLowerCase();
      return str == 'true' || str == '1' || str == 'yes';
    }
    return false;
  }
}