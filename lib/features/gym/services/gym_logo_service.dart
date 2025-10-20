// lib/features/gym/services/gym_logo_service.dart

import 'package:dio/dio.dart';
import '../../../features/auth/models/login_response.dart';
import '../../../core/services/user_role_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/session_service.dart';
import '../../../core/di/dependency_injection.dart';
import '../models/gym_logo_model.dart';

class GymLogoService {
  final Dio _dio;
  
  GymLogoService(this._dio);
  
  /// Recupera il logo di una palestra specifica per ID
  Future<GymLogoModel?> getGymLogo(int gymId) async {
    try {
      //debugPrint('[LOGO] 🔍 [GymLogoService] Fetching logo for gym ID: $gymId');
      //debugPrint('[LOGO] 🔍 [GymLogoService] API URL: ${AppConfig.baseUrl}/gyms.php?id=$gymId');
      
      final response = await _dio.get(
        '${AppConfig.baseUrl}/gyms.php?id=$gymId',
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );
      
      //debugPrint('[LOGO] 📊 [GymLogoService] Response status: ${response.statusCode}');
      //debugPrint('[LOGO] 📊 [GymLogoService] Response data: ${response.data}');
      
      if (response.data != null) {
        final gymLogo = GymLogoModel.fromJson(response.data);
        //debugPrint('[LOGO] ✅ [GymLogoService] Logo retrieved: ${gymLogo.hasCustomLogo ? gymLogo.logoFilename : "fallback"}');
        //debugPrint('[LOGO] ✅ [GymLogoService] Logo URL: ${gymLogo.logoUrl}');
        return gymLogo;
      }
      
      //debugPrint('[LOGO] ❌ [GymLogoService] No data received for gym ID: $gymId');
      return null;
    } catch (e) {
      //debugPrint('[LOGO] ❌ [GymLogoService] Error fetching gym logo for ID $gymId: $e');
      return null;
    }
  }
  
  /// Recupera il logo della palestra per l'utente corrente
  Future<GymLogoModel?> getGymLogoForCurrentUser(User user) async {
    try {
      //debugPrint('[LOGO] 🔍 [GymLogoService] Getting gym logo for user: ${user.username}');
      //debugPrint('[LOGO] 🔍 [GymLogoService] User role: ${user.roleId}');
      //debugPrint('[LOGO] 🔍 [GymLogoService] User gym_id: ${user.gymId}');
      
      // Per utenti gym, ottieni l'ID dalla palestra di cui è proprietario
      if (UserRoleService.isGymUser(user)) {
        //debugPrint('[LOGO] 🏢 [GymLogoService] User is GYM, fetching owned gym...');
        
        // Prima prova con gym_id se disponibile
        if (user.gymId != null) {
          //debugPrint('[LOGO] 🏢 [GymLogoService] Using user gym_id: ${user.gymId}');
          return getGymLogo(user.gymId!);
        }
        
        // Usa il nuovo endpoint user_gym_simple.php per ottenere i dati della palestra dell'utente
        try {
          //debugPrint('[LOGO] 🔄 [GymLogoService] Fetching user gym data from user_gym.php...');
          
          // Verifica che il token sia presente
          final sessionService = getIt<SessionService>();
          final token = await sessionService.getAuthToken();
          //debugPrint('[LOGO] 🔐 [GymLogoService] Token present: ${token != null && token.isNotEmpty}');
          
          // Invia token in multiple modi per massima compatibilità
          final response = await _dio.get(
            '${AppConfig.baseUrl}/user_gym.php?token=$token',
            options: Options(
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
                'X-Auth-Token': token,
              },
            ),
          );
          
          //debugPrint('[LOGO] 📊 [GymLogoService] User gym response: ${response.data}');
          
          if (response.data != null && response.data['success'] == true && response.data['data'] != null) {
            final gymData = response.data['data'];
            
            //debugPrint('[LOGO] 🏢 [GymLogoService] Found user gym data: ${gymData['name']}');
            
            // Crea direttamente il GymLogoModel dai dati ricevuti
            final gymLogo = GymLogoModel(
              logoFilename: gymData['logo_filename'],
              logoUrl: gymData['logo_url'],
              hasCustomLogo: gymData['has_custom_logo'] ?? false,
              gymId: gymData['id'],
              gymName: gymData['name'],
            );
            
            //debugPrint('[LOGO] ✅ [GymLogoService] Logo created directly from user_gym data');
            return gymLogo;
          } else {
            //debugPrint('[LOGO] ❌ [GymLogoService] No gym data found for user');
            return null;
          }
        } catch (e) {
          //debugPrint('[LOGO] ❌ [GymLogoService] Error fetching user gym: $e');
          return null;
        }
      }
      // Per trainer, usa il gym_id dell'utente o l'endpoint user_gym
      else if (UserRoleService.isTrainerUser(user)) {
        if (user.gymId != null) {
          //debugPrint('[LOGO] 👨‍🏫 [GymLogoService] User is TRAINER, using gym_id: ${user.gymId}');
          return getGymLogo(user.gymId!);
        } else {
          // Prova con user_gym_simple.php se gym_id non è disponibile
          try {
            //debugPrint('[LOGO] 🔄 [GymLogoService] Trainer without gym_id, fetching from user_gym.php...');
            
            // Verifica che il token sia presente
            final sessionService = getIt<SessionService>();
            final token = await sessionService.getAuthToken();
            //debugPrint('[LOGO] 🔐 [GymLogoService] Trainer token present: ${token != null && token.isNotEmpty}');
            
            // Invia token in multiple modi per massima compatibilità
            final response = await _dio.get(
              '${AppConfig.baseUrl}/user_gym.php?token=$token',
              options: Options(
                headers: {
                  'Accept': 'application/json',
                  'Authorization': 'Bearer $token',
                  'X-Auth-Token': token,
                },
              ),
            );
            
            //debugPrint('[LOGO] 📊 [GymLogoService] Trainer gym response: ${response.data}');
            
            if (response.data != null && response.data['success'] == true && response.data['data'] != null) {
              final gymData = response.data['data'];
              
              //debugPrint('[LOGO] 🏢 [GymLogoService] Found trainer gym data: ${gymData['name']}');
              
              // Crea direttamente il GymLogoModel dai dati ricevuti
              final gymLogo = GymLogoModel(
                logoFilename: gymData['logo_filename'],
                logoUrl: gymData['logo_url'],
                hasCustomLogo: gymData['has_custom_logo'] ?? false,
                gymId: gymData['id'],
                gymName: gymData['name'],
              );
              
              //debugPrint('[LOGO] ✅ [GymLogoService] Trainer logo created directly from user_gym data');
              return gymLogo;
            } else {
              //debugPrint('[LOGO] ❌ [GymLogoService] No gym data found for trainer');
              return null;
            }
          } catch (e) {
            //debugPrint('[LOGO] ❌ [GymLogoService] Error fetching trainer gym: $e');
            return null;
          }
        }
      }
      // Per standalone user, nessun logo
      else if (UserRoleService.isStandaloneUser(user)) {
        //debugPrint('[LOGO] 👤 [GymLogoService] User is STANDALONE, no gym logo needed');
        return null;
      }
      // Altri ruoli
      else {
        //debugPrint('[LOGO] ❓ [GymLogoService] Unknown user role: ${user.roleId}');
        return null;
      }
    } catch (e) {
      //debugPrint('[LOGO] ❌ [GymLogoService] Error getting gym logo for current user: $e');
      return null;
    }
  }
  
  /// Verifica se l'utente dovrebbe mostrare un logo palestra
  bool shouldShowGymLogo(User user) {
    return UserRoleService.isGymUser(user) || UserRoleService.isTrainerUser(user);
  }
  
  /// Costruisce l'URL completo del logo
  String buildLogoUrl(String? logoFilename, {String baseUrl = ''}) {
    if (logoFilename == null || logoFilename.isEmpty) {
      return '';
    }
    
    final url = '/api/serve_image.php?filename=$logoFilename&type=logo';
    return baseUrl.isNotEmpty ? '$baseUrl$url' : url;
  }
  
  /// Verifica se l'URL del logo è valido
  bool isValidLogoUrl(String logoUrl) {
    return logoUrl.isNotEmpty && logoUrl.contains('serve_image.php');
  }
}
