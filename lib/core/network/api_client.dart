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

part 'api_client.g.dart';

@RestApi()
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  // ============================================================================
  // AUTH ENDPOINTS
  // ============================================================================

  @POST("/auth.php")
  Future<LoginResponse> login(
      @Query("action") String action,
      @Body() LoginRequest loginRequest,
      );

  @POST("/auth.php")
  Future<dynamic> logout(
      @Query("action") String action,
      @Body() Map<String, dynamic> request,
      );

  @POST("/auth.php")
  Future<dynamic> verifyToken(
      @Query("action") String action,
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
  // USER PROFILE ENDPOINTS
  // ============================================================================

  @GET("/utente_profilo.php")
  Future<dynamic> getUserProfile({@Query("user_id") int? userId});

  @PUT("/utente_profilo.php")
  Future<dynamic> updateUserProfile(
      @Body() Map<String, dynamic> userProfile,
      {@Query("user_id") int? userId}
      );

  // ============================================================================
  // USER MANAGEMENT ENDPOINTS
  // ============================================================================

  @GET("/users.php")
  Future<dynamic> getUsers({
    @Query("role_name") String? roleName,
    @Query("role") String? role,
  });

  @GET("/users.php")
  Future<dynamic> getUserById(@Query("id") int userId);

  @POST("/users.php")
  Future<dynamic> createUser(@Body() Map<String, dynamic> userData);

  @PUT("/users.php")
  Future<dynamic> updateUser(
      @Query("id") int userId,
      @Body() Map<String, dynamic> userData,
      );

  @DELETE("/users.php")
  Future<dynamic> deleteUser(@Query("id") int userId);

  // ============================================================================
  // USER ROLES ENDPOINTS
  // ============================================================================

  @GET("/user_role.php")
  Future<dynamic> getRoles();

  @GET("/user_role.php")
  Future<dynamic> getRoleById(@Query("id") int roleId);

  @POST("/user_role.php")
  Future<dynamic> createRole(@Body() Map<String, dynamic> roleData);

  @PUT("/user_role.php")
  Future<dynamic> updateRole(
      @Query("id") int roleId,
      @Body() Map<String, dynamic> roleData,
      );

  @DELETE("/user_role.php")
  Future<dynamic> deleteRole(@Query("id") int roleId);

  // ============================================================================
  // USER ASSIGNMENTS ENDPOINTS
  // ============================================================================

  @GET("/user_assignments.php")
  Future<dynamic> getUserAssignments({@Query("user_id") int? userId});

  @POST("/user_assignments.php")
  Future<dynamic> assignWorkoutToUser(@Body() Map<String, dynamic> assignment);

  // ============================================================================
  // WORKOUT SCHEMAS ENDPOINTS (STANDALONE)
  // ============================================================================

  @GET("/schede_standalone.php")
  Future<dynamic> getWorkouts(@Query("user_id") int userId);

  @GET("/schede_standalone.php")
  Future<dynamic> getWorkoutExercises(@Query("scheda_id") int schedaId);

  @POST("/create_scheda_standalone.php")
  Future<dynamic> createWorkoutStandalone(@Body() Map<String, dynamic> workout);

  @PUT("/schede_standalone.php")
  Future<dynamic> updateWorkoutStandalone(
      @Body() Map<String, dynamic> workout,
      {@Query("action") String action = "update"}
      );

  // ============================================================================
  // IMAGES ENDPOINTS
  // ============================================================================

  @GET("/available_images.php")
  Future<dynamic> getAvailableImages();

  // ============================================================================
  // EXERCISES ENDPOINTS (STANDALONE)
  // ============================================================================

  @GET("/get_esercizi_standalone.php")
  Future<dynamic> getAvailableExercises(@Query("user_id") int userId);

  // ============================================================================
  // CUSTOM EXERCISES ENDPOINTS
  // ============================================================================

  @POST("/custom_exercise_standalone.php")
  Future<dynamic> createCustomExercise(@Body() Map<String, dynamic> exercise);

  @PUT("/custom_exercise_standalone.php")
  Future<dynamic> updateCustomExercise(@Body() Map<String, dynamic> exercise);

  @DELETE("/custom_exercise_standalone.php")
  Future<dynamic> deleteCustomExercise(@Body() Map<String, dynamic> request);

  // ============================================================================
  // ACTIVE WORKOUT ENDPOINTS
  // ============================================================================

  @POST("/start_active_workout_standalone.php")
  Future<dynamic> startWorkout(@Body() Map<String, dynamic> request);

  @GET("/check_pending_workout.php")
  Future<dynamic> checkPendingWorkout(@Query("user_id") int userId);

  @POST("/complete_allenamento_standalone.php")
  Future<dynamic> completeWorkout(@Body() Map<String, dynamic> request);

  // ============================================================================
  // WORKOUT HISTORY ENDPOINTS
  // ============================================================================

  @GET("/get_allenamenti_standalone.php")
  Future<dynamic> getWorkoutHistory(@Query("user_id") int userId);

  @POST("/delete_allenamento_standalone.php")
  Future<dynamic> deleteWorkoutFromHistory(@Body() Map<String, dynamic> request);

  // ============================================================================
  // COMPLETED SERIES ENDPOINTS
  // ============================================================================

  @GET("/get_completed_series_standalone.php")
  Future<dynamic> getCompletedSeries(@Query("allenamento_id") int allenamentoId);

  @GET("/get_completed_series_standalone.php")
  Future<dynamic> getWorkoutSeriesDetail(@Query("allenamento_id") int allenamentoId);

  @POST("/save_completed_series.php")
  Future<dynamic> saveCompletedSeries(@Body() Map<String, dynamic> request);

  @PUT("/update_completed_series.php")
  Future<dynamic> updateCompletedSeries(@Body() Map<String, dynamic> request);

  @POST("/delete_completed_series.php")
  Future<dynamic> deleteCompletedSeries(@Body() Map<String, dynamic> request);

  @GET("/serie_completate.php")
  Future<dynamic> getSerieCompletate({
    @Query("allenamento_id") int? allenamentoId,
    @Query("esercizio_id") int? esercizioId,
    @Query("user_id") int? userId,
    @Query("progress") String? progress,
  });

  @POST("/serie_completate.php")
  Future<dynamic> createSerieCompletata(@Body() Map<String, dynamic> serie);

  // ============================================================================
  // FEEDBACK ENDPOINTS
  // ============================================================================

  @POST("/feedback_api.php")
  Future<dynamic> submitFeedback(@Body() Map<String, dynamic> feedback);

  @GET("/feedback_api.php")
  Future<dynamic> getFeedback();

  @POST("/feedback_api.php")
  Future<dynamic> updateFeedbackStatus(
      @Body() Map<String, dynamic> request,
      @Query("action") String action,
      );

  @POST("/feedback_api.php")
  Future<dynamic> updateFeedbackNotes(
      @Body() Map<String, dynamic> request,
      @Query("action") String action,
      );

  // ============================================================================
  // STATS ENDPOINTS
  // ============================================================================

  @GET("/android_user_stats.php")
  Future<dynamic> getUserStats();

  @GET("/android_period_stats.php")
  Future<dynamic> getPeriodStats(@Query("period") String period);

  // ============================================================================
  // APP VERSION ENDPOINTS
  // ============================================================================

  @GET("/version.php")
  Future<dynamic> getAppVersion({
    @Query("platform") String? platform,
    @Query("is_tester") bool? isTester,
  });
}