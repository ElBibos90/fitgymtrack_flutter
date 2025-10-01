// lib/features/templates/presentation/widgets/template_rating_stats_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../models/template_models.dart';

class TemplateRatingStatsWidget extends StatelessWidget {
  final WorkoutTemplate template;
  final bool showDetails;

  const TemplateRatingStatsWidget({
    super.key,
    required this.template,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(isDarkMode),
          
          SizedBox(height: 16.h),
          
          // Overall rating
          _buildOverallRating(isDarkMode),
          
          if (showDetails) ...[
            SizedBox(height: 16.h),
            
            // Usage stats
            _buildUsageStats(isDarkMode),
          ],
          
          if (template.recentReviews != null && template.recentReviews!.isNotEmpty) ...[
            SizedBox(height: 16.h),
            
            // Recent reviews preview
            _buildRecentReviewsPreview(isDarkMode),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Row(
      children: [
        Icon(
          Icons.analytics,
          size: 20.sp,
          color: AppColors.primary,
        ),
        SizedBox(width: 8.w),
        Text(
          'Statistiche Template',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            '${template.usageCount} utilizzi',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverallRating(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _getRatingColor(template.ratingAverage).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _getRatingColor(template.ratingAverage).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.star,
            size: 24.sp,
            color: _getRatingColor(template.ratingAverage),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rating Medio',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
                Text(
                  template.ratingAverage.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: _getRatingColor(template.ratingAverage),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _getRatingDescription(template.ratingAverage),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: _getRatingColor(template.ratingAverage),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '${template.ratingCount} valutazioni',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: isDarkMode ? Colors.white60 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStats(bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            'Utilizzi',
            '${template.usageCount}',
            Icons.people,
            AppColors.info,
            isDarkMode,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatItem(
            'Valutazioni',
            '${template.ratingCount}',
            Icons.rate_review,
            AppColors.warning,
            isDarkMode,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatItem(
            'Categoria',
            template.categoryName,
            Icons.category,
            AppColors.primary,
            isDarkMode,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDarkMode,
  ) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 16.sp,
            color: color,
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: isDarkMode ? Colors.white60 : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReviewsPreview(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recensioni recenti',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        ...template.recentReviews!.take(2).map((review) => _buildReviewPreview(review, isDarkMode)),
        if (template.recentReviews!.length > 2) ...[
          SizedBox(height: 8.h),
          Text(
            '+${template.recentReviews!.length - 2} altre recensioni',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewPreview(TemplateReview review, bool isDarkMode) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        children: [
          // Stelle rating
          ...List.generate(5, (index) {
            return Icon(
              index < review.rating ? Icons.star : Icons.star_border,
              size: 12.sp,
              color: AppColors.warning,
            );
          }),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              review.userName,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white70 : AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            _formatDate(review.createdAt),
            style: TextStyle(
              fontSize: 9.sp,
              color: isDarkMode ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return AppColors.success;
    if (rating >= 3.0) return AppColors.warning;
    return AppColors.error;
  }

  String _getRatingDescription(double rating) {
    if (rating >= 4.5) return 'Eccellente';
    if (rating >= 4.0) return 'Molto buono';
    if (rating >= 3.5) return 'Buono';
    if (rating >= 3.0) return 'Soddisfacente';
    if (rating >= 2.5) return 'Sufficiente';
    return 'Da migliorare';
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}g fa';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h fa';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m fa';
      } else {
        return 'Ora';
      }
    } catch (e) {
      return dateString;
    }
  }
}



