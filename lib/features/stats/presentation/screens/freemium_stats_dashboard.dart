// lib/features/stats/presentation/screens/freemium_stats_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../../shared/theme/stats_theme.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../widgets/modern_kpi_card.dart';
import '../widgets/smart_insight_card.dart';
import '../widgets/achievement_card.dart';
import '../widgets/premium_upgrade_banner.dart';
import '../widgets/period_selector.dart';
import '../widgets/advanced_charts.dart';
import '../widgets/premium_upgrade_flow.dart';
import '../../models/stats_models.dart';
import '../../models/simple_stats_models.dart';
import '../../bloc/stats_bloc.dart';

/// 🎯 Freemium Stats Dashboard - Dashboard con Statistiche Differenziate
class FreemiumStatsDashboard extends StatefulWidget {
  const FreemiumStatsDashboard({super.key});

  @override
  State<FreemiumStatsDashboard> createState() => _FreemiumStatsDashboardState();
}

class _FreemiumStatsDashboardState extends State<FreemiumStatsDashboard> {
  @override
  void initState() {
    super.initState();
    // Carica le statistiche iniziali
    context.read<StatsBloc>().add(LoadInitialStats());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StatsTheme.getPageBackground(context),
      appBar: CustomAppBar(
        title: 'Le Mie Statistiche',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<StatsBloc>().add(RefreshStats());
            },
          ),
        ],
      ),
      body: BlocBuilder<StatsBloc, StatsState>(
        builder: (context, state) {
          if (state is StatsLoading) {
            return _buildLoadingState();
          } else if (state is StatsLoaded) {
            return _buildLoadedState(state);
          } else if (state is StatsError) {
            return _buildErrorState(state);
          }
          return _buildInitialState();
        },
      ),
    );
  }

  /// 🔄 Loading State
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/loading.json',
            width: 120.w,
            height: 120.h,
          ),
          SizedBox(height: 24.h),
          Text(
            'Caricamento statistiche...',
            style: StatsTheme.body1.copyWith(
              color: StatsTheme.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Loaded State
  Widget _buildLoadedState(StatsLoaded state) {
    final isPremium = state.userStats.isPremium;
    
    return RefreshIndicator(
      onRefresh: () async {
        context.read<StatsBloc>().add(RefreshStats());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(StatsTheme.space4),
        child: AnimationLimiter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 600),
              childAnimationBuilder: (widget) => SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                // 🎯 Fitness Score (Solo Premium)
                if (isPremium) ...[
                  _buildFitnessScore(state.userStats.userStats),
                  SizedBox(height: StatsTheme.space6),
                ],

                // 📊 KPI Cards (Base per tutti)
                _buildKPISection(state.userStats.userStats, isPremium),
                SizedBox(height: StatsTheme.space6),

                // 🧠 Smart Insights (Premium)
                if (isPremium) ...[
                  _buildSmartInsightsSection(state.userStats.userStats),
                  SizedBox(height: StatsTheme.space6),
                ] else ...[
                  _buildPremiumUpgradeBanner(),
                  SizedBox(height: StatsTheme.space6),
                ],

                // 🏆 Achievements (Premium)
                if (isPremium) ...[
                  _buildAchievementsSection(state.userStats.userStats),
                  SizedBox(height: StatsTheme.space6),
                ],

                // 📈 Charts (Premium)
                if (isPremium) ...[
                  _buildChartsSection(state),
                  SizedBox(height: StatsTheme.space6),
                ],

                // 📅 Period Selector
                _buildPeriodSelector(state),
                SizedBox(height: StatsTheme.space6),

                // 📊 Period Stats
                if (state.periodStats != null) ...[
                  _buildPeriodStatsSection(state.periodStats!, isPremium),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🎯 Fitness Score (Premium)
  Widget _buildFitnessScore(UserStats userStats) {
    final score = _calculateFitnessScore(userStats);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(StatsTheme.space6),
      decoration: BoxDecoration(
        gradient: StatsTheme.primaryGradient,
        borderRadius: BorderRadius.circular(StatsTheme.radius3),
        boxShadow: [
          BoxShadow(
            color: StatsTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Fitness Score',
            style: StatsTheme.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: StatsTheme.space4),
          Text(
            '${score.toStringAsFixed(0)}/100',
            style: StatsTheme.h1.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: StatsTheme.space2),
          LinearProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8.h,
          ),
          SizedBox(height: StatsTheme.space4),
          Text(
            _getFitnessScoreMessage(score),
            style: StatsTheme.body2.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 📊 KPI Section
  Widget _buildKPISection(UserStats userStats, bool isPremium) {
    final kpis = _generateKPIs(userStats, isPremium);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metriche Principali',
          style: StatsTheme.h4.copyWith(
            color: StatsTheme.getTextPrimary(context),
          ),
        ),
        SizedBox(height: StatsTheme.space4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: StatsTheme.space3,
            mainAxisSpacing: StatsTheme.space3,
            childAspectRatio: 1.4,
          ),
          itemCount: kpis.length,
          itemBuilder: (context, index) {
            return ModernKPICard(kpiData: kpis[index]);
          },
        ),
      ],
    );
  }

  /// 🧠 Smart Insights Section (Premium)
  Widget _buildSmartInsightsSection(UserStats userStats) {
    final insights = _generateSmartInsights(userStats);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.psychology,
              color: StatsTheme.primaryBlue,
              size: 24.sp,
            ),
            SizedBox(width: StatsTheme.space2),
            Text(
              'Insights Intelligenti',
              style: StatsTheme.h4.copyWith(
                color: StatsTheme.getTextPrimary(context),
              ),
            ),
          ],
        ),
        SizedBox(height: StatsTheme.space4),
        ...insights.map((insight) => Padding(
          padding: EdgeInsets.only(bottom: StatsTheme.space3),
          child: SmartInsightCard(insight: insight),
        )),
      ],
    );
  }

  /// 🏆 Achievements Section (Premium)
  Widget _buildAchievementsSection(UserStats userStats) {
    final achievements = _generateAchievements(userStats);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.emoji_events,
              color: StatsTheme.warningOrange,
              size: 24.sp,
            ),
            SizedBox(width: StatsTheme.space2),
            Text(
              'Achievements',
              style: StatsTheme.h4.copyWith(
                color: StatsTheme.getTextPrimary(context),
              ),
            ),
          ],
        ),
        SizedBox(height: StatsTheme.space4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: StatsTheme.space3,
            mainAxisSpacing: StatsTheme.space3,
            childAspectRatio: 1.1,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            return AchievementCard(achievement: achievements[index]);
          },
        ),
      ],
    );
  }

  /// 📈 Charts Section (Premium)
  Widget _buildChartsSection(StatsLoaded state) {
    if (state.isPremium) {
      return AdvancedCharts(
        userStats: state.userStats,
        periodStats: state.periodStats,
      );
    } else {
      return _buildPremiumLockedCharts();
    }
  }

  /// 🔒 Premium Locked Charts
  Widget _buildPremiumLockedCharts() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: StatsTheme.space4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: StatsTheme.space4.w),
            child: Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: StatsTheme.primaryBlue,
                  size: 20.sp,
                ),
                SizedBox(width: StatsTheme.space2.w),
                Text(
                  'Analisi Avanzate',
                  style: StatsTheme.h4.copyWith(
                    color: StatsTheme.getTextPrimary(context),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: StatsTheme.space4.h),
          
          // Chart Preview con overlay
          Stack(
            children: [
              // Preview del grafico
              Container(
                height: 200.h,
                padding: EdgeInsets.all(StatsTheme.space4.w),
                decoration: BoxDecoration(
                  color: StatsTheme.getCardBackground(context),
                  borderRadius: BorderRadius.circular(StatsTheme.radiusLarge.r),
                  border: Border.all(
                    color: StatsTheme.getBorderColor(context),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.show_chart,
                        color: StatsTheme.getTextSecondary(context),
                        size: 48.sp,
                      ),
                      SizedBox(height: StatsTheme.space2.h),
                      Text(
                        'Grafici Interattivi',
                        style: StatsTheme.h5.copyWith(
                          color: StatsTheme.getTextPrimary(context),
                        ),
                      ),
                      SizedBox(height: StatsTheme.space1.h),
                      Text(
                        'Visualizza i tuoi progressi con grafici dettagliati',
                        style: StatsTheme.bodyMedium.copyWith(
                          color: StatsTheme.getTextSecondary(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Overlay premium
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(StatsTheme.radiusLarge.r),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60.w,
                          height: 60.h,
                          decoration: BoxDecoration(
                            gradient: StatsTheme.premiumGradient,
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                          child: Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                        ),
                        
                        SizedBox(height: StatsTheme.space3.h),
                        
                        Text(
                          'Funzionalità Premium',
                          style: StatsTheme.h5.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        SizedBox(height: StatsTheme.space1.h),
                        
                        Text(
                          'Sblocca grafici avanzati con Premium',
                          style: StatsTheme.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: StatsTheme.space3.h),
                        
                        GestureDetector(
                          onTap: () => PremiumUpgradeFlow.navigateToUpgrade(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: StatsTheme.space3.w,
                              vertical: StatsTheme.space2.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: StatsTheme.premiumGradient,
                              borderRadius: BorderRadius.circular(StatsTheme.radiusMedium.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.diamond,
                                  color: Colors.white,
                                  size: 16.sp,
                                ),
                                SizedBox(width: StatsTheme.space2.w),
                                Text(
                                  'Vai Premium',
                                  style: StatsTheme.labelMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📅 Period Selector
  Widget _buildPeriodSelector(StatsLoaded state) {
    return Container(
      padding: EdgeInsets.all(StatsTheme.space4),
      decoration: BoxDecoration(
        color: StatsTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(StatsTheme.radius3),
        border: Border.all(
          color: StatsTheme.getBorderColor(context),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seleziona Periodo',
            style: StatsTheme.h5.copyWith(
              color: StatsTheme.getTextPrimary(context),
            ),
          ),
          SizedBox(height: StatsTheme.space3),
          SimplePeriodSelector(
            currentPeriod: state.currentPeriod,
            onPeriodChanged: (period) {
              context.read<StatsBloc>().add(ChangePeriod(period));
            },
          ),
        ],
      ),
    );
  }

  /// 📊 Period Stats Section
  Widget _buildPeriodStatsSection(PeriodStatsResponse periodStats, bool isPremium) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistiche del Periodo',
          style: StatsTheme.h4.copyWith(
            color: StatsTheme.getTextPrimary(context),
          ),
        ),
        SizedBox(height: StatsTheme.space4),
        
        // Base stats per tutti
        _buildPeriodKPIs(periodStats.periodStats),
        
        // Premium stats solo per utenti premium
        if (isPremium) ...[
          SizedBox(height: StatsTheme.space4),
          _buildPremiumPeriodStats(periodStats.periodStats),
        ] else ...[
          SizedBox(height: StatsTheme.space4),
          _buildPremiumUpgradeBanner(),
        ],
      ],
    );
  }

  /// 📊 Period KPIs
  Widget _buildPeriodKPIs(PeriodStats periodStats) {
    final kpis = [
      KPICard(
        title: 'Allenamenti',
        value: '${periodStats.workoutCount}',
        icon: '💪',
        color: 'blue',
      ),
      KPICard(
        title: 'Durata Totale',
        value: '${(periodStats.totalDurationMinutes / 60).toStringAsFixed(1)}h',
        icon: '⏱️',
        color: 'green',
      ),
      KPICard(
        title: 'Serie Totali',
        value: '${periodStats.totalSeries}',
        icon: '🔄',
        color: 'orange',
      ),
      KPICard(
        title: 'Peso Sollevato',
        value: '${periodStats.totalWeightKg.toStringAsFixed(0)}kg',
        icon: '🏋️',
        color: 'purple',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: StatsTheme.space3,
        mainAxisSpacing: StatsTheme.space3,
        childAspectRatio: 1.2,
      ),
      itemCount: kpis.length,
      itemBuilder: (context, index) {
        return ModernKPICard(kpiData: kpis[index]);
      },
    );
  }

  /// 💎 Premium Period Stats
  Widget _buildPremiumPeriodStats(PeriodStats periodStats) {
    return Container(
      padding: EdgeInsets.all(StatsTheme.space4),
      decoration: BoxDecoration(
        gradient: StatsTheme.premiumGradient,
        borderRadius: BorderRadius.circular(StatsTheme.radius3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.diamond,
                color: Colors.white,
                size: 20.sp,
              ),
              SizedBox(width: StatsTheme.space2),
              Text(
                'Analisi Premium',
                style: StatsTheme.h5.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: StatsTheme.space3),
          
          if (periodStats.mostActiveDay != null) ...[
            _buildPremiumStatItem(
              'Giorno più attivo',
              periodStats.mostActiveDay!,
              Icons.calendar_today,
            ),
            SizedBox(height: StatsTheme.space2),
          ],
          
          if (periodStats.averageDurationMinutes != null) ...[
            _buildPremiumStatItem(
              'Durata media allenamento',
              '${(periodStats.averageDurationMinutes! / 60).toStringAsFixed(1)}h',
              Icons.timer,
            ),
          ],
        ],
      ),
    );
  }

  /// 💎 Premium Stat Item
  Widget _buildPremiumStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.8),
          size: 16.sp,
        ),
        SizedBox(width: StatsTheme.space2),
        Text(
          label,
          style: StatsTheme.body2.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: StatsTheme.body1.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// 🚀 Premium Upgrade Banner
  Widget _buildPremiumUpgradeBanner() {
    return PremiumUpgradeBanner(
      onUpgrade: () => PremiumUpgradeFlow.navigateToUpgrade(context),
    );
  }

  /// 📈 Progress Chart
  Widget _buildProgressChart(UserStats userStats) {
    if (userStats.progressTrends == null || userStats.progressTrends!.isEmpty) {
      return Center(
        child: Text(
          'Dati insufficienti per il grafico',
          style: StatsTheme.body2.copyWith(
            color: StatsTheme.getTextSecondary(context),
          ),
        ),
      );
    }

    final spots = userStats.progressTrends!
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value.toDouble()))
        .toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: StatsTheme.primaryBlue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: StatsTheme.primaryBlue.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Calculate Fitness Score
  double _calculateFitnessScore(UserStats userStats) {
    double score = 0;
    
    // Punteggio basato su allenamenti totali (max 30 punti)
    score += (userStats.totalWorkouts / 100 * 30).clamp(0, 30);
    
    // Punteggio basato su streak corrente (max 25 punti)
    score += (userStats.currentStreak / 30 * 25).clamp(0, 25);
    
    // Punteggio basato su allenamenti questa settimana (max 20 punti)
    score += (userStats.workoutsThisWeek / 5 * 20).clamp(0, 20);
    
    // Punteggio basato su durata media (max 15 punti)
    score += (userStats.averageWorkoutDuration / 60 * 15).clamp(0, 15);
    
    // Punteggio basato su peso sollevato (max 10 punti)
    score += (userStats.totalWeightLiftedKg / 1000 * 10).clamp(0, 10);
    
    return score.clamp(0, 100);
  }

  /// 📊 Generate KPIs
  List<KPICard> _generateKPIs(UserStats userStats, bool isPremium) {
    final baseKPIs = <KPICard>[
      KPICard(
        title: 'Allenamenti Totali',
        value: '${userStats.totalWorkouts}',
        subtitle: 'Tutti i tempi',
        icon: '💪',
        color: 'blue',
        trend: userStats.workoutsThisWeek > 0 ? 5.2 : null,
        trendLabel: 'Questa settimana',
        isPositive: true,
      ),
      KPICard(
        title: 'Streak Attuale',
        value: '${userStats.currentStreak}',
        subtitle: 'Giorni consecutivi',
        icon: '🔥',
        color: 'orange',
        trend: userStats.currentStreak > userStats.longestStreak * 0.8 ? 8.1 : null,
        trendLabel: 'Record: ${userStats.longestStreak}',
        isPositive: true,
      ),
      KPICard(
        title: 'Durata Totale',
        value: '${(userStats.totalDurationMinutes / 60).toStringAsFixed(1)}h',
        subtitle: 'Tempo investito',
        icon: '⏱️',
        color: 'green',
        trend: userStats.averageWorkoutDuration > 45 ? 3.7 : null,
        trendLabel: 'Media: ${userStats.averageWorkoutDuration.toStringAsFixed(0)}min',
        isPositive: true,
      ),
      KPICard(
        title: 'Peso Sollevato',
        value: '${userStats.totalWeightLiftedKg.toStringAsFixed(0)}kg',
        subtitle: 'Totale carico',
        icon: '🏋️',
        color: 'purple',
        trend: userStats.totalWeightLiftedKg > 1000 ? 12.5 : null,
        trendLabel: 'Impressivo!',
        isPositive: true,
      ),
    ];

    if (isPremium) {
      baseKPIs.addAll([
        KPICard(
          title: 'Gruppo Preferito',
          value: userStats.mostTrainedMuscleGroup ?? 'N/A',
          subtitle: 'Muscolo più allenato',
          icon: '🎯',
          color: 'red',
        ),
        KPICard(
          title: 'Serie Totali',
          value: '${userStats.totalSeries}',
          subtitle: 'Volume di lavoro',
          icon: '🔄',
          color: 'teal',
        ),
      ]);
    }

    return baseKPIs;
  }

  /// 🧠 Generate Smart Insights
  List<SmartInsight> _generateSmartInsights(UserStats userStats) {
    final insights = <SmartInsight>[];

    // Insight su streak
    if (userStats.currentStreak >= 7) {
      insights.add(SmartInsight(
        id: 'streak_insight_${userStats.currentStreak}',
        title: 'Streak Impressivo!',
        description: 'Hai mantenuto una streak di ${userStats.currentStreak} giorni. Continua così!',
        type: 'achievement',
        icon: '🔥',
        color: 'orange',
        priority: 5,
        createdAt: DateTime.now(),
      ));
    }

    // Insight su allenamenti settimanali
    if (userStats.workoutsThisWeek >= 4) {
      insights.add(SmartInsight(
        id: 'weekly_insight_${userStats.workoutsThisWeek}',
        title: 'Settimana Produttiva',
        description: 'Hai completato ${userStats.workoutsThisWeek} allenamenti questa settimana. Ottimo ritmo!',
        type: 'achievement',
        icon: '📈',
        color: 'green',
        priority: 4,
        createdAt: DateTime.now(),
      ));
    }

    // Insight su durata media
    if (userStats.averageWorkoutDuration >= 60) {
      insights.add(SmartInsight(
        id: 'duration_insight_${userStats.averageWorkoutDuration.toStringAsFixed(0)}',
        title: 'Allenamenti Intensi',
        description: 'I tuoi allenamenti durano in media ${userStats.averageWorkoutDuration.toStringAsFixed(0)} minuti. Ottima intensità!',
        type: 'achievement',
        icon: '⚡',
        color: 'blue',
        priority: 3,
        createdAt: DateTime.now(),
      ));
    }

    // Insight su peso sollevato
    if (userStats.totalWeightLiftedKg >= 1000) {
      insights.add(SmartInsight(
        id: 'weight_insight_${userStats.totalWeightLiftedKg.toStringAsFixed(0)}',
        title: 'Powerlifter!',
        description: 'Hai sollevato oltre ${userStats.totalWeightLiftedKg.toStringAsFixed(0)}kg in totale. Incredibile!',
        type: 'achievement',
        icon: '💪',
        color: 'purple',
        priority: 5,
        createdAt: DateTime.now(),
      ));
    }

    return insights;
  }

  /// 🏆 Generate Achievements
  List<Achievement> _generateAchievements(UserStats userStats) {
    final achievements = <Achievement>[];

    // Achievement per allenamenti totali
    if (userStats.totalWorkouts >= 10) {
      achievements.add(Achievement(
        id: 'first_steps_${userStats.totalWorkouts}',
        title: 'Primi Passi',
        description: 'Completa 10 allenamenti',
        icon: '🎯',
        color: 'blue',
        category: 'milestone',
        points: 100,
        isUnlocked: userStats.totalWorkouts >= 10,
        progress: (userStats.totalWorkouts / 10).clamp(0, 1),
      ));
    }

    // Achievement per streak
    if (userStats.longestStreak >= 7) {
      achievements.add(Achievement(
        id: 'streak_master_${userStats.longestStreak}',
        title: 'Streak Master',
        description: 'Mantieni una streak di 7 giorni',
        icon: '🔥',
        color: 'orange',
        category: 'consistency',
        points: 150,
        isUnlocked: userStats.longestStreak >= 7,
        progress: (userStats.longestStreak / 7).clamp(0, 1),
      ));
    }

    // Achievement per peso sollevato
    if (userStats.totalWeightLiftedKg >= 1000) {
      achievements.add(Achievement(
        id: 'powerlifter_${userStats.totalWeightLiftedKg.toStringAsFixed(0)}',
        title: 'Powerlifter',
        description: 'Solleva 1000kg in totale',
        icon: '💪',
        color: 'purple',
        category: 'strength',
        points: 200,
        isUnlocked: userStats.totalWeightLiftedKg >= 1000,
        progress: (userStats.totalWeightLiftedKg / 1000).clamp(0, 1),
      ));
    }

    return achievements;
  }

  /// 🎯 Get Fitness Score Message
  String _getFitnessScoreMessage(double score) {
    if (score >= 90) return 'Eccellente! Sei un vero atleta!';
    if (score >= 75) return 'Ottimo lavoro! Continua così!';
    if (score >= 60) return 'Buon progresso! Puoi fare di più!';
    if (score >= 40) return 'Stai migliorando! Non mollare!';
    return 'Inizia il tuo percorso fitness!';
  }

  /// ❌ Error State
  Widget _buildErrorState(StatsError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: StatsTheme.dangerRed,
          ),
          SizedBox(height: 16.h),
          Text(
            'Errore nel caricamento',
            style: StatsTheme.h3.copyWith(
              color: StatsTheme.getTextPrimary(context),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            state.message,
            style: StatsTheme.body1.copyWith(
              color: StatsTheme.getTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              context.read<StatsBloc>().add(LoadInitialStats());
            },
            child: const Text('Riprova'),
          ),
        ],
      ),
    );
  }

  /// 🔄 Initial State
  Widget _buildInitialState() {
    return Center(
      child: Text(
        'Caricamento...',
        style: StatsTheme.body1.copyWith(
          color: StatsTheme.getTextSecondary(context),
        ),
      ),
    );
  }
}
