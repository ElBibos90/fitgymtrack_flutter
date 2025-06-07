// lib/features/subscription/repository/mock_subscription_repository.dart
import 'dart:developer' as developer;
import '../../../core/utils/result.dart';
import '../models/subscription_models.dart';

/// Mock repository per le subscription - per test e sviluppo
class MockSubscriptionRepository {
  // Simulazione di dati locali
  Subscription _currentSubscription = const Subscription(
    id: 1,
    userId: 1,
    planId: 1,
    planName: 'Free',
    status: 'active',
    price: 0.0,
    maxWorkouts: 3,
    maxCustomExercises: 5,
    currentCount: 1,
    currentCustomExercises: 2,
    advancedStats: false,
    cloudBackup: false,
    noAds: false,
    startDate: '2024-01-01',
    endDate: null,
    daysRemaining: null,
    computedStatus: 'active',
  );

  final List<SubscriptionPlan> _availablePlans = [
    const SubscriptionPlan(
      id: 1,
      name: 'Free',
      price: 0.0,
      maxWorkouts: 3,
      maxCustomExercises: 5,
      advancedStats: false,
      cloudBackup: false,
      noAds: false,
    ),
    const SubscriptionPlan(
      id: 2,
      name: 'Premium',
      price: 4.99,
      maxWorkouts: null,
      maxCustomExercises: null,
      advancedStats: true,
      cloudBackup: true,
      noAds: true,
    ),
  ];

  /// Recupera l'abbonamento corrente (MOCK)
  Future<Result<Subscription>> getCurrentSubscription() async {
    developer.log('🎯 [MOCK] getCurrentSubscription chiamato', name: 'MockSubscriptionRepository');

    // Simula delay di rete
    await Future.delayed(const Duration(milliseconds: 500));

    developer.log(
      '🎯 [MOCK] Ritornando subscription: ${_currentSubscription.planName} - €${_currentSubscription.price}',
      name: 'MockSubscriptionRepository',
    );

    return Result.success(_currentSubscription);
  }

  /// Controlla le subscription scadute (MOCK)
  Future<Result<ExpiredCheckResponse>> checkExpiredSubscriptions() async {
    developer.log('🎯 [MOCK] checkExpiredSubscriptions chiamato', name: 'MockSubscriptionRepository');

    await Future.delayed(const Duration(milliseconds: 200));

    // Simula che non ci sono subscription scadute
    const response = ExpiredCheckResponse(updatedCount: 0);

    developer.log('🎯 [MOCK] Nessuna subscription scaduta trovata', name: 'MockSubscriptionRepository');

    return Result.success(response);
  }

  /// Verifica i limiti di utilizzo (MOCK)
  Future<Result<ResourceLimits>> checkResourceLimits(String resourceType) async {
    developer.log('🎯 [MOCK] checkResourceLimits chiamato per: $resourceType', name: 'MockSubscriptionRepository');

    await Future.delayed(const Duration(milliseconds: 300));

    ResourceLimits limits;

    if (resourceType == 'max_workouts') {
      final maxWorkouts = _currentSubscription.maxWorkouts ?? 999;
      limits = ResourceLimits(
        limitReached: _currentSubscription.currentCount >= maxWorkouts,
        currentCount: _currentSubscription.currentCount,
        maxAllowed: _currentSubscription.maxWorkouts,
        remaining: maxWorkouts - _currentSubscription.currentCount,
        subscriptionStatus: _currentSubscription.status,
        daysRemaining: _currentSubscription.daysRemaining,
      );
    } else if (resourceType == 'max_custom_exercises') {
      final maxCustomExercises = _currentSubscription.maxCustomExercises ?? 999;
      limits = ResourceLimits(
        limitReached: _currentSubscription.currentCustomExercises >= maxCustomExercises,
        currentCount: _currentSubscription.currentCustomExercises,
        maxAllowed: _currentSubscription.maxCustomExercises,
        remaining: maxCustomExercises - _currentSubscription.currentCustomExercises,
        subscriptionStatus: _currentSubscription.status,
        daysRemaining: _currentSubscription.daysRemaining,
      );
    } else {
      limits = const ResourceLimits(
        limitReached: false,
        currentCount: 0,
        maxAllowed: null,
        remaining: 999,
      );
    }

    developer.log(
      '🎯 [MOCK] Limiti per $resourceType: ${limits.currentCount}/${limits.maxAllowed}',
      name: 'MockSubscriptionRepository',
    );

    return Result.success(limits);
  }

  /// Aggiorna il piano di abbonamento (MOCK)
  Future<Result<UpdatePlanResponse>> updatePlan(int planId) async {
    developer.log('🎯 [MOCK] updatePlan chiamato per planId: $planId', name: 'MockSubscriptionRepository');

    await Future.delayed(const Duration(milliseconds: 1000));

    // Trova il piano richiesto
    final plan = _availablePlans.firstWhere(
          (p) => p.id == planId,
      orElse: () => _availablePlans.first,
    );

    // Aggiorna la subscription corrente
    _currentSubscription = _currentSubscription.copyWith(
      planId: plan.id,
      planName: plan.name,
      price: plan.price,
      maxWorkouts: plan.maxWorkouts,
      maxCustomExercises: plan.maxCustomExercises,
      advancedStats: plan.advancedStats,
      cloudBackup: plan.cloudBackup,
      noAds: plan.noAds,
    );

    final response = UpdatePlanResponse(
      success: true,
      message: 'Piano aggiornato con successo a ${plan.name}',
      planName: plan.name,
    );

    developer.log(
      '🎯 [MOCK] Piano aggiornato a: ${_currentSubscription.planName}',
      name: 'MockSubscriptionRepository',
    );

    return Result.success(response);
  }

  /// Ottiene i piani disponibili (MOCK)
  Future<Result<List<SubscriptionPlan>>> getAvailablePlans() async {
    developer.log('🎯 [MOCK] getAvailablePlans chiamato', name: 'MockSubscriptionRepository');

    await Future.delayed(const Duration(milliseconds: 300));

    developer.log(
      '🎯 [MOCK] Ritornando ${_availablePlans.length} piani disponibili',
      name: 'MockSubscriptionRepository',
    );

    return Result.success(_availablePlans);
  }

  /// Verifica se l'utente può creare una nuova scheda (MOCK)
  Future<Result<bool>> canCreateWorkout() async {
    developer.log('🎯 [MOCK] canCreateWorkout chiamato', name: 'MockSubscriptionRepository');

    await Future.delayed(const Duration(milliseconds: 100));

    final canCreate = _currentSubscription.maxWorkouts == null ||
        _currentSubscription.currentCount < _currentSubscription.maxWorkouts!;

    developer.log(
      '🎯 [MOCK] Può creare scheda: $canCreate (${_currentSubscription.currentCount}/${_currentSubscription.maxWorkouts})',
      name: 'MockSubscriptionRepository',
    );

    return Result.success(canCreate);
  }

  /// Verifica se l'utente può creare un nuovo esercizio personalizzato (MOCK)
  Future<Result<bool>> canCreateCustomExercise() async {
    developer.log('🎯 [MOCK] canCreateCustomExercise chiamato', name: 'MockSubscriptionRepository');

    await Future.delayed(const Duration(milliseconds: 100));

    final canCreate = _currentSubscription.maxCustomExercises == null ||
        _currentSubscription.currentCustomExercises < _currentSubscription.maxCustomExercises!;

    developer.log(
      '🎯 [MOCK] Può creare esercizio: $canCreate (${_currentSubscription.currentCustomExercises}/${_currentSubscription.maxCustomExercises})',
      name: 'MockSubscriptionRepository',
    );

    return Result.success(canCreate);
  }

  // ============================================================================
  // METODI HELPER PER TESTING
  // ============================================================================

  /// Simula upgrade a Premium per testing
  void simulateUpgradeToPremium() {
    _currentSubscription = _currentSubscription.copyWith(
      planId: 2,
      planName: 'Premium',
      price: 4.99,
      maxWorkouts: null,
      maxCustomExercises: null,
      advancedStats: true,
      cloudBackup: true,
      noAds: true,
    );
    developer.log('🎯 [MOCK] Simulato upgrade a Premium', name: 'MockSubscriptionRepository');
  }

  /// Simula downgrade a Free per testing
  void simulateDowngradeToFree() {
    _currentSubscription = _currentSubscription.copyWith(
      planId: 1,
      planName: 'Free',
      price: 0.0,
      maxWorkouts: 3,
      maxCustomExercises: 5,
      advancedStats: false,
      cloudBackup: false,
      noAds: false,
    );
    developer.log('🎯 [MOCK] Simulato downgrade a Free', name: 'MockSubscriptionRepository');
  }

  /// Simula subscription scaduta per testing
  void simulateExpiredSubscription() {
    _currentSubscription = _currentSubscription.copyWith(
      planName: 'Free',
      price: 0.0,
      status: 'expired',
      computedStatus: 'expired',
      daysRemaining: 0,
    );
    developer.log('🎯 [MOCK] Simulata subscription scaduta', name: 'MockSubscriptionRepository');
  }

  /// Simula limite raggiunto per testing
  void simulateWorkoutLimitReached() {
    _currentSubscription = _currentSubscription.copyWith(
      currentCount: _currentSubscription.maxWorkouts ?? 3,
    );
    developer.log('🎯 [MOCK] Simulato limite schede raggiunto', name: 'MockSubscriptionRepository');
  }

  /// Reset ai valori di default
  void reset() {
    _currentSubscription = const Subscription(
      id: 1,
      userId: 1,
      planId: 1,
      planName: 'Free',
      status: 'active',
      price: 0.0,
      maxWorkouts: 3,
      maxCustomExercises: 5,
      currentCount: 1,
      currentCustomExercises: 2,
      advancedStats: false,
      cloudBackup: false,
      noAds: false,
      startDate: '2024-01-01',
      endDate: null,
      daysRemaining: null,
      computedStatus: 'active',
    );
    developer.log('🎯 [MOCK] Reset ai valori di default', name: 'MockSubscriptionRepository');
  }
}