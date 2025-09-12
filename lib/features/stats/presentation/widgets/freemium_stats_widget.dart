// lib/features/stats/presentation/widgets/freemium_stats_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/theme/stats_theme.dart';
import '../../models/stats_models.dart';
import '../../models/simple_stats_models.dart';
import 'modern_kpi_card.dart';
import 'premium_upgrade_banner.dart';
import 'smart_insight_card.dart';
import 'achievement_card.dart';

/// 🎯 Freemium Stats Widget - Widget per Statistiche Differenziate
class FreemiumStatsWidget extends StatefulWidget {
  final UserStatsResponse userStats;
  final PeriodStatsResponse? periodStats;
  final VoidCallback? onUpgrade;

  const FreemiumStatsWidget({
    super.key,
    required this.userStats,
    this.periodStats,
    this.onUpgrade,
  });

  @override
  State<FreemiumStatsWidget> createState() => _FreemiumStatsWidgetState();
}

class _FreemiumStatsWidgetState extends State<FreemiumStatsWidget> {
  @override
  Widget build(BuildContext context) {
    final isPremium = widget.userStats.isPremium;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 📊 Base Stats (per tutti)
        _buildBaseStatsSection(widget.userStats.userStats),
        SizedBox(height: StatsTheme.space6),
        
        // 💎 Premium Stats (solo per premium)
        if (isPremium) ...[
          _buildPremiumStatsSection(widget.userStats.userStats),
          SizedBox(height: StatsTheme.space6),
        ] else ...[
          _buildPremiumUpgradeSection(),
          SizedBox(height: StatsTheme.space6),
        ],
        
        // 📅 Period Stats
        if (widget.periodStats != null) ...[
          _buildPeriodStatsSection(widget.periodStats!, isPremium),
        ],
      ],
    );
  }

  /// 📊 Base Stats Section (Free)
  Widget _buildBaseStatsSection(UserStats userStats) {
    final baseKPIs = _generateBaseKPIs(userStats);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.analytics,
              color: StatsTheme.primaryBlue,
              size: 24.sp,
            ),
            SizedBox(width: StatsTheme.space2),
            Text(
              'Statistiche Base',
              style: StatsTheme.h4.copyWith(
                color: StatsTheme.getTextPrimary(context),
              ),
            ),
            SizedBox(width: StatsTheme.space2),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: StatsTheme.space2,
                vertical: StatsTheme.space1,
              ),
              decoration: BoxDecoration(
                color: StatsTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(StatsTheme.radius1),
              ),
              child: Text(
                'GRATIS',
                style: StatsTheme.caption.copyWith(
                  color: StatsTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
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
            childAspectRatio: 1.2,
          ),
          itemCount: baseKPIs.length,
          itemBuilder: (context, index) {
            return ModernKPICard(kpiData: baseKPIs[index]);
          },
        ),
      ],
    );
  }

  /// 💎 Premium Stats Section
  Widget _buildPremiumStatsSection(UserStats userStats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.diamond,
              color: StatsTheme.warningOrange,
              size: 24.sp,
            ),
            SizedBox(width: StatsTheme.space2),
            Text(
              'Statistiche Premium',
              style: StatsTheme.h4.copyWith(
                color: StatsTheme.getTextPrimary(context),
              ),
            ),
            SizedBox(width: StatsTheme.space2),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: StatsTheme.space2,
                vertical: StatsTheme.space1,
              ),
              decoration: BoxDecoration(
                gradient: StatsTheme.premiumGradient,
                borderRadius: BorderRadius.circular(StatsTheme.radius1),
              ),
              child: Text(
                'PREMIUM',
                style: StatsTheme.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: StatsTheme.space4),
        
        // Premium KPIs
        _buildPremiumKPIs(userStats),
        SizedBox(height: StatsTheme.space4),
        
        // Smart Insights
        _buildSmartInsights(userStats),
        SizedBox(height: StatsTheme.space4),
        
        // Achievements
        _buildAchievements(userStats),
      ],
    );
  }

  /// 🚀 Premium Upgrade Section
  Widget _buildPremiumUpgradeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.diamond,
              color: StatsTheme.warningOrange,
              size: 24.sp,
            ),
            SizedBox(width: StatsTheme.space2),
            Text(
              'Statistiche Premium',
              style: StatsTheme.h4.copyWith(
                color: StatsTheme.getTextPrimary(context),
              ),
            ),
          ],
        ),
        SizedBox(height: StatsTheme.space4),
        
        PremiumUpgradeBanner(
          onUpgrade: widget.onUpgrade ?? () {},
          title: 'Sblocca Statistiche Avanzate',
          description: 'Accedi ad analisi dettagliate, insights personalizzati e achievements',
          features: [
            'Analisi dei gruppi muscolari',
            'Insights intelligenti',
            'Achievements e obiettivi',
            'Grafici e visualizzazioni',
            'Confronti temporali',
            'Raccomandazioni personalizzate',
          ],
        ),
      ],
    );
  }

  /// 📅 Period Stats Section
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
        
        // Base period stats
        _buildPeriodBaseStats(periodStats.periodStats),
        
        // Premium period stats
        if (isPremium) ...[
          SizedBox(height: StatsTheme.space4),
          _buildPeriodPremiumStats(periodStats.periodStats),
        ] else ...[
          SizedBox(height: StatsTheme.space4),
          CompactPremiumBanner(
            onUpgrade: widget.onUpgrade ?? () {},
            message: 'Sblocca analisi avanzate del periodo con Premium',
          ),
        ],
      ],
    );
  }

  /// 📊 Generate Base KPIs
  List<KPICard> _generateBaseKPIs(UserStats userStats) {
    return <KPICard>[
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
  }

  /// 💎 Build Premium KPIs
  Widget _buildPremiumKPIs(UserStats userStats) {
    final premiumKPIs = <KPICard>[
      if (userStats.mostTrainedMuscleGroup != null)
        KPICard(
          title: 'Gruppo Preferito',
          value: userStats.mostTrainedMuscleGroup!,
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
      KPICard(
        title: 'Allenamenti Settimana',
        value: '${userStats.workoutsThisWeek}',
        subtitle: 'Questa settimana',
        icon: '📅',
        color: 'indigo',
      ),
      KPICard(
        title: 'Allenamenti Mese',
        value: '${userStats.workoutsThisMonth}',
        subtitle: 'Questo mese',
        icon: '📊',
        color: 'pink',
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
      itemCount: premiumKPIs.length,
      itemBuilder: (context, index) {
        return ModernKPICard(kpiData: premiumKPIs[index]);
      },
    );
  }

  /// 🧠 Build Smart Insights
  Widget _buildSmartInsights(UserStats userStats) {
    final insights = _generateSmartInsights(userStats);
    
    if (insights.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.psychology,
              color: StatsTheme.primaryBlue,
              size: 20.sp,
            ),
            SizedBox(width: StatsTheme.space2),
            Text(
              'Insights Intelligenti',
              style: StatsTheme.h5.copyWith(
                color: StatsTheme.getTextPrimary(context),
              ),
            ),
          ],
        ),
        SizedBox(height: StatsTheme.space3),
        ...insights.map((insight) => Padding(
          padding: EdgeInsets.only(bottom: StatsTheme.space2),
          child: SmartInsightCard(insight: insight),
        )),
      ],
    );
  }

  /// 🏆 Build Achievements
  Widget _buildAchievements(UserStats userStats) {
    final achievements = _generateAchievements(userStats);
    
    if (achievements.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.emoji_events,
              color: StatsTheme.warningOrange,
              size: 20.sp,
            ),
            SizedBox(width: StatsTheme.space2),
            Text(
              'Achievements',
              style: StatsTheme.h5.copyWith(
                color: StatsTheme.getTextPrimary(context),
              ),
            ),
          ],
        ),
        SizedBox(height: StatsTheme.space3),
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

  /// 📊 Build Period Base Stats
  Widget _buildPeriodBaseStats(PeriodStats periodStats) {
    final kpis = <KPICard>[
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

  /// 💎 Build Period Premium Stats
  Widget _buildPeriodPremiumStats(PeriodStats periodStats) {
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
                'Analisi Premium del Periodo',
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

    return achievements;
  }
}
