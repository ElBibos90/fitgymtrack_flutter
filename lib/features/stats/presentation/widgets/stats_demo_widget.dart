// lib/features/stats/presentation/widgets/stats_demo_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/stats_theme.dart';
import 'modern_kpi_card.dart';
import 'smart_insight_card.dart';
import 'achievement_card.dart';
import '../../models/simple_stats_models.dart';

/// 🎯 Stats Demo Widget - Widget di Demo per le Nuove Statistiche
class StatsDemoWidget extends StatefulWidget {
  const StatsDemoWidget({super.key});

  @override
  State<StatsDemoWidget> createState() => _StatsDemoWidgetState();
}

class _StatsDemoWidgetState extends State<StatsDemoWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StatsTheme.getPageBackground(context),
      appBar: AppBar(
        title: Text(
          'Demo Statistiche Moderne',
          style: StatsTheme.h3.copyWith(
            color: StatsTheme.getTextPrimary(context),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(StatsTheme.space4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section Demo
            _buildHeroDemo(),
            
            SizedBox(height: StatsTheme.space6.h),
            
            // KPI Cards Demo
            _buildKPIDemo(),
            
            SizedBox(height: StatsTheme.space6.h),
            
            // Smart Insights Demo
            _buildInsightsDemo(),
            
            SizedBox(height: StatsTheme.space6.h),
            
            // Achievements Demo
            _buildAchievementsDemo(),
            
            SizedBox(height: StatsTheme.space20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroDemo() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(StatsTheme.space6.w),
      decoration: BoxDecoration(
        gradient: StatsTheme.primaryGradient,
        borderRadius: BorderRadius.circular(StatsTheme.radiusXLarge.r),
        boxShadow: StatsTheme.shadowLarge,
      ),
      child: Column(
        children: [
          Text(
            'Fitness Score',
            style: StatsTheme.labelLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: StatsTheme.space2.h),
          Text(
            '85',
            style: StatsTheme.metricLarge.copyWith(
              color: Colors.white,
            ),
          ),
          SizedBox(height: StatsTheme.space2.h),
          Text(
            'Eccellente',
            style: StatsTheme.h4.copyWith(
              color: Colors.white,
            ),
          ),
          SizedBox(height: StatsTheme.space4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreItem('Forza', '90', Colors.white),
              _buildScoreItem('Costanza', '85', Colors.white),
              _buildScoreItem('Progressione', '80', Colors.white),
              _buildScoreItem('Equilibrio', '85', Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: StatsTheme.metricSmall.copyWith(
            color: color,
          ),
        ),
        SizedBox(height: StatsTheme.space1.h),
        Text(
          label,
          style: StatsTheme.caption.copyWith(
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildKPIDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metriche Principali',
          style: StatsTheme.h4.copyWith(
            color: StatsTheme.getTextPrimary(context),
          ),
        ),
        SizedBox(height: StatsTheme.space4.h),
        
        // Prima riga
        Row(
          children: [
            Expanded(
              child: ModernKPICard(
                kpiData: KPICard(
                  title: 'Allenamenti',
                  value: '45',
                  icon: 'fitness_center',
                  color: 'primary',
                  trend: 12.5,
                  trendLabel: 'vs scorsa settimana',
                  isPositive: true,
                ),
              ),
            ),
            SizedBox(width: StatsTheme.space3.w),
            Expanded(
              child: ModernKPICard(
                kpiData: KPICard(
                  title: 'Durata Totale',
                  value: '2h 30m',
                  icon: 'schedule',
                  color: 'success',
                  trend: 8.2,
                  trendLabel: 'vs scorsa settimana',
                  isPositive: true,
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: StatsTheme.space3.h),
        
        // Seconda riga
        Row(
          children: [
            Expanded(
              child: ModernKPICard(
                kpiData: KPICard(
                  title: 'Serie Totali',
                  value: '180',
                  icon: 'repeat',
                  color: 'warning',
                  trend: -2.1,
                  trendLabel: 'vs scorsa settimana',
                  isPositive: false,
                ),
              ),
            ),
            SizedBox(width: StatsTheme.space3.w),
            Expanded(
              child: ModernKPICard(
                kpiData: KPICard(
                  title: 'Peso Sollevato',
                  value: '1.2t',
                  icon: 'scale',
                  color: 'info',
                  trend: 15.3,
                  trendLabel: 'vs scorsa settimana',
                  isPositive: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightsDemo() {
    final insights = [
      SmartInsight(
        id: '1',
        title: 'Ottimo progresso questa settimana!',
        description: 'Hai migliorato del 15% rispetto alla settimana scorsa. Continua così!',
        type: 'achievement',
        icon: 'emoji_events',
        color: 'premium',
        priority: 5,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      SmartInsight(
        id: '2',
        title: 'Suggerimento: Aumenta il peso',
        description: 'Potresti provare ad aumentare il peso del 5% sulla panca piana.',
        type: 'recommendation',
        icon: 'lightbulb_outline',
        color: 'info',
        priority: 3,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      SmartInsight(
        id: '3',
        title: 'Attenzione: Troppi allenamenti',
        description: 'Hai allenato le gambe 4 volte questa settimana. Considera più riposo.',
        type: 'warning',
        icon: 'warning_amber_outlined',
        color: 'warning',
        priority: 4,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    return SmartInsightsList(
      insights: insights,
      onInsightTap: (insight) => _showInsightDetails(insight),
      onInsightDismiss: (insight) => _dismissInsight(insight),
    );
  }

  Widget _buildAchievementsDemo() {
    final achievements = [
      Achievement(
        id: '1',
        title: 'Primo Allenamento',
        description: 'Completa il tuo primo allenamento',
        icon: 'fitness_center',
        color: 'primary',
        category: 'consistency',
        points: 10,
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 30)),
        progress: 1.0,
      ),
      Achievement(
        id: '2',
        title: 'Streak di 7 Giorni',
        description: 'Allenati per 7 giorni consecutivi',
        icon: 'schedule',
        color: 'success',
        category: 'consistency',
        points: 25,
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 5)),
        progress: 1.0,
      ),
      Achievement(
        id: '3',
        title: 'Sollevatore di Pesi',
        description: 'Solleva 1000kg in totale',
        icon: 'scale',
        color: 'warning',
        category: 'strength',
        points: 50,
        isUnlocked: false,
        progress: 0.75,
      ),
      Achievement(
        id: '4',
        title: 'Maratoneta',
        description: 'Completa 100 allenamenti',
        icon: 'local_fire_department',
        color: 'info',
        category: 'endurance',
        points: 100,
        isUnlocked: false,
        progress: 0.45,
      ),
    ];

    return AchievementsGrid(
      achievements: achievements,
      onAchievementTap: (achievement) => _showAchievementDetails(achievement),
    );
  }

  void _showInsightDetails(SmartInsight insight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(insight.title),
        content: Text(insight.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  void _dismissInsight(SmartInsight insight) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Insight "${insight.title}" rimosso'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAchievementDetails(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(achievement.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.description),
            SizedBox(height: StatsTheme.space4.h),
            if (achievement.isUnlocked) ...[
              Text(
                'Sbloccato!',
                style: StatsTheme.labelLarge.copyWith(
                  color: StatsTheme.successGreen,
                ),
              ),
            ] else ...[
              Text(
                'Progresso: ${(achievement.progress * 100).toInt()}%',
                style: StatsTheme.labelMedium,
              ),
            ],
            SizedBox(height: StatsTheme.space2.h),
            Text(
              'Punti: ${achievement.points}',
              style: StatsTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }
}
