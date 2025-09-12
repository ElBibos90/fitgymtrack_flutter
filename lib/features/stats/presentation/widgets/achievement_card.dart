// lib/features/stats/presentation/widgets/achievement_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/stats_theme.dart';
import '../../models/simple_stats_models.dart';

/// 🏆 Achievement Card - Card per Achievement
class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback? onTap;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: StatsTheme.animationMedium,
        curve: Curves.easeOutCubic,
        child: Container(
          padding: EdgeInsets.all(StatsTheme.space3.w),
          decoration: BoxDecoration(
            color: StatsTheme.getCardBackground(context),
            borderRadius: BorderRadius.circular(StatsTheme.radiusLarge.r),
            boxShadow: achievement.isUnlocked 
                ? StatsTheme.shadowMedium 
                : StatsTheme.shadowSmall,
            border: Border.all(
              color: achievement.isUnlocked 
                  ? _getCategoryColor().withOpacity(0.3)
                  : StatsTheme.neutral300,
              width: achievement.isUnlocked ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icona achievement
              Stack(
                children: [
                  Container(
                    padding: EdgeInsets.all(StatsTheme.space3.w),
                    decoration: BoxDecoration(
                      gradient: achievement.isUnlocked 
                          ? _getCategoryGradient()
                          : LinearGradient(
                              colors: [StatsTheme.neutral300, StatsTheme.neutral400],
                            ),
                      borderRadius: BorderRadius.circular(StatsTheme.radiusMedium.r),
                    ),
                    child: Icon(
                      _getCategoryIcon(),
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                  
                  // Badge sbloccato
                  if (achievement.isUnlocked)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: StatsTheme.successGreen,
                          borderRadius: BorderRadius.circular(StatsTheme.radiusSmall.r),
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 10.sp,
                        ),
                      ),
                    ),
                ],
              ),
              
              SizedBox(height: StatsTheme.space2.h),
              
              // Titolo
              Flexible(
                child: Text(
                  achievement.title,
                  style: StatsTheme.labelMedium.copyWith(
                    color: achievement.isUnlocked 
                        ? StatsTheme.getTextPrimary(context)
                        : StatsTheme.getTextSecondary(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              SizedBox(height: StatsTheme.space1.h),
              
              // Descrizione
              Flexible(
                child: Text(
                  achievement.description,
                  style: StatsTheme.caption.copyWith(
                    color: StatsTheme.getTextSecondary(context),
                    fontSize: 10.sp,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              SizedBox(height: StatsTheme.space2.h),
              
              // Progress bar (se non sbloccato)
              if (!achievement.isUnlocked) ...[
                Container(
                  height: 3.h,
                  decoration: BoxDecoration(
                    color: StatsTheme.neutral200,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: achievement.progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: _getCategoryGradient(),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: StatsTheme.space1.h),
                Text(
                  '${(achievement.progress * 100).toInt()}%',
                  style: StatsTheme.caption.copyWith(
                    color: StatsTheme.getTextSecondary(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 9.sp,
                  ),
                ),
              ] else ...[
                // Data sbloccamento
                if (achievement.unlockedAt != null)
                  Text(
                    'Sbloccato ${_formatDate(achievement.unlockedAt!)}',
                    style: StatsTheme.caption.copyWith(
                      color: _getCategoryColor(),
                      fontWeight: FontWeight.w600,
                      fontSize: 9.sp,
                    ),
                  ),
              ],
              
              SizedBox(height: StatsTheme.space1.h),
              
              // Punti
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: StatsTheme.space1.w,
                  vertical: 2.h,
                ),
                decoration: BoxDecoration(
                  color: _getCategoryColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(StatsTheme.radiusSmall.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      color: _getCategoryColor(),
                      size: 10.sp,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      '${achievement.points} pts',
                      style: StatsTheme.caption.copyWith(
                        color: _getCategoryColor(),
                        fontWeight: FontWeight.w600,
                        fontSize: 9.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (achievement.category) {
      case 'strength':
        return Icons.fitness_center;
      case 'consistency':
        return Icons.schedule;
      case 'endurance':
        return Icons.local_fire_department;
      case 'variety':
        return Icons.diversity_3;
      default:
        return Icons.emoji_events;
    }
  }

  Color _getCategoryColor() {
    switch (achievement.category) {
      case 'strength':
        return StatsTheme.warningOrange;
      case 'consistency':
        return StatsTheme.successGreen;
      case 'endurance':
        return StatsTheme.warningRed;
      case 'variety':
        return StatsTheme.infoCyan;
      default:
        return StatsTheme.primaryBlue;
    }
  }

  LinearGradient _getCategoryGradient() {
    switch (achievement.category) {
      case 'strength':
        return StatsTheme.warningGradient;
      case 'consistency':
        return StatsTheme.successGradient;
      case 'endurance':
        return LinearGradient(
          colors: [StatsTheme.warningRed, Color(0xFFFF6B6B)],
        );
      case 'variety':
        return StatsTheme.infoGradient;
      default:
        return StatsTheme.primaryGradient;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'oggi';
    } else if (difference.inDays == 1) {
      return 'ieri';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} giorni fa';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} settimane fa';
    } else {
      return '${(difference.inDays / 30).floor()} mesi fa';
    }
  }
}

/// 🏆 Achievements Grid - Griglia Achievement
class AchievementsGrid extends StatelessWidget {
  final List<Achievement> achievements;
  final Function(Achievement)? onAchievementTap;

  const AchievementsGrid({
    super.key,
    required this.achievements,
    this.onAchievementTap,
  });

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: StatsTheme.space4.w),
          child: Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: StatsTheme.warningOrange,
                size: 20.sp,
              ),
              SizedBox(width: StatsTheme.space2.w),
              Text(
                'Achievements',
                style: StatsTheme.h4.copyWith(
                  color: StatsTheme.getTextPrimary(context),
                ),
              ),
              const Spacer(),
              // Statistiche achievement
              _buildAchievementStats(),
            ],
          ),
        ),
        
        SizedBox(height: StatsTheme.space4.h),
        
        // Griglia achievement
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: StatsTheme.space4.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: StatsTheme.space3.w,
            mainAxisSpacing: StatsTheme.space3.h,
            childAspectRatio: 1.0,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            return AchievementCard(
              achievement: achievements[index],
              onTap: () => onAchievementTap?.call(achievements[index]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAchievementStats() {
    final unlocked = achievements.where((a) => a.isUnlocked).length;
    final total = achievements.length;
    final percentage = total > 0 ? (unlocked / total * 100).round() : 0;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: StatsTheme.space2.w,
        vertical: StatsTheme.space1.h,
      ),
      decoration: BoxDecoration(
        color: StatsTheme.successGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(StatsTheme.radiusSmall.r),
      ),
      child: Text(
        '$unlocked/$total ($percentage%)',
        style: StatsTheme.caption.copyWith(
          color: StatsTheme.successGreen,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(StatsTheme.space8.w),
      margin: EdgeInsets.symmetric(horizontal: StatsTheme.space4.w),
      decoration: BoxDecoration(
        color: StatsTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(StatsTheme.radiusLarge.r),
        boxShadow: StatsTheme.shadowSmall,
      ),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            color: StatsTheme.getTextSecondary(context),
            size: 48.sp,
          ),
          SizedBox(height: StatsTheme.space4.h),
          Text(
            'Nessun achievement disponibile',
            style: StatsTheme.h4.copyWith(
              color: StatsTheme.getTextPrimary(context),
            ),
          ),
          SizedBox(height: StatsTheme.space2.h),
          Text(
            'Inizia ad allenarti per sbloccare i tuoi primi achievement!',
            style: StatsTheme.bodyMedium.copyWith(
              color: StatsTheme.getTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
