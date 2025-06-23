// lib/features/achievements/presentation/screens/achievements_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/loading_shimmer_widgets.dart';
import '../../../../shared/widgets/error_handling_widgets.dart';
import '../../models/achievement_models.dart';
import '../../services/achievement_service.dart';
import '../widgets/achievement_card.dart';

/// Schermata degli Achievement
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Achievement> _achievements = [];
  List<AchievementCategory> _categories = [];
  AchievementStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAchievements() {
    setState(() {
      _isLoading = true;
    });

    // Simula dati utente - in futuro verranno dai BLoC
    final mockData = _getMockUserData();

    _achievements = AchievementService.getBasicAchievements(
      workoutCount: mockData['workoutCount'],
      profileCompleteness: mockData['profileCompleteness'],
      currentStreak: mockData['currentStreak'],
      maxWeight: mockData['maxWeight'],
      totalMinutes: mockData['totalMinutes'],
    );

    _categories = AchievementService.organizeByCategories(_achievements);
    _stats = AchievementService.calculateStats(_achievements);

    _tabController = TabController(
      length: _categories.length + 1, // +1 per "Tutti"
      vsync: this,
    );

    setState(() {
      _isLoading = false;
    });
  }

  Map<String, dynamic> _getMockUserData() {
    // TODO: Sostituire con dati reali dai BLoC
    return {
      'workoutCount': 8, // Simulato: 8 allenamenti completati
      'profileCompleteness': 75, // Simulato: 75% profilo completato
      'currentStreak': 5, // Simulato: 5 giorni di streak
      'maxWeight': 120.0, // Simulato: peso massimo 120kg
      'totalMinutes': 720, // Simulato: 12 ore totali (720 minuti)
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Achievement'),
          centerTitle: true,
        ),
        body: const ShimmerAchievementsPage(),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Header con statistiche
          _buildStatsHeader(isDarkMode),

          // Tab bar
          _buildTabBar(isDarkMode),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllAchievementsTab(),
                ..._categories.map((category) => _buildCategoryTab(category)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Achievement'),
      centerTitle: true,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: _showHelpDialog,
          tooltip: 'Aiuto',
        ),
      ],
    );
  }

  Widget _buildStatsHeader(bool isDarkMode) {
    if (_stats == null) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Titolo e livello
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Livello ${_stats!.userLevel}',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${_stats!.totalPoints} punti totali',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Icon(
                  Icons.emoji_events,
                  size: 30.sp,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Statistiche
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Sbloccati',
                  '${_stats!.unlockedAchievements}/${_stats!.totalAchievements}',
                  Icons.check_circle,
                ),
              ),
              Container(
                width: 1,
                height: 30.h,
                color: Colors.white.withOpacity(0.3),
                margin: EdgeInsets.symmetric(horizontal: 16.w),
              ),
              Expanded(
                child: _buildStatItem(
                  'Progresso',
                  '${_stats!.completionPercentage.toStringAsFixed(0)}%',
                  Icons.trending_up,
                ),
              ),
              Container(
                width: 1,
                height: 30.h,
                color: Colors.white.withOpacity(0.3),
                margin: EdgeInsets.symmetric(horizontal: 16.w),
              ),
              Expanded(
                child: _buildStatItem(
                  'Prossimo Livello',
                  '${_stats!.pointsToNextLevel} punti',
                  Icons.arrow_upward,
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Barra progresso livello
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progresso verso livello ${_stats!.userLevel + 1}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              SizedBox(height: 4.h),
              LinearProgressIndicator(
                value: _stats!.levelProgress,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20.sp,
          color: Colors.white.withOpacity(0.9),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabBar(bool isDarkMode) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(6.r),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
        labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12.sp),
        tabs: [
          Tab(text: 'Tutti (${_achievements.length})'),
          ..._categories.map((category) {
            return Tab(
              text: '${category.name} (${category.unlockedCount}/${category.totalCount})',
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAllAchievementsTab() {
    final unlockedAchievements = _achievements.where((a) => a.isUnlocked).toList();
    final lockedAchievements = _achievements.where((a) => !a.isUnlocked).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (unlockedAchievements.isNotEmpty) ...[
            Text(
              'Sbloccati (${unlockedAchievements.length})',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            ...unlockedAchievements.map((achievement) {
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: AchievementCard(achievement: achievement),
              );
            }),

            SizedBox(height: 24.h),
          ],

          if (lockedAchievements.isNotEmpty) ...[
            Text(
              'Da sbloccare (${lockedAchievements.length})',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            ...lockedAchievements.map((achievement) {
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: AchievementCard(achievement: achievement),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryTab(AchievementCategory category) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header categoria
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            margin: EdgeInsets.only(bottom: 16.h),
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: category.color.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  category.icon,
                  color: category.color,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: category.color,
                        ),
                      ),
                      Text(
                        category.description,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: category.color.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${category.unlockedCount}/${category.totalCount}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: category.color,
                  ),
                ),
              ],
            ),
          ),

          // Achievement della categoria
          ...category.achievements.map((achievement) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: AchievementCard(achievement: achievement),
            );
          }),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help, color: Colors.blue, size: 24.sp),
            SizedBox(width: 8.w),
            const Text('Achievement'),
          ],
        ),
        content: const Text(
            'Gli achievement sono riconoscimenti che ottieni completando '
                'determinate attività o raggiungendo specifici traguardi.\n\n'
                '• Completa allenamenti per sbloccare achievement\n'
                '• Mantieni una streak di giorni consecutivi\n'
                '• Completa il tuo profilo\n'
                '• Aumenta i carichi negli esercizi\n\n'
                'Ogni achievement ti fa guadagnare punti che determinano il tuo livello!'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}