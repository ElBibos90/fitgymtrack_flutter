// lib/features/notifications/presentation/widgets/modern_notification_menu.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../bloc/notification_bloc.dart';
import '../../models/notification_models.dart' as models;
import 'notification_message_widget.dart';

/// 🔔 Menu notifiche moderno con popup a scomparsa e swipe gestures
class ModernNotificationMenu extends StatefulWidget {
  final Color? color;
  final double size;

  const ModernNotificationMenu({
    super.key,
    this.color,
    this.size = 24.0,
  });

  @override
  State<ModernNotificationMenu> createState() => _ModernNotificationMenuState();
}

class _ModernNotificationMenuState extends State<ModernNotificationMenu>
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showNotificationMenu() {
    _animationController.forward();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _NotificationMenuOverlay(
        animationController: _animationController,
        fadeAnimation: _fadeAnimation,
        slideAnimation: _slideAnimation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        int unreadCount = 0;
        
        if (state is NotificationLoaded) {
          unreadCount = state.notifications
              .where((notification) => notification.readAt == null)
              .length;
        }

        return GestureDetector(
          onTap: _showNotificationMenu,
          child: Container(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: widget.size,
                  color: widget.color ?? Theme.of(context).iconTheme.color,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 1,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 🎨 Overlay del menu notifiche con animazioni
class _NotificationMenuOverlay extends StatefulWidget {
  final AnimationController animationController;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const _NotificationMenuOverlay({
    required this.animationController,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  State<_NotificationMenuOverlay> createState() => _NotificationMenuOverlayState();
}

class _NotificationMenuOverlayState extends State<_NotificationMenuOverlay> {
  void _closeMenu() {
    widget.animationController.reverse().then((_) {
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
        onTap: _closeMenu,
        child: Container(
          color: Colors.black.withValues(alpha: 0.5),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Previene la chiusura quando si clicca sul menu
              child: FadeTransition(
                opacity: widget.fadeAnimation,
                child: SlideTransition(
                  position: widget.slideAnimation,
                  child: Container(
                    width: 350.w,
                    height: 600.h,
                    margin: EdgeInsets.symmetric(horizontal: 20.w),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header
                        _buildHeader(isDark),
                        // Content
                        Expanded(
                          child: _buildNotificationList(isDark),
                        ),
                        // Footer
                        _buildFooter(isDark),
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

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.indigo600, AppColors.green600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.notifications_rounded,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifiche',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                BlocBuilder<NotificationBloc, NotificationState>(
                  builder: (context, state) {
                    int unreadCount = 0;
                    if (state is NotificationLoaded) {
                      unreadCount = state.notifications
                          .where((notification) => notification.readAt == null)
                          .length;
                    }
                    return Text(
                      '$unreadCount non lette',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              size: 24.sp,
            ),
            onPressed: _closeMenu,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(bool isDark) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        if (state is NotificationLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (state is NotificationLoaded) {
          final notifications = state.notifications;
          
          if (notifications.isEmpty) {
            return _buildEmptyState(isDark);
          }
          
          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildSwipeableNotificationItem(notification, isDark);
            },
          );
        } else if (state is NotificationError) {
          return _buildErrorState(isDark);
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSwipeableNotificationItem(models.Notification notification, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Dismissible(
        key: Key('notification_${notification.id}'),
        direction: DismissDirection.horizontal,
        background: _buildSwipeBackground(
          Icons.check_rounded,
          'Segna come letta',
          Colors.green,
          Alignment.centerLeft,
        ),
        secondaryBackground: _buildSwipeBackground(
          notification.isUnread ? Icons.mark_email_read_rounded : Icons.mark_email_unread_rounded,
          notification.isUnread ? 'Segna letta' : 'Segna non letta',
          notification.isUnread ? Colors.green : Colors.orange,
          Alignment.centerRight,
        ),
        onDismissed: (direction) {
          // Non facciamo nulla qui - gestiamo tutto con confirmDismiss
          // Questo evita l'errore "dismissed Dismissible widget is still part of the tree"
        },
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Swipe sinistro - Segna come letta (solo se non letta)
            if (notification.isUnread) {
              context.read<NotificationBloc>().add(
                MarkAsReadEvent(notification.id),
              );
            }
            return false; // Non rimuovere il widget
          } else if (direction == DismissDirection.endToStart) {
            // Swipe destro - Toggle stato lettura
            if (notification.isUnread) {
              // Se non letta, segna come letta
              context.read<NotificationBloc>().add(
                MarkAsReadEvent(notification.id),
              );
            } else {
              // Se letta, segna come non letta
              context.read<NotificationBloc>().add(
                MarkAsUnreadEvent(notification.id),
              );
            }
            return false; // Non rimuovere il widget
          }
          return false; // Non rimuovere mai il widget
        },
        child: _buildNotificationItem(notification, isDark),
      ),
    );
  }

  Widget _buildSwipeBackground(IconData icon, String label, Color color, Alignment alignment) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.r),
      ),
      alignment: alignment,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: alignment == Alignment.centerLeft 
            ? MainAxisAlignment.start 
            : MainAxisAlignment.end,
        children: [
          Icon(icon, color: Colors.white, size: 24.sp),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(models.Notification notification, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: notification.isUnread 
            ? (isDark ? AppColors.indigo600.withValues(alpha: 0.2) : AppColors.indigo50)
            : (isDark ? AppColors.backgroundDark : AppColors.backgroundLight),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: notification.isUnread 
              ? AppColors.indigo600.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
          width: notification.isUnread ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          _closeMenu();
          // Naviga alla schermata notifiche completa per i dettagli
          Navigator.of(context).pushNamed('/notifications');
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con icona, titolo e stato
            Row(
              children: [
                // Icona tipo
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: _getPriorityColor(notification.priority).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: Text(
                      notification.typeIcon,
                      style: TextStyle(fontSize: 20.sp),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                // Titolo e mittente
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: notification.isUnread ? FontWeight.bold : FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        notification.senderDisplayName,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark ? Colors.grey[300] : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Pulsante cestino per cancellare
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20.sp,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onPressed: () => _showDeleteConfirmation(notification, isDark),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                SizedBox(width: 8.w),
                // Indicatore non letta
                if (notification.isUnread)
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            // Messaggio (con gestione \n)
            NotificationMessageWidget(
              message: notification.message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              isDark: isDark,
            ),
            SizedBox(height: 12.h),
            // Footer con data e priorità
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  notification.formattedDate,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(notification.priority).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    notification.priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: _getPriorityColor(notification.priority),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
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
          SizedBox(height: 8.h),
          Text(
            'Le notifiche dalla tua palestra\nappariranno qui',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
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

  Widget _buildFooter(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () {
                _closeMenu();
                Navigator.of(context).pushNamed('/notifications');
              },
              icon: Icon(
                Icons.list_rounded,
                size: 18.sp,
                color: AppColors.indigo600,
              ),
              label: Text(
                'Vedi tutte',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.indigo600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: TextButton.icon(
              onPressed: () {
                context.read<NotificationBloc>().add(const MarkAllAsReadEvent());
                _closeMenu();
              },
              icon: Icon(
                Icons.done_all_rounded,
                size: 18.sp,
                color: AppColors.green600,
              ),
              label: Text(
                'Segna tutte',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.green600,
                  fontWeight: FontWeight.w600,
                ),
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

  /// Mostra dialog di conferma per cancellare la notifica
  void _showDeleteConfirmation(models.Notification notification, bool isDark) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[800] : Colors.white,
          title: Text(
            'Elimina Notifica',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Sei sicuro di voler eliminare questa notifica?',
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.black54,
              fontSize: 14.sp,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annulla',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14.sp,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<NotificationBloc>().add(
                  DeleteNotificationEvent(notification.id),
                );
              },
              child: Text(
                'Elimina',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
