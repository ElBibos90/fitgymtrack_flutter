// lib/features/notifications/presentation/widgets/notification_badge_icon.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/notification_bloc.dart';

/// 🔔 Widget per icona notifiche con badge counter
class NotificationBadgeIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;

  const NotificationBadgeIcon({
    super.key,
    required this.icon,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationBloc, NotificationState>(
      listener: (context, state) {
        // Forza rebuild quando lo stato cambia
      },
      builder: (context, state) {
        int unreadCount = 0;
        
        if (state is NotificationLoaded) {
          // Conta le notifiche non lette
          unreadCount = state.notifications
              .where((notification) => notification.readAt == null)
              .length;
        }

        return Stack(
          children: [
            Icon(
              icon,
              size: size,
              color: color,
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
        );
      },
    );
  }
}
