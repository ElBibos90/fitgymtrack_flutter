// lib/features/subscription/models/gym_subscription.dart

/// Modello per l'abbonamento palestra
class GymSubscription {
  final int id;
  final int gymId;
  final String gymName;
  final String planName;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int? maxWorkouts;
  final int? maxCustomExercises;
  final bool hasAdvancedStats;
  final bool hasCloudBackup;
  final bool hasNoAds;
  final int daysRemaining;
  final double price;
  final String currency;

  const GymSubscription({
    required this.id,
    required this.gymId,
    required this.gymName,
    required this.planName,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.maxWorkouts,
    this.maxCustomExercises,
    required this.hasAdvancedStats,
    required this.hasCloudBackup,
    required this.hasNoAds,
    required this.daysRemaining,
    required this.price,
    required this.currency,
  });

  /// Verifica se l'abbonamento è scaduto
  bool get isExpired => DateTime.now().isAfter(endDate);

  /// Verifica se l'abbonamento è attivo e non scaduto
  bool get isValid => isActive && !isExpired;

  /// Ottieni il nome del piano formattato
  String get formattedPlanName {
    if (planName.toLowerCase().contains('premium')) {
      return 'Premium';
    } else if (planName.toLowerCase().contains('pro')) {
      return 'Pro';
    } else if (planName.toLowerCase().contains('basic')) {
      return 'Base';
    }
    return planName;
  }

  /// Ottieni il prezzo formattato
  String get formattedPrice {
    if (price == 0) {
      return 'Gratuito';
    }
    return '${price.toStringAsFixed(2)} $currency';
  }

  /// Ottieni i giorni rimanenti formattati
  String get formattedDaysRemaining {
    if (daysRemaining <= 0) {
      return 'Scaduto';
    } else if (daysRemaining == 1) {
      return '1 giorno';
    } else {
      return '$daysRemaining giorni';
    }
  }

  factory GymSubscription.fromJson(Map<String, dynamic> json) {
    return GymSubscription(
      id: json['id'] ?? 0,
      gymId: json['gym_id'] ?? 0,
      gymName: json['gym_name'] ?? 'Palestra',
      planName: json['subscription_name'] ?? 'Piano Base',
      startDate: json['start_date'] != null 
          ? DateTime.parse(json['start_date']) 
          : DateTime.now(),
      endDate: json['end_date'] != null 
          ? DateTime.parse(json['end_date']) 
          : DateTime.now().add(const Duration(days: 30)),
      isActive: json['status'] == 'active',
      maxWorkouts: json['max_workouts'],
      maxCustomExercises: json['max_custom_exercises'],
      hasAdvancedStats: json['advanced_stats'] == 1,
      hasCloudBackup: json['cloud_backup'] == 1,
      hasNoAds: json['no_ads'] == 1,
      daysRemaining: json['days_remaining'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'EUR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gym_id': gymId,
      'gym_name': gymName,
      'subscription_name': planName,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': isActive ? 'active' : 'inactive',
      'max_workouts': maxWorkouts,
      'max_custom_exercises': maxCustomExercises,
      'advanced_stats': hasAdvancedStats ? 1 : 0,
      'cloud_backup': hasCloudBackup ? 1 : 0,
      'no_ads': hasNoAds ? 1 : 0,
      'days_remaining': daysRemaining,
      'price': price,
      'currency': currency,
    };
  }

  @override
  String toString() {
    return 'GymSubscription(id: $id, gymName: $gymName, planName: $planName, isActive: $isActive, daysRemaining: $daysRemaining)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GymSubscription && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
