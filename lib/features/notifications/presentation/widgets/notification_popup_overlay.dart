// lib/features/notifications/presentation/widgets/notification_popup_overlay.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../bloc/notification_bloc.dart';
import '../../models/notification_models.dart' as models;
import 'notification_message_widget.dart';

/// 🔔 Popup overlay per notifiche stile moderno
class NotificationPopupOverlay extends StatefulWidget {
  const NotificationPopupOverlay({super.key});

  @override
  State<NotificationPopupOverlay> createState() => _NotificationPopupOverlayState();
}

class _NotificationPopupOverlayState extends State<NotificationPopupOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closePopup() {
    _animationController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _closePopup,
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Previene la chiusura quando si clicca sul popup
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    width: 350.w,
                    height: 500.h,
                    margin: EdgeInsets.symmetric(horizontal: 20.w),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16.r),
                              topRight: Radius.circular(16.r),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.notifications_rounded,
                                color: AppColors.indigo600,
                                size: 24.sp,
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                'Notifiche',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                                ),
                                onPressed: _closePopup,
                              ),
                            ],
                          ),
                        ),
                        // Content
                        Expanded(
                          child: BlocBuilder<NotificationBloc, NotificationState>(
                            builder: (context, state) {
                              if (state is NotificationLoading) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              } else if (state is NotificationLoaded) {
                                final notifications = state.notifications;
                                
                                if (notifications.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.notifications_none_rounded,
                                          size: 64.sp,
                                          color: isDark ? Colors.white38 : AppColors.textSecondary,
                                        ),
                                        SizedBox(height: 16.h),
                                        Text(
                                          'Nessuna notifica',
                                          style: TextStyle(
                                            fontSize: 18.sp,
                                            color: isDark ? Colors.white70 : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                
                                return ListView.builder(
                                  padding: EdgeInsets.all(16.w),
                                  itemCount: notifications.length,
                                  itemBuilder: (context, index) {
                                    final notification = notifications[index];
                                    return _buildNotificationItem(notification, isDark);
                                  },
                                );
                              } else if (state is NotificationError) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 64.sp,
                                        color: Colors.red,
                                      ),
                                      SizedBox(height: 16.h),
                                      Text(
                                        'Errore nel caricamento',
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(models.Notification notification, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? AppColors.border.withOpacity(0.3) : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                notification.typeIcon,
                style: TextStyle(fontSize: 20.sp),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  notification.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              if (notification.isUnread)
                Container(
                  width: 8.w,
                  height: 8.h,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          NotificationMessageWidget(
            message: notification.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            isDark: isDark,
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Text(
                notification.formattedDate,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (notification.isUnread)
                TextButton(
                  onPressed: () {
                    context.read<NotificationBloc>().add(
                      MarkAsReadEvent(notification.id),
                    );
                  },
                  child: Text(
                    'Segna come letta',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.indigo600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
