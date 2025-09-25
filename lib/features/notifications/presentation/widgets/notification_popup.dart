// lib/features/notifications/presentation/widgets/notification_popup.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../models/notification_models.dart' as models;

class NotificationPopup extends StatelessWidget {
  final models.Notification notification;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onClose;
  final List<NotificationAction>? customActions;

  const NotificationPopup({
    super.key,
    required this.notification,
    this.onMarkAsRead,
    this.onClose,
    this.customActions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 20.w),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con icona e titolo
            _buildHeader(isDark),
            
            // Contenuto della notifica
            _buildContent(isDark),
            
            // Azioni
            _buildActions(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: _getPriorityColor(notification.priority).withOpacity(0.1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
      ),
      child: Row(
        children: [
          // Icona tipo notifica
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: _getPriorityColor(notification.priority).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Text(
                notification.typeIcon,
                style: TextStyle(
                  fontSize: 24.sp,
                  color: _getPriorityColor(notification.priority),
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          
          // Titolo e mittente
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Da: ${notification.senderDisplayName}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[300] : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Priorità
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: _getPriorityColor(notification.priority).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              notification.priority.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _getPriorityColor(notification.priority),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Messaggio
          Text(
            notification.message,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[300] : AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Data e ora
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16.w,
                color: isDark ? Colors.grey[400] : AppColors.textSecondary,
              ),
              SizedBox(width: 8.w),
              Text(
                notification.formattedDate,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16.r),
          bottomRight: Radius.circular(16.r),
        ),
      ),
      child: Row(
        children: [
          // Pulsante Segna come letta
          if (notification.isUnread && onMarkAsRead != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onMarkAsRead,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Segna come letta'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.success,
                  side: BorderSide(color: AppColors.success),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
          
          if (notification.isUnread && onMarkAsRead != null)
            SizedBox(width: 12.w),
          
          // Azioni personalizzate (per il futuro)
          if (customActions != null && customActions!.isNotEmpty)
            ...customActions!.map((action) => 
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: 12.w),
                  child: ElevatedButton.icon(
                    onPressed: action.onPressed,
                    icon: Icon(action.icon),
                    label: Text(action.label),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: action.color,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
              ),
            ),
          
          // Pulsante Chiudi
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onClose ?? () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              label: const Text('Chiudi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey[300],
                foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'normal':
        return AppColors.indigo600;
      case 'low':
        return Colors.grey;
      default:
        return AppColors.indigo600;
    }
  }
}

// Classe per azioni personalizzate (per il futuro)
class NotificationAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const NotificationAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });
}
