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
  // WORKOUT SCHEMAS ENDPOINTS (GENERAL)
  // ============================================================================

  @GET("/schede.php")
  Future<dynamic> getWorkoutSchemas({
    @Query("show_inactive") String? showInactive,
  });

  @GET("/schede.php")
  Future<dynamic> getWorkoutSchemaById(@Query("id") int schedaId);

  @POST("/schede.php")
  Future<dynamic> createWorkoutSchema(@Body() Map<String, dynamic> scheda);

  @PUT("/schede.php")
  Future<dynamic> updateWorkoutSchema(
      @Query("id") int schedaId,
      @Body() Map<String, dynamic> scheda,
      );

  @DELETE("/schede.php")
  Future<dynamic> deleteWorkoutSchema(@Query("id") int schedaId);

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
  // EXERCISES ENDPOINTS (GENERAL)
  // ============================================================================

  @GET("/esercizi.php")
  Future<dynamic> getExercises();

  @GET("/esercizi.php")
  Future<dynamic> getExerciseById(@Query("id") int exerciseId);

  @POST("/esercizi.php")
  Future<dynamic> createExercise(@Body() Map<String, dynamic> exercise);

  @PUT("/esercizi.php")
  Future<dynamic> updateExercise(
      @Query("id") int exerciseId,
      @Body() Map<String, dynamic> exercise,
      );

  @DELETE("/esercizi.php")
  Future<dynamic> deleteExercise(@Query("id") int exerciseId);

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

  @GET("/user_exercises_standalone.php")
  Future<dynamic> getUserCustomExercises(@Query("user_id") int userId);

  @DELETE("/user_exercises_standalone.php")
  Future<dynamic> deleteUserCustomExercise(
      @Query("user_id") int userId,
      @Body() Map<String, dynamic> request,
      );

  // ============================================================================
  // EXERCISE APPROVAL ENDPOINTS (ADMIN)
  // ============================================================================

  @GET("/pending_exercises.php")
  Future<dynamic> getPendingExercises();

  @POST("/approve_exercise.php")
  Future<dynamic> approveExercise(@Body() Map<String, dynamic> request);

  // ============================================================================
  // EQUIPMENT ENDPOINTS
  // ============================================================================

  @GET("/equipment_types.php")
  Future<dynamic> getEquipmentTypes();

  @GET("/equipment_types.php")
  Future<dynamic> getEquipmentTypeById(@Query("id") int equipmentId);

  @POST("/equipment_types.php")
  Future<dynamic> createEquipmentType(@Body() Map<String, dynamic> equipment);

  @PUT("/equipment_types.php")
  Future<dynamic> updateEquipmentType(
      @Query("id") int equipmentId,
      @Body() Map<String, dynamic> equipment,
      );

  @DELETE("/equipment_types.php")
  Future<dynamic> deleteEquipmentType(@Query("id") int equipmentId);

  @GET("/equipment_weights.php")
  Future<dynamic> getEquipmentWeights(@Query("equipment_id") int equipmentId);

  @GET("/equipment_weights.php")
  Future<dynamic> getEquipmentWeightById(@Query("id") int weightId);

  @POST("/equipment_weights.php")
  Future<dynamic> createEquipmentWeight(@Body() Map<String, dynamic> weight);

  @DELETE("/equipment_weights.php")
  Future<dynamic> deleteEquipmentWeight(@Query("id") int weightId);

  @GET("/equipment_discs.php")
  Future<dynamic> getEquipmentDiscs(@Query("equipment_id") int equipmentId);

  @GET("/equipment_discs.php")
  Future<dynamic> getEquipmentDiscById(@Query("id") int discId);

  @POST("/equipment_discs.php")
  Future<dynamic> createEquipmentDisc(@Body() Map<String, dynamic> disc);

  @PUT("/equipment_discs.php")
  Future<dynamic> updateEquipmentDisc(
      @Query("id") int discId,
      @Body() Map<String, dynamic> disc,
      );

  @DELETE("/equipment_discs.php")
  Future<dynamic> deleteEquipmentDisc(@Query("id") int discId);

  @GET("/public_equipment_data.php")
  Future<dynamic> getPublicEquipmentByExercise(@Query("exercise_id") int exerciseId);

  @GET("/public_equipment_data.php")
  Future<dynamic> getPublicEquipmentBySchedaExercise(@Query("scheda_esercizi_id") int schedaEserciziId);

  // ============================================================================
  // WORKOUTS/ALLENAMENTI ENDPOINTS
  // ============================================================================

  @GET("/allenamenti.php")
  Future<dynamic> getAllenamenti();

  @GET("/allenamenti.php")
  Future<dynamic> getAllenamentoById(@Query("id") int allenamentoId);

  @POST("/allenamenti.php")
  Future<dynamic> createAllenamento(@Body() Map<String, dynamic> allenamento);

  @PUT("/allenamenti.php")
  Future<dynamic> updateAllenamento(
      @Query("id") int allenamentoId,
      @Body() Map<String, dynamic> allenamento,
      );

  @DELETE("/allenamenti.php")
  Future<dynamic> deleteAllenamento(@Query("id") int allenamentoId);

  // ============================================================================
  // ACTIVE WORKOUT ENDPOINTS
  // ============================================================================

  @POST("/start_active_workout_standalone.php")
  Future<dynamic> startWorkout(@Body() Map<String, dynamic> request);

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
  // SUBSCRIPTION ENDPOINTS
  // ============================================================================

  @GET("/subscription_api.php")
  Future<dynamic> getCurrentSubscription(@Query("action") String action);

  @GET("/subscription_api.php")
  Future<dynamic> getSubscriptionPlans(@Query("action") String action);

  @GET("/subscription_api.php")
  Future<dynamic> checkSubscriptionLimits(
      @Query("action") String action,
      @Query("resource_type") String resourceType,
      );

  @GET("/subscription_api.php")
  Future<dynamic> checkExpiredSubscriptions(@Query("action") String action);

  @POST("/subscription_api.php")
  Future<dynamic> updatePlan(
      @Body() Map<String, dynamic> request,
      @Query("action") String action,
      );

  @POST("/subscription_api.php")
  Future<dynamic> recordDonation(
      @Body() Map<String, dynamic> request,
      @Query("action") String action,
      );

  // ============================================================================
  // PAYMENT ENDPOINTS
  // ============================================================================

  @POST("/paypal_payment.php")
  Future<dynamic> createPayPalPayment(@Body() Map<String, dynamic> request);

  // ============================================================================
  // GYM REQUEST ENDPOINTS
  // ============================================================================

  @POST("/gym_request.php")
  Future<dynamic> submitGymRequest(@Body() Map<String, dynamic> request);

  @GET("/gym_requests.php")
  Future<dynamic> getGymRequests();

  @POST("/update_gym_request.php")
  Future<dynamic> updateGymRequest(@Body() Map<String, dynamic> request);

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
}