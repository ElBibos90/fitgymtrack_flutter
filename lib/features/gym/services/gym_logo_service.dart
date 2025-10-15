// lib/features/gym/services/gym_logo_service.dart

import '../../../core/network/dio_client.dart';
import '../../../features/auth/models/login_response.dart';
import '../../../core/services/user_role_service.dart';
import '../models/gym_logo_model.dart';

class GymLogoService {
  final DioClient _dioClient;
  
  GymLogoService(this._dioClient);
  
  /// Recupera il logo di una palestra specifica per ID
  Future<GymLogoModel?> getGymLogo(int gymId) async {
    try {
      print('[GymLogoService] 🔍 Fetching logo for gym ID: $gymId');
      
      final response = await _dioClient.get('/api/gyms.php?id=$gymId');
      
      if (response.data != null) {
        final gymLogo = GymLogoModel.fromJson(response.data);
        print('[GymLogoService] ✅ Logo retrieved: ${gymLogo.hasCustomLogo ? gymLogo.logoFilename : "fallback"}');
        return gymLogo;
      }
      
      print('[GymLogoService] ❌ No data received for gym ID: $gymId');
      return null;
    } catch (e) {
      print('[GymLogoService] ❌ Error fetching gym logo for ID $gymId: $e');
      return null;
    }
  }
  
  /// Recupera il logo della palestra per l'utente corrente
  Future<GymLogoModel?> getGymLogoForCurrentUser(User user) async {
    try {
      print('[GymLogoService] 🔍 Getting gym logo for user: ${user.username}');
      print('[GymLogoService] 🔍 User role: ${user.roleId}');
      print('[GymLogoService] 🔍 User gym_id: ${user.gymId}');
      
      // Per utenti gym, ottieni l'ID dalla palestra di cui è proprietario
      if (UserRoleService.isGymUser(user)) {
        print('[GymLogoService] 🏢 User is GYM, fetching owned gym...');
        
        final response = await _dioClient.get('/api/gyms.php');
        
        if (response.data != null && response.data is List && (response.data as List).isNotEmpty) {
          final gymData = (response.data as List).first;
          final gymId = gymData['id'] as int;
          
          print('[GymLogoService] 🏢 Found owned gym ID: $gymId');
          return getGymLogo(gymId);
        } else {
          print('[GymLogoService] ❌ No gym found for gym user');
          return null;
        }
      }
      // Per trainer, usa il gym_id dell'utente
      else if (UserRoleService.isTrainerUser(user) && user.gymId != null) {
        print('[GymLogoService] 👨‍🏫 User is TRAINER, using gym_id: ${user.gymId}');
        return getGymLogo(user.gymId!);
      }
      // Per standalone user, nessun logo
      else if (UserRoleService.isStandaloneUser(user)) {
        print('[GymLogoService] 👤 User is STANDALONE, no gym logo needed');
        return null;
      }
      // Altri ruoli
      else {
        print('[GymLogoService] ❓ Unknown user role: ${user.roleId}');
        return null;
      }
    } catch (e) {
      print('[GymLogoService] ❌ Error getting gym logo for current user: $e');
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
