// lib/core/network/api_client.dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

// Auth models
import '../../features/auth/models/login_request.dart';
import '../../features/auth/models/login_response.dart';
import '../../features/auth/models/register_request.dart';
import '../../features/auth/models/register_response.dart';
import '../../features/auth/models/password_reset_models.dart';

import '../../features/workouts/models/series_request_models.dart';
import '../../features/exercises/models/exercises_response.dart';
import '../../features/workouts/models/workout_response_types.dart';


// TODO: Uncomment when we create the workout models
// Workout models
// import '../../features/exercises/models/exercise.dart';
// import '../../features/workouts/models/workout_plan_models.dart';
// import '../../features/workouts/models/active_workout_models.dart';
// import '../../features/stats/models/user_stats_models.dart';

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

  // ============================================================================
  // TODO: WORKOUT ENDPOINTS - Uncomment when we create models
  // ============================================================================

  // @GET("/schede_standalone.php")
  // Future<WorkoutPlansResponse> getWorkoutPlans(
  //   @Query("user_id") int userId,
  // );

  // @POST("/schede_standalone.php")
  // Future<WorkoutPlanResponse> createWorkoutPlan(
  //   @Body() CreateWorkoutPlanRequest request,
  // );

  // ============================================================================
  // GENERIC ENDPOINTS (keeping existing dynamic ones for now)
  // ============================================================================

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
  // ============================================================================
  // WORKOUT PLANS ENDPOINTS
  // ============================================================================

  @GET("/get_esercizi_standalone.php")
  Future<dynamic> getAvailableExercises(
      @Query("user_id") int userId,
      );

  // ============================================================================
  // ACTIVE WORKOUT ENDPOINTS
  // ============================================================================

  @POST("/start_active_workout_standalone.php")
  Future<dynamic> startWorkout(
      @Body() Map<String, dynamic> request,
      );

  @GET("/get_completed_series_standalone.php")
  Future<dynamic> getCompletedSeries(
      @Query("allenamento_id") int allenamentoId,
      );

  @POST("/save_completed_series.php")
  Future<dynamic> saveCompletedSeries(
      @Body() Map<String, dynamic> request,
      );

  @POST("/complete_allenamento_standalone.php")
  Future<dynamic> completeWorkout(
      @Body() Map<String, dynamic> request,
      );

  // ============================================================================
  // WORKOUT HISTORY ENDPOINTS
  // ============================================================================

  @GET("/get_allenamenti_standalone.php")
  Future<dynamic> getWorkoutHistory(
      @Query("user_id") int userId,
      );

  @GET("/get_completed_series_standalone.php")
  Future<dynamic> getWorkoutSeriesDetail(
      @Query("allenamento_id") int allenamentoId,
      );

  @POST("/delete_completed_series.php")
  Future<dynamic> deleteCompletedSeries(
      @Body() Map<String, dynamic> request,
      );

  @PUT("/update_completed_series.php")
  Future<dynamic> updateCompletedSeries(
      @Body() Map<String, dynamic> request,
      );

  @POST("/delete_allenamento_standalone.php")
  Future<dynamic> deleteWorkoutFromHistory(
      @Body() Map<String, dynamic> request,
      );
}