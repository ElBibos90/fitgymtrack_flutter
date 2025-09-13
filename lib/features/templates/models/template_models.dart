// lib/features/templates/models/template_models.dart
import 'package:json_annotation/json_annotation.dart';

part 'template_models.g.dart';

// Helper function per convertire int a bool
bool _boolFromInt(dynamic value) {
  try {
    if (value == null) {
      print('🔍 _boolFromInt: value is null, returning false');
      return false;
    }
    if (value is bool) return value;
    if (value is int) {
      final result = value != 0;
      print('🔍 _boolFromInt: int $value -> $result');
      return result;
    }
    if (value is String) {
      final result = value == '1' || value.toLowerCase() == 'true';
      print('🔍 _boolFromInt: string "$value" -> $result');
      return result;
    }
    print('🔍 _boolFromInt: value=$value, type=${value.runtimeType}');
    return false;
  } catch (e) {
    print('❌ _boolFromInt ERROR: value=$value, type=${value.runtimeType}, error=$e');
    return false;
  }
}

// Helper function per convertire string/int a double (nullable)
double? _doubleFromDynamic(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

// Helper function per convertire string/int a double (non-nullable)
double _doubleFromDynamicRequired(dynamic value) {
  try {
    if (value == null) {
      print('🔍 _doubleFromDynamicRequired: value is null, returning 0.0');
      return 0.0;
    }
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final result = double.tryParse(value) ?? 0.0;
      print('🔍 _doubleFromDynamicRequired: string "$value" -> $result');
      return result;
    }
    print('🔍 _doubleFromDynamicRequired: value=$value, type=${value.runtimeType}');
    return 0.0;
  } catch (e) {
    print('❌ _doubleFromDynamicRequired ERROR: value=$value, type=${value.runtimeType}, error=$e');
    return 0.0;
  }
}

// Helper function per convertire dynamic a string (non-nullable)
String _stringFromDynamic(dynamic value) {
  try {
    if (value == null) return '';
    if (value is String) return value;
    print('🔍 _stringFromDynamic: value=$value, type=${value.runtimeType}');
    return value.toString();
  } catch (e) {
    print('❌ _stringFromDynamic ERROR: value=$value, type=${value.runtimeType}, error=$e');
    return '';
  }
}

// Helper function per convertire string/int a int (nullable)
int? _intFromDynamicNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

// Helper function per convertire string/int a int
int _intFromDynamic(dynamic value) {
  try {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    print('🔍 _intFromDynamic: value=$value, type=${value.runtimeType}');
    return 0;
  } catch (e) {
    print('❌ _intFromDynamic ERROR: value=$value, type=${value.runtimeType}, error=$e');
    return 0;
  }
}

/// Modello per una categoria di template
@JsonSerializable()
class TemplateCategory {
  final int id;
  final String name;
  final String description;
  final String icon;
  final String color;
  @JsonKey(name: 'sort_order', fromJson: _intFromDynamic)
  final int sortOrder;
  @JsonKey(name: 'template_count', fromJson: _intFromDynamic)
  final int templateCount;
  @JsonKey(name: 'free_template_count', fromJson: _intFromDynamic)
  final int freeTemplateCount;
  @JsonKey(name: 'premium_template_count', fromJson: _intFromDynamic)
  final int premiumTemplateCount;

  const TemplateCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.sortOrder,
    required this.templateCount,
    required this.freeTemplateCount,
    required this.premiumTemplateCount,
  });

  factory TemplateCategory.fromJson(Map<String, dynamic> json) =>
      _$TemplateCategoryFromJson(json);
  Map<String, dynamic> toJson() => _$TemplateCategoryToJson(this);
}

/// Modello per un template di allenamento
@JsonSerializable()
class WorkoutTemplate {
  final int id;
  final String name;
  final String description;
  @JsonKey(name: 'category_id', fromJson: _intFromDynamic)
  final int categoryId;
  @JsonKey(name: 'category_name')
  final String categoryName;
  @JsonKey(name: 'category_icon')
  final String categoryIcon;
  @JsonKey(name: 'category_color')
  final String categoryColor;
  @JsonKey(name: 'difficulty_level')
  final String difficultyLevel;
  final String goal;
  @JsonKey(name: 'muscle_groups')
  final List<String>? muscleGroups;
  @JsonKey(name: 'equipment_required')
  final List<String>? equipmentRequired;
  @JsonKey(name: 'duration_weeks', fromJson: _intFromDynamicNullable)
  final int? durationWeeks;
  @JsonKey(name: 'sessions_per_week', fromJson: _intFromDynamicNullable)
  final int? sessionsPerWeek;
  @JsonKey(name: 'estimated_duration_minutes', fromJson: _intFromDynamicNullable)
  final int? estimatedDurationMinutes;
  @JsonKey(name: 'is_premium', fromJson: _boolFromInt)
  final bool isPremium;
  @JsonKey(name: 'is_featured', fromJson: _boolFromInt)
  final bool isFeatured;
  @JsonKey(name: 'rating_average', fromJson: _doubleFromDynamicRequired)
  final double ratingAverage;
  @JsonKey(name: 'rating_count', fromJson: _intFromDynamic)
  final int ratingCount;
  @JsonKey(name: 'usage_count', fromJson: _intFromDynamic)
  final int usageCount;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'user_has_access', fromJson: _boolFromInt, defaultValue: true)
  final bool userHasAccess;
  final List<TemplateExercise>? exercises;
  @JsonKey(name: 'recent_reviews')
  final List<TemplateReview>? recentReviews;
  @JsonKey(name: 'user_rating')
  final TemplateRating? userRating;

  const WorkoutTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.difficultyLevel,
    required this.goal,
    this.muscleGroups,
    this.equipmentRequired,
    this.durationWeeks,
    this.sessionsPerWeek,
    this.estimatedDurationMinutes,
    required this.isPremium,
    required this.isFeatured,
    required this.ratingAverage,
    required this.ratingCount,
    required this.usageCount,
    required this.createdAt,
    required this.userHasAccess,
    this.exercises,
    this.recentReviews,
    this.userRating,
  });

  /// Livello di difficoltà formattato
  String get difficultyLevelFormatted {
    switch (difficultyLevel) {
      case 'beginner':
        return 'Principiante';
      case 'intermediate':
        return 'Intermedio';
      case 'advanced':
        return 'Avanzato';
      default:
        return difficultyLevel;
    }
  }

  /// Obiettivo formattato
  String get goalFormatted {
    switch (goal) {
      case 'strength':
        return 'Forza';
      case 'hypertrophy':
        return 'Ipertrofia';
      case 'endurance':
        return 'Resistenza';
      case 'weight_loss':
        return 'Dimagrimento';
      case 'general':
        return 'Generale';
      default:
        return goal;
    }
  }

  /// Durata formattata
  String get durationFormatted {
    if (durationWeeks == null) return 'Non specificato';
    if (durationWeeks == 1) {
      return '1 settimana';
    } else if (durationWeeks! < 5) {
      return '$durationWeeks settimane';
    } else {
      final months = (durationWeeks! / 4).round();
      return '$months ${months == 1 ? 'mese' : 'mesi'}';
    }
  }

  /// Durata stimata formattata
  String get estimatedDurationFormatted {
    if (estimatedDurationMinutes == null) return 'Non specificato';
    if (estimatedDurationMinutes! < 60) {
      return '${estimatedDurationMinutes}min';
    } else {
      final hours = estimatedDurationMinutes! ~/ 60;
      final minutes = estimatedDurationMinutes! % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}min';
      }
    }
  }

  /// Rating formattato
  String get ratingFormatted {
    if (ratingCount == 0) {
      return 'Nessuna valutazione';
    }
    return '${ratingAverage.toStringAsFixed(1)} ($ratingCount valutazioni)';
  }

  /// Gruppi muscolari formattati
  String get muscleGroupsFormatted {
    if (muscleGroups == null || muscleGroups!.isEmpty) {
      return 'Tutto il corpo';
    }
    return muscleGroups!.join(', ');
  }

  /// Attrezzature formattate
  String get equipmentFormatted {
    if (equipmentRequired == null || equipmentRequired!.isEmpty) {
      return 'Corpo libero';
    }
    return equipmentRequired!.join(', ');
  }

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 WorkoutTemplate.fromJson: parsing template ${json['id']} - ${json['name']}');
      return _$WorkoutTemplateFromJson(json);
    } catch (e) {
      print('❌ WorkoutTemplate.fromJson ERROR: template ${json['id']} - ${json['name']}, error=$e');
      print('❌ JSON data: $json');
      rethrow;
    }
  }
  Map<String, dynamic> toJson() => _$WorkoutTemplateToJson(this);
}

/// Modello per un esercizio in un template
@JsonSerializable()
class TemplateExercise {
  @JsonKey(fromJson: _intFromDynamic)
  final int id;
  @JsonKey(name: 'template_id', fromJson: _intFromDynamic)
  final int templateId;
  @JsonKey(name: 'exercise_id', fromJson: _intFromDynamic)
  final int exerciseId;
  @JsonKey(name: 'order_index', fromJson: _intFromDynamic)
  final int orderIndex;
  @JsonKey(fromJson: _intFromDynamic)
  final int sets;
  @JsonKey(name: 'reps_min', fromJson: _intFromDynamic)
  final int repsMin;
  @JsonKey(name: 'reps_max', fromJson: _intFromDynamic)
  final int repsMax;
  @JsonKey(name: 'weight_percentage', fromJson: _doubleFromDynamicRequired)
  final double weightPercentage;
  @JsonKey(name: 'rest_seconds', fromJson: _intFromDynamic)
  final int restSeconds;
  @JsonKey(name: 'set_type')
  final String setType;
  @JsonKey(name: 'linked_to_previous', fromJson: _boolFromInt)
  final bool linkedToPrevious;
  @JsonKey(name: 'is_rest_pause', fromJson: _boolFromInt)
  final bool isRestPause;
  @JsonKey(name: 'rest_pause_reps', fromJson: _intFromDynamic)
  final int restPauseReps;
  @JsonKey(name: 'rest_pause_rest_seconds', fromJson: _intFromDynamic)
  final int restPauseRestSeconds;
  @JsonKey(fromJson: _stringFromDynamic)
  final String notes;
  @JsonKey(name: 'exercise_name')
  final String exerciseName;
  @JsonKey(name: 'exercise_description')
  final String exerciseDescription;
  @JsonKey(name: 'muscle_groups')
  final String muscleGroups;
  @JsonKey(name: 'equipment', fromJson: _stringFromDynamic)
  final String equipment;
  @JsonKey(name: 'image_url', fromJson: _stringFromDynamic)
  final String imageUrl;
  @JsonKey(name: 'is_isometric', fromJson: _intFromDynamic)
  final int isIsometric;

  const TemplateExercise({
    required this.id,
    required this.templateId,
    required this.exerciseId,
    required this.orderIndex,
    required this.sets,
    required this.repsMin,
    required this.repsMax,
    required this.weightPercentage,
    required this.restSeconds,
    required this.setType,
    required this.linkedToPrevious,
    required this.isRestPause,
    required this.restPauseReps,
    required this.restPauseRestSeconds,
    required this.notes,
    required this.exerciseName,
    required this.exerciseDescription,
    required this.muscleGroups,
    required this.equipment,
    required this.imageUrl,
    required this.isIsometric,
  });

  /// Ripetizioni formattate
  String get repsFormatted {
    if (repsMin == repsMax) {
      return '$repsMin';
    } else {
      return '$repsMin-$repsMax';
    }
  }

  /// Tipo di set formattato
  String get setTypeFormatted {
    switch (setType) {
      case 'normal':
        return 'Normale';
      case 'superset':
        return 'Superset';
      case 'dropset':
        return 'Dropset';
      case 'rest_pause':
        return 'Rest-Pause';
      case 'giant_set':
        return 'Giant Set';
      case 'circuit':
        return 'Circuit';
      default:
        return setType;
    }
  }

  /// Tempo di recupero formattato
  String get restTimeFormatted {
    if (restSeconds < 60) {
      return '${restSeconds}s';
    } else {
      final minutes = restSeconds ~/ 60;
      final seconds = restSeconds % 60;
      if (seconds == 0) {
        return '${minutes}min';
      } else {
        return '${minutes}min ${seconds}s';
      }
    }
  }

  /// Proprietà calcolata per compatibilità
  bool get isIsometricBool => isIsometric > 0;

  factory TemplateExercise.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 TemplateExercise.fromJson: parsing exercise ${json['exercise_id']} - ${json['exercise_name']}');
      return _$TemplateExerciseFromJson(json);
    } catch (e) {
      print('❌ TemplateExercise.fromJson ERROR: exercise ${json['exercise_id']} - ${json['exercise_name']}, error=$e');
      print('❌ JSON data: $json');
      rethrow;
    }
  }
  Map<String, dynamic> toJson() => _$TemplateExerciseToJson(this);
}

/// Modello per una recensione di template
@JsonSerializable()
class TemplateReview {
  final int rating;
  final String? review;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'user_name')
  final String userName;

  const TemplateReview({
    required this.rating,
    this.review,
    required this.createdAt,
    required this.userName,
  });

  factory TemplateReview.fromJson(Map<String, dynamic> json) =>
      _$TemplateReviewFromJson(json);
  Map<String, dynamic> toJson() => _$TemplateReviewToJson(this);
}

/// Modello per il rating di un utente su un template
@JsonSerializable()
class TemplateRating {
  final int rating;
  final String? review;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  const TemplateRating({
    required this.rating,
    this.review,
    required this.createdAt,
    this.updatedAt,
  });

  factory TemplateRating.fromJson(Map<String, dynamic> json) =>
      _$TemplateRatingFromJson(json);
  Map<String, dynamic> toJson() => _$TemplateRatingToJson(this);
}

/// Modello per la risposta della lista di template
@JsonSerializable()
class TemplatesResponse {
  final bool success;
  final List<WorkoutTemplate> templates;
  final TemplatesPagination pagination;
  @JsonKey(name: 'user_premium', fromJson: _boolFromInt, defaultValue: false)
  final bool userPremium;

  const TemplatesResponse({
    required this.success,
    required this.templates,
    required this.pagination,
    required this.userPremium,
  });

  factory TemplatesResponse.fromJson(Map<String, dynamic> json) =>
      _$TemplatesResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TemplatesResponseToJson(this);
}

/// Modello per la paginazione dei template
@JsonSerializable()
class TemplatesPagination {
  @JsonKey(fromJson: _intFromDynamic)
  final int total;
  @JsonKey(fromJson: _intFromDynamic)
  final int limit;
  @JsonKey(fromJson: _intFromDynamic)
  final int page;
  @JsonKey(fromJson: _intFromDynamic)
  final int pages;

  const TemplatesPagination({
    required this.total,
    required this.limit,
    required this.page,
    required this.pages,
  });

  /// Calcola se ci sono più pagine disponibili
  bool get hasMore => page < pages;

  factory TemplatesPagination.fromJson(Map<String, dynamic> json) =>
      _$TemplatesPaginationFromJson(json);
  Map<String, dynamic> toJson() => _$TemplatesPaginationToJson(this);
}

/// Modello per la risposta delle categorie
@JsonSerializable()
class CategoriesResponse {
  final bool success;
  final List<TemplateCategory> categories;

  const CategoriesResponse({
    required this.success,
    required this.categories,
  });

  factory CategoriesResponse.fromJson(Map<String, dynamic> json) =>
      _$CategoriesResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CategoriesResponseToJson(this);
}

/// Modello per la risposta dei dettagli di un template
@JsonSerializable()
class TemplateDetailsResponse {
  final bool success;
  final WorkoutTemplate template;
  @JsonKey(name: 'user_premium', fromJson: _boolFromInt, defaultValue: false)
  final bool userPremium;

  const TemplateDetailsResponse({
    required this.success,
    required this.template,
    required this.userPremium,
  });

  factory TemplateDetailsResponse.fromJson(Map<String, dynamic> json) =>
      _$TemplateDetailsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TemplateDetailsResponseToJson(this);
}

/// Modello per la creazione di una scheda da template
@JsonSerializable()
class CreateWorkoutFromTemplateRequest {
  @JsonKey(name: 'template_id')
  final int templateId;
  @JsonKey(name: 'workout_name')
  final String workoutName;
  @JsonKey(name: 'workout_description')
  final String? workoutDescription;

  const CreateWorkoutFromTemplateRequest({
    required this.templateId,
    required this.workoutName,
    this.workoutDescription,
  });

  factory CreateWorkoutFromTemplateRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateWorkoutFromTemplateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateWorkoutFromTemplateRequestToJson(this);
}

/// Modello per la risposta della creazione di una scheda da template
@JsonSerializable()
class CreateWorkoutFromTemplateResponse {
  final bool success;
  final String message;
  final Map<String, dynamic> workout;
  @JsonKey(name: 'template_used')
  final Map<String, dynamic> templateUsed;

  const CreateWorkoutFromTemplateResponse({
    required this.success,
    required this.message,
    required this.workout,
    required this.templateUsed,
  });

  factory CreateWorkoutFromTemplateResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateWorkoutFromTemplateResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CreateWorkoutFromTemplateResponseToJson(this);
}

/// Modello per il rating di un template
@JsonSerializable()
class TemplateRatingRequest {
  @JsonKey(name: 'template_id')
  final int templateId;
  final int rating;
  final String? review;

  const TemplateRatingRequest({
    required this.templateId,
    required this.rating,
    this.review,
  });

  factory TemplateRatingRequest.fromJson(Map<String, dynamic> json) =>
      _$TemplateRatingRequestFromJson(json);
  Map<String, dynamic> toJson() => _$TemplateRatingRequestToJson(this);
}

/// Modello per la risposta del rating
@JsonSerializable()
class TemplateRatingResponse {
  final bool success;
  final String message;
  final int rating;
  final String? review;

  const TemplateRatingResponse({
    required this.success,
    required this.message,
    required this.rating,
    this.review,
  });

  factory TemplateRatingResponse.fromJson(Map<String, dynamic> json) =>
      _$TemplateRatingResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TemplateRatingResponseToJson(this);
}

/// Modello per la valutazione di un template da parte di un utente
@JsonSerializable()
class UserTemplateRating {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'template_id')
  final int templateId;
  @JsonKey(fromJson: _doubleFromDynamicRequired)
  final double rating;
  final String? review;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'user_name')
  final String? userName;

  const UserTemplateRating({
    required this.id,
    required this.userId,
    required this.templateId,
    required this.rating,
    this.review,
    required this.createdAt,
    this.userName,
  });

  factory UserTemplateRating.fromJson(Map<String, dynamic> json) =>
      _$UserTemplateRatingFromJson(json);
  Map<String, dynamic> toJson() => _$UserTemplateRatingToJson(this);
}
