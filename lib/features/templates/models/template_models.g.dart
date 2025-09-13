// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TemplateCategory _$TemplateCategoryFromJson(Map<String, dynamic> json) =>
    TemplateCategory(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      sortOrder: _intFromDynamic(json['sort_order']),
      templateCount: _intFromDynamic(json['template_count']),
      freeTemplateCount: _intFromDynamic(json['free_template_count']),
      premiumTemplateCount: _intFromDynamic(json['premium_template_count']),
    );

Map<String, dynamic> _$TemplateCategoryToJson(TemplateCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'icon': instance.icon,
      'color': instance.color,
      'sort_order': instance.sortOrder,
      'template_count': instance.templateCount,
      'free_template_count': instance.freeTemplateCount,
      'premium_template_count': instance.premiumTemplateCount,
    };

WorkoutTemplate _$WorkoutTemplateFromJson(Map<String, dynamic> json) =>
    WorkoutTemplate(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String,
      categoryId: _intFromDynamic(json['category_id']),
      categoryName: json['category_name'] as String,
      categoryIcon: json['category_icon'] as String,
      categoryColor: json['category_color'] as String,
      difficultyLevel: json['difficulty_level'] as String,
      goal: json['goal'] as String,
      muscleGroups: (json['muscle_groups'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      equipmentRequired: (json['equipment_required'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      durationWeeks: _intFromDynamicNullable(json['duration_weeks']),
      sessionsPerWeek: _intFromDynamicNullable(json['sessions_per_week']),
      estimatedDurationMinutes:
          _intFromDynamicNullable(json['estimated_duration_minutes']),
      isPremium: _boolFromInt(json['is_premium']),
      isFeatured: _boolFromInt(json['is_featured']),
      ratingAverage: _doubleFromDynamicRequired(json['rating_average']),
      ratingCount: _intFromDynamic(json['rating_count']),
      usageCount: _intFromDynamic(json['usage_count']),
      createdAt: json['created_at'] as String,
      userHasAccess: json['user_has_access'] == null
          ? true
          : _boolFromInt(json['user_has_access']),
      exercises: (json['exercises'] as List<dynamic>?)
          ?.map((e) => TemplateExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentReviews: (json['recent_reviews'] as List<dynamic>?)
          ?.map((e) => TemplateReview.fromJson(e as Map<String, dynamic>))
          .toList(),
      userRating: json['user_rating'] == null
          ? null
          : TemplateRating.fromJson(
              json['user_rating'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$WorkoutTemplateToJson(WorkoutTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'category_id': instance.categoryId,
      'category_name': instance.categoryName,
      'category_icon': instance.categoryIcon,
      'category_color': instance.categoryColor,
      'difficulty_level': instance.difficultyLevel,
      'goal': instance.goal,
      'muscle_groups': instance.muscleGroups,
      'equipment_required': instance.equipmentRequired,
      'duration_weeks': instance.durationWeeks,
      'sessions_per_week': instance.sessionsPerWeek,
      'estimated_duration_minutes': instance.estimatedDurationMinutes,
      'is_premium': instance.isPremium,
      'is_featured': instance.isFeatured,
      'rating_average': instance.ratingAverage,
      'rating_count': instance.ratingCount,
      'usage_count': instance.usageCount,
      'created_at': instance.createdAt,
      'user_has_access': instance.userHasAccess,
      'exercises': instance.exercises,
      'recent_reviews': instance.recentReviews,
      'user_rating': instance.userRating,
    };

TemplateExercise _$TemplateExerciseFromJson(Map<String, dynamic> json) =>
    TemplateExercise(
      id: _intFromDynamic(json['id']),
      templateId: _intFromDynamic(json['template_id']),
      exerciseId: _intFromDynamic(json['exercise_id']),
      orderIndex: _intFromDynamic(json['order_index']),
      sets: _intFromDynamic(json['sets']),
      repsMin: _intFromDynamic(json['reps_min']),
      repsMax: _intFromDynamic(json['reps_max']),
      weightPercentage: _doubleFromDynamicRequired(json['weight_percentage']),
      restSeconds: _intFromDynamic(json['rest_seconds']),
      setType: json['set_type'] as String,
      linkedToPrevious: _boolFromInt(json['linked_to_previous']),
      isRestPause: _boolFromInt(json['is_rest_pause']),
      restPauseReps: _intFromDynamic(json['rest_pause_reps']),
      restPauseRestSeconds: _intFromDynamic(json['rest_pause_rest_seconds']),
      notes: _stringFromDynamic(json['notes']),
      exerciseName: json['exercise_name'] as String,
      exerciseDescription: json['exercise_description'] as String,
      muscleGroups: json['muscle_groups'] as String,
      equipment: _stringFromDynamic(json['equipment']),
      imageUrl: _stringFromDynamic(json['image_url']),
      isIsometric: _intFromDynamic(json['is_isometric']),
    );

Map<String, dynamic> _$TemplateExerciseToJson(TemplateExercise instance) =>
    <String, dynamic>{
      'id': instance.id,
      'template_id': instance.templateId,
      'exercise_id': instance.exerciseId,
      'order_index': instance.orderIndex,
      'sets': instance.sets,
      'reps_min': instance.repsMin,
      'reps_max': instance.repsMax,
      'weight_percentage': instance.weightPercentage,
      'rest_seconds': instance.restSeconds,
      'set_type': instance.setType,
      'linked_to_previous': instance.linkedToPrevious,
      'is_rest_pause': instance.isRestPause,
      'rest_pause_reps': instance.restPauseReps,
      'rest_pause_rest_seconds': instance.restPauseRestSeconds,
      'notes': instance.notes,
      'exercise_name': instance.exerciseName,
      'exercise_description': instance.exerciseDescription,
      'muscle_groups': instance.muscleGroups,
      'equipment': instance.equipment,
      'image_url': instance.imageUrl,
      'is_isometric': instance.isIsometric,
    };

TemplateReview _$TemplateReviewFromJson(Map<String, dynamic> json) =>
    TemplateReview(
      rating: (json['rating'] as num).toInt(),
      review: json['review'] as String?,
      createdAt: json['created_at'] as String,
      userName: json['user_name'] as String,
    );

Map<String, dynamic> _$TemplateReviewToJson(TemplateReview instance) =>
    <String, dynamic>{
      'rating': instance.rating,
      'review': instance.review,
      'created_at': instance.createdAt,
      'user_name': instance.userName,
    };

TemplateRating _$TemplateRatingFromJson(Map<String, dynamic> json) =>
    TemplateRating(
      rating: (json['rating'] as num).toInt(),
      review: json['review'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$TemplateRatingToJson(TemplateRating instance) =>
    <String, dynamic>{
      'rating': instance.rating,
      'review': instance.review,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

TemplatesResponse _$TemplatesResponseFromJson(Map<String, dynamic> json) =>
    TemplatesResponse(
      success: json['success'] as bool,
      templates: (json['templates'] as List<dynamic>)
          .map((e) => WorkoutTemplate.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: TemplatesPagination.fromJson(
          json['pagination'] as Map<String, dynamic>),
      userPremium: json['user_premium'] == null
          ? false
          : _boolFromInt(json['user_premium']),
    );

Map<String, dynamic> _$TemplatesResponseToJson(TemplatesResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'templates': instance.templates,
      'pagination': instance.pagination,
      'user_premium': instance.userPremium,
    };

TemplatesPagination _$TemplatesPaginationFromJson(Map<String, dynamic> json) =>
    TemplatesPagination(
      total: _intFromDynamic(json['total']),
      limit: _intFromDynamic(json['limit']),
      page: _intFromDynamic(json['page']),
      pages: _intFromDynamic(json['pages']),
    );

Map<String, dynamic> _$TemplatesPaginationToJson(
        TemplatesPagination instance) =>
    <String, dynamic>{
      'total': instance.total,
      'limit': instance.limit,
      'page': instance.page,
      'pages': instance.pages,
    };

CategoriesResponse _$CategoriesResponseFromJson(Map<String, dynamic> json) =>
    CategoriesResponse(
      success: json['success'] as bool,
      categories: (json['categories'] as List<dynamic>)
          .map((e) => TemplateCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CategoriesResponseToJson(CategoriesResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'categories': instance.categories,
    };

TemplateDetailsResponse _$TemplateDetailsResponseFromJson(
        Map<String, dynamic> json) =>
    TemplateDetailsResponse(
      success: json['success'] as bool,
      template:
          WorkoutTemplate.fromJson(json['template'] as Map<String, dynamic>),
      userPremium: json['user_premium'] == null
          ? false
          : _boolFromInt(json['user_premium']),
    );

Map<String, dynamic> _$TemplateDetailsResponseToJson(
        TemplateDetailsResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'template': instance.template,
      'user_premium': instance.userPremium,
    };

CreateWorkoutFromTemplateRequest _$CreateWorkoutFromTemplateRequestFromJson(
        Map<String, dynamic> json) =>
    CreateWorkoutFromTemplateRequest(
      templateId: (json['template_id'] as num).toInt(),
      workoutName: json['workout_name'] as String,
      workoutDescription: json['workout_description'] as String?,
    );

Map<String, dynamic> _$CreateWorkoutFromTemplateRequestToJson(
        CreateWorkoutFromTemplateRequest instance) =>
    <String, dynamic>{
      'template_id': instance.templateId,
      'workout_name': instance.workoutName,
      'workout_description': instance.workoutDescription,
    };

CreateWorkoutFromTemplateResponse _$CreateWorkoutFromTemplateResponseFromJson(
        Map<String, dynamic> json) =>
    CreateWorkoutFromTemplateResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      workout: json['workout'] as Map<String, dynamic>,
      templateUsed: json['template_used'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$CreateWorkoutFromTemplateResponseToJson(
        CreateWorkoutFromTemplateResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'workout': instance.workout,
      'template_used': instance.templateUsed,
    };

TemplateRatingRequest _$TemplateRatingRequestFromJson(
        Map<String, dynamic> json) =>
    TemplateRatingRequest(
      templateId: (json['template_id'] as num).toInt(),
      rating: (json['rating'] as num).toInt(),
      review: json['review'] as String?,
    );

Map<String, dynamic> _$TemplateRatingRequestToJson(
        TemplateRatingRequest instance) =>
    <String, dynamic>{
      'template_id': instance.templateId,
      'rating': instance.rating,
      'review': instance.review,
    };

TemplateRatingResponse _$TemplateRatingResponseFromJson(
        Map<String, dynamic> json) =>
    TemplateRatingResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      rating: (json['rating'] as num).toInt(),
      review: json['review'] as String?,
    );

Map<String, dynamic> _$TemplateRatingResponseToJson(
        TemplateRatingResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'rating': instance.rating,
      'review': instance.review,
    };

UserTemplateRating _$UserTemplateRatingFromJson(Map<String, dynamic> json) =>
    UserTemplateRating(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      templateId: (json['template_id'] as num).toInt(),
      rating: _doubleFromDynamicRequired(json['rating']),
      review: json['review'] as String?,
      createdAt: json['created_at'] as String,
      userName: json['user_name'] as String?,
    );

Map<String, dynamic> _$UserTemplateRatingToJson(UserTemplateRating instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'template_id': instance.templateId,
      'rating': instance.rating,
      'review': instance.review,
      'created_at': instance.createdAt,
      'user_name': instance.userName,
    };
