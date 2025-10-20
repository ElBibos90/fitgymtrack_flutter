// lib/features/templates/presentation/widgets/template_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../models/template_models.dart';

class TemplateCard extends StatelessWidget {
  final WorkoutTemplate template;
  final bool userPremium;
  final VoidCallback onTap;

  const TemplateCard({
    super.key,
    required this.template,
    required this.userPremium,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: template.userHasAccess ? onTap : _showPremiumDialog,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con badge
            _buildHeader(isDarkMode),
            
            // Contenuto principale
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titolo e descrizione
                  _buildTitleAndDescription(context),
                  
                  SizedBox(height: 12.h),
                  
                  // Informazioni template
                  _buildTemplateInfo(),
                  
                  SizedBox(height: 12.h),
                  
                  // Rating e utilizzi
                  _buildRatingAndUsage(context),
                  
                  SizedBox(height: 16.h),
                  
                  // Pulsante azione
                  _buildActionButton(isDarkMode),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Container(
      height: 4.h,
      decoration: BoxDecoration(
        color: template.isFeatured 
            ? AppColors.primary 
            : Color(int.parse(template.categoryColor.replaceFirst('#', '0xff'))),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12.r),
          topRight: Radius.circular(12.r),
        ),
      ),
      child: Row(
        children: [
          if (template.isFeatured) ...[
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTitleAndDescription(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                template.name,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (template.isPremium && !userPremium)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'PREMIUM',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          template.description,
          style: TextStyle(
            fontSize: 14.sp,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTemplateInfo() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        _buildInfoChip(
          icon: Icons.trending_up,
          label: template.difficultyLevelFormatted,
          color: _getDifficultyColor(template.difficultyLevel),
        ),
        _buildInfoChip(
          icon: Icons.flag,
          label: template.goalFormatted,
          color: _getGoalColor(template.goal),
        ),
        _buildInfoChip(
          icon: Icons.schedule,
          label: template.estimatedDurationFormatted,
          color: AppColors.info,
        ),
        _buildInfoChip(
          icon: Icons.calendar_today,
          label: template.durationFormatted,
          color: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12.sp,
            color: color,
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingAndUsage(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        // Rating
        if (template.ratingCount > 0) ...[
          Icon(
            Icons.star,
            size: 16.sp,
            color: AppColors.warning,
          ),
          SizedBox(width: 4.w),
          Text(
            template.ratingAverage.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            '(${template.ratingCount})',
            style: TextStyle(
              fontSize: 12.sp,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
            ),
          ),
        ] else ...[
          Icon(
            Icons.star_border,
            size: 16.sp,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
          ),
          SizedBox(width: 4.w),
          Text(
            'Nessuna valutazione',
            style: TextStyle(
              fontSize: 12.sp,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
            ),
          ),
        ],
        
        const Spacer(),
        
        // Utilizzi
        Icon(
          Icons.people,
          size: 16.sp,
          color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
        ),
        SizedBox(width: 4.w),
        Text(
          '${template.usageCount} utilizzi',
          style: TextStyle(
            fontSize: 12.sp,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: template.userHasAccess ? onTap : _showPremiumDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: template.userHasAccess 
              ? AppColors.primary 
              : AppColors.textSecondary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              template.userHasAccess ? Icons.play_arrow : Icons.lock,
              size: 18.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              template.userHasAccess ? 'Visualizza Template' : 'Richiede Premium',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return AppColors.success;
      case 'intermediate':
        return AppColors.warning;
      case 'advanced':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getGoalColor(String goal) {
    switch (goal) {
      case 'strength':
        return AppColors.error;
      case 'hypertrophy':
        return AppColors.primary;
      case 'endurance':
        return AppColors.info;
      case 'weight_loss':
        return AppColors.success;
      case 'general':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  void _showPremiumDialog() {
    // TODO: Implementare dialog per upgrade premium
  }
}
