// lib/features/notifications/presentation/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../bloc/notification_bloc.dart';
import '../../models/notification_models.dart' as models;
import '../../repositories/notification_repository.dart';
import '../../../../core/config/app_config.dart';
import '../widgets/notification_popup.dart';
import '../widgets/notification_message_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Carica le notifiche iniziali
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationBloc>().add(const LoadNotificationsEvent());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreNotifications();
    }
  }

  void _loadMoreNotifications() {
    final state = context.read<NotificationBloc>().state;
    if (state is NotificationLoaded && !state.hasReachedMax) {
      _currentPage++;
      context.read<NotificationBloc>().add(
        LoadNotificationsEvent(page: _currentPage),
      );
    }
  }

  void _showNotificationPopup(models.Notification notification) {
    showDialog(
      context: context,
      builder: (context) => NotificationPopup(
        notification: notification,
        onMarkAsRead: notification.isUnread ? () {
          Navigator.of(context).pop(); // Chiudi popup
          _markAsRead(notification.id);
        } : null,
        onClose: () => Navigator.of(context).pop(),
        // Azioni personalizzate per il futuro (corsi, iscrizioni, etc.)
        customActions: _getCustomActions(notification),
      ),
    );
  }

  void _markAsRead(int notificationId) {
    // Invia l'evento al BLoC
    context.read<NotificationBloc>().add(MarkAsReadEvent(notificationId));
  }

  // Metodo per azioni personalizzate (per il futuro)
  List<NotificationAction>? _getCustomActions(models.Notification notification) {
    // TODO: Implementare azioni specifiche per tipo di notifica
    // Esempio futuro:
    // switch (notification.type) {
    //   case 'course_invitation':
    //     return [
    //       NotificationAction(
    //         label: 'Iscriviti',
    //         icon: Icons.school,
    //         color: AppColors.success,
    //         onPressed: () => _enrollInCourse(notification),
    //       ),
    //     ];
    //   case 'workout_reminder':
    //     return [
    //       NotificationAction(
    //         label: 'Inizia Allenamento',
    //         icon: Icons.fitness_center,
    //         color: AppColors.indigo600,
    //         onPressed: () => _startWorkout(notification),
    //       ),
    //     ];
    // }
    return null;
  }

  void _refreshNotifications() {
    _currentPage = 1;
    context.read<NotificationBloc>().add(
      const LoadNotificationsEvent(page: 1, refresh: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BlocListener<NotificationBloc, NotificationState>(
      listener: (context, state) {
        if (state is NotificationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore: ${state.message}'),
              duration: const Duration(seconds: 3),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(
          title: Text(
            'Notifiche',
            style: TextStyle(
              fontSize: 24,
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          elevation: 0,
          actions: [
            BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, state) {
                if (state is NotificationLoaded && state.unreadCount > 0) {
                  return Container(
                    margin: EdgeInsets.only(right: 16.w),
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      '${state.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            if (state is NotificationLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is NotificationError) {
              return _buildErrorState(state.message, isDark);
            }

            if (state is NotificationLoaded) {
              if (state.notifications.isEmpty) {
                return _buildEmptyState(isDark);
              }

              return RefreshIndicator(
                onRefresh: () async {
                  _refreshNotifications();
                },
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(16.w),
                  itemCount: state.notifications.length + (state.hasReachedMax ? 0 : 1),
                  itemBuilder: (context, index) {
                    if (index >= state.notifications.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final notification = state.notifications[index];
                    return _buildNotificationCard(notification, isDark);
                  },
                ),
              );
            }

            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard(models.Notification notification, bool isDark) {
    return Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: notification.isUnread 
              ? (isDark ? AppColors.indigo600.withOpacity(0.2) : AppColors.indigo50)
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: notification.isUnread 
                ? AppColors.indigo600.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
            width: notification.isUnread ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            _showNotificationPopup(notification);
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
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
                        color: _getPriorityColor(notification.priority).withOpacity(0.1),
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
                              fontSize: 16,
                              fontWeight: notification.isUnread ? FontWeight.bold : FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            notification.senderDisplayName,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey[300] : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                // Messaggio
                NotificationMessageWidget(
                  message: notification.message,
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
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(notification.priority).withOpacity(0.1),
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
              ],
            ),
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
            Icons.notifications_none,
            size: 64.w,
            color: Colors.grey.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'Nessuna notifica',
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Le notifiche dalla tua palestra\nappariranno qui',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.w,
            color: Colors.red.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'Errore',
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _refreshNotifications,
            icon: const Icon(Icons.refresh),
            label: const Text('Riprova'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.indigo600,
              foregroundColor: Colors.white,
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