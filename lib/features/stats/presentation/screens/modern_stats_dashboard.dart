// lib/features/stats/presentation/screens/modern_stats_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/stats_theme.dart';
import '../../models/simple_stats_models.dart';
import '../widgets/modern_kpi_card.dart';
import '../widgets/smart_insight_card.dart';

/// 📊 Modern Stats Dashboard - Dashboard Statistiche Moderna
class ModernStatsDashboard extends StatefulWidget {
  const ModernStatsDashboard({super.key});

  @override
  State<ModernStatsDashboard> createState() => _ModernStatsDashboardState();
}

class _ModernStatsDashboardState extends State<ModernStatsDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StatsTheme.getPageBackground(context),
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildAnalyticsTab(),
          _buildAchievementsTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'Statistiche',
        style: StatsTheme.h3.copyWith(
          color: StatsTheme.getTextPrimary(context),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.refresh,
            color: StatsTheme.primaryBlue,
            size: 24.sp,
          ),
          onPressed: _refreshStats,
        ),
        IconButton(
          icon: Icon(
            Icons.share,
            color: StatsTheme.primaryBlue,
            size: 24.sp,
          ),
          onPressed: _shareStats,
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _refreshStats,
      color: StatsTheme.primaryBlue,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(StatsTheme.space4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section con Fitness Score
            _buildHeroSection(),
            
            SizedBox(height: StatsTheme.space6.h),
            
            // KPI Cards
            _buildKPISection(),
            
            SizedBox(height: StatsTheme.space6.h),
            
            // Smart Insights
            _buildInsightsSection(),
            
            SizedBox(height: StatsTheme.space6.h),
            
            // Quick Actions
            _buildQuickActionsSection(),
            
            SizedBox(height: StatsTheme.space20.h), // Spazio per bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(StatsTheme.space4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analisi Dettagliate',
            style: StatsTheme.h3.copyWith(
              color: StatsTheme.getTextPrimary(context),
            ),
          ),
          SizedBox(height: StatsTheme.space4.h),
          
          // Placeholder per analisi dettagliate
          _buildPlaceholderCard(
            'Grafici di Progressione',
            'Visualizza i tuoi progressi nel tempo',
            Icons.trending_up,
            StatsTheme.primaryGradient,
          ),
          
          SizedBox(height: StatsTheme.space4.h),
          
          _buildPlaceholderCard(
            'Analisi Gruppi Muscolari',
            'Scopri quali muscoli alleni di più',
            Icons.fitness_center,
            StatsTheme.successGradient,
          ),
          
          SizedBox(height: StatsTheme.space4.h),
          
          _buildPlaceholderCard(
            'Confronti Temporali',
            'Confronta le tue performance',
            Icons.compare_arrows,
            StatsTheme.warningGradient,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(StatsTheme.space4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Achievements',
            style: StatsTheme.h3.copyWith(
              color: StatsTheme.getTextPrimary(context),
            ),
          ),
          SizedBox(height: StatsTheme.space4.h),
          
          // Placeholder per achievements
          _buildPlaceholderCard(
            'Sistema Achievement',
            'Sblocca badge e riconoscimenti',
            Icons.emoji_events,
            StatsTheme.premiumGradient,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
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
          // Fitness Score
          Text(
            'Fitness Score',
            style: StatsTheme.labelLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: StatsTheme.space2.h),
          
          // Score principale
          Text(
            '85',
            style: StatsTheme.metricLarge.copyWith(
              color: Colors.white,
            ),
          ),
          SizedBox(height: StatsTheme.space2.h),
          
          // Descrizione
          Text(
            'Eccellente',
            style: StatsTheme.h4.copyWith(
              color: Colors.white,
            ),
          ),
          SizedBox(height: StatsTheme.space4.h),
          
          // Score breakdown
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

  Widget _buildKPISection() {
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
        
        // Prima riga KPI
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
        
        // Seconda riga KPI
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

  Widget _buildInsightsSection() {
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
    ];

    return SmartInsightsList(
      insights: insights,
      onInsightTap: (insight) => _showInsightDetails(insight),
      onInsightDismiss: (insight) => _dismissInsight(insight),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Azioni Rapide',
          style: StatsTheme.h4.copyWith(
            color: StatsTheme.getTextPrimary(context),
          ),
        ),
        SizedBox(height: StatsTheme.space4.h),
        
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Esporta Dati',
                Icons.download,
                StatsTheme.primaryGradient,
                () => _exportData(),
              ),
            ),
            SizedBox(width: StatsTheme.space3.w),
            Expanded(
              child: _buildActionButton(
                'Condividi',
                Icons.share,
                StatsTheme.successGradient,
                () => _shareStats(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    LinearGradient gradient,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(StatsTheme.space4.w),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(StatsTheme.radiusLarge.r),
          boxShadow: StatsTheme.shadowMedium,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24.sp,
            ),
            SizedBox(height: StatsTheme.space2.h),
            Text(
              label,
              style: StatsTheme.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCard(
    String title,
    String description,
    IconData icon,
    LinearGradient gradient,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(StatsTheme.space6.w),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(StatsTheme.radiusLarge.r),
        boxShadow: StatsTheme.shadowMedium,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 48.sp,
          ),
          SizedBox(height: StatsTheme.space4.h),
          Text(
            title,
            style: StatsTheme.h4.copyWith(
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: StatsTheme.space2.h),
          Text(
            description,
            style: StatsTheme.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: StatsTheme.getCardBackground(context),
        boxShadow: StatsTheme.shadowLarge,
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: StatsTheme.primaryBlue,
        labelColor: StatsTheme.primaryBlue,
        unselectedLabelColor: StatsTheme.getTextSecondary(context),
        labelStyle: StatsTheme.labelMedium,
        tabs: const [
          Tab(
            icon: Icon(Icons.dashboard),
            text: 'Overview',
          ),
          Tab(
            icon: Icon(Icons.analytics),
            text: 'Analisi',
          ),
          Tab(
            icon: Icon(Icons.emoji_events),
            text: 'Achievements',
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 🎯 ACTIONS - Azioni
  // ============================================================================

  Future<void> _refreshStats() async {
    // TODO: Implementare refresh delle statistiche
    await Future.delayed(const Duration(seconds: 1));
  }

  void _shareStats() {
    // TODO: Implementare condivisione statistiche
  }

  void _exportData() {
    // TODO: Implementare esportazione dati
  }

  void _showInsightDetails(SmartInsight insight) {
    // TODO: Mostrare dettagli insight
  }

  void _dismissInsight(SmartInsight insight) {
    // TODO: Rimuovere insight
  }
}
