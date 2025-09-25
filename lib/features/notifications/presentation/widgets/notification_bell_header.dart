// lib/features/notifications/presentation/widgets/notification_bell_header.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/notification_bloc.dart';
import 'notification_popup_overlay.dart';

/// 🔔 Widget per campanellina notifiche nell'header
class NotificationBellHeader extends StatelessWidget {
  final Color? color;
  final double size;

  const NotificationBellHeader({
    super.key,
    this.color,
    this.size = 24.0,
  });

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
          onTap: () {
            // Mostra popup notifiche
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (context) => const NotificationPopupOverlay(),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: size,
                  color: color ?? Theme.of(context).iconTheme.color,
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
