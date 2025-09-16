// lib/features/subscription/models/subscription_models.dart
import 'package:json_annotation/json_annotation.dart';

part 'subscription_models.g.dart';

/// Modello principale per l'abbonamento
@JsonSerializable()
class Subscription {
  final int? id;
  @JsonKey(name: 'user_id')
  final int? userId;
  @JsonKey(name: 'plan_id')
  final int planId;
  @JsonKey(name: 'plan_name')
  final String planName;
  final String status;
  @JsonKey(fromJson: _parseDouble, toJson: _doubleToJson)
  final double price;
  @JsonKey(name: 'max_workouts')
  final int? maxWorkouts;
  @JsonKey(name: 'max_custom_exercises')
  final int? maxCustomExercises;
  @JsonKey(name: 'current_count', fromJson: _parseInt, toJson: _intToJson)
  final int currentCount;
  @JsonKey(name: 'current_custom_exercises', fromJson: _parseInt, toJson: _intToJson)
  final int currentCustomExercises;
  @JsonKey(name: 'advanced_stats', fromJson: _parseBool, toJson: _boolToInt)
  final bool advancedStats;
  @JsonKey(name: 'cloud_backup', fromJson: _parseBool, toJson: _boolToInt)
  final bool cloudBackup;
  @JsonKey(name: 'no_ads', fromJson: _parseBool, toJson: _boolToInt)
  final bool noAds;
  @JsonKey(name: 'start_date')
  final String? startDate;
  @JsonKey(name: 'end_date')
  final String? endDate;
  @JsonKey(name: 'days_remaining')
  final int? daysRemaining;
  @JsonKey(name: 'computed_status')
  final String? computedStatus;
  @JsonKey(name: 'stripe_subscription_id')
  final String? stripeSubscriptionId;
  @JsonKey(name: 'payment_type')
  final String? paymentType;
  @JsonKey(name: 'auto_renew', fromJson: _parseBool, toJson: _boolToInt)
  final bool autoRenew;
  @JsonKey(name: 'cancel_at_period_end', fromJson: _parseBool, toJson: _boolToInt)
  final bool cancelAtPeriodEnd;

  const Subscription({
    this.id,
    this.userId,
    required this.planId,
    required this.planName,
    this.status = 'active',
    required this.price,
    this.maxWorkouts,
    this.maxCustomExercises,
    this.currentCount = 0,
    this.currentCustomExercises = 0,
    this.advancedStats = false,
    this.cloudBackup = false,
    this.noAds = false,
    this.startDate,
    this.endDate,
    this.daysRemaining,
    this.computedStatus,
    this.stripeSubscriptionId,
    this.paymentType,
    this.autoRenew = true,
    this.cancelAtPeriodEnd = false,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionToJson(this);

  /// Indica se l'abbonamento è Premium
  bool get isPremium => price > 0.0;

  /// Indica se l'abbonamento è scaduto
  bool get isExpired => computedStatus == 'expired' || status == 'expired';

  /// Indica se l'abbonamento sta per scadere (entro 7 giorni)
  bool get isExpiring => daysRemaining != null && daysRemaining! <= 7 && daysRemaining! > 0;

  /// Prezzo formattato
  String get formattedPrice {
    if (price <= 0) return 'Gratuito';
    return '€${price.toStringAsFixed(2)}/mese';
  }

  /// Indica se l'abbonamento è ricorrente (si rinnova automaticamente)
  bool get isRecurring => paymentType == 'recurring' && autoRenew && !cancelAtPeriodEnd;

  /// Indica se l'abbonamento è programmato per cancellarsi a fine periodo
  bool get willCancelAtPeriodEnd => cancelAtPeriodEnd;

  /// Indica se l'abbonamento può essere cancellato (solo Stripe e attivo)
  bool get canBeCancelled => stripeSubscriptionId != null && isPremium && !isExpired && !cancelAtPeriodEnd;

  /// Progresso schede di allenamento (0.0 - 1.0)
  double get workoutsProgress {
    if (maxWorkouts == null) return 0.0;
    return (currentCount / maxWorkouts!).clamp(0.0, 1.0);
  }

  /// Progresso esercizi personalizzati (0.0 - 1.0)
  double get customExercisesProgress {
    if (maxCustomExercises == null) return 0.0;
    return (currentCustomExercises / maxCustomExercises!).clamp(0.0, 1.0);
  }

  /// Testo per il limite schede
  String get workoutsLimitText {
    if (maxWorkouts == null) return '$currentCount/illimitate';
    return '$currentCount/$maxWorkouts';
  }

  /// Testo per il limite esercizi personalizzati
  String get customExercisesLimitText {
    if (maxCustomExercises == null) return '$currentCustomExercises/illimitati';
    return '$currentCustomExercises/$maxCustomExercises';
  }

  /// Copia con modifiche
  Subscription copyWith({
    int? id,
    int? userId,
    int? planId,
    String? planName,
    String? status,
    double? price,
    int? maxWorkouts,
    int? maxCustomExercises,
    int? currentCount,
    int? currentCustomExercises,
    bool? advancedStats,
    bool? cloudBackup,
    bool? noAds,
    String? startDate,
    String? endDate,
    int? daysRemaining,
    String? computedStatus,
    String? stripeSubscriptionId,
    String? paymentType,
    bool? autoRenew,
    bool? cancelAtPeriodEnd,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      status: status ?? this.status,
      price: price ?? this.price,
      maxWorkouts: maxWorkouts ?? this.maxWorkouts,
      maxCustomExercises: maxCustomExercises ?? this.maxCustomExercises,
      currentCount: currentCount ?? this.currentCount,
      currentCustomExercises: currentCustomExercises ?? this.currentCustomExercises,
      advancedStats: advancedStats ?? this.advancedStats,
      cloudBackup: cloudBackup ?? this.cloudBackup,
      noAds: noAds ?? this.noAds,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      computedStatus: computedStatus ?? this.computedStatus,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
      paymentType: paymentType ?? this.paymentType,
      autoRenew: autoRenew ?? this.autoRenew,
      cancelAtPeriodEnd: cancelAtPeriodEnd ?? this.cancelAtPeriodEnd,
    );
  }
}

/// Piano di abbonamento disponibile
@JsonSerializable()
class SubscriptionPlan {
  final int id;
  final String name;
  @JsonKey(fromJson: _parseDouble, toJson: _doubleToJson)
  final double price;
  @JsonKey(name: 'billing_cycle')
  final String billingCycle;
  @JsonKey(name: 'max_workouts')
  final int? maxWorkouts;
  @JsonKey(name: 'max_custom_exercises')
  final int? maxCustomExercises;
  @JsonKey(name: 'advanced_stats', fromJson: _parseBool, toJson: _boolToInt)
  final bool advancedStats;
  @JsonKey(name: 'cloud_backup', fromJson: _parseBool, toJson: _boolToInt)
  final bool cloudBackup;
  @JsonKey(name: 'no_ads', fromJson: _parseBool, toJson: _boolToInt)
  final bool noAds;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    this.billingCycle = 'monthly',
    this.maxWorkouts,
    this.maxCustomExercises,
    this.advancedStats = false,
    this.cloudBackup = false,
    this.noAds = false,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPlanFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionPlanToJson(this);

  /// Prezzo formattato
  String get formattedPrice {
    if (price <= 0) return 'Gratuito';
    return '€${price.toStringAsFixed(2)}/mese';
  }

  /// Lista delle funzionalità del piano
  List<SubscriptionFeature> get features {
    return [
      SubscriptionFeature(
        name: 'Schede di allenamento',
        isIncluded: true,
        maxDetail: maxWorkouts == null ? 'illimitate' : 'max $maxWorkouts',
      ),
      SubscriptionFeature(
        name: 'Esercizi personalizzati',
        isIncluded: true,
        maxDetail: maxCustomExercises == null ? 'illimitati' : 'max $maxCustomExercises',
      ),
      SubscriptionFeature(
        name: 'Statistiche avanzate',
        isIncluded: advancedStats,
      ),
      SubscriptionFeature(
        name: 'Backup cloud',
        isIncluded: cloudBackup,
      ),
      SubscriptionFeature(
        name: 'Nessuna pubblicità',
        isIncluded: noAds,
      ),
    ];
  }
}

/// Funzionalità di un piano
class SubscriptionFeature {
  final String name;
  final bool isIncluded;
  final String? maxDetail;

  const SubscriptionFeature({
    required this.name,
    required this.isIncluded,
    this.maxDetail,
  });

  /// Testo da mostrare
  String get displayText {
    if (maxDetail != null) {
      return '$name ($maxDetail)';
    }
    return name;
  }
}

/// Limiti di utilizzo delle risorse
@JsonSerializable()
class ResourceLimits {
  @JsonKey(name: 'limit_reached', fromJson: _parseBool)
  final bool limitReached;
  @JsonKey(name: 'current_count', fromJson: _parseInt)
  final int currentCount;
  @JsonKey(name: 'max_allowed')
  final int? maxAllowed;
  @JsonKey(fromJson: _parseInt)
  final int remaining;
  @JsonKey(name: 'subscription_status')
  final String? subscriptionStatus;
  @JsonKey(name: 'days_remaining')
  final int? daysRemaining;

  const ResourceLimits({
    required this.limitReached,
    required this.currentCount,
    this.maxAllowed,
    required this.remaining,
    this.subscriptionStatus,
    this.daysRemaining,
  });

  factory ResourceLimits.fromJson(Map<String, dynamic> json) =>
      _$ResourceLimitsFromJson(json);

  Map<String, dynamic> toJson() => _$ResourceLimitsToJson(this);

  /// Progresso (0.0 - 1.0)
  double get progress {
    if (maxAllowed == null || maxAllowed! <= 0) return 0.0;
    return (currentCount / maxAllowed!).clamp(0.0, 1.0);
  }

  /// Testo del limite
  String get limitText {
    if (maxAllowed == null) return '$currentCount/illimitati';
    return '$currentCount/$maxAllowed';
  }
}

/// Richiesta di aggiornamento piano
@JsonSerializable()
class UpdatePlanRequest {
  @JsonKey(name: 'plan_id')
  final int planId;

  const UpdatePlanRequest({required this.planId});

  factory UpdatePlanRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdatePlanRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdatePlanRequestToJson(this);
}

/// Risposta API generica per subscription
@JsonSerializable(genericArgumentFactories: true)
class SubscriptionApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  const SubscriptionApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory SubscriptionApiResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Object? json) fromJsonT,
      ) =>
      _$SubscriptionApiResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$SubscriptionApiResponseToJson(this, toJsonT);
}

/// Risposta per il controllo delle scadenze
@JsonSerializable()
class ExpiredCheckResponse {
  @JsonKey(name: 'updated_count', fromJson: _parseInt)
  final int updatedCount;

  const ExpiredCheckResponse({required this.updatedCount});

  factory ExpiredCheckResponse.fromJson(Map<String, dynamic> json) =>
      _$ExpiredCheckResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ExpiredCheckResponseToJson(this);
}

/// Risposta per l'aggiornamento del piano
@JsonSerializable()
class UpdatePlanResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'plan_name')
  final String planName;

  const UpdatePlanResponse({
    required this.success,
    required this.message,
    required this.planName,
  });

  factory UpdatePlanResponse.fromJson(Map<String, dynamic> json) =>
      _$UpdatePlanResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UpdatePlanResponseToJson(this);
}

// ============================================================================
// HELPER FUNCTIONS FOR ROBUST JSON PARSING
// ============================================================================

/// Converte qualsiasi tipo a double in modo robusto
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    try {
      return double.parse(value);
    } catch (e) {
      return 0.0;
    }
  }
  return 0.0;
}

/// Converte double a dynamic per JSON
dynamic _doubleToJson(double value) => value;

/// Converte qualsiasi tipo a int in modo robusto
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    try {
      return int.parse(value);
    } catch (e) {
      return 0;
    }
  }
  return 0;
}

/// Converte int a dynamic per JSON
dynamic _intToJson(int value) => value;

/// Converte qualsiasi tipo a bool in modo robusto
bool _parseBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    final str = value.toLowerCase();
    return str == 'true' || str == '1' || str == 'yes';
  }
  return false;
}

/// Converte bool a int per compatibilità con API PHP
int _boolToInt(bool value) => value ? 1 : 0;