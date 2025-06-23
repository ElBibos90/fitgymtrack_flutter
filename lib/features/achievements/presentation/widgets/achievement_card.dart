// lib/features/achievements/presentation/widgets/achievement_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../models/achievement_models.dart';

/// Card per visualizzare un achievement
class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback? onTap;
  final bool showProgress;
  final bool compact;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.onTap,
    this.showProgress = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap ?? () => _showAchievementDetails(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(compact ? 12.w : 16.w),
        decoration: BoxDecoration(
          color: _getBackgroundColor(isDarkMode),
          borderRadius: BorderRadius.circular(12.r),
          border: _getBorder(),
          boxShadow: achievement.isUnlocked ? [
            BoxShadow(
              color: achievement.color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Icona achievement
                _buildIcon(),

                SizedBox(width: 12.w),

                // Contenuto principale
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle(isDarkMode),
                      SizedBox(height: 4.h),
                      _buildDescription(isDarkMode),
                      if (!compact && showProgress) ...[
                        SizedBox(height: 8.h),
                        _buildProgressInfo(isDarkMode),
                      ],
                    ],
                  ),
                ),

                // Badge/Punti
                _buildBadge(isDarkMode),
              ],
            ),

            // Barra di progresso (solo se non sbloccato e showProgress)
            if (!achievement.isUnlocked && showProgress && !compact) ...[
              SizedBox(height: 12.h),
              _buildProgressBar(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: compact ? 40.w : 48.w,
      height: compact ? 40.w : 48.w,
      decoration: BoxDecoration(
        color: achievement.isUnlocked
            ? achievement.color.withOpacity(0.2)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: achievement.isUnlocked
            ? Border.all(color: achievement.color.withOpacity(0.3))
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Icona principale
          Icon(
            achievement.icon,
            size: compact ? 20.sp : 24.sp,
            color: achievement.isUnlocked
                ? achievement.color
                : Colors.grey.shade400,
          ),

          // Overlay per achievement bloccati
          if (!achievement.isUnlocked)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),

          // Badge sbloccato
          if (achievement.isUnlocked)
            Positioned(
              top: 2.h,
              right: 2.w,
              child: Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Icon(
                  Icons.check,
                  size: 8.sp,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitle(bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: Text(
            achievement.title,
            style: TextStyle(
              fontSize: compact ? 14.sp : 16.sp,
              fontWeight: FontWeight.bold,
              color: achievement.isUnlocked
                  ? (isDarkMode ? Colors.white : Colors.black)
                  : Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Emoji se disponibile
        if (achievement.iconEmoji != null) ...[
          SizedBox(width: 4.w),
          Text(
            achievement.iconEmoji!,
            style: TextStyle(fontSize: compact ? 14.sp : 16.sp),
          ),
        ],
      ],
    );
  }

  Widget _buildDescription(bool isDarkMode) {
    return Text(
      achievement.description,
      style: TextStyle(
        fontSize: compact ? 11.sp : 12.sp,
        color: achievement.isUnlocked
            ? (isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700)
            : Colors.grey.shade500,
        height: 1.3,
      ),
      maxLines: compact ? 1 : 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildProgressInfo(bool isDarkMode) {
    if (achievement.isUnlocked) {
      return Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 14.sp,
            color: Colors.green,
          ),
          SizedBox(width: 4.w),
          Text(
            'Completato!',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (achievement.unlockedAt != null) ...[
            SizedBox(width: 8.w),
            Text(
              '• ${_formatDate(achievement.unlockedAt!)}',
              style: TextStyle(
                fontSize: 10.sp,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        Icon(
          Icons.radio_button_unchecked,
          size: 14.sp,
          color: Colors.grey.shade400,
        ),
        SizedBox(width: 4.w),
        Text(
          achievement.progressDescription,
          style: TextStyle(
            fontSize: 11.sp,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          '(${achievement.progressPercentage}%)',
          style: TextStyle(
            fontSize: 10.sp,
            color: achievement.color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: achievement.isUnlocked
            ? achievement.color.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: achievement.isUnlocked
              ? achievement.color.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: 12.sp,
            color: achievement.isUnlocked
                ? achievement.color
                : Colors.grey.shade400,
          ),
          SizedBox(width: 2.w),
          Text(
            '${achievement.points}',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: achievement.isUnlocked
                  ? achievement.color
                  : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progresso',
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              '${achievement.progressPercentage}%',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: achievement.color,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        LinearProgressIndicator(
          value: achievement.progress,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(achievement.color),
          minHeight: 4.h,
        ),
      ],
    );
  }

  Color _getBackgroundColor(bool isDarkMode) {
    if (achievement.isUnlocked) {
      return isDarkMode
          ? AppColors.surfaceDark
          : Colors.white;
    }

    return isDarkMode
        ? AppColors.surfaceDark.withOpacity(0.7)
        : Colors.grey.shade50;
  }

  Border? _getBorder() {
    if (achievement.isUnlocked) {
      return Border.all(
        color: achievement.color.withOpacity(0.3),
        width: 1,
      );
    }

    return Border.all(
      color: Colors.grey.withOpacity(0.2),
      width: 1,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Oggi';
    } else if (difference.inDays == 1) {
      return 'Ieri';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} giorni fa';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showAchievementDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AchievementDetailsDialog(achievement: achievement),
    );
  }
}

/// Dialog con dettagli dell'achievement
class _AchievementDetailsDialog extends StatelessWidget {
  final Achievement achievement;

  const _AchievementDetailsDialog({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      title: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: achievement.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              achievement.icon,
              color: achievement.color,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              achievement.title,
              style: TextStyle(fontSize: 18.sp),
            ),
          ),
          if (achievement.iconEmoji != null)
            Text(
              achievement.iconEmoji!,
              style: TextStyle(fontSize: 24.sp),
            ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            achievement.description,
            style: TextStyle(
              fontSize: 14.sp,
              height: 1.4,
            ),
          ),

          SizedBox(height: 16.h),

          Row(
            children: [
              Icon(
                Icons.category,
                size: 16.sp,
                color: Colors.grey.shade600,
              ),
              SizedBox(width: 8.w),
              Text(
                'Categoria: ${achievement.type.displayName}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          Row(
            children: [
              Icon(
                Icons.star,
                size: 16.sp,
                color: Colors.grey.shade600,
              ),
              SizedBox(width: 8.w),
              Text(
                'Punti: ${achievement.points}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          if (achievement.isUnlocked) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Achievement sbloccato!',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: achievement.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: achievement.color.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progresso: ${achievement.progressDescription}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: achievement.color,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  LinearProgressIndicator(
                    value: achievement.progress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(achievement.color),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${achievement.progressPercentage}% completato',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: achievement.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Chiudi'),
        ),
      ],
    );
  }
}