// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Subscription _$SubscriptionFromJson(Map<String, dynamic> json) => Subscription(
      id: (json['id'] as num?)?.toInt(),
      userId: (json['user_id'] as num?)?.toInt(),
      planId: (json['plan_id'] as num).toInt(),
      planName: json['plan_name'] as String,
      status: json['status'] as String? ?? 'active',
      price: _parseDouble(json['price']),
      maxWorkouts: (json['max_workouts'] as num?)?.toInt(),
      maxCustomExercises: (json['max_custom_exercises'] as num?)?.toInt(),
      currentCount:
          json['current_count'] == null ? 0 : _parseInt(json['current_count']),
      currentCustomExercises: json['current_custom_exercises'] == null
          ? 0
          : _parseInt(json['current_custom_exercises']),
      advancedStats: json['advanced_stats'] == null
          ? false
          : _parseBool(json['advanced_stats']),
      cloudBackup: json['cloud_backup'] == null
          ? false
          : _parseBool(json['cloud_backup']),
      noAds: json['no_ads'] == null ? false : _parseBool(json['no_ads']),
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      daysRemaining: (json['days_remaining'] as num?)?.toInt(),
      computedStatus: json['computed_status'] as String?,
    );

Map<String, dynamic> _$SubscriptionToJson(Subscription instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'plan_id': instance.planId,
      'plan_name': instance.planName,
      'status': instance.status,
      'price': _doubleToJson(instance.price),
      'max_workouts': instance.maxWorkouts,
      'max_custom_exercises': instance.maxCustomExercises,
      'current_count': _intToJson(instance.currentCount),
      'current_custom_exercises': _intToJson(instance.currentCustomExercises),
      'advanced_stats': _boolToInt(instance.advancedStats),
      'cloud_backup': _boolToInt(instance.cloudBackup),
      'no_ads': _boolToInt(instance.noAds),
      'start_date': instance.startDate,
      'end_date': instance.endDate,
      'days_remaining': instance.daysRemaining,
      'computed_status': instance.computedStatus,
    };

SubscriptionPlan _$SubscriptionPlanFromJson(Map<String, dynamic> json) =>
    SubscriptionPlan(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      price: _parseDouble(json['price']),
      billingCycle: json['billing_cycle'] as String? ?? 'monthly',
      maxWorkouts: (json['max_workouts'] as num?)?.toInt(),
      maxCustomExercises: (json['max_custom_exercises'] as num?)?.toInt(),
      advancedStats: json['advanced_stats'] == null
          ? false
          : _parseBool(json['advanced_stats']),
      cloudBackup: json['cloud_backup'] == null
          ? false
          : _parseBool(json['cloud_backup']),
      noAds: json['no_ads'] == null ? false : _parseBool(json['no_ads']),
    );

Map<String, dynamic> _$SubscriptionPlanToJson(SubscriptionPlan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'price': _doubleToJson(instance.price),
      'billing_cycle': instance.billingCycle,
      'max_workouts': instance.maxWorkouts,
      'max_custom_exercises': instance.maxCustomExercises,
      'advanced_stats': _boolToInt(instance.advancedStats),
      'cloud_backup': _boolToInt(instance.cloudBackup),
      'no_ads': _boolToInt(instance.noAds),
    };

ResourceLimits _$ResourceLimitsFromJson(Map<String, dynamic> json) =>
    ResourceLimits(
      limitReached: _parseBool(json['limit_reached']),
      currentCount: _parseInt(json['current_count']),
      maxAllowed: (json['max_allowed'] as num?)?.toInt(),
      remaining: _parseInt(json['remaining']),
      subscriptionStatus: json['subscription_status'] as String?,
      daysRemaining: (json['days_remaining'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ResourceLimitsToJson(ResourceLimits instance) =>
    <String, dynamic>{
      'limit_reached': instance.limitReached,
      'current_count': instance.currentCount,
      'max_allowed': instance.maxAllowed,
      'remaining': instance.remaining,
      'subscription_status': instance.subscriptionStatus,
      'days_remaining': instance.daysRemaining,
    };

UpdatePlanRequest _$UpdatePlanRequestFromJson(Map<String, dynamic> json) =>
    UpdatePlanRequest(
      planId: (json['plan_id'] as num).toInt(),
    );

Map<String, dynamic> _$UpdatePlanRequestToJson(UpdatePlanRequest instance) =>
    <String, dynamic>{
      'plan_id': instance.planId,
    };

SubscriptionApiResponse<T> _$SubscriptionApiResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    SubscriptionApiResponse<T>(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: _$nullableGenericFromJson(json['data'], fromJsonT),
    );

Map<String, dynamic> _$SubscriptionApiResponseToJson<T>(
  SubscriptionApiResponse<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': _$nullableGenericToJson(instance.data, toJsonT),
    };

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) =>
    input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) =>
    input == null ? null : toJson(input);

ExpiredCheckResponse _$ExpiredCheckResponseFromJson(
        Map<String, dynamic> json) =>
    ExpiredCheckResponse(
      updatedCount: _parseInt(json['updated_count']),
    );

Map<String, dynamic> _$ExpiredCheckResponseToJson(
        ExpiredCheckResponse instance) =>
    <String, dynamic>{
      'updated_count': instance.updatedCount,
    };

UpdatePlanResponse _$UpdatePlanResponseFromJson(Map<String, dynamic> json) =>
    UpdatePlanResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      planName: json['plan_name'] as String,
    );

Map<String, dynamic> _$UpdatePlanResponseToJson(UpdatePlanResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'plan_name': instance.planName,
    };
