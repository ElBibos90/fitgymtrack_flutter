import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../features/auth/models/login_request.dart';
import '../../features/auth/models/login_response.dart';
import '../../features/auth/models/register_request.dart';
import '../../features/auth/models/register_response.dart';
import '../../features/auth/models/password_reset_models.dart';

part 'api_client.g.dart';

@RestApi()
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  // ============================================================================
  // AUTH ENDPOINTS - Con tipi specifici che hanno fromJson
  // ============================================================================

  @POST("/auth.php")
  Future<LoginResponse> login(
      @Query("action") String action,
      @Body() LoginRequest loginRequest,
      );

  @POST("/standalone_register.php")
  Future<RegisterResponse> register(
      @Body() RegisterRequest registerRequest,
      );

  // ============================================================================
  // ENDPOINTS CHE RITORNANO Response<dynamic> - Senza fromJson
  // ============================================================================

  @POST("/password_reset.php")
  Future<dynamic> requestPasswordReset(
      @Query("action") String action,
      @Body() PasswordResetRequest resetRequest,
      );

  @POST("/reset_simple.php")
  Future<dynamic> confirmPasswordReset(
      @Query("action") String action,
      @Body() PasswordResetConfirmRequest resetConfirmRequest,
      );

  @GET("/utente_profilo.php")
  Future<dynamic> getUserProfile();

  @PUT("/utente_profilo.php")
  Future<dynamic> updateUserProfile(
      @Body() Map<String, dynamic> userProfile,
      );

  @GET("/schede_standalone.php")
  Future<dynamic> getWorkouts();

  @POST("/schede_standalone.php")
  Future<dynamic> createWorkout(
      @Body() Map<String, dynamic> workout,
      );

  @PUT("/schede_standalone.php")
  Future<dynamic> updateWorkout(
      @Body() Map<String, dynamic> workout,
      );

  @DELETE("/schede_standalone.php")
  Future<dynamic> deleteWorkout(
      @Query("id") int workoutId,
      );

  @GET("/android_user_stats.php")
  Future<dynamic> getUserStats();

  @GET("/android_period_stats.php")
  Future<dynamic> getPeriodStats(
      @Query("period") String period,
      );

  @GET("/subscription_api.php")
  Future<dynamic> getCurrentSubscription(
      @Query("action") String action,
      );

  @POST("/subscription_api.php")
  Future<dynamic> updatePlan(
      @Body() Map<String, dynamic> request,
      @Query("action") String action,
      );
}
