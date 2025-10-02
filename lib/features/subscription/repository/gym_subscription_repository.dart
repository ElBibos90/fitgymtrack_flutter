// lib/features/subscription/repository/gym_subscription_repository.dart
import 'package:dio/dio.dart';
import '../../../core/utils/result.dart';
import '../../../core/network/api_client.dart';
import '../models/subscription_models.dart';
import '../models/gym_subscription.dart';

/// Repository per la gestione degli abbonamenti palestra
class GymSubscriptionRepository {
  final ApiClient _apiClient;
  final Dio _dio;

  GymSubscriptionRepository({
    required ApiClient apiClient,
    required Dio dio,
  })  : _apiClient = apiClient,
        _dio = dio;

  /// Recupera l'abbonamento palestra dell'utente
  Future<Result<GymSubscription>> getGymSubscription(int userId) async {
    //print('[CONSOLE] [gym_subscription_repository] 🏋️ Recupero abbonamento palestra per utente: $userId');

    return Result.tryCallAsync(() async {
      try {
        // 🎯 USA L'API CORRETTA: client_subscription_management.php (ricreata da zero)
        final response = await _dio.get('/client_subscription_management.php', queryParameters: {
          'action': 'client_subscription',
          'client_id': userId.toString(),
        });

        //print('[CONSOLE] [gym_subscription_repository] 🔍 DEBUG - Status code: ${response.statusCode}');
        //print('[CONSOLE] [gym_subscription_repository] 🔍 DEBUG - Response headers: ${response.headers}');
        
        final data = response.data;
      
        // 🔍 DEBUG: Log della risposta completa
        //print('[CONSOLE] [gym_subscription_repository] 🔍 DEBUG - Risposta API completa: $data');
        //print('[CONSOLE] [gym_subscription_repository] 🔍 DEBUG - success: ${data['success']}');
        //print('[CONSOLE] [gym_subscription_repository] 🔍 DEBUG - subscription: ${data['subscription']}');

        if (data['success'] == true && data['subscription'] != null) {
          final subscriptionData = data['subscription'];

          final gymSubscription = GymSubscription(
            id: subscriptionData['id'] ?? 0,
            gymId: subscriptionData['gym_id'] ?? 6,
            gymName: 'Palestra FitGymTrack',
            planName: subscriptionData['subscription_name'] ?? 'Piano Base',
            startDate: subscriptionData['start_date'] != null
                ? DateTime.parse(subscriptionData['start_date'])
                : DateTime.now(),
            endDate: subscriptionData['end_date'] != null
                ? DateTime.parse(subscriptionData['end_date'])
                : DateTime.now().add(const Duration(days: 30)),
            isActive: subscriptionData['status'] == 'active',
            maxWorkouts: 999,
            maxCustomExercises: 999,
            hasAdvancedStats: true,
            hasCloudBackup: true,
            hasNoAds: true,
            daysRemaining: subscriptionData['days_remaining'] ?? 0,
            price: double.tryParse(subscriptionData['price']?.toString() ?? '0.0') ?? 0.0,
            currency: subscriptionData['currency'] ?? 'EUR',
          );

          //print('[CONSOLE] [gym_subscription_repository] ✅ Abbonamento palestra recuperato: ${gymSubscription.gymName} - ${gymSubscription.planName}');
          return gymSubscription;
        } else {
          //print('[CONSOLE] [gym_subscription_repository] ℹ️ Nessun abbonamento attivo per l\'utente');
          //print('[CONSOLE] [gym_subscription_repository] 🔍 DEBUG - success: ${data['success']}, subscription: ${data['subscription']}');
          //print('[CONSOLE] [gym_subscription_repository] 🔍 DEBUG - message: ${data['message']}');
          throw Exception(data['message'] ?? 'Nessun abbonamento attivo');
        }
      } on DioException catch (e) {
        print('[CONSOLE] [gym_subscription_repository] ❌ DioException: ${e.type}');
        print('[CONSOLE] [gym_subscription_repository] ❌ DioException message: ${e.message}');
        print('[CONSOLE] [gym_subscription_repository] ❌ DioException response: ${e.response?.data}');
        print('[CONSOLE] [gym_subscription_repository] ❌ DioException statusCode: ${e.response?.statusCode}');
        
        // Se c'è una risposta, proviamo a parsarla
        if (e.response?.data != null) {
          try {
            final data = e.response!.data;
            if (data is Map && data.containsKey('error')) {
              throw Exception(data['error']);
            }
          } catch (parseError) {
            print('[CONSOLE] [gym_subscription_repository] ❌ Parse error: $parseError');
          }
        }
        
        rethrow;
      } catch (e) {
        print('[CONSOLE] [gym_subscription_repository] ❌ Generic Error: $e');
        rethrow;
      }
    });
  }

  /// Verifica se l'abbonamento palestra è scaduto
  Future<Result<bool>> isGymSubscriptionExpired() async {
    return Result.tryCallAsync(() async {
      // Implementazione per verificare se l'abbonamento è scaduto
      // Per ora restituiamo false
      return false;
    });
  }
}
