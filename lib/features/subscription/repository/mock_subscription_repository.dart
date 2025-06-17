// lib/features/subscription/repository/mock_subscription_repository.dart

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
    ////print('[CONSOLE] [mock_subscription_repository]🎯 [MOCK] getCurrentSubscription chiamato');

    // Simula delay di rete
    await Future.delayed(const Duration(milliseconds: 500));

    /*print(
      '🎯 [MOCK] Ritornando subscription: ${_currentSubscription.planName} - €${_currentSubscription.price}'
    );*/

    return Result.success(_currentSubscription);
  }

  /// Controlla le subscription scadute (MOCK)
  Future<Result<ExpiredCheckResponse>> checkExpiredSubscriptions() async {
    ////print('[CONSOLE] [mock_subscription_repository]🎯 [MOCK] checkExpiredSubscriptions chiamato');

    await Future.delayed(const Duration(milliseconds: 200));

    // Simula che non ci sono subscription scadute
    const response = ExpiredCheckResponse(updatedCount: 0);

    ////print('[CONSOLE] [mock_subscription_repository]🎯 [MOCK] Nessuna subscription scaduta trovata');

    return Result.success(response);
  }

  /// Verifica i limiti di utilizzo (MOCK)
  Future<Result<ResourceLimits>> checkResourceLimits(String resourceType) async {
    ////print('[CONSOLE] [mock_subscription_repository]🎯 [MOCK] checkResourceLimits chiamato per: $resourceType');

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

    print(
      '🎯 [MOCK] Limiti per $resourceType: ${limits.currentCount}/${limits.maxAllowed}'
    );

    return Result.success(limits);
  }

  /// Aggiorna il piano di abbonamento (MOCK)
  Future<Result<UpdatePlanResponse>> updatePlan(int planId) async {
    ////print('[CONSOLE] [mock_subscription_repository]🎯 [MOCK] updatePlan chiamato per planId: $planId');

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

    /*print(
      '🎯 [MOCK] Piano aggiornato a: ${_currentSubscription.planName}'
    );*/

    return Result.success(response);
  }

  /// Ottiene i piani disponibili (MOCK)
  Future<Result<List<SubscriptionPlan>>> getAvailablePlans() async {
    //print('[CONSOLE] [mock_subscription_repository]🎯 [MOCK] getAvailablePlans chiamato');

    await Future.delayed(const Duration(milliseconds: 300));

    /*print(
      '🎯 [MOCK] Ritornando ${_availablePlans.length} piani disponibili'
    );*/

    return Result.success(_availablePlans);
  }

  /// Verifica se l'utente può creare una nuova scheda (MOCK)
  Future<Result<bool>> canCreateWorkout() async {
    //print('[CONSOLE] [mock_subscription_repository]🎯 [MOCK] canCreateWorkout chiamato');

    await Future.delayed(const Duration(milliseconds: 100));

    final canCreate = _currentSubscription.maxWorkouts == null ||
        _currentSubscription.currentCount < _currentSubscription.maxWorkouts!;

    /*print(
      '🎯 [MOCK] Può creare scheda: $canCreate (${_currentSubscription.currentCount}/${_currentSubscription.maxWorkouts})'
    );*/

    return Result.success(canCreate);
  }

  /// Verifica se l'utente può creare un nuovo esercizio personalizzato (MOCK)
  Future<Result<bool>> canCreateCustomExercise() async {
    //print('[CONSOLE] [mock_subscription_repository]🎯 [MOCK] canCreateCustomExercise chiamato');

    await Future.delayed(const Duration(milliseconds: 100));

    final canCreate = _currentSubscription.maxCustomExercises == null ||
        _currentSubscription.currentCustomExercises < _currentSubscription.maxCustomExercises!;

    /*print(
      '🎯 [MOCK] Può creare esercizio: $canCreate (${_currentSubscription.currentCustomExercises}/${_currentSubscription.maxCustomExercises})'
    );*/

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
    //print('[CONSOLE] [mock_subscription_repository]🎯 [MOCK] Simulato upgrade a Premium');
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
    //print('[CONSOLE] [mock_subscription_repository]🎯 [MOCK] Simulato downgrade a Free');
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
    //print('[CONSOLE] [mock_subscription_repository]🎯 [MOCK] Simulata subscription scaduta');
  }

  /// Simula limite raggiunto per testing
  void simulateWorkoutLimitReached() {
    _currentSubscription = _currentSubscription.copyWith(
      currentCount: _currentSubscription.maxWorkouts ?? 3,
    );
    //print('[CONSOLE] [mock_subscription_repository]🎯 [MOCK] Simulato limite schede raggiunto');
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
    //print('[CONSOLE] [mock_subscription_repository]🎯 [MOCK] Reset ai valori di default');
  }
}