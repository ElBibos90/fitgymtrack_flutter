// lib/features/stats/presentation/screens/stats_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';

import '../../bloc/stats_bloc.dart';
import '../widgets/stats_card.dart';
import '../widgets/period_selector.dart';
import '../widgets/premium_stats_section.dart';
import '../widgets/premium_upgrade_banner.dart';
import '../../models/stats_models.dart';
import '../../repository/stats_repository.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/bloc/auth_bloc.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late final StatsBloc _statsBloc;

  @override
  void initState() {
    super.initState();
    // Usa GetIt per accedere ad ApiClient
    final apiClient = GetIt.instance<ApiClient>();
    final repository = StatsRepository(apiClient);
    _statsBloc = StatsBloc(repository);

    // 🔧 FIX: NON caricare automaticamente - aspetta che l'utente sia autenticato
    // Le statistiche verranno caricate quando l'utente naviga nella tab stats
  }

  @override
  void dispose() {
    _statsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {
        // 🔧 FIX: Carica statistiche solo quando l'utente è autenticato
        if ((authState is AuthAuthenticated || authState is AuthLoginSuccess)) {
          final currentStatsState = _statsBloc.state;
          if (currentStatsState is StatsInitial) {
            _statsBloc.add(const LoadInitialStats());
          }
        }
      },
      child: BlocProvider.value(
      value: _statsBloc,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'Statistiche',
          actions: [
            BlocBuilder<StatsBloc, StatsState>(
              builder: (context, state) {
                if (state is StatsLoaded) {
                  return IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: AppColors.indigo600,
                      size: 24.sp,
                    ),
                    onPressed: () => _statsBloc.add(RefreshStats()),
                    tooltip: 'Aggiorna statistiche',
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocBuilder<StatsBloc, StatsState>(
          builder: (context, state) {
            return RefreshIndicator(
              color: AppColors.indigo600,
              onRefresh: () async {
                _statsBloc.add(RefreshStats());
                // Aspetta che il refresh sia completato
                await _statsBloc.stream.firstWhere(
                      (state) => state is StatsLoaded || state is StatsError,
                );
              },
              child: _buildBody(context, state),
            );
          },
        ),
      ),
    ),
    ); // Chiusura BlocListener
  }

  Widget _buildBody(BuildContext context, StatsState state) {
    if (state is StatsInitial || state is StatsLoading) {
      return const LoadingOverlay(
        isLoading: true,
        child: SizedBox.expand(),
      );
    }

    if (state is StatsPeriodLoading) {
      return _buildLoadedContent(
        context,
        userStats: state.userStats,
        periodStats: null,
        currentPeriod: state.currentPeriod,
        isPremium: state.isPremium,
        isLoadingPeriod: true,
      );
    }

    if (state is StatsLoaded) {
      return _buildLoadedContent(
        context,
        userStats: state.userStats,
        periodStats: state.periodStats,
        currentPeriod: state.currentPeriod,
        isPremium: state.isPremium,
      );
    }

    if (state is StatsError) {
      return _buildErrorWidget(state);
    }

    return const Center(child: Text('Stato non riconosciuto.'));
  }

  Widget _buildErrorWidget(StatsError errorState) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: AppColors.error,
            ),
            SizedBox(height: 16.h),
            Text(
              errorState.message,
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (errorState.canRetry) ...[
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () => _statsBloc.add(const LoadInitialStats()),
                child: const Text('Riprova'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedContent(
      BuildContext context, {
        required UserStatsResponse userStats,
        required PeriodStatsResponse? periodStats,
        required StatsPeriod currentPeriod,
        required bool isPremium,
        bool isLoadingPeriod = false,
      }) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📅 SELETTORE PERIODO
          PeriodSelector(
            currentPeriod: currentPeriod,
            onPeriodChanged: (period) {
              _statsBloc.add(ChangePeriod(period));
            },
          ),

          SizedBox(height: 20.h),

          // 📊 STATISTICHE GENERALI UTENTE
          _buildUserStatsSection(context, userStats, isPremium),

          SizedBox(height: 24.h),

          // 📅 STATISTICHE PERIODO
          _buildPeriodStatsSection(
            context,
            periodStats,
            currentPeriod,
            isPremium,
            isLoadingPeriod,
          ),

          SizedBox(height: 24.h),

          // 🔥 SEZIONE PREMIUM
          if (isPremium)
            _buildPremiumStatsSection(context, userStats, periodStats)
          else
            PremiumUpgradeBanner(
              onUpgrade: () {
                // TODO: Implementare navigazione a schermata upgrade
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funzionalità di upgrade in arrivo!'),
                  ),
                );
              },
            ),

          SizedBox(height: 80.h), // Spazio extra per la bottom navigation
        ],
      ),
    );
  }

  Widget _buildUserStatsSection(
      BuildContext context,
      UserStatsResponse userStatsResponse,
      bool isPremium,
      ) {
    final stats = userStatsResponse.userStats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistiche Generali',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16.h),

        // Prima riga di statistiche
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Allenamenti',
                value: '${stats.totalWorkouts}',
                icon: Icons.fitness_center,
                color: AppColors.indigo600,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: StatsCard(
                title: 'Durata totale',
                value: '${stats.totalDurationMinutes}m',
                icon: Icons.schedule,
                color: AppColors.green600,
              ),
            ),
          ],
        ),

        SizedBox(height: 12.h),

        // Seconda riga di statistiche
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Serie totali',
                value: '${stats.totalSeries}',
                icon: Icons.repeat,
                color: AppColors.orange600,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: StatsCard(
                title: 'Peso sollevato',
                value: '${stats.totalWeightLiftedKg.toStringAsFixed(1)}kg',
                icon: Icons.scale,
                color: AppColors.success,
              ),
            ),
          ],
        ),

        SizedBox(height: 12.h),

        // Terza riga - Streak
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Serie attuale',
                value: '${stats.currentStreak} giorni',
                icon: Icons.local_fire_department,
                color: AppColors.warning,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: StatsCard(
                title: 'Record serie',
                value: '${stats.longestStreak} giorni',
                icon: Icons.military_tech,
                color: AppColors.error,
              ),
            ),
          ],
        ),

        SizedBox(height: 12.h),

        // Quarta riga - Questa settimana/mese
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Questa settimana',
                value: '${stats.workoutsThisWeek}',
                icon: Icons.calendar_today,
                color: AppColors.info,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: StatsCard(
                title: 'Questo mese',
                value: '${stats.workoutsThisMonth}',
                icon: Icons.calendar_month,
                color: AppColors.purple600,
              ),
            ),
          ],
        ),

        SizedBox(height: 12.h),

        // Quinta riga - Medie
        StatsCard(
          title: 'Durata media allenamento',
          value: '${stats.averageWorkoutDuration.toStringAsFixed(1)} minuti',
          icon: Icons.timer,
          color: AppColors.textSecondary,
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildPeriodStatsSection(
      BuildContext context,
      PeriodStatsResponse? periodStatsResponse,
      StatsPeriod currentPeriod,
      bool isPremium,
      bool isLoading,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistiche ${currentPeriod.displayName}',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16.h),

        if (isLoading)
          Center(
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: CircularProgressIndicator(color: AppColors.indigo600),
            ),
          )
        else if (periodStatsResponse != null)
          _buildPeriodStatsCards(context, periodStatsResponse.periodStats)
        else
          Center(
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: Text(
                'Nessun dato disponibile per questo periodo.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPeriodStatsCards(BuildContext context, PeriodStats stats) {
    return Column(
      children: [
        // Prima riga
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Allenamenti',
                value: '${stats.workoutCount}',
                icon: Icons.fitness_center,
                color: AppColors.indigo600,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: StatsCard(
                title: 'Durata totale',
                value: '${stats.totalDurationMinutes}m',
                icon: Icons.schedule,
                color: AppColors.green600,
              ),
            ),
          ],
        ),

        SizedBox(height: 12.h),

        // Seconda riga
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Serie',
                value: '${stats.totalSeries}',
                icon: Icons.repeat,
                color: AppColors.orange600,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: StatsCard(
                title: 'Peso totale',
                value: '${stats.totalWeightKg.toStringAsFixed(1)}kg',
                icon: Icons.scale,
                color: AppColors.success,
              ),
            ),
          ],
        ),

        SizedBox(height: 12.h),

        // Terza riga
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Durata media',
                value: '${stats.averageDuration.toStringAsFixed(1)}m',
                icon: Icons.timer,
                color: AppColors.info,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: StatsCard(
                title: 'Giorno più attivo',
                value: stats.mostActiveDay ?? 'N/A',
                icon: Icons.star,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPremiumStatsSection(
      BuildContext context,
      UserStatsResponse userStats,
      PeriodStatsResponse? periodStats,
      ) {
    return PremiumStatsSection(
      userStats: userStats,
      periodStats: periodStats,
    );
  }
}